# 00 — Design coverage vs. what is built

Status key: ✅ built · 🟡 partial / differs from design · ⬜ not started

## Cross-cutting rules the design sets

| Rule | Where it comes from | Status in app |
|------|--------------------|---------------|
| Soft auth gate — dashboard and content reachable logged out; login asked only when saving progress, quiz, certificate, webinar seat | LAU group intro, HOM-02, LAU-05 | ⬜ no auth |
| Gated items are **visible and marked 🔒**, never hidden | HOM-02 logged-out | ⬜ |
| Ad/partner slots: 8 configurable slots, **empty = collapsed to 0 px**, no placeholder; partner red `#B21935` only inside a confirmed creative | SLOT-A/B/C | 🟡 8 slots exist but all on home; 6 Robi banners always shown in a carousel |
| Clinical palette (blue-grey `--clinical-*`) for any health reading; never green/amber/red | BMI group intro | ⬜ |
| Data-cost consent: show size before video playback / large PDF; "read later on Wi-Fi" queues the download | CRS-02, LIB-01/02, INF-04 | ⬜ |
| Distinct failure states: offline, slow (skeleton after 3 s), server error (with code + time), forced update | SYS-01…04 | ⬜ |
| Content from VPS, progress in Supabase → "content server unreachable" is its own state and never implies lost progress | DGS intro | ⬜ |
| Bangla copy verbatim from wireframes; Bangla numerals in UI | all | 🟡 l10n set up (bn/en), only ~30 strings |
| Design tokens: green 50–900 (`--green-500 #03AC13`, primary fill `--green-600 #19871B`), neutrals `--n-0…900`, radius 6/10/14/pill, spacing 4-pt scale, Noto Sans Bengali / Noto Sans | token sheet | 🟡 theme uses seed `#1F9D55` + hard-coded `#118514` / `#F8FAF6` |

## Screen-by-screen

### SLOT — Advertising & partner slots
| ID | Screen / state | Status |
|----|----------------|--------|
| SLOT-A | `home_banner` filled with confirmed partner creative | 🟡 static assets, not remote-driven |
| SLOT-B | House promotion (PUST9) in a slot, brand tint | ⬜ |
| SLOT-C | Empty → collapsed | 🟡 `_SlotBanner` empty handling exists; confirm it renders 0 px |
| — | Named slots seen in design: `home_banner`, `pust9_banner`, `chapter_header`, `cert_footer`, `library_header`, `viewer_footer` (+2 unnamed) | ⬜ app slots are `home-top`, `after-sms`, … all on home |

### LAU — Launch & authentication (5)
| ID | Screen | Status |
|----|--------|--------|
| LAU-01 | Splash, ≤ 3 s, never blocks on network | ✅ `animated_brand_splash.dart` (verify 3 s cap) |
| LAU-02 | Language selection, first run only | ✅ `language_selection_screen.dart` |
| LAU-03 | Phone entry (+880, any operator; PUST9 needs Robi/Airtel) | ⬜ |
| LAU-04 | OTP — awaiting, wrong code, resend countdown | ⬜ |
| LAU-05 | Login prompt bottom sheet over context, "return where you were" | ⬜ |

### HOM — Home & navigation (2)
| ID | Screen | Status |
|----|--------|--------|
| HOM-01 | Dashboard: PUST9 card, 4 tiles (Webinar, Course, Digi Skills, Library), BMI card, slot — filled & empty | 🟡 built; tiles not wired (`onTap: () {}`), extra carousel & slots not in design |
| HOM-02 | Sidebar — logged in (phone, badge) / logged out (🔒 items, "লগইন করুন →"), version footer | 🟡 drawer only shows env label |

### SMS — PUST9 subscription (1 screen, 3 states)
| ID | State | Status |
|----|-------|--------|
| SMS-01 | Path A USSD `*213*02025#` (dial / copy) | ⬜ |
| SMS-01 | Path B SMS `START PUST9` → 21213 (open SMS app / copy), `pust9_banner` slot | ⬜ |
| SMS-01 | Not eligible operator → still useful, routes to Course / Digi Skills | ⬜ |

