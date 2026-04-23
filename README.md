# Hardly Working

A tongue-in-cheek iOS break timer for tracking time spent *not* working at work. Start a timer when you slack, categorize the activity, and watch your "reclaimed wages" accumulate at your hourly rate. Framed as an onboarding tool for the fictional **Hardly Working Corp.** — the world's leading time-reclamation firm.

Inspired by David Graeber's *Bullshit Jobs*.

- **App Store:** https://apps.apple.com/app/id6761917321
- **Website:** https://hardlyworking.app

## Tech stack

- SwiftUI + SwiftData (iOS 26+, Swift 6)
- Live Activities + Dynamic Island (widget extension target)
- Supabase (auth, profiles, daily stats, friend groups, benchmarks)
- RevenueCat (subscriptions)
- No attribution SDK, no third-party analytics, no ad networks

## Getting started

1. Open `HardlyWorking.xcodeproj` in Xcode 26+.
2. Configure signing with your development team.
3. Publishable keys are in source:
   - `AppDelegate.swift` — RevenueCat
   - `SupabaseManager.swift` — Supabase URL + publishable key
4. Build and run on an iOS 26+ simulator or device.

## Links

- [Privacy Policy](https://hardlyworking.app/privacy)
- [Terms of Service](https://hardlyworking.app/terms)
- [Memos](https://hardlyworking.app/memos) — corporate dispatches from Hardly Working Corp.

## License

All rights reserved. © 2026 Antonio Baltic.
