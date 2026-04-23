# Hardly Working

> **Status (April 2026)**: V1 complete. Build uploaded to App Store Connect. Metadata configuration in progress. Target: manual release, Tuesday/Wednesday morning once Apple approves.

A satirical iOS break timer that tracks time spent NOT working and calculates its dollar value at the user's hourly rate. Framed as the fictional "Hardly Working Corp." — every surface reads like a corporate memo. Inspired by David Graeber's *Bullshit Jobs*.

---

## Role context for assistants

This project operates with two coexisting AI roles:

- **Engineering assistant** — helps with SwiftUI, SwiftData, Supabase, RevenueCat, Xcode project issues
- **CMO** — handles brand voice, App Store Connect setup, launch strategy, marketing content

When in doubt about tone, branding, or marketing strategy: **read `marketing.md` first.** It is the source of truth for voice, character canon, political positioning, and launch strategy. Don't re-derive decisions already made there.

When in doubt about code or features: code state is authoritative. Read the relevant Swift file.

---

## One-paragraph brand summary

Corporate training video meets children's toy. Visuals are cheerful and innocent (wooden-toy mascot, bold colors, white backgrounds); content is dark (tracking wage theft as "reclamation," referencing Bullshit Jobs). Two named characters: **J. Pemberton, CSO** (written voice — all memos/official copy) and **John D.** (the mascot — performative/visual). Dry institutional bureaucratic tone. No snark, no crime metaphors ("reclaimed" not "stolen"). **Full brand rules in `marketing.md`.**

## Visual language (quick reference)

```
Background:         #FFFFFF
"Blood" Red:        #E63946   — stamps, destructive actions
"Dead" Blue:        #457B9D   — accent, John D.'s shirt
"Caution" Yellow:   #F4A261   — highlights, gold podium tier
"Reclaimed" Green:  #2A9D8F   — MONEY, always and only
Text Navy:          #1D3557   — body text (never pure black)
Card Background:    #F1FAEE   — off-white warm
```

**Money is always green (`#2A9D8F`). No exceptions across app, share cards, marketing.**

Light mode only — `HardlyWorkingApp.swift` forces `.preferredColorScheme(.light)`. Dark mode is not supported in V1.

## Language rules (quick reference)

- ✅ Reclaimed, Activity, Session, Employee, Reclamation Unit, Orientation, Promotion, Executive tier
- ❌ Stolen, Offense, Incident, Perpetrator, Group, Signup, Upgrade, Pro
- ❌ Crime/cop metaphors entirely (no "booking," "suspect," "rap sheet")
- ❌ Moralizing at users or at specific named employers
- Money shown in exactly one place per screen (never duplicated)

---

## Tech stack

- **SwiftUI + SwiftData** — local-first, offline capable
- **Supabase** — auth (Sign in with Apple), profile sync, aggregate stats, Reclamation Unit leaderboards
- **RevenueCat** — subscription management; identity synced to Supabase user via `logIn/logOut` in `SupabaseManager.listenForAuthChanges`
- **iOS 26+** deployment target
- **Swift 6.0**

No attribution SDK and no ATT prompt — the app does not track users.

## Data residency

| Data | Lives in | Synced across devices? |
|---|---|---|
| Raw `TimeEntry` records | SwiftData (on-device) | ❌ No |
| `UnlockedAchievement` records | SwiftData (on-device) | ❌ No |
| `CustomCategory` records | SwiftData (on-device) | ❌ No |
| Profile (wage, country, industry, schedule, Employee ID) | Supabase `profiles` | ✅ Yes via SIWA |
| Daily aggregated stats | Supabase `daily_stats` | ✅ Yes |
| Reclamation Units (groups, memberships, display names) | Supabase | ✅ Yes |
| Subscription state | RevenueCat (keychain-backed + receipt sync) | ✅ Yes |

The app explicitly does NOT use CloudKit sync. No iCloud container. Cross-device continuity comes from Supabase (profile + aggregates) and iCloud Backup (device-level snapshots only).

## File layout

```
HardlyWorking/
  App/             HardlyWorkingApp, AppDelegate, ContentView
  Models/          SwiftData models + ShareCardData + ClearanceLevel
  Services/        SupabaseManager, SubscriptionManager, RatingManager,
                   AchievementManager, NotificationManager, ShareCardRenderer,
                   CSVExporter, RecordingLimits, AchievementCatalog, MockBenchmarkData
  Theme/           Theme.swift (colors/money formatting), Haptics
  Views/
    Timer/         TimerView, TimerViewModel, AddEntrySheet, EntryEditSheet, AddCategorySheet
    Dashboard/     DashboardView, daily/category charts, Insights, Lifetime/*
    WallOfShame/   BenchmarkViewModel + country/industry/global views (Intel tab)
    Groups/        GroupsView, GroupsViewModel, Create/Join/Detail sheets (Units tab)
    RapSheet/      RapSheetView + Settings + BookingHeader + Achievements + CoverStory (Dossier tab)
    Onboarding/    OnboardingContainerView + 10 step views + PaywallView
    Shared/        ShareSheet, ShareCardView, ClearanceBadgeView, ProUpgradeBanner, ProLockedView
supabase/          Edge Functions (delete_account)
web/               (gitignored) Next.js landing page — lives at hardlyworking.app
marketing.md       CMO playbook — brand bible + launch strategy
```

## Tab names (in ContentView)

Time Sheet · Reports · Intel · Units · Dossier

---

## Monetization (as shipped)

Free tier ("Intern"): full timer, all 10 categories, Today + This Week dashboards, benchmarks summary, joining existing Reclamation Units, basic share cards (with watermark), 10 achievements.

