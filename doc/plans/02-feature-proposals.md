# 02 — Feature proposals (beyond the current design)

Prioritised by **value to families ÷ build cost**. Each item lists what it reuses from the design so the additions stay consistent.

## P1 — high value, low cost (add to the first releases)

### P1-1 PUST9 tip archive and subscription status (SMS-02)
- **Why:** SMS tips get deleted or missed. `pusti9_sms/` already has the daily send history (17:27 daily) — the content exists.
- **What:** "আজকের টিপ" plus a day-by-day archive (Day 1…60) readable in-app for free; subscriber status (subscribed / not / unknown), how to stop (`STOP PUST9`), FAQ on charges.
- **Reuses:** SMS-01 layout, remote-config price/codes (O-01/O-02).
- **Open question:** may non-subscribers read the archive? (business model) — option: subscribers see all, others see the last 3 days.

### P1-2 Personalised home (logged-in variant of HOM-01)
- "চালিয়ে যান" — the chapter/module in progress (CRS-01 "চলমান").
- "আপনার পরবর্তী ওয়েবিনার" — from WEB-03.
- "আরিফের মাপ নেওয়ার সময় হয়েছে" — from BMI-03 last record date.
- Today's tip filtered by life stage (pregnant / breastfeeding toggles in PRO-02) and interests (PRO-04e). Re-uses the existing `homeNutritionTip*` strings.
- Logged-out home stays exactly as HOM-01 (design rule: identical logged in/out — so place this as **one extra card**, not a different layout; confirm with design).

### P1-3 BMI input that fits local habits
- Feet + inches ↔ cm toggle, kg (and optional lb), Bangla digit input, sanity ranges per age.
- Stepper/wheel for children's height to avoid typos.

### P1-4 Measurement reminders per family member
- Under-5: monthly; 5–19: every 3 months; adults: every 6 months (clinical team to confirm).
- Local notifications (no server needed), toggle in NOT-02 as a new category "স্বাস্থ্য রেকর্ড".

### P1-5 Downloads manager + Wi-Fi queue (LIB-03)
- Completes the promise made in LIB-02 ("ওয়াই-ফাইতে পরে পড়ব") and INF-04 ("ডাউনলোড করা ফাইল").
- List of downloaded PDFs/chapters with size, delete, "download when on Wi-Fi" queue with status.

### P1-6 Webinar reminders and join
- Local reminders 24 h and 15 min before; "যোগ দিন" button that appears when the link is live; recording player (WEB-04).

### P1-7 Share & invite
- Share a library poster / tip / chapter link to WhatsApp/Messenger with app deep link (huge reach channel in BD households).

## P2 — high value, needs clinical or content work

### P2-1 Growth monitoring for children (replaces "বৃদ্ধির গ্রাফ শীঘ্রই যুক্ত হবে")
- Under-5: weight-for-age / length-for-age / weight-for-length (WHO 2006). 5–19: BMI-for-age (WHO 2007) chart.
- Plot history from BMI-03 on the WHO curves, in the clinical palette, with plain-language trend ("গত ৩ মাসে বৃদ্ধি স্বাভাবিক ধারায়").
- **Blocked by** O-13/O-17 clinical sign-off. Needs a referral message when crossing thresholds.

### P2-2 Pregnancy & breastfeeding journey
- If the holder toggles গর্ভবতী/স্তন্যদানকারী (PRO-02): week-by-week nutrition tips, ANC visit reminders, iron-folic acid reminders, link to relevant chapters & library posters.

### P2-3 Audio narration (শুনুন)
- Recorded Bangla audio (preferred) or on-device TTS for chapter text, tips and posters. Big gain for low-literacy and elderly users; small data cost if pre-downloaded.

### P2-4 Global search (HOM-03)
- One search across chapters, modules, library, webinars; recent searches; suggests categories when nothing matches (re-uses LIB-01 no-results pattern).

### P2-5 Bookmarks / "সংরক্ষিত"
- Save any chapter section, poster or tip; available offline.

### P2-6 Public certificate verification page (CRT-03, web)
- `verify.epushti.org/EP-2026-XXXX` and QR → shows valid / revoked, name snapshot, module, date. Needed by employers (BFSA certificate value). **Blocked by** O-15.

## P3 — later / validate first

| Idea | Note |
|------|------|
| Local food guide & seasonal recipes (Bangladesh Food-Based Dietary Guidelines) | Content-heavy; strong engagement |
| Family meal planner / simple food diary | Validate demand first; high effort |
| Learning streaks & badges | Light gamification on Academy; avoid on health readings |
| Ask-an-expert queue tied to webinars | Pre-submitted questions answered live; avoids 1-to-1 medical advice (INF-02 scope) |
| Assisted mode for community health workers | One CHW registers several households — needs a different consent model |
| Aggregated impact dashboard for BIID | Anonymised, consent-based (PRO-03 already mentions aggregate reporting) |
| In-app feedback/rating prompt after quiz pass or certificate | Cheap, good timing for store ratings |

## Not recommended

- **Diagnosis-like features** (symptom checkers, diet prescriptions) — conflicts with INF-02 scope and BMI disclaimers.
- **Showing ads inside health results or quizzes** — keep slots out of BMI-02 and ASM flows.
