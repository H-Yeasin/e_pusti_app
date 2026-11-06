-- e-Pushti Phase 3: learning progress, one assessment engine for both
-- tracks with server-side grading, and verifiable certificates.

-- Progress per account and item ---------------------------------------------
create table public.learning_progress (
  account_id uuid not null default auth.uid()
    references auth.users (id) on delete cascade,
  item_type text not null check (item_type in ('chapter', 'module')),
  item_id text not null,
  status text not null check (status in ('in_progress', 'completed')),
  score int check (score between 0 and 100),
  updated_at timestamptz not null default now(),
  primary key (account_id, item_type, item_id)
);

alter table public.learning_progress enable row level security;
create policy progress_read on public.learning_progress
  for select using (account_id = auth.uid());
-- Clients may only record that they started something; completion is
-- written by submit_assessment().
create policy progress_start on public.learning_progress
  for insert with check (account_id = auth.uid() and status = 'in_progress');

-- Assessments -------------------------------------------------------------
create table public.assessments (
  id text primary key,
  title text not null,
  item_type text not null check (item_type in ('chapter', 'module')),
  item_id text not null,
  source text,
  pass_mark int not null default 70 check (pass_mark between 1 and 100),
  max_attempts int not null default 3 check (max_attempts >= 1),
  cooldown_hours int not null default 24 check (cooldown_hours >= 0),
  issues_certificate boolean not null default false,
  published boolean not null default false
);

create table public.assessment_questions (
  id text primary key,
  assessment_id text not null references public.assessments (id) on delete cascade,
  position int not null,
  prompt text not null,
  options jsonb not null check (jsonb_typeof(options) = 'array'),
  unique (assessment_id, position)
);

-- The answer key: RLS on and no policies, so no client role can read it.
create table public.assessment_keys (
  question_id text primary key references public.assessment_questions (id) on delete cascade,
  correct_index int not null,
  explanation text not null
);

alter table public.assessments enable row level security;
alter table public.assessment_questions enable row level security;
alter table public.assessment_keys enable row level security;

create policy assessments_read on public.assessments
  for select to authenticated using (published);
create policy questions_read on public.assessment_questions
  for select to authenticated using (
    exists (select 1 from public.assessments a where a.id = assessment_id and a.published)
  );

create table public.assessment_attempts (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references auth.users (id) on delete cascade,
  assessment_id text not null references public.assessments (id),
  answers jsonb not null,
  correct int not null,
  total int not null,
  score int not null,
  passed boolean not null,
  submitted_at timestamptz not null default now()
);

create index attempts_lookup on public.assessment_attempts (account_id, assessment_id, submitted_at desc);
alter table public.assessment_attempts enable row level security;
create policy attempts_read on public.assessment_attempts
  for select using (account_id = auth.uid());

-- Certificates --------------------------------------------------------------
-- account_id is set null when the account is deleted: the certificate stays
-- verifiable by third parties (INF-05). Name and title are snapshots.
create table public.certificates (
  code text primary key,
  account_id uuid references auth.users (id) on delete set null,
  assessment_id text not null references public.assessments (id),
  holder_name text not null,
  title text not null,
  source text,
  issued_at timestamptz not null default now(),
  revoked_at timestamptz,
  revoke_reason text
);

create unique index certificates_one_per_account
  on public.certificates (account_id, assessment_id) where account_id is not null;
alter table public.certificates enable row level security;
create policy certificates_own on public.certificates
  for select using (account_id = auth.uid());

-- Random, non-sequential codes: EP-<year>-XXXXXXXX without look-alikes.
create function public.new_certificate_code() returns text
language plpgsql as $$
declare
  alphabet constant text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  body text := '';
  i int;
begin
  for i in 1..8 loop
    body := body || substr(alphabet, 1 + floor(random() * length(alphabet))::int, 1);
  end loop;
  return 'EP-' || extract(year from now())::int || '-' || body;
end;
$$;

-- Attempt window --------------------------------------------------------------
create function public.assessment_status(p_assessment_id text)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  a public.assessments;
  recent int;
  oldest timestamptz;
  ever_passed boolean;