Paid tier ("Executive"): $2.99/week OR $24.99/year (7-day free trial on annual).

Pro unlocks: Month/Year/Lifetime dashboards, Audit Findings (insights), personal records + category rankings, full country/industry benchmarks, creating Reclamation Units, custom activity codes, CSV export, premium share cards (no watermark), 5 executive-only achievements.

Product IDs (ASC ↔ RevenueCat):
- Weekly: `hw_weekly`
- Annual: `hw_annual`

---

## Activity codes (ordered innocent → existential)

Coffee Run, Bathroom Break, Chatting, Doom Scrolling, Online Shopping, Errands, Looking Busy, "Thinking", Into the Void, Long Lunch

## Industries

Office Drone, Tech Bro, Suit & Tie, Scrubs, Teacher's Lounge, Bureaucrat, Retail Warrior, Blue Collar, Creative, Call Center Survivor, Hospitality, Other

## User profile fields (collected during onboarding)

| Field | AppStorage key |
|---|---|
| Hourly rate | `hourlyRate` |
| Currency | `currency` |
| Work hours/day | `workHoursPerDay` |
| Work days/week | `workDaysPerWeek` |
| Country | `userCountry` |
| Industry | `userIndustry` |
| Include weekends in charts | `includeWeekends` |
| Employee ID | `employeeId` (server-assigned on `handle_new_user`) |

Profile data syncs to Supabase via `SupabaseManager.syncProfile` and restores on new devices via `HardlyWorkingApp.restoreProfileFromSupabase`.

---

## What's shipped in V1

- Full timer + all 10 activity codes + retroactive add + edit/delete
- Day / Week / Month / Year / Lifetime dashboards
- Benchmarks (live Supabase data, not mocks)
- Reclamation Units (create, join, leaderboards weekly/monthly/all-time with `joined_at` filtering, per-unit display names, server-assigned `#HW-XXXXX` Employee IDs)
- Achievements (15 definitions × 5 rarity tiers, with drip-feed banner queue)
- Share cards (6 card types, 4:3 format = 1080×1440 final)
- Onboarding (10 steps + SIWA + paywall)
- Rating system (5 trigger points, iOS-3/year cap respected, Settings "Rate" button + App Store fallback URL)
- Sign in with Apple → Supabase auth → RevenueCat identity sync (all three in lockstep via `listenForAuthChanges`)
- Account deletion via Supabase Edge Function
- Privacy manifest (`PrivacyInfo.xcprivacy`)

## App Store Connect state (as of April 2026)

Locked:
- **Name**: `Hardly Working: Slacking Timer`
- **Subtitle**: `Calculate your reclaimed wages`
- **Keywords**: `break,paycheck,pomodoro,anti work,office,hourly,tracker,coffee,lunch,employee,shift,desk,meeting`
- **Promotional text**: launch-day "NOW HIRING" version (150 chars)
- **Description**: 3,750-char full memo voice, J. Pemberton signature
- **Support URL + Marketing URL**: `https://hardlyworking.app`
- **Version**: `1.0`
- **Copyright**: `© 2026 Hardly Working Corp. All rights reclaimed.`
- **Primary Category**: Lifestyle
- **Secondary Category**: Productivity
- **Content Rights**: No third-party content
- **Age Rating**: 4+ (all NO on questionnaire)
- **Privacy Nutrition Label**: 5 data types, 0 declared as tracking (PurchaseHistory, ProductInteraction, OtherUsageData, UserID, CoarseLocation — all `NSPrivacyTracking=false`). ASC-side nutrition label needs to be updated to match — previous declaration included Device ID + Advertising Data as tracking, both dropped when AppsFlyer was removed.
- **Apple Silicon Mac + Vision Pro availability**: OFF
- **Billing Grace Period**: 16 days
- **Streamlined Purchasing**: ON
- **Release**: Manual
- **App Accessibility declarations**: skipped (no audit yet)

In progress:
- Subscription products — Reference Names set, product IDs (`hw_weekly`, `hw_annual`) verified, but pricing + intro offer + localization + paywall review screenshot still to complete
- App Store screenshots — not started (saved for last)
- App Review Information notes — drafted, ~900 chars, ready to paste

---

## Post-launch backlog (not blocking V1)

- **Rename `First Offense` + `Repeat Offender` achievements** — violate our "no crime metaphors" rule. Candidates: `Initial Filing` / `Pattern of Conduct`.
- **Typo in MEMO-2026-009**: "reduce the guilt of your colleagues is also doing" — either fix or leave as authentic-document texture.
- **Accessibility audit + implementation** — Dynamic Type support, VoiceOver labels throughout, respect Reduce Motion, WCAG contrast review. Then claim on ASC accessibility section.
- **Real CloudKit sync for `TimeEntry` records** — currently local-only, users lose raw history on device change unless iCloud Backup restored.
- **Support page** at `hardlyworking.app/support` — currently we rely on the landing page footer Contact link.
- **`User Privacy Choices URL`** (ASC privacy section, optional) — only needed if we add CCPA-style in-app opt-out flows.

---

## Launch operating principles

- **Manual release** on approved build — hit the button on a Tuesday/Wednesday morning.
- **Social-led growth** — primary channel is TikTok/Reels featuring John D. as a character. Not App Store search.
- **Volume > star average** for ratings. Every meaningful positive moment calls `AppStore.requestReview` directly. No satisfaction-survey gating.
- **Brand-voice consistency is the whole product.** If copy sounds like a Hardly Working Corp. memo, ship it. If it sounds like a startup marketing bro, kill it.

For full launch strategy, content pillars, channel strategy, and the "first 90 days" sequencing: see `marketing.md` §9–11 and §15.
