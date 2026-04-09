# Hardly Working

A tongue-in-cheek iOS app that tracks time spent not working at work. Users run timers when slacking, categorize activities, input their hourly wage, and see how much they "stole" from their employer. German localization: "Arbeitszeitbetrug".

## Brand Direction: "Soulless"

Corporate training video meets children's toy. Friendly on the surface. Dead inside. The visual language is cheerful and innocent (wooden-toy characters, bold colors, white backgrounds) but the content is dark (tracking wage theft, existential corporate dread). The tension between the two is the brand.

Think: Fisher-Price made a playset called "My First Existential Crisis." Every design choice answers: "What would HR approve?" — but the data is absurd.

References: Untitled Goose Game (cute style, antisocial behavior), Papers Please (mundane aesthetic, dark content), Human Resource Machine.

## Mascot

A low-poly / wooden-toy office worker with dead black dot eyes, blue dress shirt, black tie. Soulless, blocky, slightly unsettling. Appears in onboarding, empty states, achievements, marketing.

App icon: cropped tight to just the head/face on a bold background. The dead eyes are the hook.

## Color Palette

Slightly-off primaries. Like primary colors that have been sitting under fluorescent office lighting too long and faded.

```
Background:         #FFFFFF  (pure white)
"Blood" Red:        #E63946  (slightly warm, not Google red)
"Dead" Blue:        #457B9D  (muted, desaturated - faded dress shirt)
"Caution" Yellow:   #F4A261  (mustard/amber - aged sticky note)
"Reclaimed" Green:     #2A9D8F  (institutional, not neon - for money amounts)
Text:               #1D3557  (dark navy, not pure black)
Card Background:    #F1FAEE  (slight warmth, off-white)
```

Money amounts are ALWAYS in Reclaimed Green. That color = money throughout the app. Use "reclaimed" not "stolen" — empowering, not criminal.

Dark mode = "after hours" — same layout but the lights are off in the office.

## Typography

- Body: clean, corporate, slightly characterless on purpose (Inter or IBM Plex Sans)
- Numbers/money: monospace or tabular font (receipt/invoice feel)
- Calibri-like for any spreadsheet-themed elements (share cards, wrapped)

## Spreadsheet DNA (Seasoning, Not the Meal)

The core UI is clean, white, native iOS. Spreadsheet personality shows up in specific moments:

- Formula bar as status header: `=SUM(time_stolen)` -> `2h 34m`
- Excel error codes for empty states: `#N/A`, `####`, `#REF!`
- Share cards styled as spreadsheet printouts / corporate memos
- Achievement notifications as Excel pop-ups: "Circular reference detected in your work ethic"
- Year-end Wrapped styled as an annual report

## In-App Copy Tone

Cheeky, conspiratorial, corporate-ironic:

- Timer tab: "Timer" or contextual
- Dashboard: "The Evidence"
- Leaderboard: "Wall of Shame"
- Profile: "Rap Sheet"
- Settings: "Cover Story"
- Premium: "Career Criminal"

## Key Screens

1. **Timer** — start/stop, quick-add category presets, today's log, retroactive entry
2. **The Evidence** — dashboard with charts, stats by period, category breakdown, insights, share button
3. **Wall of Shame** — leaderboards (global, country, industry). Premium feature.
4. **Rap Sheet** — profile, all-time stats, achievements, settings

## Tech Stack

- SwiftUI + SwiftData (local-first, offline capable)
- Supabase backend (auth, leaderboards, aggregate stats)
- iOS 26+, Swift 6
- Raw TimeEntry data stays on-device. Only aggregated stats sync for privacy.

## Monetization: Freemium

### Free
- Timer (start/stop, quick-add, retroactive)
- 3 default categories
- Today + this week stats
- Daily totals (time + money)
- Basic bar chart (current week)

### Premium
- Unlimited custom categories
- Full dashboard (month/year, donut chart, insights)
- Leaderboards
- Achievements & titles
- Share cards
- Yearly Wrapped
- Export (CSV)
- History beyond 7 days

## Viral Mechanics

- Wrapped-style year/month-end review (styled as corporate annual report)
- Share cards: personalized stats as identity ("I stole $4,200 this year")
- Leaderboards with percentile ranks
- Achievement badges with dark humor
