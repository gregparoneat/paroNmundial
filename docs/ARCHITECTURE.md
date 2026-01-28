# Fantasy 11 - Architecture & Low-Level Design (LLD)

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Diagrams](#architecture-diagrams)
3. [Component Details](#component-details)
4. [Data Flow Diagrams](#data-flow-diagrams)
5. [Database Schema](#database-schema)
6. [API Integration](#api-integration)
7. [Caching Strategy](#caching-strategy)
8. [Fantasy League System](#fantasy-league-system)
9. [Security Considerations](#security-considerations)

---

## System Overview

Fantasy 11 is a fantasy sports application built with Flutter, following a **Clean Architecture** pattern with **Repository Pattern** for data management. The app integrates with SportMonks API for real-time football data and uses Hive for local persistence.

### Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter 3.32.5+ / Dart 3.8.1+ |
| State Management | flutter_bloc (Cubits) |
| Local Storage | Hive (NoSQL) |
| API Client | http package |
| Image Caching | cached_network_image |
| Localization | flutter_intl |

---

## Architecture Diagrams

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FANTASY 11 APP                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         PRESENTATION LAYER                           │   │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────────────┐   │   │
│  │  │  Player   │ │  League   │ │  Team     │ │  Fantasy Points   │   │   │
│  │  │  Search   │ │  Details  │ │  Builder  │ │  Prediction       │   │   │
│  │  └───────────┘ └───────────┘ └───────────┘ └───────────────────┘   │   │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────────────┐   │   │
│  │  │  Player   │ │  Fixtures │ │  Wallet   │ │  Authentication   │   │   │
│  │  │  Profile  │ │  List     │ │  Screen   │ │  Screens          │   │   │
│  │  └───────────┘ └───────────┘ └───────────┘ └───────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                        BUSINESS LOGIC LAYER                          │   │
│  │  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────┐   │   │
│  │  │ FantasyPoints   │ │ LeagueCubit     │ │ AuthenticationCubit │   │   │
│  │  │ Predictor       │ │                 │ │                     │   │   │
│  │  └─────────────────┘ └─────────────────┘ └─────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                         REPOSITORY LAYER                             │   │
│  │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌────────────┐ │   │
│  │  │ Players      │ │ Fixtures     │ │ Seasons      │ │ League     │ │   │
│  │  │ Repository   │ │ Repository   │ │ Repository   │ │ Repository │ │   │
│  │  └──────────────┘ └──────────────┘ └──────────────┘ └────────────┘ │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                          │                    │                             │
│              ┌───────────┴───────────┐       │                             │
│              ▼                       ▼       ▼                             │
│  ┌─────────────────────┐ ┌─────────────────────────┐                       │
│  │   SportMonks API    │ │    Hive Cache Service   │                       │
│  │   Client            │ │    (Local Storage)      │                       │
│  └─────────────────────┘ └─────────────────────────┘                       │
│              │                                                              │
└──────────────┼──────────────────────────────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           EXTERNAL SERVICES                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      SportMonks Football API                         │   │
│  │  • Players Data      • Team Squads        • Live Scores             │   │
│  │  • Fixtures          • Statistics         • Standings               │   │
│  │  • Seasons           • Leagues            • Venues                  │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Module Dependency Graph

```
                    ┌─────────────┐
                    │    main     │
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │   routes    │ │  services   │ │  app_config │
    └──────┬──────┘ └──────┬──────┘ └─────────────┘
           │               │
           ▼               ▼
    ┌─────────────────────────────────────────────┐
    │                  features                    │
    │  ┌─────────┐ ┌─────────┐ ┌─────────┐       │
    │  │ player  │ │ league  │ │ fantasy │ ...   │
    │  └────┬────┘ └────┬────┘ └────┬────┘       │
    └───────┼───────────┼───────────┼────────────┘
            │           │           │
            └───────────┼───────────┘
                        ▼
              ┌─────────────────┐
              │       api       │
              │  ┌───────────┐  │
              │  │repositories│  │
              │  └─────┬─────┘  │
              │        ▼        │
              │ ┌─────────────┐ │
              │ │sportmonks   │ │
              │ │client       │ │
              │ └─────────────┘ │
              └─────────────────┘
```

---

## Component Details

### 1. API Layer (`lib/api/`)

#### SportMonksClient (`sportmonks_client.dart`)

Handles all HTTP communication with SportMonks API.

```dart
class SportMonksClient {
  // Base configuration
  static const String baseUrl = 'https://api.sportmonks.com/v3/football';
  
  // Core methods
  Future<ApiResponse> searchPlayers(String query, {List<String> includes});
  Future<ApiResponse> getPlayerById(int id, {List<String> includes});
  Future<ApiResponse> getTeamById(int id, {List<String> includes});
  Future<ApiResponse> getFixturesByDateRange(String start, String end, int teamId);
  Future<ApiResponse> getSeasonById(int id, {List<String> includes});
}
```

#### Repositories

| Repository | Responsibility |
|------------|----------------|
| `PlayersRepository` | Player search, details, Liga MX roster management |
| `FixturesRepository` | Match fixtures, recent form, tournament stats |
| `SeasonsRepository` | Season data, current stage identification |
| `LeagueRepository` | Fantasy league CRUD operations |

### 2. Feature Modules (`lib/features/`)

#### Player Module

```
features/player/
├── models/
│   └── player_info.dart      # Player, PlayerStatistics, PlayerTeamInfo
├── ui/
│   └── player_details_page.dart
└── widgets/
    └── player_card.dart
```

#### League Module (Fantasy Leagues)

```
features/league/
├── models/
│   └── league_models.dart    # League, FantasyTeam, FantasyTeamPlayer
├── ui/
│   ├── create_league_page.dart
│   ├── league_details_page.dart
│   ├── team_builder_page.dart
│   └── widgets/
│       ├── soccer_field_widget.dart
│       └── bench_widget.dart
└── cubit/
    └── league_cubit.dart
```

### 3. Services Layer (`lib/services/`)

#### CacheService (`cache_service.dart`)

Manages Hive-based local storage with automatic expiry.

```dart
class CacheService {
  // Hive boxes
  Box<String> _playersBox;
  Box<String> _fixturesBox;
  Box<String> _teamsBox;
  Box<String> _generalBox;
  
  // Liga MX roster caching (6-hour expiry)
  List<Map<String, dynamic>>? getLigaMxRoster();
  Future<void> saveLigaMxRoster(List<Map<String, dynamic>> players);
  Future<void> addToLigaMxRoster(List<Map<String, dynamic>> newPlayers);
  
  // Team caching
  List<Map<String, dynamic>>? getLigaMxTeams();
  Future<void> saveLigaMxTeams(List<Map<String, dynamic>> teams);
}
```

---

## Data Flow Diagrams

### Player Search Flow

```
┌──────────┐     ┌───────────────┐     ┌──────────────────┐
│   User   │────▶│ PlayersSearch │────▶│ PlayersRepository│
│  Input   │     │    Page       │     │                  │
└──────────┘     └───────────────┘     └────────┬─────────┘
                                                │
                        ┌───────────────────────┼───────────────────────┐
                        ▼                       ▼                       ▼
              ┌─────────────────┐     ┌─────────────────┐     ┌────────────────┐
              │ Check Hive     │     │ Search API      │     │ Parse & Cache  │
              │ Cache First    │     │ (debounced)     │     │ Results        │
              └────────┬────────┘     └────────┬────────┘     └────────────────┘
                       │                       │
                       ▼                       ▼
              ┌─────────────────────────────────────────┐
              │          Return Player Results          │
              │    (merged local cache + API results)   │
              └─────────────────────────────────────────┘
```

### Team Builder Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         TEAM BUILDER PAGE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. INITIAL LOAD                                                        │
│  ┌────────────┐     ┌─────────────────┐     ┌──────────────────┐       │
│  │ Check Hive │────▶│ Return Cached   │────▶│ Display Players  │       │
│  │ Cache      │     │ Players         │     │ on Field + List  │       │
│  └────────────┘     └─────────────────┘     └──────────────────┘       │
│        │                                                                │
│        │ (if cache empty)                                               │
│        ▼                                                                │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ Load from API (lazy loading, team by team, page by page)       │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  2. PLAYER SELECTION                                                    │
│  ┌────────────┐     ┌─────────────────┐     ┌──────────────────┐       │
│  │ Tap Empty  │────▶│ Show Player     │────▶│ Filter by        │       │
│  │ Slot       │     │ Selection Sheet │     │ Position/Team    │       │
│  └────────────┘     └─────────────────┘     └──────────────────┘       │
│                             │                                           │
│                             ▼                                           │
│                     ┌─────────────────┐                                 │
│                     │ API Search      │ (if query >= 2 chars)          │
│                     │ (debounced)     │                                 │
│                     └─────────────────┘                                 │
│                                                                         │
│  3. SQUAD VALIDATION                                                    │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │ • Max 15 players (11 starters + 4 subs)                        │    │
│  │ • Max 2 GK, 5 DEF, 5 MID, 3 FWD                                │    │
│  │ • Max 4 players from same team                                 │    │
│  │ • Budget constraint (100 credits default)                      │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Fantasy Points Prediction Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FANTASY POINTS PREDICTOR                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  INPUT DATA                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │ Player Stats │  │ Recent Form  │  │ Next Match   │                  │
│  │ (Season)     │  │ (Last 5)     │  │ (Opponent)   │                  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘                  │
│         │                 │                 │                           │
│         └─────────────────┼─────────────────┘                           │
│                           ▼                                             │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    CALCULATION ENGINE                            │   │
│  │                                                                  │   │
│  │  Base Score (50) ─────────────────────────────────────┐         │   │
│  │                                                        │         │   │
│  │  + Position Bonus (0-10) ─────────────────────────────┤         │   │
│  │    • GK: +5 if clean sheets                           │         │   │
│  │    • DEF: +5 if clean sheets                          │         │   │
│  │    • MID: +3 base                                     │         │   │
│  │    • FWD: +7 if goals > 0.3/match                     │         │   │
│  │                                                        │         │   │
│  │  + Form Score (-10 to +15) ───────────────────────────┤         │   │
│  │    • Goals: +5 each                                   │         │   │
│  │    • Assists: +3 each                                 │         │   │
│  │    • Clean sheets: +4 each                            │         │   │
│  │    • Yellow cards: -1 each                            │         │   │
│  │    • Red cards: -3 each                               │         │   │
│  │                                                        │         │   │
│  │  + Opponent Analysis (-10 to +10) ────────────────────┤         │   │
│  │    • Goals conceded analysis                          │         │   │
│  │    • Form of opponent                                 │         │   │
│  │                                                        │         │   │
│  │  + Home Advantage (+3 if home) ───────────────────────┤         │   │
│  │                                                        │         │   │
│  │  + Captain Bonus (2x) / Vice-Captain (1.5x) ──────────┘         │   │
│  │                                                                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                           │                                             │
│                           ▼                                             │
│  OUTPUT: Predicted Points + Confidence Level + Recommendation Tier     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Database Schema

### Hive Box Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          HIVE LOCAL STORAGE                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  BOX: players_cache                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Key                          │ Value Type                       │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │ recent_players               │ JSON Array of Player objects     │   │
│  │ player_search_results_{q}    │ JSON Array of search results     │   │
│  │ liga_mx_roster               │ JSON Array of RosterPlayer       │   │
│  │ liga_mx_roster_timestamp     │ ISO8601 DateTime string          │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  BOX: teams_cache                                                       │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Key                          │ Value Type                       │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │ teams_{teamId}               │ JSON Object of team details      │   │
│  │ liga_mx_teams                │ JSON Array of LigaMxTeam         │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  BOX: fixtures_cache                                                    │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Key                          │ Value Type                       │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │ fixtures_{date}              │ JSON Array of fixtures           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  BOX: general_cache                                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ Key                          │ Value Type                       │   │
│  ├─────────────────────────────────────────────────────────────────┤   │
│  │ current_season               │ JSON Object of season info       │   │
│  │ user_leagues                 │ JSON Array of user's leagues     │   │
│  │ user_teams                   │ JSON Array of user's teams       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Data Models

```dart
// Player Statistics
class PlayerStatistics {
  int id;
  int? seasonId;
  int? playerId;
  int? teamId;
  int? appearances;     // type_id: 321
  int? lineups;         // type_id: 322
  int? minutesPlayed;   // type_id: 119
  int? goals;           // type_id: 52
  int? assists;         // type_id: 79
  int? yellowCards;     // type_id: 84
  int? redCards;        // type_id: 83
  int? cleanSheets;     // type_id: 194
  double? rating;
}

// Fantasy Team Player
class FantasyTeamPlayer {
  int playerId;
  String playerName;
  String? playerImageUrl;
  PlayerPosition position;
  String? teamName;
  double credits;
  bool isCaptain;
  bool isViceCaptain;
}

// Roster Player (for team building)
class RosterPlayer {
  int id;
  String name;
  String displayName;
  String position;
  String positionCode;  // GK, DEF, MID, FWD
  int teamId;
  String teamName;
  double credits;
  double projectedPoints;
}
```

---

## API Integration

### SportMonks Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/players/search/{name}` | GET | Search players by name |
| `/players/{id}` | GET | Get player details |
| `/teams/{id}` | GET | Get team details with optional players |
| `/fixtures/between/{start}/{end}/{teamId}` | GET | Get fixtures for date range |
| `/seasons/{id}` | GET | Get season with stages |

### Request Includes Strategy

```dart
// Optimal includes for player details
static const List<String> playerIncludes = [
  'nationality',
  'position',
  'detailedposition',
  'teams.team',
  'statistics.details',
  'statistics.season',
  'trophies',
  'transfers',
];

// Optimal includes for team with players
static const List<String> teamWithPlayersIncludes = [
  'players',
];

// Optimal includes for player search
static const List<String> searchIncludes = [
  'position',
  'detailedPosition',
  'nationality',
  'teams',
  'statistics.details',
];
```

---

## Caching Strategy

### Cache Layers

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CACHING HIERARCHY                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  LAYER 1: In-Memory Cache (Fastest)                                     │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Static variables in Repository classes                        │   │
│  │ • Lives for app session only                                    │   │
│  │ • No serialization overhead                                     │   │
│  │ • Used for: frequently accessed data during session             │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                           │                                             │
│                           ▼                                             │
│  LAYER 2: Hive Persistent Cache (Fast)                                  │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • JSON serialized to Hive boxes                                 │   │
│  │ • Persists across app restarts                                  │   │
│  │ • 6-hour expiry for roster data                                 │   │
│  │ • Used for: player rosters, teams, search results               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                           │                                             │
│                           ▼                                             │
│  LAYER 3: SportMonks API (Network)                                      │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Fresh data from server                                        │   │
│  │ • Rate limited by subscription plan                             │   │
│  │ • Used for: real-time data, cache misses                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Cache Expiry Rules

| Data Type | Expiry | Reason |
|-----------|--------|--------|
| Liga MX Roster | 6 hours | Player transfers are infrequent |
| Liga MX Teams | 24 hours | Team data rarely changes |
| Player Search | 1 hour | Balance freshness vs API calls |
| Recent Players | Never | User preference |
| Fixtures | 30 minutes | Scores can change |

---

## Fantasy League System

### League Types

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         LEAGUE TYPES                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  PUBLIC LEAGUE                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Open for anyone to join                                       │   │
│  │ • Visible in league browser                                     │   │
│  │ • Auto-starts when max members reached                          │   │
│  │ • Standard scoring rules                                        │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
│  PRIVATE LEAGUE                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │ • Invite-only via unique code                                   │   │
│  │ • Hidden from public listings                                   │   │
│  │ • Manual start by admin                                         │   │
│  │ • Custom scoring rules (optional)                               │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Team Building Constraints

```dart
// Squad composition rules
const int kTotalSquadSize = 15;      // 11 starters + 4 subs
const int kStartingXI = 11;
const int kMaxGK = 2;
const int kMaxDEF = 5;
const int kMaxMID = 5;
const int kMaxFWD = 3;
const int kMaxPlayersPerTeam = 4;    // Max from same club
const double kDefaultBudget = 100.0; // Credits

// Formations supported
enum Formation {
  f442,  // 4-4-2
  f433,  // 4-3-3
  f352,  // 3-5-2
  f451,  // 4-5-1
  f343,  // 3-4-3
  f532,  // 5-3-2
}
```

### Scoring System

| Action | Points |
|--------|--------|
| Playing 60+ minutes | +2 |
| Goal (Forward) | +4 |
| Goal (Midfielder) | +5 |
| Goal (Defender) | +6 |
| Goal (Goalkeeper) | +8 |
| Assist | +3 |
| Clean Sheet (GK/DEF) | +4 |
| Clean Sheet (MID) | +1 |
| Penalty Save | +5 |
| Penalty Miss | -2 |
| Yellow Card | -1 |
| Red Card | -3 |
| Own Goal | -2 |
| Captain | 2x points |
| Vice-Captain | 1.5x points |

---

## Security Considerations

### API Key Protection

```dart
// DO NOT commit API keys to version control
// Use environment variables or secure storage

// Development: Use .env file (gitignored)
// Production: Use platform-specific secure storage
//   - Android: EncryptedSharedPreferences
//   - iOS: Keychain
```

### Data Validation

```dart
// All API responses are validated before use
// Type-safe parsing with null safety
int? _parseIntValue(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
```

### Network Security

- All API calls use HTTPS
- Certificate pinning recommended for production
- Request timeouts prevent hanging connections
- Error responses don't expose sensitive information

---

## Performance Optimizations

### Lazy Loading

```dart
// Players are loaded page by page, team by team
// Only load more when user scrolls near bottom
_scrollController.addListener(() {
  if (_scrollController.position.pixels >= 
      _scrollController.position.maxScrollExtent - 200) {
    _loadMorePlayers();
  }
});
```

### Image Caching

```dart
// Using cached_network_image for automatic caching
CachedNetworkImage(
  imageUrl: player.imagePath ?? '',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.person),
  memCacheHeight: 100,  // Resize in memory
  memCacheWidth: 100,
)
```

### Debounced Search

```dart
// API search is debounced to prevent excessive calls
Timer? _debounceTimer;

void _onSearchChanged(String query) {
  _debounceTimer?.cancel();
  if (query.length >= 2) {
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _searchPlayersFromApi(query);
    });
  }
}
```

---

## Testing Strategy

### Unit Tests

```dart
// Repository tests
test('should return cached players when available', () async {
  // Arrange
  when(cacheService.getLigaMxRoster()).thenReturn(mockPlayers);
  
  // Act
  final result = repository.getCachedPlayers();
  
  // Assert
  expect(result.length, equals(mockPlayers.length));
});
```

### Widget Tests

```dart
// UI component tests
testWidgets('TeamBuilderPage shows soccer field', (tester) async {
  await tester.pumpWidget(MaterialApp(home: TeamBuilderPage()));
  
  expect(find.byType(SoccerFieldWidget), findsOneWidget);
});
```

### Integration Tests

```dart
// End-to-end flow tests
testWidgets('User can build a complete team', (tester) async {
  // Navigate to team builder
  // Select 15 players
  // Verify budget constraints
  // Save team
  // Verify team saved correctly
});
```

---

## Future Enhancements

1. **Real-time Updates**: WebSocket integration for live match updates
2. **Push Notifications**: Match reminders, lineup announcements
3. **Social Features**: Friend system, head-to-head leagues
4. **Analytics Dashboard**: Detailed performance analysis
5. **Machine Learning**: Improved prediction using historical patterns
6. **Multi-League Support**: Expand beyond Liga MX

---

*Last Updated: January 2026*
