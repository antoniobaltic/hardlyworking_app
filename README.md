# Hardly Working

A tongue-in-cheek iOS break timer that tracks time spent not working at work. Users run timers when slacking, categorize activities, input their hourly wage, and see how much they've "reclaimed" from their employer. Built as a fictional onboarding tool for **Hardly Working Corp.** — the world's leading time reclamation firm.

Inspired by David Graeber's *Bullshit Jobs*.

## Screenshots

*Coming soon*

## Features

- **Break Timer** — One-tap start/stop with 10 activity categories (Coffee Run → Into the Void)
- **Wage Calculator** — Real-time reclaimed wages based on hourly rate and currency
- **Performance Dashboards** — Day, Week, Month, Year, and Lifetime views with charts and insights
- **Industry Benchmarks** — Anonymous aggregate rankings by country, industry, and global averages
- **Friend Groups** — Private "Reclamation Units" with weekly + all-time leaderboards, QR code invites
- **15 Achievements** — 5 rarity tiers, 10 free + 5 Pro, silent tracking for retroactive credit on upgrade
- **Share Cards** — Personalized stats as shareable images (free with watermark, Pro without)
- **CSV Export** — Full time entry history export (Pro)
- **Custom Categories** — Create your own beyond the 10 defaults (Pro)
- **Local Notifications** — Background timer reminders at 1h and 2h with "Stop Timer" action
- **Recording Limits** — Soft cap (2h), hard cap (4h), daily cap, overnight detection
- **Sign in with Apple** — Supabase auth with iCloud sync via CloudKit
- **App Rating Prompts** — Happiness-based scoring with satisfaction survey

## Monetization

Freemium with two tiers:

| | Intern (Free) | Executive (Pro) |
|---|---|---|
| Timer + 10 categories | ✅ | ✅ |
| Today + Week dashboards | ✅ | ✅ |
| Basic benchmarks | ✅ | ✅ |
| Join groups | ✅ | ✅ |
| Share cards (watermark) | ✅ | ✅ |
| 10 achievements | ✅ | ✅ |
| Month/Year/Lifetime dashboards | ❌ | ✅ |
| Insights engine | ❌ | ✅ |
| Full benchmark rankings | ❌ | ✅ |
| Create groups | ❌ | ✅ |
| Custom categories | ❌ | ✅ |
| CSV export | ❌ | ✅ |
| Premium share cards | ❌ | ✅ |
| 5 exclusive achievements | ❌ | ✅ |

**Pricing:** $4.99/week (no trial) or $39.99/year (7-day free trial).

## Tech Stack

- **UI:** SwiftUI (iOS 26+, Swift 6)
- **Data:** SwiftData + CloudKit (iCloud sync)
- **Backend:** Supabase (eu-central-1) — auth, profiles, daily stats, groups, benchmarks
- **Subscriptions:** RevenueCat
- **Attribution:** AppsFlyer (SKAN 4.0, ATT)
- **Notifications:** UNUserNotificationCenter (local)

## Project Structure

```
HardlyWorking/
├── App/
│   ├── HardlyWorkingApp.swift      Three-state launch flow, environment injection
│   ├── AppDelegate.swift           RevenueCat, AppsFlyer, notifications delegate
│   └── ContentView.swift           5-tab layout, achievement/Pro banners
├── Models/
│   ├── TimeEntry.swift             Core SwiftData model
│   ├── UnlockedAchievement.swift   Achievement persistence
│   ├── CustomCategory.swift        User-created categories
│   ├── SlackCategory.swift         10 defaults + helpers
│   └── ShareCardData.swift         Share card data structures
├── Services/
│   ├── AchievementManager.swift    15 achievements, unlock queue, drip-feed
│   ├── AchievementCatalog.swift    Achievement definitions, streak helpers
│   ├── SubscriptionManager.swift   RevenueCat + real-time listener
│   ├── SupabaseManager.swift       Auth, profiles, stats, groups, benchmarks
│   ├── NotificationManager.swift   Local notification scheduling
│   ├── RatingManager.swift         Happiness scoring, review prompts
│   ├── RecordingLimits.swift       Caps, validation, overnight detection
│   ├── CSVExporter.swift           Data export
│   ├── ShareCardRenderer.swift     ImageRenderer at 3x
│   └── MockBenchmarkData.swift     Benchmark fallback data
├── Theme/
│   └── Haptics.swift               Haptic feedback patterns
├── Views/
│   ├── Timer/                      Timer, entry management, custom categories
│   ├── Dashboard/                  Charts, insights, personal records, rankings
│   ├── WallOfShame/                Global benchmarks (country, industry, global)
│   ├── Groups/                     Create, join, leaderboards, QR codes
│   ├── RapSheet/                   Profile, achievements, settings, account mgmt
│   ├── Onboarding/                 11-screen flow + paywall + ATT prompt
│   └── Shared/                     Pro banners, share cards, survey
└── Resources/
    └── Assets.xcassets/            App icon, 11 mascot images
```

## Setup

1. Open `HardlyWorking.xcodeproj` in Xcode 26+
2. Configure signing with your development team
3. API keys are in:
   - `AppDelegate.swift` — RevenueCat (`appl_...`) + AppsFlyer
   - `SupabaseManager.swift` — Supabase URL + publishable key
4. Build and run on iOS 26+ simulator or device

## Brand

**Voice:** Corporate-ironic. Bland HR language on the surface, absurd content underneath. Think: Fisher-Price made a playset called "My First Existential Crisis."

**Mascot:** John D., Employee Relations Officer — low-poly wooden-toy office worker with dead black dot eyes, blue dress shirt, black tie.

**Colors:**
| Name | Hex | Usage |
|------|-----|-------|
| Background | `#FFFFFF` | Pure white |
| Blood Red | `#E63946` | Timer, danger |
| Dead Blue | `#457B9D` | Accent |
| Caution Yellow | `#F4A261` | Warnings |
| Reclaimed Green | `#2A9D8F` | Money (always) |
| Text Primary | `#1D3557` | Dark navy |
| Card Background | `#F1FAEE` | Subtle warmth |

**Language:** "Reclaimed" never "stolen." Section headers: ALL CAPS, monospaced, bold, tracking 1.5, opacity 0.3.

## Links

- [Website](https://hardlyworking.app)
- [App Store](https://apps.apple.com/app/id6761917321)
- [Memos](https://hardlyworking.app/memos) — Corporate dispatches from Hardly Working Corp.
- [Privacy Policy](https://hardlyworking.app/privacy)
- [Terms of Service](https://hardlyworking.app/terms)

## License

All rights reserved. © 2026 Antonio Baltic.
