# Fantasy 11 - Flow & Architectural Diagrams

## Table of Contents

1. [Application Flow Diagrams](#application-flow-diagrams)
2. [Sequence Diagrams](#sequence-diagrams)
3. [State Diagrams](#state-diagrams)
4. [Component Diagrams](#component-diagrams)
5. [Data Flow Diagrams](#data-flow-diagrams)

---

## Application Flow Diagrams

### Main Application Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            APP LAUNCH                                        │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         INITIALIZATION                                       │
│  • Initialize Hive boxes                                                    │
│  • Load app configuration                                                   │
│  • Check authentication status                                              │
│  • Load user preferences (language, theme)                                  │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
           Authenticated                     Not Authenticated
                    │                               │
                    ▼                               ▼
┌───────────────────────────────┐   ┌───────────────────────────────┐
│         HOME SCREEN           │   │      AUTHENTICATION           │
│  • My Contests                │   │  • Login                      │
│  • Upcoming Matches           │   │  • Register                   │
│  • Quick Actions              │   │  • OTP Verification           │
└───────────────┬───────────────┘   └───────────────────────────────┘
                │
    ┌───────────┼───────────┬───────────┬───────────┐
    ▼           ▼           ▼           ▼           ▼
┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐
│ Player  │ │ Fantasy │ │ My      │ │ Wallet  │ │ Account │
│ Search  │ │ Leagues │ │ Matches │ │         │ │ Profile │
└─────────┘ └─────────┘ └─────────┘ └─────────┘ └─────────┘
```

### User Journey: Creating a Fantasy League

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     CREATE FANTASY LEAGUE JOURNEY                            │
└─────────────────────────────────────────────────────────────────────────────┘

Step 1: League Creation
┌───────────────────────────────────────────────────────────────────────────┐
│                                                                           │
│  User clicks "Create League"                                              │
│         │                                                                 │
│         ▼                                                                 │
│  ┌─────────────────────────────────┐                                     │
│  │   LEAGUE CREATION FORM          │                                     │
│  │                                 │                                     │
│  │   • League Name ___________     │                                     │
│  │   • Type: [Public/Private]      │                                     │
│  │   • Max Members: [2-20]         │                                     │
│  │   • Entry Fee: ___________      │                                     │
│  │   • Budget: 100 credits         │                                     │
│  │                                 │                                     │
│  │   [Create League]               │                                     │
│  └─────────────────────────────────┘                                     │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
                    │
                    ▼
Step 2: Team Building
┌───────────────────────────────────────────────────────────────────────────┐
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                    TEAM BUILDER PAGE                                 │ │
│  ├─────────────────────────────────────────────────────────────────────┤ │
│  │                                                                     │ │
│  │  ┌─────────────────────────────────────────────────────────────┐   │ │
│  │  │                    SOCCER FIELD VIEW                         │   │ │
│  │  │                                                              │   │ │
│  │  │                         GK                                   │   │ │
│  │  │                        [+]                                   │   │ │
│  │  │                                                              │   │ │
│  │  │              DEF    DEF    DEF    DEF                        │   │ │
│  │  │              [+]    [+]    [+]    [+]                        │   │ │
│  │  │                                                              │   │ │
│  │  │              MID    MID    MID    MID                        │   │ │
│  │  │              [+]    [+]    [+]    [+]                        │   │ │
│  │  │                                                              │   │ │
│  │  │                    FWD    FWD                                │   │ │
│  │  │                    [+]    [+]                                │   │ │
│  │  │                                                              │   │ │
│  │  └─────────────────────────────────────────────────────────────┘   │ │
│  │                                                                     │ │
│  │  ┌─────────────────────────────────────────────────────────────┐   │ │
│  │  │  BENCH: [+GK] [+DEF] [+MID] [+FWD]                          │   │ │
│  │  └─────────────────────────────────────────────────────────────┘   │ │
│  │                                                                     │ │
│  │  Budget: 67.5 / 100 credits     Players: 8 / 15                   │ │
│  │                                                                     │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
                    │
                    │ User taps [+] slot
                    ▼
Step 3: Player Selection
┌───────────────────────────────────────────────────────────────────────────┐
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                  PLAYER SELECTION SHEET                              │ │
│  ├─────────────────────────────────────────────────────────────────────┤ │
│  │  🔍 [Search players...]                                             │ │
│  │                                                                     │ │
│  │  [Sort ▼] [Filter by Team ▼] [Position: DEF]                       │ │
│  │                                                                     │ │
│  │  ┌─────────────────────────────────────────────────────────────┐   │ │
│  │  │ 👤 Carlos Salcedo    │ DEF │ Tigres  │ 7.5c │ 52pts │ [+]  │   │ │
│  │  │ 👤 Jesús Angulo      │ DEF │ Chivas  │ 6.8c │ 48pts │ [+]  │   │ │
│  │  │ 👤 Brían García      │ DEF │ Toluca  │ 6.2c │ 45pts │ [+]  │   │ │
│  │  │ ...                                                         │   │ │
│  │  └─────────────────────────────────────────────────────────────┘   │ │
│  │                                                                     │ │
│  │  [Load More ↓]                                                     │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
                    │
                    │ User selects player
                    ▼
Step 4: Captain Selection
┌───────────────────────────────────────────────────────────────────────────┐
│                                                                           │
│  After 15 players selected:                                               │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐ │
│  │                    CAPTAIN SELECTION                                 │ │
│  │                                                                     │ │
│  │  Select your Captain (2x points):                                   │ │
│  │  ○ Paulinho (FWD) - 72 projected pts                               │ │
│  │  ○ André-Pierre Gignac (FWD) - 68 projected pts                    │ │
│  │  ● Kevin Álvarez (MID) - 65 projected pts  ✓                       │ │
│  │                                                                     │ │
│  │  Select your Vice-Captain (1.5x points):                           │ │
│  │  ● Orbelín Pineda (MID) - 58 projected pts  ✓                      │ │
│  │                                                                     │ │
│  │  [Save Team]                                                        │ │
│  └─────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
                    │
                    ▼
Step 5: League Ready
┌───────────────────────────────────────────────────────────────────────────┐
│                                                                           │
│  ✅ League Created Successfully!                                          │
│                                                                           │
│  League Code: ABC-123-XYZ (for private leagues)                          │
│                                                                           │
│  • Share with friends                                                     │
│  • Wait for members to join                                               │
│  • League starts automatically when full                                  │
│                                                                           │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## Sequence Diagrams

### Player Search Sequence

```
┌────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────────┐     ┌─────────────┐
│  User  │     │ SearchPage   │     │ PlayersRepo     │     │ CacheService │     │ SportMonks  │
└───┬────┘     └──────┬───────┘     └────────┬────────┘     └──────┬───────┘     └──────┬──────┘
    │                 │                      │                     │                    │
    │ Enter "Paulinho"│                      │                     │                    │
    │────────────────▶│                      │                     │                    │
    │                 │                      │                     │                    │
    │                 │ debounce 500ms       │                     │                    │
    │                 │──────────┐           │                     │                    │
    │                 │          │           │                     │                    │
    │                 │◀─────────┘           │                     │                    │
    │                 │                      │                     │                    │
    │                 │ searchRosterPlayers()│                     │                    │
    │                 │─────────────────────▶│                     │                    │
    │                 │                      │                     │                    │
    │                 │                      │ getFromCache()      │                    │
    │                 │                      │────────────────────▶│                    │
    │                 │                      │                     │                    │
    │                 │                      │ null (cache miss)   │                    │
    │                 │                      │◀────────────────────│                    │
    │                 │                      │                     │                    │
    │                 │                      │ searchPlayers()     │                    │
    │                 │                      │────────────────────────────────────────▶│
    │                 │                      │                     │                    │
    │                 │                      │                 API Response             │
    │                 │                      │◀────────────────────────────────────────│
    │                 │                      │                     │                    │
    │                 │                      │ saveToCache()       │                    │
    │                 │                      │────────────────────▶│                    │
    │                 │                      │                     │                    │
    │                 │  List<RosterPlayer>  │                     │                    │
    │                 │◀─────────────────────│                     │                    │
    │                 │                      │                     │                    │
    │  Display Results│                      │                     │                    │
    │◀────────────────│                      │                     │                    │
    │                 │                      │                     │                    │
```

### Fantasy Points Prediction Sequence

```
┌────────────────┐     ┌───────────────────┐     ┌─────────────────┐     ┌──────────────────┐
│ PlayerDetails  │     │ FantasyPredictor  │     │ FixturesRepo    │     │ SeasonsRepo      │
└───────┬────────┘     └─────────┬─────────┘     └────────┬────────┘     └─────────┬────────┘
        │                        │                        │                        │
        │ loadPrediction()       │                        │                        │
        │───────────────────────▶│                        │                        │
        │                        │                        │                        │
        │                        │ getCurrentSeason()     │                        │
        │                        │────────────────────────────────────────────────▶│
        │                        │                        │                        │
        │                        │                   SeasonInfo                    │
        │                        │◀────────────────────────────────────────────────│
        │                        │                        │                        │
        │                        │ getNextMatch()         │                        │
        │                        │───────────────────────▶│                        │
        │                        │                        │                        │
        │                        │     MatchInfo          │                        │
        │                        │◀───────────────────────│                        │
        │                        │                        │                        │
        │                        │ getRecentForm()        │                        │
        │                        │───────────────────────▶│                        │
        │                        │                        │                        │
        │                        │  RecentMatchStats      │                        │
        │                        │◀───────────────────────│                        │
        │                        │                        │                        │
        │                        │ ┌──────────────────┐   │                        │
        │                        │ │ Calculate:       │   │                        │
        │                        │ │ • Base Score     │   │                        │
        │                        │ │ • Position Bonus │   │                        │
        │                        │ │ • Form Score     │   │                        │
        │                        │ │ • Opponent Adj   │   │                        │
        │                        │ │ • Home Advantage │   │                        │
        │                        │ └──────────────────┘   │                        │
        │                        │                        │                        │
        │  PredictionResult      │                        │                        │
        │◀───────────────────────│                        │                        │
        │                        │                        │                        │
```

### Team Building with Validation

```
┌────────┐     ┌───────────────┐     ┌───────────────────┐     ┌──────────────────┐
│  User  │     │ TeamBuilder   │     │ ValidationEngine  │     │ FantasyTeam      │
└───┬────┘     └───────┬───────┘     └─────────┬─────────┘     └─────────┬────────┘
    │                  │                       │                         │
    │ Tap Add Player   │                       │                         │
    │─────────────────▶│                       │                         │
    │                  │                       │                         │
    │                  │ validateAddition()    │                         │
    │                  │──────────────────────▶│                         │
    │                  │                       │                         │
    │                  │                       │ Check:                  │
    │                  │                       │ • Squad size < 15       │
    │                  │                       │ • Position limit        │
    │                  │                       │ • Club limit <= 4       │
    │                  │                       │ • Budget available      │
    │                  │                       │ • Not duplicate         │
    │                  │                       │                         │
    │                  │   ValidationResult    │                         │
    │                  │◀──────────────────────│                         │
    │                  │                       │                         │
    │                  │                       │                         │
    │         ┌────────┴────────┐              │                         │
    │         │                 │              │                         │
    │      Valid             Invalid           │                         │
    │         │                 │              │                         │
    │         ▼                 ▼              │                         │
    │  ┌──────────────┐  ┌──────────────┐     │                         │
    │  │ addPlayer()  │  │ showError()  │     │                         │
    │  └──────┬───────┘  └──────────────┘     │                         │
    │         │                               │                         │
    │         │────────────────────────────────────────────────────────▶│
    │         │                               │                         │
    │  Update UI       │                       │                         │
    │◀─────────────────│                       │                         │
    │                  │                       │                         │
```

---

## State Diagrams

### Fantasy Team State Machine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FANTASY TEAM STATES                                  │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────┐
                              │   EMPTY     │
                              │  (0 players)│
                              └──────┬──────┘
                                     │
                                     │ addPlayer()
                                     ▼
                              ┌─────────────┐
               ┌──────────────│  BUILDING   │──────────────┐
               │              │ (1-14 plrs) │              │
               │              └──────┬──────┘              │
               │                     │                     │
    removePlayer()          addPlayer()           removePlayer()
               │                     │                     │
               │                     ▼                     │
               │              ┌─────────────┐              │
               │              │   COMPLETE  │              │
               │              │ (15 players)│              │
               │              └──────┬──────┘              │
               │                     │                     │
               │         setCaptain() & setViceCaptain()   │
               │                     │                     │
               │                     ▼                     │
               │              ┌─────────────┐              │
               └──────────────│    READY    │──────────────┘
                              │  (Captains  │
                              │   Selected) │
                              └──────┬──────┘
                                     │
                                     │ saveTeam()
                                     ▼
                              ┌─────────────┐
                              │    SAVED    │
                              │  (Can edit) │
                              └─────────────┘
```

### League State Machine

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           LEAGUE STATES                                      │
└─────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────┐
                              │   CREATED   │
                              │(Admin only) │
                              └──────┬──────┘
                                     │
                                     │ publishLeague()
                                     ▼
                              ┌─────────────┐
               ┌──────────────│   OPEN      │
               │              │(Accepting   │
               │              │ members)    │
               │              └──────┬──────┘
               │                     │
       memberLeaves()       memberJoins() OR maxReached()
               │                     │
               ▼                     ▼
┌─────────────────┐          ┌─────────────┐
│  INSUFFICIENT   │          │    FULL     │
│  (< min members)│          │(Max members)│
└────────┬────────┘          └──────┬──────┘
         │                          │
         │ memberJoins()            │ startLeague()
         │                          │
         └──────────────────────────┼──────────────────────────┐
                                    ▼                          │
                              ┌─────────────┐                  │
                              │   ACTIVE    │                  │
                              │(In progress)│                  │
                              └──────┬──────┘                  │
                                     │                         │
                                     │ seasonEnds()            │
                                     ▼                         │
                              ┌─────────────┐                  │
                              │  COMPLETED  │                  │
                              │(Final ranks)│                  │
                              └─────────────┘                  │
                                                               │
                                     │ cancelLeague()          │
                                     ◀─────────────────────────┘
                                     │
                                     ▼
                              ┌─────────────┐
                              │  CANCELLED  │
                              │(Refunds)    │
                              └─────────────┘
```

---

## Component Diagrams

### UI Component Hierarchy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         UI COMPONENT TREE                                    │
└─────────────────────────────────────────────────────────────────────────────┘

MaterialApp
│
├── ThemeData (Dark Theme)
│
└── Router
    │
    ├── HomeScreen
    │   ├── AppBar
    │   ├── BottomNavigationBar
    │   └── Body
    │       ├── UpcomingMatchesCarousel
    │       ├── MyContestsSection
    │       └── QuickActionsGrid
    │
    ├── PlayerSearchPage
    │   ├── SearchBar
    │   ├── RecentPlayersList
    │   └── SearchResultsList
    │       └── PlayerCard (repeating)
    │
    ├── PlayerDetailsPage
    │   ├── PlayerHeader
    │   │   ├── PlayerImage
    │   │   ├── PlayerInfo
    │   │   └── TeamBadge
    │   ├── StatisticsSection
    │   │   ├── SeasonStatsCard
    │   │   └── TournamentStatsCard
    │   ├── FantasyPredictionCard
    │   │   ├── NextMatchInfo
    │   │   ├── ScoreBreakdown
    │   │   └── RecommendationBadge
    │   └── RecentFormSection
    │
    ├── TeamBuilderPage
    │   ├── FormationSelector
    │   ├── SoccerFieldWidget
    │   │   └── PlayerSlot (repeating)
    │   ├── BenchWidget
    │   │   └── BenchSlot (repeating)
    │   ├── BudgetIndicator
    │   └── PlayerSelectionSheet (Modal)
    │       ├── SearchBar
    │       ├── FilterChips
    │       ├── SortDropdown
    │       └── PlayerListView
    │           └── SelectablePlayerCard (repeating)
    │
    └── LeagueDetailsPage
        ├── LeagueHeader
        ├── MembersSection
        ├── MyTeamSection
        │   ├── SoccerFieldWidget
        │   └── ProjectedPointsCard
        └── StandingsTable
```

### Service Layer Components

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SERVICE LAYER ARCHITECTURE                            │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                              REPOSITORIES                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐            │
│  │ PlayersRepo     │  │ FixturesRepo    │  │ SeasonsRepo     │            │
│  │                 │  │                 │  │                 │            │
│  │ • searchPlayers │  │ • getFixtures   │  │ • getCurrentSzn │            │
│  │ • getPlayerById │  │ • getNextMatch  │  │ • getStages     │            │
│  │ • getLigaMxRstr │  │ • getRecentForm │  │ • getTournament │            │
│  │ • getTeamInfo   │  │ • getTmntStats  │  │                 │            │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘            │
│           │                    │                    │                      │
│           └────────────────────┼────────────────────┘                      │
│                                │                                           │
│                                ▼                                           │
│                    ┌─────────────────────┐                                 │
│                    │  SportMonksClient   │                                 │
│                    │                     │                                 │
│                    │  • HTTP requests    │                                 │
│                    │  • Auth handling    │                                 │
│                    │  • Error parsing    │                                 │
│                    └─────────────────────┘                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
                                │
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CACHE SERVICE                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         HIVE BOXES                                   │   │
│  │                                                                      │   │
│  │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐           │   │
│  │  │ players_cache │  │ fixtures_cache│  │ teams_cache   │           │   │
│  │  │               │  │               │  │               │           │   │
│  │  │ • recent      │  │ • by date     │  │ • team info   │           │   │
│  │  │ • search rslts│  │ • by team     │  │ • Liga MX     │           │   │
│  │  │ • Liga MX rstr│  │               │  │               │           │   │
│  │  └───────────────┘  └───────────────┘  └───────────────┘           │   │
│  │                                                                      │   │
│  │  ┌───────────────┐                                                  │   │
│  │  │ general_cache │                                                  │   │
│  │  │               │                                                  │   │
│  │  │ • seasons     │                                                  │   │
│  │  │ • user prefs  │                                                  │   │
│  │  │ • leagues     │                                                  │   │
│  │  └───────────────┘                                                  │   │
│  │                                                                      │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### Liga MX Roster Loading Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     LIGA MX ROSTER LOADING                                   │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌────────────────────┐
                    │ TeamBuilderPage    │
                    │ opens              │
                    └─────────┬──────────┘
                              │
                              ▼
                    ┌────────────────────┐
                    │ Check Hive Cache   │
                    │ for Liga MX Roster │
                    └─────────┬──────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
         Cache Hit      Cache Expired     Cache Miss
              │               │               │
              ▼               ▼               ▼
    ┌─────────────────┐  ┌─────────────────────────────────┐
    │ Return cached   │  │                                 │
    │ players         │  │  FETCH FROM API                 │
    └─────────────────┘  │                                 │
                         │  1. Load LigaMxTeamIds.csv      │
                         │     ┌─────────────────────┐     │
                         │     │ 18 Team IDs         │     │
                         │     │ (Toluca, America,   │     │
                         │     │  Chivas, etc.)      │     │
                         │     └─────────┬───────────┘     │
                         │               │                 │
                         │               ▼                 │
                         │  2. For each team:              │
                         │     GET /teams/{id}?include=    │
                         │         players                 │
                         │     ┌─────────────────────┐     │
                         │     │ Extract player IDs  │     │
                         │     │ from squad          │     │
                         │     └─────────┬───────────┘     │
                         │               │                 │
                         │               ▼                 │
                         │  3. For each player:            │
                         │     GET /players/{id}?include=  │
                         │         position;statistics     │
                         │     ┌─────────────────────┐     │
                         │     │ Parse player details│     │
                         │     │ Calculate credits   │     │
                         │     │ Calculate projected │     │
                         │     │ points              │     │
                         │     └─────────────────────┘     │
                         │                                 │
                         └─────────────┬───────────────────┘
                                       │
                                       ▼
                         ┌─────────────────────────────────┐
                         │  Save to Hive Cache             │
                         │  (6-hour expiry)                │
                         └─────────────┬───────────────────┘
                                       │
                                       ▼
                         ┌─────────────────────────────────┐
                         │  Display players in UI          │
                         │  (lazy loaded, 20 at a time)    │
                         └─────────────────────────────────┘
```

### Player Credit Calculation Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     PLAYER CREDIT CALCULATION                                │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌────────────────────┐
                    │ Player Statistics  │
                    │ from API           │
                    └─────────┬──────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────────────┐
        │              CALCULATE PROJECTED POINTS          │
        │                                                  │
        │  Goals scored      × 4.0 (FWD) / 5.0 (MID)      │
        │  Assists           × 3.0                        │
        │  Clean sheets      × 4.0 (GK/DEF) / 1.0 (MID)   │
        │  Minutes played    × 0.01                       │
        │  Rating bonus      × 5.0 (if > 7.0)             │
        │  Yellow cards      × -1.0                       │
        │  Red cards         × -3.0                       │
        │                                                  │
        │  = projectedPoints                               │
        └─────────────────────┬────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────────────┐
        │              DETERMINE PRICE TIER                │
        │                                                  │
        │  if projectedPoints >= 60  → Elite    (9-10c)   │
        │  if projectedPoints >= 45  → Premium  (7-8.9c)  │
        │  if projectedPoints >= 30  → Mid-tier (5-6.9c)  │
        │  if projectedPoints >= 15  → Budget   (4-4.9c)  │
        │  else                      → Bargain  (3-3.9c)  │
        │                                                  │
        └─────────────────────┬────────────────────────────┘
                              │
                              ▼
        ┌─────────────────────────────────────────────────┐
        │              APPLY POSITION ADJUSTMENT           │
        │                                                  │
        │  GK:  +0.5 credits                              │
        │  DEF: +0.3 credits                              │
        │  MID: +0.0 credits (base)                       │
        │  FWD: +0.8 credits (premium for goals)          │
        │                                                  │
        │  = Final credits value                           │
        └─────────────────────────────────────────────────┘
```

---

*Last Updated: January 2026*

