-- e-Pushti Phase 2: accounts, family profiles, consent and BMI records.
-- Every row belongs to one account (auth.users) and is visible only to it.

-- People: the account holder and dependants -------------------------------
create table public.people (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  relationship text not null
    check (relationship in ('holder', 'child', 'spouse', 'parent', 'sibling', 'other')),
  name text check (char_length(name) <= 120),
  date_of_birth date check (date_of_birth <= current_date),
  sex text check (sex in ('female', 'male', 'other')),
  district text,
  occupation text,
  pregnant boolean not null default false,
  breastfeeding boolean not null default false,
  interests text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index people_one_holder_per_account
  on public.people (account_id) where relationship = 'holder';
create index people_account_idx on public.people (account_id);

-- Measurements: height and weight; BMI is derived, never stored ------------
create table public.measurements (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  person_id uuid not null references public.people (id) on delete cascade,
  measured_at timestamptz not null default now(),
  height_cm numeric(5, 1) not null check (height_cm between 40 and 250),
  weight_kg numeric(5, 1) not null check (weight_kg between 2 and 300),
  created_at timestamptz not null default now()
);

create index measurements_person_idx on public.measurements (person_id, measured_at desc);

-- Consent (PRO-03): both checkboxes are recorded with time ----------------
create table public.consents (
  account_id uuid primary key default auth.uid()
    references auth.users (id) on delete cascade,
  terms_accepted_at timestamptz,
  health_data_accepted_at timestamptz,
  health_data_withdrawn_at timestamptz,
  updated_at timestamptz not null default now()
);

-- Row level security: each account sees and changes only its own rows -----
alter table public.people enable row level security;
alter table public.measurements enable row level security;
alter table public.consents enable row level security;

create policy people_own on public.people
  for all using (account_id = auth.uid()) with check (account_id = auth.uid());

create policy consents_own on public.consents
  for all using (account_id = auth.uid()) with check (account_id = auth.uid());

-- A measurement may only point at one of the account's own people, and only
-- while health-data consent is given.
create policy measurements_read on public.measurements
  for select using (account_id = auth.uid());

create policy measurements_delete on public.measurements
  for delete using (account_id = auth.uid());

create policy measurements_write on public.measurements
  for insert with check (
    account_id = auth.uid()
    and exists (
      select 1 from public.people p
      where p.id = person_id and p.account_id = auth.uid()
    )
    and exists (
      select 1 from public.consents c
      where c.account_id = auth.uid()
        and c.health_data_accepted_at is not null
        and (c.health_data_withdrawn_at is null
             or c.health_data_withdrawn_at < c.health_data_accepted_at)
    )
  );

create policy measurements_update on public.measurements
  for update using (account_id = auth.uid())
  with check (
    account_id = auth.uid()
    and exists (
      select 1 from public.people p
      where p.id = person_id and p.account_id = auth.uid()
    )
  );

-- updated_at bookkeeping ---------------------------------------------------
create function public.touch_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger people_touch before update on public.people
  for each row execute function public.touch_updated_at();
create trigger consents_touch before update on public.consents
  for each row execute function public.touch_updated_at();

-- Account deletion (INF-05) ------------------------------------------------
-- Deleting the auth user cascades to people, measurements and consents.
-- Issued certificates (Phase 3) are stored as snapshots without a cascading
-- foreign key, so they remain verifiable.
create function public.delete_my_account() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then
    raise exception 'not signed in';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
