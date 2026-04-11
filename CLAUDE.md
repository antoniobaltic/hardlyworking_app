# Hardly Working

A tongue-in-cheek iOS app that tracks time spent not working at work. Users run timers when slacking, categorize activities, input their hourly wage, and see how much they "reclaimed" from their employer. German localization: "Arbeitszeitbetrug". Inspired by David Graeber's "Bullshit Jobs."

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
"Reclaimed" Green:  #2A9D8F  (institutional, not neon - for money amounts)
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

- Formula bar as status header: `=SUM(time_reclaimed)` -> `2h 34m`
- Excel error codes for empty states: `#N/A`, `####`, `#REF!`
- Share cards styled as spreadsheet printouts / corporate memos
- Achievement notifications as Excel pop-ups: "Circular reference detected in your work ethic"
- Year-end Wrapped styled as an annual report

## Language Rules

- "reclaimed" never "stolen" — empowering, not criminal
- "slacking" is fine for actions ("Start Slacking", "Stop Slacking")
- Section headers: ALL CAPS, monospaced, bold, letter-spaced (tracking 1.5), opacity 0.3
- Money shows in exactly ONE place per screen (formula bar), never duplicated
- Formula bar formula must match what it's computing (e.g. `=SUM(today_reclaimed)` for money)
- **Corporate-ironic voice throughout.** Tab names and section headers use bland corporate jargon (HR-speak, audit language, performance review terminology). The humor comes from the tension between professional language and absurd content — not from crime/police metaphors. No "booking," "suspect," "criminal," "expunge," "offense," etc. Think: what would appear on a soulless corporate intranet portal?

## In-App Copy Tone

Corporate-ironic. Bland HR language on the surface, absurd data underneath.

- Time Sheet tab: "Time Sheet"
- Dashboard tab: "Performance"
- Benchmarks tab: "Benchmarks"
- Profile tab: "Profile"
- Settings section: "Preferences"
- Premium: "Career Criminal" (product name, not a UI label)

## Key Screens

1. **Time Sheet** — category-first flow (tap a category to start), live timer, today's log with edit/delete/retroactive add
2. **Performance** — Day/Week/Month/Year/All dashboards. Day has timeline, Week has daily bars (Mon-Fri), Month has weekly bars (split at month boundaries), Year has monthly bars (Jan-Dec), All has career stats grid + category rankings + personal records
3. **Benchmarks** — NOT individual leaderboards (self-reported data can't be trusted). Shows anonymous aggregate benchmarks: your position vs global average, country rankings, industry rankings, global stats. Mock data for now, Supabase later.
4. **Profile** — personnel file (identity card), performance review (career stats), commendations (achievements placeholder), preferences (settings)

## Benchmarks Design Decisions

- Individual leaderboards are broken because data is self-reported — users can just let the timer run overnight
- Instead: aggregate benchmarks that can't be gamed (individual outliers wash out in averages)
- Country and industry comparisons answer "Am I normal?" which is more compelling than "Am I #1?"
- Future feature: private friend groups where coworkers can hold each other accountable. This is separate from Benchmarks and requires Supabase + persistent identities.

## Categories (ordered by escalation: innocent → existential)

Coffee Run, Bathroom Break, Chatting, Doom Scrolling, Online Shopping, Errands, Looking Busy, "Thinking", Into the Void, Long Lunch

## Industry List (fun labels)

Office Drone, Tech Bro, Suit & Tie, Scrubs, Teacher's Lounge, Bureaucrat, Retail Warrior, Blue Collar, Creative, Call Center Survivor, Hospitality, Other

## Tech Stack

- SwiftUI + SwiftData (local-first, offline capable)
- Supabase backend (auth, aggregate stats, benchmarks) — NOT YET SET UP
- RevenueCat (in-app purchases) — SDK integrated, no products configured
- AppsFlyer (attribution) — SDK integrated, placeholder keys
- iOS 26+, Swift 6
- Raw TimeEntry data stays on-device. Only aggregated stats sync for privacy.

## User Data Needed (for onboarding)

| Field | AppStorage Key | Status |
|-------|---------------|--------|
| Hourly rate | `hourlyRate` | Exists, defaults to $15 |
| Currency | `currency` | Exists, defaults to "USD" |
| Work hours/day | `workHoursPerDay` | Exists, defaults to 8 |
| Work days/week | `workDaysPerWeek` | Exists, defaults to 5 |
| Country | `userCountry` | Exists, defaults to "" |
| Industry | `userIndustry` | Exists, defaults to "" |
| Include weekends in charts | `includeWeekends` | Exists, defaults to false |

## Monetization: Freemium

**Pricing:** $4.99/week (no trial) or $39.99/year (7-day free trial). Annual saves 85%.

**Principle:** Free users are your marketing department. Gate depth, not breadth. Never restrict the daily habit loop or anything that puts the app on someone else's social feed.

### Free (the viral engine)
- Full timer (start/stop, all 10 categories, retroactive add, edit/delete)
- Today + This Week dashboard (daily stats, weekly bar chart, category breakdown)
- Benchmarks summary (your position vs. global average — "Top 30%" tease only)
- Personnel File + Preferences (full settings access)
- Join friend groups (via link/QR, view leaderboard, submit data)
- Share cards — basic, with app watermark (when built)
- Wrapped — basic shareable version (when built)

### Pro ("Hardly Working Pro")

**Dashboard depth:**
- Month, Year, and Lifetime dashboards
- Insights engine ("Audit Findings")
- Personal Records
- Category Rankings

**Benchmarks depth:**
- Full country rankings
- Full industry rankings
- Global stats detail

**Friend groups:**
- Create groups (unlimited)
- Customize (name, emoji, description)
- Generate invite links / QR codes
- Manage members

**Extras:**
- Achievements & titles
- Custom categories (beyond 10 defaults)
- CSV export
- Premium share cards (custom themes, no watermark)
- Premium Wrapped (detailed version)

### Why this split
- Free tier = complete daily tool. Timer + Today + This Week is genuinely useful. Users form habits, see value daily, tell friends.
- Paywall triggers naturally at ~2 weeks when users want Month view. They've accumulated data and the upgrade feels like unlocking their own analysis.
- Share cards + Wrapped stay free = viral loop intact. Every share with watermark = free ad.
- Friend groups: joining is free (every invite = new user), creating is Pro (one paying user brings in 5-10 free users).
- Benchmarks tease creates curiosity. "Top 30%" is free. Full rankings are Pro.

## Build Roadmap

### Done
- [x] Time Sheet screen (fully functional)
- [x] Performance screen (Day/Week/Month/Year/All)
- [x] Benchmarks (UI with mock data)
- [x] Profile screen (personnel file, performance review, preferences)
- [x] RevenueCat + AppsFlyer SDK integration
- [x] App icon + asset catalog
- [x] Brand theme (colors, fonts, haptics)

### Next
1. **Onboarding** — collect wage, country, industry, work schedule
2. **Supabase backend** — anonymous auth, aggregate sync, live Benchmarks
3. **Benchmarks live data** — replace mocks with Supabase queries
5. **Friend groups** — private group leaderboards (premium)
6. **Premium paywall** — RevenueCat product setup, gate features
7. **Polish** — dark mode, animations, share cards, German localization, Wrapped

## Viral Mechanics

- Wrapped-style year/month-end review (styled as corporate annual report)
- Share cards: personalized stats as identity ("I reclaimed $4,200 this year")
- Country/industry rankings as shareable content
- Achievement badges with dark humor
