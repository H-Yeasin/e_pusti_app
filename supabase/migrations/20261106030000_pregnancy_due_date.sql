-- e-Pushti Phase 5: pregnancy journey needs the expected due date.
alter table public.people
  add column expected_due_date date
  check (expected_due_date is null or expected_due_date <= current_date + 300);
