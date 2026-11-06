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