begin
  select * into a from public.assessments where id = p_assessment_id and published;
  if not found then raise exception 'unknown assessment'; end if;

  select count(*), min(submitted_at) into recent, oldest
  from (
    select submitted_at from public.assessment_attempts
    where account_id = auth.uid() and assessment_id = a.id
      and submitted_at > now() - make_interval(hours => a.cooldown_hours)
    order by submitted_at desc limit a.max_attempts
  ) t;

  select exists (
    select 1 from public.assessment_attempts
    where account_id = auth.uid() and assessment_id = a.id and passed
  ) into ever_passed;

  return jsonb_build_object(
    'attempts_left', greatest(a.max_attempts - recent, 0),
    'passed', ever_passed,
    'locked_until', case when recent >= a.max_attempts
      then oldest + make_interval(hours => a.cooldown_hours) end
  );
end;
$$;

-- Grading (server-side), progress and certificate issue in one transaction.
create function public.submit_assessment(
  p_assessment_id text,
  p_answers jsonb,
  p_holder_name text
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  a public.assessments;
  st jsonb;
  q record;
  chosen int;
  n_correct int := 0;
  n_total int := 0;
  pct int;
  did_pass boolean;
  review jsonb := '[]'::jsonb;
  cert_code text;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select * into a from public.assessments where id = p_assessment_id and published;
  if not found then raise exception 'unknown assessment'; end if;

  st := public.assessment_status(p_assessment_id);
  if (st ->> 'locked_until') is not null and (st ->> 'locked_until')::timestamptz > now() then
    raise exception 'attempts_exhausted:%', st ->> 'locked_until';
  end if;
  if a.issues_certificate and coalesce(trim(p_holder_name), '') = '' then
    raise exception 'name_required';
  end if;

  for q in
    select qq.id, qq.prompt, qq.options, k.correct_index, k.explanation
    from public.assessment_questions qq
    join public.assessment_keys k on k.question_id = qq.id
    where qq.assessment_id = a.id
    order by qq.position
  loop
    n_total := n_total + 1;
    chosen := (p_answers ->> q.id)::int;
    if chosen = q.correct_index then n_correct := n_correct + 1; end if;
    review := review || jsonb_build_object(
      'question_id', q.id, 'prompt', q.prompt, 'options', q.options,
      'chosen_index', chosen, 'correct_index', q.correct_index,
      'explanation', q.explanation
    );
  end loop;

  pct := case when n_total = 0 then 0 else round(n_correct * 100.0 / n_total) end;
  did_pass := pct >= a.pass_mark;

  insert into public.assessment_attempts (account_id, assessment_id, answers, correct, total, score, passed)
  values (auth.uid(), a.id, p_answers, n_correct, n_total, pct, did_pass);

  if did_pass then
    insert into public.learning_progress (account_id, item_type, item_id, status, score)
    values (auth.uid(), a.item_type, a.item_id, 'completed', pct)
    on conflict (account_id, item_type, item_id) do update
      set status = 'completed',
          score = greatest(coalesce(public.learning_progress.score, 0), excluded.score),
          updated_at = now();

    if a.issues_certificate then
      select code into cert_code from public.certificates
      where account_id = auth.uid() and assessment_id = a.id;
      if cert_code is null then
        loop
          cert_code := public.new_certificate_code();
          begin
            insert into public.certificates (code, account_id, assessment_id, holder_name, title, source)
            values (cert_code, auth.uid(), a.id, trim(p_holder_name), a.title, a.source);
            exit;
          exception when unique_violation then
            -- code collision: try another
          end;
        end loop;
      end if;
    end if;
  end if;

  st := public.assessment_status(p_assessment_id);
  return jsonb_build_object(
    'correct', n_correct, 'total', n_total, 'pass_mark', a.pass_mark,
    'passed', did_pass,
    'attempts_left', st -> 'attempts_left',
    'locked_until', st -> 'locked_until',
    'certificate_code', cert_code,
    'review', review
  );
end;
$$;

-- Public verification (CRT-03): anyone with the code sees validity and the
-- snapshot fields, nothing else.
create function public.verify_certificate(p_code text)
returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'code', c.code,
    'holder_name', c.holder_name,
    'title', c.title,
    'source', c.source,
    'issued_at', c.issued_at,
    'revoked', c.revoked_at is not null
  )
  from public.certificates c
  where c.code = upper(trim(p_code));
$$;

revoke all on function public.assessment_status(text) from public, anon;
revoke all on function public.submit_assessment(text, jsonb, text) from public, anon;
revoke all on function public.verify_certificate(text) from public;
grant execute on function public.assessment_status(text) to authenticated;
grant execute on function public.submit_assessment(text, jsonb, text) to authenticated;
grant execute on function public.verify_certificate(text) to anon, authenticated;