### PRO — Profile & family (9)
| ID | Screen | Status |
|----|--------|--------|
| PRO-01 | Profile — holder only / with dependants | ⬜ |
| PRO-02 | Person form — holder (pregnant / breastfeeding toggles) / dependant | ⬜ |
| PRO-03 | Consent — 2 required checkboxes, "not now" still allows browsing | ⬜ |
| PRO-04a–f | Pickers: district (64, grouped by division, search), occupation, relationship, sex (with BMI consequence), interests (multi), date of birth | ⬜ |

### BMI — Health tools (3 screens, 5 result cases)
| ID | Screen | Status |
|----|--------|--------|
| BMI-01 | Entry — logged in (choose family member) / anonymous (optional age) | ⬜ (home card only) |
| BMI-02 | Results: 1 adult 19+ (WHO bands) · 2 age 5–19 (BMI-for-age) · 3 under 5 (no number) · 4 sex "other" < 19 (no number) · 5 no DOB (adult standard + prompt) | ⬜ |
| BMI-03 | History per person — populated / empty; "growth chart coming soon" | ⬜ |

### CRS — Courses / e-Pushti Academy (2)
| ID | Screen | Status |
|----|--------|--------|
| CRS-01 | Chapter list (6) — logged in with progress + `chapter_header` slot / logged out | ⬜ |
| CRS-02 | Chapter — video with size before playback / video failed, text still readable, "take quiz" | ⬜ |

### DGS — Digi Skills (2)
| ID | Screen | Status |
|----|--------|--------|
| DGS-01 | Module list with source (BFSA / UNICEF / IPHN), sequential lock, `cert_footer` slot / VPS unreachable | ⬜ |
| DGS-02 | Module content, "70 % to get certificate" / VPS unavailable, progress safe | ⬜ |

### ASM — Assessment (2)
| ID | Screen | Status |
|----|--------|--------|
| ASM-01 | One question per screen; exit confirm preserves answers | ⬜ |
| ASM-02 | Result — passed (certificate issued, answer review with explanations) / failed (attempts left) | ⬜ |

### CRT — Certificates (2)
| ID | Screen | Status |
|----|--------|--------|
| CRT-01 | My certificates — populated / empty → modules | ⬜ |
| CRT-02 | Detail — QR + random code, PDF, share / revoked banner | ⬜ |

### LIB — Library (2)
| ID | Screen | Status |
|----|--------|--------|
| LIB-01 | List — category picker, size & pages per row, downloaded ✓ / search no results | ⬜ |
| LIB-02 | Viewer — page counter, download, `viewer_footer` slot / large file consent (open vs. read later on Wi-Fi) | ⬜ |

### WEB — Webinars (3)
| ID | Screen | Status |
|----|--------|--------|
| WEB-01 | List — upcoming (seats left) + past (recording) / no upcoming | ⬜ |
| WEB-02 | Detail — seats available / full (notify for recording) / lost the last seat (race) | ⬜ |
| WEB-03 | My registrations — add to calendar, link before event, cancel / empty | ⬜ |

### NOT — Notifications (2)
| ID | Screen | Status |
|----|--------|--------|
| NOT-01 | Inbox — unread first, mark all read / empty | ⬜ |
| NOT-02 | Preferences per category / OS permission denied trap | ⬜ |

### INF — Information & support (5)
| ID | Screen | Status |
|----|--------|--------|
| INF-01 | About us, partners, privacy, terms, version | ⬜ |
| INF-02 | Support — scope statement before the box, subject, message, direct contact | ⬜ |
| INF-03 | Message sent with reference number | ⬜ |
| INF-04 | Settings — language, notifications, video on Wi-Fi only, downloaded files, privacy, logout, delete account | ⬜ |
| INF-05 | Delete account — what is deleted / what survives (certificates, aggregates, PUST9 at operator) | ⬜ |

### SYS — System states (4)
| ID | Screen | Status |
|----|--------|--------|
| SYS-01 | Offline — cached content still reachable | ⬜ |
| SYS-02 | Slow connection — skeleton after 3 s, cancel | ⬜ |
| SYS-03 | Server error — not your fault, code + timestamp, report to support | ⬜ |
| SYS-04 | Forced update — no dismiss, size stated | ⬜ |

**Totals:** 42 screens → 2 built, 3 partial, 37 not started.
