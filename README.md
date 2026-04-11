# Hardly Working

iOS break timer app. Tracks slacking time and calculates what it's worth.

## Requirements

- iOS 26.0+
- Xcode 26+
- Swift 6.0

## Stack

- SwiftUI + SwiftData
- RevenueCat (subscriptions)
- Supabase (backend — groups, wall of shame)
- AppsFlyer (attribution)

## Structure

```
HardlyWorking/
├── App/                  App entry point, delegate, content view
├── Models/               SwiftData models (TimeEntry, SlackCategory, etc.)
├── Services/             Business logic
│   ├── AchievementManager    Achievement tracking + catalog
│   ├── SubscriptionManager   RevenueCat integration
│   ├── SupabaseManager       Backend client (groups, benchmarks)
│   ├── NotificationManager   Local notifications
│   ├── RatingManager         App Store review prompts
│   └── RecordingLimits       Free tier limits
├── Theme/                Haptics
├── Views/
│   ├── Timer/            Main timer + entry management
│   ├── Dashboard/        Stats, charts, personal records
│   ├── RapSheet/         Profile, achievements, share cards
│   ├── Groups/           Group creation, joining, leaderboards
│   ├── WallOfShame/      Global benchmarks
│   ├── Onboarding/       Multi-step onboarding + paywall
│   └── Shared/           Reusable components (share sheet, pro banners, etc.)
└── Resources/            Assets, mascot images, app icon
```

## Setup

1. Open `HardlyWorking.xcodeproj` in Xcode
2. Configure signing with your team
3. Add your API keys:
   - RevenueCat API key in `SubscriptionManager.swift`
   - Supabase URL + anon key in `SupabaseManager.swift`
   - AppsFlyer dev key in `AppDelegate.swift`
4. Build and run

## Links

- [App Store](https://apps.apple.com/app/id6761917321)
- [Website](https://hardlyworking.app)
