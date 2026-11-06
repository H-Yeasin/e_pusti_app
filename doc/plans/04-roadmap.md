# 04 — Roadmap

Phases are ordered by dependency and user value. Each phase ends in a shippable internal build. Screen IDs refer to the design (see 00); `P*` items refer to 02.

## Phase 0 — Decisions & foundation
**Decide:** A1–A7 in 01 (PUST9 length, certificate track, chapter titles, slot policy, attempts rule). Chase O-01, O-02, O-13, O-15, O-17 owners.
**Build:** 03 §1 tokens, §2 core widgets + catalog, §3 router with auth-redirect skeleton, §4 remote config with bundled defaults, §5 error taxonomy, §6 connectivity/slow timer.
**Rework home:** HOM-01 to spec — remove carousel, single `home_banner` `AdSlot`, wire tiles to routes, HOM-02 sidebar (logged-out variant).
**Exit:** home + sidebar match design in bn/en; all slots collapse; golden tests in CI.

**Status (2026-11-06):**
- Done: design tokens + theme (`core/theme/app_tokens.dart`), `AdSlot` / `EpPromoCard` / `EpStateView` / `EpAppBar`, dev component catalog (`/dev/catalog`), remote config with bundled defaults (`core/config/remote_config.dart`, PUST9 = 60 days provisional), `AppFailure` taxonomy, `go_router` with gated routes + LAU-05 login sheet + return-to-origin, HOM-01 rework (carousel removed, single `home_banner` slot, tiles wired), HOM-02 sidebar (🔒 when logged out, version footer), placeholder screens for every destination, unit + widget tests.
- Still open: bundle Noto Sans Bengali / Noto Sans fonts (currently system fallback), connectivity watcher + 3 s slow timer (needs `connectivity_plus`), golden tests and CI, logout kick-out from gated screens, decisions A1–A7, a real `/config` endpoint.

## Phase 1 — Free value without login
| Feature | Screens | Notes |
|---------|---------|-------|
| PUST9 subscription | SMS-01 (3 states), P1-1 basic "today's tip" | Price/codes from remote config |
| BMI anonymous | BMI-01 anonymous, BMI-02 cases 1, 2, 3, 4, 5 | Engine + WHO tables, unit tests; P1-3 feet/inch |
| Academy (read) | CRS-01 logged out, CRS-02 (size gate, video failed) | Content from VPS |
| Library | LIB-01, LIB-02, P1-5 downloads + Wi-Fi queue (LIB-03) | |
| Webinars (browse) | WEB-01, WEB-02 (view only) | |
| Info | INF-01, INF-02, INF-03, INF-04 (partial) | Support works without login |
| System | SYS-01…04 | |
**Exit:** a logged-out user can do everything the design allows logged-out; offline mode works for downloaded/read content.

**Status (2026-11-06):**
- Done: SMS-01 (dial / SMS / copy, charge, operator check with "never a dead end", `pust9_banner` slot); BMI engine with all 5 result cases + feet/inch and Bangla-digit input, results in the clinical palette, save → login sheet that returns to the same result; CRS-01/02 (logged-out list, video size gate, Wi-Fi-only setting, failed-video state, quiz → login); LIB-01/02 + LIB-03 downloads list (search, category picker, no-results way out, large-file consent, Wi-Fi queue); WEB-01/02 browse (upcoming/past, seats, full); INF-01 about, INF-02 support (opens the email app), INF-04 settings (language, video on Wi-Fi only, downloads, logout); SYS-01 offline card on home, SYS-02 slow skeleton after 3 s, SYS-03 error with code + time, SYS-04 forced update via `minSupportedVersion`. Content comes from fixture repositories behind interfaces.
- Still open: **WHO 2007 BMI-for-age tables** (`assets/who/bmi_for_age_2007.csv`; until bundled, ages 5–19 show no classification); clinical sign-off on result copy (O-13/O-17); real VPS content API, video player and PDF renderer (need real URLs); actual file transfer for the download queue; INF-03 reference number (needs a support API); privacy/terms URLs.

## Phase 2 — Account, family, saving
| Feature | Screens |
|---------|---------|
| Auth | LAU-03, LAU-04 (+ rate-limit/delay states), LAU-05 return-to-context, LAU-06 change number |
| Consent | PRO-03, INF-07 privacy centre (withdraw) |
| Profile & family | PRO-01, PRO-02, PRO-04a–f, edit/remove dependant |
| BMI saved | BMI-01 logged in (who for?), save actions, BMI-03 history (+ edit/delete) |
| Reminders | P1-4 measurement reminders |
| Settings | INF-04 full, INF-05 delete account, INF-06 logout confirm |
**Exit:** family of 4 can be created, measured and tracked; deletion removes all listed data.

## Phase 3 — Learning, assessment, certificates
| Feature | Screens |
|---------|---------|
| Academy progress | CRS-01 logged in (progress, `chapter_header` slot), resume |
| Digi Skills | DGS-01 (lock, sources, VPS unreachable), DGS-02 |
| Assessment | ASM-01 (+ offline submit), ASM-02 pass/fail (+ attempts exhausted) |
| Certificates | CRT-01, CRT-02 (QR, PDF, share, revoked), CRT-03 public verify page (needs O-15) |
**Exit:** module → quiz → certificate → third-party verification works end to end.

## Phase 4 — Engagement
| Feature | Screens |
|---------|---------|
| Webinar registration | WEB-02 register (seat race), WEB-03, P1-6 reminders/join, WEB-04 recording |
| Notifications | NOT-01, NOT-02 (+ OS denied), push + deep links |
| Personalised home | P1-2 |
| PUST9 archive | P1-1 full archive + subscription status/stop |
| Share & invite | P1-7 |
| Partner slots live | SLOT-A/B with real creatives & consented analytics |
**Exit:** retention features live; slot revenue path proven.

## Phase 5 — Depth (after clinical/content sign-off)
P2-1 growth charts · P2-2 pregnancy/breastfeeding journey · P2-3 audio narration · P2-4 global search · P2-5 bookmarks · selected P3 items after user research.

## Dependency map (blocking items)

| Blocker | Blocks |
|---------|--------|
| O-01 / O-02 PUST9 price & codes | SMS-01 final copy (can ship with remote config defaults) |
| O-13 / O-17 clinical sign-off | BMI-02 non-normal result copy, P2-1, P1-4 intervals |
| O-15 verification domain | CRT-02 QR target, CRT-03 |
| A2 certificate track decision | ASM-02 pass screen, CRT-01 empty state, LAU-05 copy |
| Supabase project + VPS content API | Phases 2–4 (Phase 1 can mock content with fixtures) |

## Suggested per-feature definition of done
1. Every state drawn in the design (and listed in 01 §B) implemented and covered by a golden test in **bn and en**.
2. Works at 1.3× text scale, with TalkBack labels.
3. Offline / slow / server-error paths tested with a fake repository.
4. No hard-coded colours, strings or prices.
5. Analytics events (if any) reviewed for PII/health data.
