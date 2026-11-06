# 05 — PUST9 on bdapps: publishing checklist

The PUST9 app is already provisioned on bdapps (Robi/Airtel). This list
covers what the bdapps developer guide (<https://dev.bdapps.com/developer-guide.php>)
asks for, plus what the in-app integration needs. Technical setup is in
`supabase/README.md` → *PUST9 on bdapps*.

## Store listing (bdapps app store)
- [ ] App title: **PUST9 — দৈনিক পুষ্টি পরামর্শ**
- [ ] Poster / icon in the sizes the portal asks for. Use the e-Pushti brand assets.
- [ ] Short description of **at least 150 characters**. Drafts:
  - bn: "PUST9 — ৬০ দিনের পুষ্টি পাঠ্যক্রম। প্রতিদিন আপনার মোবাইলে একটি করে সহজ পুষ্টি পরামর্শ এসএমএসে আসবে: মা ও শিশুর খাবার, নিরাপদ খাদ্য, সুষম খাদ্যাভ্যাস ও স্বাস্থ্যকর জীবনধারা। চার্জ ৳১/দিন + ভ্যাট। বন্ধ করতে STOP PUST9 লিখে 21213-এ পাঠান।"
  - en: "PUST9 is a 60-day nutrition curriculum by SMS. Every day you get one simple, practical tip on mother and child nutrition, safe food, balanced diets and healthy living. Tk 1/day + VAT. Send STOP PUST9 to 21213 to stop."
- [ ] Category: Health / Education.
- [ ] Charging: subscription, Tk 1 per day. This must match `pust9.pricePerDayTaka` in remote config and the app copy.

## Content rules
- [ ] Tips are reviewed by BIID and seeded for every day of the course (`pust9_tips`). bdapps expects SMS services to deliver relevant content every interval.
- [ ] No adult, political, religious, racist or gambling content. We own the copyright of every tip.
- [ ] Pro apps must update their content **every week**. The archive (SMS-02) and new tips cover this.

## Marketing
- [ ] Send all marketing material (banners, social posts, the in-app PUST9 card, and the home promo) to **support@bdapps.com** for approval before it goes live. Say where and when each piece will be published.

## Integration checks before switching the portal URLs
- [ ] bdapps confirms that the OTP and Subscription APIs are enabled for the app.
- [ ] Function secrets are set, the functions are deployed, and the cron and Vault secrets are in place.
- [ ] Tips are seeded. A test member gets the welcome SMS and the day-1 SMS.
- [ ] Callback URLs are saved in the portal: subscription, SMS MO, delivery report and USSD.
- [ ] Live test on a Robi SIM and an Airtel SIM:
  - in-app subscribe
  - status shows "Day 1 of 60"
  - USSD menu items 1–4
  - SMS STOP
  - in-app stop
- [ ] Turn on `pust9.inAppSubscribe` in remote config, and set `stopKeyword` / `stopShortcode`.

## Open decisions
- Auto-stop after the last day is **on** (`PUST9_AUTO_STOP`), so nobody pays past the course. Confirm this with BIID.
- Course length: 60 days, from remote config `courseDays` (decision A1).
