# 03 — Technical foundation plan

The repo has a clean feature-first layout (`lib/features/*/{data,domain,presentation}`) with Riverpod and l10n, but only `flutter_riverpod` and `shared_preferences` as dependencies. Every screen in the design needs the pieces below; build them once, before the feature work.

## 1. Design tokens → `lib/core/theme/`
- `app_colors.dart`: green 50–900, neutral n-0…900, clinical (`tint #F2F7F9`, `line #E1EAEE`, `graphic #6A8C9B`, `text #577684`, `strong #415B67`), destructive (`fill #C6452B`, `tint #FFF3EE`, …), band-1/2/3 for BMI scales, partner red `#B21935` (exported only to the slot widget).
- `app_spacing.dart` (4/8/12/16/20/24/32/40/48), `app_radius.dart` (6/10/14/pill), `app_elevation.dart`, `app_motion.dart` (80/140/200/280 ms, respect reduced-motion).
- `app_typography.dart`: Noto Sans Bengali / Noto Sans bundled as assets (don't rely on system fonts), sizes display 34, heading 19, body 16, body-sm 15, label 14, caption 13.
- `ThemeData` built from tokens (primary fill `green-600 #19871B`, brand `green-500 #03AC13`), `ThemeExtension` for clinical/destructive. Replace hard-coded colours in `home_screen.dart`.
- **Lint rule:** no `Color(0x…)` outside `core/theme`.

## 2. Shared widgets → `lib/core/widgets/` (folders already exist)
| Folder | Widgets (from the design) |
|--------|---------------------------|
| `navigation/` | `EpAppBar` (back + title + action), `EpSidebar` (logged in/out, 🔒 items, badge), login bottom sheet |
| `input/` | `PhoneField(+880)`, `OtpField(6)`, `PickerRow` (label › value), list picker page with search & sections, multi-select with confirm, DOB wheel, unit-toggle number field |
| `feedback/` | `StateView` (icon, title, body, primary/secondary actions) for empty/offline/error, inline banner (info/clinical/destructive), skeleton, toast |
| `display/` | Card, progress row (✓ / number / 🔒), size chip ("12.4 MB"), source chip (BFSA/UNICEF/IPHN), clinical result card + band scale |
| `commercial/` | `AdSlot(slotId)` — renders creative or **`SizedBox.shrink()`**; house-promo variant |
| `content/` | Chapter text renderer, video player with size gate, PDF viewer wrapper |

Build a **widget catalog screen** (dev flavor only) to compare against the design.

## 3. Routing
- Add `go_router` with typed routes; one route per screen ID (e.g. `/bmi/result`, `/webinars/:id`).
- **Auth redirect that remembers context**: gated actions call `requireLogin(returnTo: currentLocation, then: action)` → LAU-05 sheet → LAU-03/04 → back to `returnTo` and run `action`.
- Deep links (`epushti://`, https app links) for notifications and sharing (P1-7).

## 4. Remote config & slots
- One `GET /config` (cached, with defaults bundled) containing: PUST9 price/days/USSD/shortcode (O-01/O-02), slot assignments (`slotId → creative | house | empty`), min supported version + latest version (SYS-04), feature flags.
- Slot creative = image URL + click URL + `confirmedPartner` flag; impression/click events (consented analytics only).
- Launch default: **all slots empty**.

## 5. Backend clients
- **Supabase** (`supabase_flutter`): phone OTP auth, profile & dependants, consent records, BMI measurements, progress, quiz attempts, certificates, webinar registrations (seat capacity in an RPC/transaction → "lost the last seat" state), notifications inbox, support tickets.
- **VPS content API** (`dio`): chapters, modules, library, webinar catalogue. Separate error type `ContentServerUnavailable` vs `NoConnection` vs `ServerError(code)` vs `Timeout` → maps 1:1 to DGS-01/02 and SYS-01…03.
- Repository pattern per feature (`domain/repositories` contracts are already scaffolded).

## 6. Offline & data cost
- Connectivity watcher (`connectivity_plus`) + 3 s slow-request timer → skeleton (SYS-02).
- Local DB (`drift` or `isar`) for: read chapter text, downloaded docs index, pending quiz answers, BMI records written offline (sync later), notification inbox.
- Download manager with Wi-Fi-only queue (`background_downloader`), size known before download (HEAD / metadata field).
- "Video on Wi-Fi only" setting enforced in the player.

## 7. Domain logic needing tests first
- **BMI engine:** age in months from DOB; routing to the 5 result cases; WHO adult bands; WHO 2007 BMI-for-age z-score (LMS tables bundled as assets) for 5–19; under-5 → no number; sex "other" < 19 → no number; no DOB → adult standard + prompt. Unit tests with WHO reference values.
- Operator detection from +880 prefix (013/017 Grameenphone, 018 Robi, 016 Airtel, 019/014 Banglalink, 015 Teletalk) for SMS-01 eligibility — warn, never block (number portability).
- Quiz state machine (answer, exit preserving, submit, retry limits).

## 8. Notifications
- FCM push + local notifications; categories = NOT-02 list (+ "স্বাস্থ্য রেকর্ড" for P1-4); OS-permission check feeding NOT-02 denied state; every push also written to the inbox (NOT-01).

## 9. Quality, privacy, release
- Analytics only after PRO-03 consent; no health values in analytics events.
- Crash reporting (Sentry/Crashlytics) with PII scrubbing.
- Golden tests per screen state (each design frame = one golden) in bn and en.
- CI: `flutter analyze`, tests, l10n completeness check (bn and en keys equal).
- Account deletion endpoint that keeps certificate snapshots verifiable (INF-05) — required by Play Store/App Store policy.
- APK size budget (≤ 25 MB; SYS-04 mentions 18 MB) — fonts subset, no GIF icons (`assets/icons/*.gif` → vector/Lottie).
