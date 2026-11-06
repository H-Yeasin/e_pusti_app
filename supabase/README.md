# Backend (Supabase)

The app talks to Supabase only through the repository interfaces in
`lib/features/auth/domain/auth_repository.dart` and
`lib/features/profile/domain/profile_models.dart`.

## Which backend a build uses

| Build | Keys given | Backend |
|-------|-----------|---------|
| any flavor | `SUPABASE_URL` + `SUPABASE_ANON_KEY` | Supabase |
| dev / staging | none | on-device dev backend — any valid number, code `123456` |
| prod | none | accounts unavailable; everything open to logged-out users still works |

```bash
flutter run -t lib/main_staging.dart --dart-define=SUPABASE_URL=https://<project>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable key>
```

Use the project's publishable (anon) key only — never the service-role key.

## Setting up a project

1. Create the project and apply `migrations/` (`supabase db push`, or paste
   the SQL in the SQL editor).
2. Authentication → Providers → **Phone**: enable it and connect an SMS
   provider that delivers to Bangladeshi numbers. OTP length **6**, expiry
   as short as practical (e.g. 5 minutes).
3. Authentication → Rate limits: keep SMS sends per number low; the app
   shows a "too many attempts" state for `over_sms_send_rate_limit`.

## What the schema guarantees

- Every table has row-level security: an account can only read and change
  its own rows.
- Measurements can only be written for the account's own people and only
  while health-data consent is given (enforced in the database, not just
  the app).
- `delete_my_account()` deletes the auth user; people, measurements and
  consent cascade. Certificates (Phase 3) will be stored as snapshots
  without a cascading key so they stay verifiable (INF-05).

## Learning, assessments and certificates (Phase 3)

- `assessments`, `assessment_questions` and `assessment_keys` hold the quiz
  content. Clients can read published assessments and questions but **not**
  `assessment_keys` (RLS on, no policies). Grading happens only in
  `submit_assessment()`, which also records the attempt, completes progress
  and issues the certificate in one transaction.
- Attempts: `max_attempts` within `cooldown_hours` (defaults 3 / 24 h),
  enforced in the database.
- Certificates use random `EP-<year>-XXXXXXXX` codes, keep name and title as
  snapshots, and set `account_id` to null when an account is deleted so they
  stay verifiable. Revoke by setting `revoked_at` (and `revoke_reason`).
- Seed the assessments from BFSA-reviewed content. The app's dev backend uses
  sample questions in `lib/features/assessment/data/fixture_assessments.dart`.

## Public verification page (CRT-03)

`verify/index.html` is a static page. Once the verification domain exists
(open item O-15):

1. Put the project URL and publishable key in the two constants at the top of
   its script.
2. Host it so `https://<domain>/EP-2026-XXXXXXXX` serves the page (rewrite all
   paths to `index.html`).
3. Set `verifyBaseUrl` in the app's remote config; certificates then show a
   QR code pointing at that page.

It calls `verify_certificate(code)`, which anyone may call and which returns
only the code, holder name, title, source, issue date and revoked flag.
