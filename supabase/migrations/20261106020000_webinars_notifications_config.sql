-- e-Pushti Phase 4: webinar registration with enforced capacity, the
-- notification inbox, live app config and partner-slot events.

-- Webinars (seat and link data; the catalogue text comes from the VPS) ----
create table public.webinars (
  id text primary key,
  title text not null,
  starts_at timestamptz not null,
  duration_minutes int not null check (duration_minutes > 0),
  capacity int not null check (capacity >= 0),
  join_url text,
  recording_url text
);

alter table public.webinars enable row level security;
-- Everyone may read the public columns; the join link is only revealed by
-- webinar_join_link().
create policy webinars_read on public.webinars for select using (true);
revoke select on public.webinars from anon, authenticated;
grant select (id, title, starts_at, duration_minutes, capacity, recording_url)
  on public.webinars to anon, authenticated;

create table public.webinar_registrations (
  account_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  webinar_id text not null references public.webinars (id) on delete cascade,
  registered_at timestamptz not null default now(),
  primary key (account_id, webinar_id)
);

alter table public.webinar_registrations enable row level security;
create policy registrations_own on public.webinar_registrations
  for select using (account_id = auth.uid());
-- Inserts and deletes only through the functions below.

create function public.webinar_seats_left(p_ids text[])
returns table (webinar_id text, seats_left int)
language sql stable security definer set search_path = '' as $$
  select w.id,
         greatest(w.capacity - (
           select count(*) from public.webinar_registrations r where r.webinar_id = w.id
         ), 0)::int
  from public.webinars w
  where w.id = any (p_ids);
$$;

-- Capacity is enforced in a transaction: the webinar row is locked, so two
-- people cannot both take the last seat. Returns 'registered' or 'full'.
create function public.register_for_webinar(p_webinar_id text)
returns text
language plpgsql security definer set search_path = '' as $$
declare
  w public.webinars;
  taken int;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select * into w from public.webinars where id = p_webinar_id for update;
  if not found then raise exception 'unknown webinar'; end if;
  if w.starts_at + make_interval(mins => w.duration_minutes) < now() then
    raise exception 'webinar ended';
  end if;

  if exists (
    select 1 from public.webinar_registrations
    where account_id = auth.uid() and webinar_id = w.id
  ) then
    return 'registered';
  end if;

  select count(*) into taken from public.webinar_registrations where webinar_id = w.id;
  if taken >= w.capacity then
    return 'full';
  end if;

  insert into public.webinar_registrations (account_id, webinar_id)
  values (auth.uid(), w.id);
  return 'registered';
end;
$$;

create function public.cancel_webinar_registration(p_webinar_id text)
returns void
language sql security definer set search_path = '' as $$
  delete from public.webinar_registrations
  where account_id = auth.uid() and webinar_id = p_webinar_id;
$$;

-- The meeting link: registered users only, from 15 minutes before the start
-- until the end.
create function public.webinar_join_link(p_webinar_id text)
returns text
language sql stable security definer set search_path = '' as $$
  select w.join_url
  from public.webinars w
  join public.webinar_registrations r
    on r.webinar_id = w.id and r.account_id = auth.uid()
  where w.id = p_webinar_id
    and now() >= w.starts_at - interval '15 minutes'
    and now() < w.starts_at + make_interval(mins => w.duration_minutes);
$$;

