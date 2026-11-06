# e-Pushti — design review & delivery plans

Source reviewed: **"e-Pushti UI (standalone)"** — Claude Design project `8f9ac6d7…` (now moved to Claude, read-only), 42 screens from wireframe V4 batches 1–4, drawn at 390 × 844.
Compared against: this repository at `main` (`6924d5f`), 2026-11-06.

| # | Document | What it answers |
|---|----------|-----------------|
| 00 | [Design coverage](00-design-coverage.md) | Every screen in the design, grouped, with its build status in the app today |
| 01 | [Design review — gaps & fixes](01-design-review.md) | Inconsistencies, missing states and missing screens in the current design |
| 02 | [Feature proposals](02-feature-proposals.md) | New features that would make the app more useful, prioritised |
| 03 | [Technical foundation](03-foundation-plan.md) | The shared plumbing every feature needs (tokens, routing, auth, slots, offline…) |
| 04 | [Roadmap](04-roadmap.md) | Phased delivery plan with screen IDs, dependencies and exit criteria |

## Summary

**The design is strong on "honest states".** It draws empty, offline, failed, revoked, race-lost and permission-denied states for almost every flow, uses a soft login gate (browse everything, log in only when saving), separates clinical colours from brand colours, and treats data cost as a consent question (video/PDF size shown before spending). Those principles should be kept as non-negotiable acceptance criteria.

**The app is at ~5 % of the design.** Splash, language selection and a first-cut home screen exist. The 14 feature folders (`auth`, `bmi`, `courses`, …) are empty scaffolds. There is no routing, network layer, backend client, remote config or design-token theme yet.

**Top 5 things to decide before building further** (detail in 01):
1. PUST9 is described as a **30-day** course in the app and **60-day** in the design.
2. Which track issues certificates — Academy courses (LAU-05 says "quiz and get a certificate") or only Digi Skills (CRT-01 empty state)?
3. Chapter 4 title differs between LAU-05 ("খাদ্য নিরাপত্তা") and CRS-01 ("মানসিক স্বাস্থ্য").
4. The current home shows 6 always-on operator banners; the design's launch state is **all slots collapsed** and partner red only inside a confirmed creative.
5. Open items O-01/O-02 (PUST9 price & codes), O-13/O-17 (clinical sign-off for BMI copy), O-15 (verification domain) block their features.

**Highest-value additions** (detail in 02): in-app PUST9 tip archive + subscription status, a personalised home ("continue", "next webinar", "Arif's measurement is due"), feet/inch + Bangla-numeral input for BMI, child measurement reminders, a downloads manager for the Wi-Fi queue the design already promises, and audio narration for low-literacy users.
