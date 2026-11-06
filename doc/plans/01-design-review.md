# 01 — Design review: gaps and fixes

What to fix or add in the design itself before (or while) it is built. Ordered by impact.

## A. Inconsistencies to resolve (need a product decision)

| # | Issue | Where | Recommendation |
|---|-------|-------|----------------|
| A1 | PUST9 length: app says "30-day course", design says "৬০ দিনের" | `app_en.arb: homeSmsSubtitle` vs HOM-01 / SMS-01 | Confirm with BIID; make the number remote config together with price (O-01/O-02) |
| A2 | Which track gives certificates? LAU-05 says Academy quiz → certificate; CRT-01 empty state says only Digi Skills modules (BFSA) | LAU-05, CRT-01, DGS-02 | Pick one. Suggested: Digi Skills = verifiable BFSA certificate; Academy = completion badge (no verification) |
| A3 | Chapter 4 title: "খাদ্য নিরাপত্তা" vs "মানসিক স্বাস্থ্য" | LAU-05 vs CRS-01 | Chapter list must come from content API, not hard-coded copy |
| A4 | Home today shows 6 Robi pack banners in a carousel + 8 home slots; design = one `home_banner` slot, empty at launch, red only in confirmed creative | `home_screen.dart` vs SLOT-A/C, HOM-01 | Remove the carousel; drive slots from remote config (see 03 §4) |
| A5 | Unused strings "Today's nutrition tip" / "Health check" exist in app but not in design | `app_en.arb` | Re-introduce as the personalised home card (02 §P1-2) rather than delete |
| A6 | Theme colours don't match tokens | `app_theme.dart` | Implement tokens (03 §1) |
| A7 | Quiz attempts: ASM-02 says "২টি সুযোগ বাকি" but no rule or exhausted state | ASM-02 | Define max attempts + cool-down, draw the "no attempts left" state |

## B. Missing states on existing screens

| Screen | Missing state | Why it matters |
|--------|---------------|----------------|
| LAU-03/04 | Invalid number format; OTP rate-limited / too many attempts; SMS delayed > 2 min (offer voice call or another number) | OTP is the most common drop-off point on BD mobile networks |
| LAU-05 | After login, the return-to-context confirmation (e.g. toast "অগ্রগতি সংরক্ষিত") | Design promises "you'll return where you were" |
| HOM-01 | Logged-in personalised variant; loading skeleton; PUST9 card when already subscribed | Same card for subscribers is wasted space |
| SMS-01 | **Already subscribed** state; how to **stop** (STOP PUST9 / USSD); SMS app not available (tablets) | INF-05 tells users they must unsubscribe separately but no screen shows how |
| BMI-01 | Height in **feet + inches**, weight validation ranges, Bangla-digit keyboard input | Most Bangladeshi households know height in feet/inches |
| BMI-02 | Under/over-weight and obesity result copy (only "স্বাভাবিক" is drawn) for adult and child; "save" when logged out → LAU-05 | The hard cases need clinical copy (O-13/O-17) |
| BMI-03 | Delete / edit a wrong record | Typos are common; history should be correctable |
| PRO-01/02 | Edit and **remove** a dependant; dependant turning 19 (moves to adult standard) | Lifecycle of family data |
| PRO-03 | Withdraw consent later (in Settings) | Consent must be revocable; also needed for INF-04 |
| CRS-01/02 | Chapter downloaded for offline; resume position in video; "video on Wi-Fi only" setting effect | SYS-01 promises "read chapters' text" offline |
| DGS-01 | All modules complete; new module badge | Completion moment |
| ASM-01 | Offline mid-quiz / submit failed (answers kept locally) | Grading is server-side |
| CRT-02 | Generating / pending; PDF download failed | Issue is asynchronous |
| LIB-01 | Category picker sheet itself; downloading progress; download failed; storage full | The ⌄ picker and ↓ actions are drawn but not their states |
| LIB-02 | "Queued for Wi-Fi" confirmation and where to find it | Queue must be visible somewhere |
| WEB-02 | Registered state ("you're in", join link timing); event live now → Join | Detail after registration is undefined |
| WEB-03 | Cancel confirmation; join link available; recording available | |
| NOT-01 | Tap → deep link destination; expired content | |
| SYS-04 | **Optional** (soft) update banner | Not every update should block |

## C. Missing screens

| Screen | Purpose | Suggested ID |
|--------|---------|--------------|
| Downloaded files manager | INF-04 links "ডাউনলোড করা ফাইল 3.2 MB ›" — list, delete, Wi-Fi queue status | LIB-03 |
| Global search | Search across chapters, modules, library, webinars | HOM-03 |
| Change phone number / account recovery | Users change SIMs often | LAU-06 |
| Logout confirm | What stays on device (downloads) | INF-06 |
| Consent & data (privacy centre) | View/withdraw consent, export data | INF-07 |
| PUST9 tips archive & status | See 02 §P1-1 | SMS-02 |
| Recording player | WEB-01 "রেকর্ডিং দেখুন" has no destination | WEB-04 |
| Public certificate verification (web) | Third parties verify by code/QR — O-15 | CRT-03 (web) |
| First-run "what's inside" (1 screen, skippable) | Explains free content vs. PUST9 paid SMS | LAU-02b |

## D. UX/quality suggestions

1. **Bottom navigation vs. hamburger only.** Every destination is 2 taps away behind ☰. Consider a 4-item bottom bar (হোম · শিখুন · লাইব্রেরি · প্রোফাইল) once logged-in features exist; keep the sidebar for secondary items.
2. **Merge "Course" and "Digi Skills" under a single "শিখুন" hub** with two tabs — users won't understand the difference from the tile labels; the hub can explain (free academy vs. certified modules).
3. **Accessibility:** support system text scale up to 1.3× without clipping (design is drawn at 1.0×), TalkBack/VoiceOver Bangla labels for icon glyphs (▶ ▤ ✦ ▣), minimum 48 dp targets on the OTP boxes and pickers.
4. **Low-literacy support:** an audio "শুনুন" button on chapter text and tips (see 02 §P2-3).
5. **Numerals:** decide Bangla vs. Latin digits per locale for inputs (phone, height) — the design mixes "163 cm" (Latin) with Bangla elsewhere.
6. **Dates:** WEB items omit the year and weekday; add weekday for upcoming events ("বৃহঃ, ১২ সেপ্টেম্বর").
7. **Partner attribution:** show source logos (BFSA, UNICEF, IPHN) — not just text chips — for trust.
