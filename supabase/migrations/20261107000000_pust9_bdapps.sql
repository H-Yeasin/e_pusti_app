-- e-Pushti: PUST9 on bdapps (Robi/Airtel). In-app subscription through the
-- bdapps OTP API, the daily tip SMS, SMS keywords and the USSD menu.
--
-- Only the Edge Functions (service role) write these tables. The bdapps
-- application password never reaches the app; see supabase/README.md.

-- One row per bdapps subscriber (masked id), however they joined: app,
-- SMS keyword or USSD. user_id links the ones who subscribed in the app.
create table public.pust9_members (
  subscriber_id text primary key,
  status text not null check (status in ('registered', 'unregistered')),
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  last_day_sent int not null default 0,
  last_sent_on date,
  user_id uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now()
);
create index pust9_members_registered on public.pust9_members (status)
  where status = 'registered';
alter table public.pust9_members enable row level security;
-- No client policies: the service role only.

-- The signed-in user's in-app subscription. The OTP reference stays here and
-- is never sent to the app.
create table public.pust9_subscriptions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  phone text not null,
  subscriber_id text references public.pust9_members (subscriber_id)
    on delete set null,
  status text not null default 'pending'
    check (status in ('pending', 'registered', 'unregistered')),
  otp_reference text,
  otp_expires_at timestamptz,
  otp_requests int not null default 0,
  otp_window_start timestamptz,
  subscribed_at timestamptz,
  updated_at timestamptz not null default now()
);
alter table public.pust9_subscriptions enable row level security;
create policy pust9_subscriptions_own on public.pust9_subscriptions
  for select using (user_id = auth.uid());
revoke select on public.pust9_subscriptions from anon, authenticated;
grant select (user_id, phone, status, subscribed_at, updated_at)
  on public.pust9_subscriptions to authenticated;

-- Course content: one tip per day, reviewed by BIID before it is seeded.
create table public.pust9_tips (
  day_no int primary key check (day_no > 0),
  body_bn text not null,
  body_en text
);
alter table public.pust9_tips enable row level security;

-- Every callback from bdapps, for audit and debugging.
create table public.bdapps_events (
  id bigint generated always as identity primary key,
  kind text not null,
  payload jsonb not null,
  received_at timestamptz not null default now()
);
create index bdapps_events_received on public.bdapps_events (received_at desc);
alter table public.bdapps_events enable row level security;

-- USSD menu position for a live session.
create table public.ussd_sessions (
  session_id text primary key,
  subscriber_id text not null,
  state text not null,
  updated_at timestamptz not null default now()
);
alter table public.ussd_sessions enable row level security;

-- Daily tip SMS at 09:00 Asia/Dhaka (03:00 UTC). Needs pg_cron and pg_net
-- enabled and two Vault secrets: `project_url` and `pust9_cron_token`
-- (the same value as the function secret PUST9_CRON_TOKEN).
create extension if not exists pg_cron;
create extension if not exists pg_net;

select cron.schedule(
  'pust9-daily-send',
  '0 3 * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets
            where name = 'project_url') || '/functions/v1/pust9-daily-send',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-cron-token', (select decrypted_secret from vault.decrypted_secrets
                       where name = 'pust9_cron_token')
    ),
    body := '{}'::jsonb
  );
  $$
);

-- Old raw events and stale USSD sessions are pruned weekly.
select cron.schedule(
  'bdapps-prune',
  '30 3 * * 0',
  $$
  delete from public.bdapps_events where received_at < now() - interval '90 days';
  delete from public.ussd_sessions where updated_at < now() - interval '1 day';
  $$
);