create table public.recording_alerts (
  account_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  webinar_id text not null references public.webinars (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (account_id, webinar_id)
);

alter table public.recording_alerts enable row level security;
create policy recording_alerts_own on public.recording_alerts
  for all using (account_id = auth.uid()) with check (account_id = auth.uid());

-- Inbox (NOT-01) ----------------------------------------------------------
create table public.inbox_items (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references auth.users (id) on delete cascade,
  category text not null check (category in ('webinar', 'course', 'content', 'general', 'health')),
  title text not null,
  body text not null default '',
  route text check (route is null or (route like '/%' and route not like '//%')),
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index inbox_account_idx on public.inbox_items (account_id, created_at desc);
alter table public.inbox_items enable row level security;
create policy inbox_read on public.inbox_items
  for select using (account_id = auth.uid());
-- Clients may only mark their own items read.
create policy inbox_mark_read on public.inbox_items
  for update using (account_id = auth.uid()) with check (account_id = auth.uid());
revoke update on public.inbox_items from authenticated;
grant update (read_at) on public.inbox_items to authenticated;

create function public.inbox_on_registration() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  w public.webinars;
begin
  select * into w from public.webinars where id = new.webinar_id;
  insert into public.inbox_items (account_id, category, title, body, route)
  values (
    new.account_id, 'webinar',
    'রেজিস্ট্রেশন সম্পন্ন: ' || w.title,
    'ইভেন্টের ১৫ মিনিট আগে যোগ দেওয়ার লিংক দেখা যাবে।',
    '/webinars/' || w.id
  );
  return new;
end;
$$;

create trigger registration_to_inbox after insert on public.webinar_registrations
  for each row execute function public.inbox_on_registration();

create function public.inbox_on_certificate() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.account_id is not null then
    insert into public.inbox_items (account_id, category, title, body, route)
    values (
      new.account_id, 'course', 'আপনার সার্টিফিকেট প্রস্তুত', new.title,
      '/certificates/' || new.code
    );
  end if;
  return new;
end;
$$;

create trigger certificate_to_inbox after insert on public.certificates
  for each row execute function public.inbox_on_certificate();

-- Recording published → tell everyone who asked.
create function public.inbox_on_recording() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if new.recording_url is not null and old.recording_url is null then
    insert into public.inbox_items (account_id, category, title, body, route)
    select a.account_id, 'webinar', 'রেকর্ডিং প্রকাশিত: ' || new.title, '',
           '/webinars/' || new.id
    from public.recording_alerts a where a.webinar_id = new.id;
  end if;
  return new;
end;
$$;

create trigger recording_to_inbox after update of recording_url on public.webinars
  for each row execute function public.inbox_on_recording();

-- Announcements to everyone (run by staff with the service role).
create function public.announce(p_category text, p_title text, p_body text, p_route text)
returns int
language sql security definer set search_path = '' as $$
  with ins as (
    insert into public.inbox_items (account_id, category, title, body, route)
    select id, p_category, p_title, coalesce(p_body, ''), p_route from auth.users
    returning 1
  )
  select count(*)::int from ins;
$$;

revoke all on function public.announce(text, text, text, text) from public, anon, authenticated;

-- Live app config (remote config) -----------------------------------------
create table public.app_config (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.app_config enable row level security;
create policy app_config_read on public.app_config for select using (true);

insert into public.app_config (key, value) values ('mobile', '{}'::jsonb)
on conflict do nothing;

-- Partner slot events (consented, signed-in users only) -------------------
create table public.slot_events (
  id bigint generated always as identity primary key,
  account_id uuid default auth.uid() references auth.users (id) on delete set null,
  slot text not null,
  kind text not null check (kind in ('impression', 'click')),
  creative text,
  created_at timestamptz not null default now()
);

alter table public.slot_events enable row level security;
-- Insert only; nobody reads events through the API.
create policy slot_events_insert on public.slot_events
  for insert to authenticated
  with check (
    account_id = auth.uid()
    and exists (
      select 1 from public.consents c
      where c.account_id = auth.uid() and c.terms_accepted_at is not null
    )
  );

grant execute on function public.webinar_seats_left(text[]) to anon, authenticated;
revoke all on function public.register_for_webinar(text) from public, anon;
revoke all on function public.cancel_webinar_registration(text) from public, anon;
revoke all on function public.webinar_join_link(text) from public, anon;
grant execute on function public.register_for_webinar(text) to authenticated;
grant execute on function public.cancel_webinar_registration(text) to authenticated;
grant execute on function public.webinar_join_link(text) to authenticated;
