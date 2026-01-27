# Fantasy 11 - Low-Level Design (LLD) Document

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Architecture Patterns](#2-architecture-patterns)
3. [Component Design](#3-component-design)
4. [Data Models](#4-data-models)
5. [API Layer Design](#5-api-layer-design)
6. [Repository Layer Design](#6-repository-layer-design)
7. [Caching Strategy](#7-caching-strategy)
8. [Fantasy Points Prediction Algorithm](#8-fantasy-points-prediction-algorithm)
9. [State Management](#9-state-management)
10. [Error Handling](#10-error-handling)
11. [Sequence Diagrams](#11-sequence-diagrams)
12. [Database Schema](#12-database-schema)

---

## 1. System Overview

### 1.1 Purpose

Fantasy 11 is a fantasy sports mobile application that enables users to:
- Search and analyze football players
- View real-time match fixtures and statistics
- Get AI-powered fantasy points predictions
- Build fantasy teams and participate in contests

### 1.2 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              CLIENT LAYER                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Android   │  │     iOS     │  │     Web     │  │   Desktop   │     │
│  │    App      │  │     App     │  │     App     │  │    App      │     │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘     │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER APPLICATION                             │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                         PRESENTATION LAYER                          │  │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │   │  Pages   │  │ Widgets  │  │  Cubits  │  │  Routes  │          │  │
│  │   └──────────┘  └──────────┘  └──────────┘  └──────────┘          │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                    │                                      │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                          BUSINESS LOGIC LAYER                       │  │
│  │   ┌────────────────────┐  ┌────────────────────┐                   │  │
│  │   │ Fantasy Predictor  │  │   Data Processors  │                   │  │
│  │   └────────────────────┘  └────────────────────┘                   │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                    │                                      │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                          REPOSITORY LAYER                           │  │
│  │   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │  │
│  │   │   Players    │  │   Fixtures   │  │   Seasons    │            │  │
│  │   │  Repository  │  │  Repository  │  │  Repository  │            │  │
│  │   └──────────────┘  └──────────────┘  └──────────────┘            │  │
│  └────────────────────────────────────────────────────────────────────┘  │
│                                    │                                      │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                            DATA LAYER                               │  │
│  │   ┌──────────────────┐              ┌──────────────────┐           │  │
│  │   │  SportMonks      │              │   Cache Service  │           │  │
│  │   │  API Client      │              │   (Hive)         │           │  │
│  │   └──────────────────┘              └──────────────────┘           │  │
│  └────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          EXTERNAL SERVICES                                │
│   ┌──────────────────────────┐    ┌──────────────────────────┐          │
│   │     SportMonks API       │    │      Google AdMob        │          │
│   │   (Football Data)        │    │   (Advertisements)       │          │
│   └──────────────────────────┘    └──────────────────────────┘          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Architecture Patterns

### 2.1 Repository Pattern

The application implements the Repository Pattern to abstract data sources from the business logic.

```dart
// Abstract interface (implicit in Dart)
abstract class IPlayersRepository {
  Future<List<Player>> searchPlayers(String query);
  Future<Player?> getPlayerById(int id);
}

// Concrete implementation
class PlayersRepository implements IPlayersRepository {
  final SportMonksClient _client;
  final CacheService _cache;
  
  @override
  Future<List<Player>> searchPlayers(String query) async {
    // 1. Check cache first
    final cached = _cache.getPlayerSearchResults(query);
    if (cached != null) return cached.map(Player.fromJson).toList();
    
    // 2. Fetch from API
    final response = await _client.searchPlayers(query);
    
    // 3. Cache results
    await _cache.cachePlayerSearchResults(query, response.data);
    
    return response.data.map(Player.fromJson).toList();
  }
}
```

### 2.2 BLoC Pattern (Business Logic Component)

State management uses the BLoC pattern via `flutter_bloc`:

```dart
// State
abstract class LanguageState {}
class LanguageLoaded extends LanguageState {
  final Locale locale;
}

// Cubit (simplified BLoC)
class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('en'));
  
  Future<void> setLanguage(String code) async {
    emit(Locale(code));
  }
}
```

### 2.3 Dependency Injection

Dependencies are injected through constructors with optional parameters for testing:

```dart
class FixturesRepository {
  final SportMonksClient _client;
  
  FixturesRepository({SportMonksClient? client}) 
      : _client = client ?? SportMonksClient();
}
```

---

## 3. Component Design

### 3.1 Feature Module Structure

Each feature follows a consistent structure:

```
features/
└── player/
    ├── models/
    │   └── player_info.dart      # Data models
    └── ui/
        └── player_details_page.dart  # UI widgets
```

### 3.2 Key Components

#### 3.2.1 Player Details Page

**Responsibilities:**
- Display player information and statistics
- Show fantasy points prediction
- Display next match information
- Show tournament-specific and season statistics

**State Variables:**
```dart
class _PlayerDetailsPageState extends State<PlayerDetailsPage> {
  Player? _player;
  bool _isLoading = true;
  bool _isLoadingTeams = false;
  bool _isLoadingNextMatch = false;
  bool _isLoadingRecentForm = false;
  bool _isLoadingTournamentStats = false;
  MatchInfo? _nextMatch;
  OpponentInfo? _opponentInfo;
  RecentMatchStats? _recentMatchStats;
  RecentMatchStats? _tournamentStats;
  SeasonInfo? _currentSeason;
  String? _error;
}
```

**Lifecycle:**
```
initState()
    │
    ├─► _loadCurrentSeason()
    │       │
    │       └─► [on success] _loadTournamentStats()
    │
    ├─► _loadPlayerData() or _loadDemoPlayer()
    │       │
    │       ├─► _loadTeamDetails()
    │       ├─► _loadNextMatch()
    │       └─► _loadRecentForm()
    │
    └─► [renders UI with loaded data]
```

#### 3.2.2 Fantasy Points Predictor

**Purpose:** Calculate predicted fantasy points for a player

**Input:**
- `Player` object with statistics
- `RecentMatchStats` (optional) - last N matches data
- `OpponentInfo` (optional) - next opponent analysis
- `currentSeasonId` (optional) - for season-specific stats

**Output:**
- `FantasyPrediction` with total points, tier, factors, confidence

---

## 4. Data Models

### 4.1 Player Model

```dart
class Player {
  final int id;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? commonName;
  final String? imagePath;
  final DateTime? dateOfBirth;
  final int? jerseyNumber;
  final int? height;
  final int? weight;
  final Position? position;
  final Position? detailedPosition;
  final Nationality? nationality;
  final List<TeamAssociation> teams;
  final List<PlayerStatistics> statistics;
  final List<Trophy>? trophies;
  
  // Computed properties
  TeamAssociation? get currentTeam;
  PlayerStatistics? get latestStats;
  bool get isGoalkeeper;
  int? get age;
}
```

### 4.2 Player Statistics Model

```dart
class PlayerStatistics {
  final int id;
  final int? seasonId;
  final int? playerId;
  final int? teamId;
  final int? appearances;
  final int? lineups;
  final int? minutesPlayed;
  final int? goals;
  final int? assists;
  final int? yellowCards;
  final int? yellowRedCards;
  final int? redCards;
  final int? cleanSheets;
  final int? saves;
  final int? penaltiesScored;
  final int? penaltiesMissed;
  final int? penaltiesSaved;
  final double? rating;
  final String? seasonName;
  
  // Computed properties
  int? get goalContributions;
  double? get minutesPerGoal;
  String get formattedMinutes;
}
```

### 4.3 Season & Stage Models

```dart
/// Represents a stage/tournament within a season (e.g., Apertura, Clausura)
class StageInfo {
  final int id;
  final String name;
  final int seasonId;
  final bool isCurrent;
  final bool isFinished;
  final DateTime? startDate;
  final DateTime? endDate;
}

/// Represents a football season (full year)
class SeasonInfo {
  final int id;
  final String name;
  final int leagueId;
  final bool isCurrent;
  final bool isFinished;
  final DateTime? startDate;
  final DateTime? endDate;
  final StageInfo? currentStage;
  final List<StageInfo> stages;
}
```

### 4.4 Match Info Model

```dart
class MatchInfo {
  final int id;
  final String? name;
  final DateTime? startingAt;
  final int? homeTeamId;
  final int? awayTeamId;
  final String? homeTeamName;
  final String? awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int? homeScore;
  final int? awayScore;
  final String? status;
  final String? venueName;
  final String? leagueName;
  
  // Methods
  bool get isLive;
  bool get isFinished;
  bool get isUpcoming;
  String getTimeRemaining();
}
```

### 4.5 Recent Match Stats Model

```dart
class RecentMatchStats {
  final int matchesPlayed;
  final int goals;
  final int assists;
  final int minutesPlayed;
  final int cleanSheets;
  final int yellowCards;
  final int redCards;
  final int saves;
  final double? averageRating;
  
  // Computed properties
  double get goalsPerMatch;
  double get assistsPerMatch;
  double get contributionsPerMatch;
  double get minutesPerMatch;
  double get cleanSheetRate;
  double get cardsPerMatch;
}
```

### 4.6 Class Diagram

```
┌─────────────────────┐       ┌─────────────────────┐
│       Player        │       │    PlayerStatistics │
├─────────────────────┤       ├─────────────────────┤
│ - id: int           │       │ - seasonId: int?    │
│ - displayName       │ 1   * │ - appearances: int? │
│ - position          │◄──────│ - goals: int?       │
│ - nationality       │       │ - assists: int?     │
│ - teams: List       │       │ - rating: double?   │
│ - statistics: List  │       └─────────────────────┘
└─────────────────────┘
         │
         │ 1
         ▼ *
┌─────────────────────┐       ┌─────────────────────┐
│   TeamAssociation   │       │      SeasonInfo     │
├─────────────────────┤       ├─────────────────────┤
│ - teamId: int       │       │ - id: int           │
│ - teamName: String? │       │ - name: String      │
│ - position: String? │       │ - currentStage      │
│ - jerseyNumber: int?│       │ - stages: List      │
└─────────────────────┘       └─────────────────────┘
                                       │
                                       │ 1
                                       ▼ *
                              ┌─────────────────────┐
                              │      StageInfo      │
                              ├─────────────────────┤
                              │ - id: int           │
                              │ - name: String      │
                              │ - startDate         │
                              │ - endDate           │
                              └─────────────────────┘
```

---

## 5. API Layer Design

### 5.1 SportMonks Client

**Purpose:** HTTP client for SportMonks Football API v3

**Key Methods:**
```dart
class SportMonksClient {
  // Player endpoints
  Future<SportMonksResponse<List<Map>>> searchPlayers(String name, {...});
  Future<SportMonksResponse<Map>> getPlayerById(int playerId, {...});
  
  // Fixture endpoints
  Future<SportMonksResponse<List<Map>>> getFixturesByDate(DateTime date, {...});
  Future<SportMonksResponse<List<Map>>> getFixturesByTeam(int teamId, {...});
  Future<SportMonksResponse<List<Map>>> getLiveFixtures({...});
  
  // Team endpoints
  Future<SportMonksResponse<Map>> getTeamById(int teamId, {...});
  
  // Season endpoints
  Future<SportMonksResponse<List<Map>>> getSeasonsByLeague(int leagueId, {...});
}
```

### 5.2 Response Wrapper

```dart
class SportMonksResponse<T> {
  final T data;
  final Map<String, dynamic>? pagination;
  final Map<String, dynamic>? rateLimit;
  final String? timezone;
  
  bool get hasMore;
  int? get currentPage;
  int? get nextPage;
  int? get totalCount;
}
```

### 5.3 Error Handling

```dart
class SportMonksException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic response;
  
  // Status code meanings:
  // 401 - Invalid API token
  // 403 - Access forbidden (subscription issue)
  // 404 - Resource not found
  // 429 - Rate limit exceeded
  // 5xx - Server errors
}
```

---

## 6. Repository Layer Design

### 6.1 Players Repository

```dart
class PlayersRepository {
  final SportMonksClient _client;
  
  /// Search players by name
  /// Returns up to 25 matching players
  Future<List<Player>> searchPlayers(String query, {int? page});
  
  /// Get detailed player information
  /// Includes statistics, teams, trophies
  Future<Player?> getPlayerById(int playerId);
  
  /// Get recent players from cache
  List<Player> getRecentPlayers();
  
  /// Get a demo player for development
  Future<Player?> getDemoPlayer();
}
```

### 6.2 Fixtures Repository

```dart
class FixturesRepository {
  final SportMonksClient _client;
  
  /// Get fixtures for today
  Future<List<MatchInfo>> getTodayFixtures();
  
  /// Get fixtures for a specific date
  Future<List<MatchInfo>> getFixturesByDate(DateTime date);
  
  /// Get upcoming fixtures for next N days
  Future<List<MatchInfo>> getUpcomingFixtures({int days = 7});
  
  /// Get live fixtures
  Future<List<MatchInfo>> getLiveFixtures();
  
  /// Get next match for a team
  Future<MatchInfo?> getNextMatchForTeam(int teamId);
  
  /// Get player's recent match statistics
  Future<RecentMatchStats?> getPlayerRecentStats(int playerId, int teamId, {int matchCount = 5});
  
  /// Get player's tournament-specific statistics
  Future<RecentMatchStats?> getPlayerTournamentStats(int playerId, int teamId, {
    required DateTime startDate,
    DateTime? endDate,
  });
}
```

### 6.3 Seasons Repository

```dart
class SeasonsRepository {
  final SportMonksClient _client;
  static const int ligaMxLeagueId = 262;
  
  /// Get current Liga MX season with stage info
  Future<SeasonInfo?> getCurrentLigaMxSeason({bool forceRefresh = false});
  
  /// Get current stage/tournament (e.g., Clausura)
  Future<StageInfo?> getCurrentStage();
  
  /// Get season by ID
  Future<SeasonInfo?> getSeasonById(int seasonId);
  
  /// Clear cached season data
  void clearCache();
}
```

---

## 7. Caching Strategy

### 7.1 Cache Architecture

```
┌─────────────────────────────────────────────────┐
│                  CacheService                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌─────────────┐  ┌─────────────┐              │
│  │ players_box │  │ fixtures_box│              │
│  │ (Hive Box)  │  │ (Hive Box)  │              │
│  └─────────────┘  └─────────────┘              │
│                                                 │
│  ┌─────────────┐  ┌─────────────┐              │
│  │  teams_box  │  │ general_box │              │
│  │ (Hive Box)  │  │ (Hive Box)  │              │
│  └─────────────┘  └─────────────┘              │
│                                                 │
└─────────────────────────────────────────────────┘
```

### 7.2 Cache Keys

```dart
class CacheKeys {
  static const String recentPlayers = 'recent_players';
  static const String playerSearchResults = 'player_search_results';
  static const String fixtures = 'fixtures';
  static const String teams = 'teams';
  static const String leagues = 'leagues';
}
```

### 7.3 Cache Operations

| Operation | Description | TTL |
|-----------|-------------|-----|
| Recent Players | Last 10 viewed players | Indefinite |
| Search Results | Player search by query | Session |
| Fixtures | Fixtures by date | 15 minutes |
| Teams | Team details by ID | 1 hour |
| Seasons | Season/stage info | 6 hours |

### 7.4 Cache Flow

```
Request for Data
       │
       ▼
┌──────────────────┐
│  Check Cache     │
└──────────────────┘
       │
       ├─── Cache Hit ───► Return Cached Data
       │
       ▼ Cache Miss
┌──────────────────┐
│  Fetch from API  │
└──────────────────┘
       │
       ▼
┌──────────────────┐
│  Store in Cache  │
└──────────────────┘
       │
       ▼
   Return Data
```

---

## 8. Fantasy Points Prediction Algorithm

### 8.1 Algorithm Overview

The fantasy points prediction uses a weighted multi-factor analysis:

```
Total Score = Base Score 
            + Position Bonus 
            + Form Score 
            + Opponent Adjustment 
            + Home Advantage 
            + Statistics Bonus
```

### 8.2 Scoring Breakdown

#### Base Score (50 points)
Every player starts with 50 points as a baseline.

#### Position Bonus (0-10 points)
```dart
switch (position) {
  case 'Forward':  return 10.0;  // High scoring potential
  case 'Midfielder': return 8.0;  // Balanced contribution
  case 'Defender': return 5.0;   // Clean sheet potential
  case 'Goalkeeper': return 3.0; // Limited scoring
  default: return 0.0;
}
```

#### Form Score (-10 to +15 points)
Based on recent match performance:

```dart
double formScore = 0;

// Goals contribution (+2 per goal avg)
formScore += recentForm.goalsPerMatch * 2;

// Assists contribution (+1.5 per assist avg)
formScore += recentForm.assistsPerMatch * 1.5;

// Clean sheets for defenders/GK (+3 per clean sheet rate)
if (isDefensive) {
  formScore += recentForm.cleanSheetRate * 3;
}

// Cards penalty (-1 per card avg)
formScore -= recentForm.cardsPerMatch;

// Playing time bonus (max +2 for 90 min avg)
formScore += (recentForm.minutesPerMatch / 45).clamp(0, 2);

return formScore.clamp(-10, 15);
```

#### Opponent Analysis (-10 to +10 points)
```dart
double opponentScore = 0;

// Defensive weakness (more goals conceded = easier opponent)
if (opponentGoalsConcededPerGame > 1.5) {
  opponentScore += 5;  // Weak defense
} else if (opponentGoalsConcededPerGame < 0.8) {
  opponentScore -= 5;  // Strong defense
}

// League position factor
if (opponentPosition > 15) {
  opponentScore += 3;  // Bottom team
} else if (opponentPosition < 5) {
  opponentScore -= 3;  // Top team
}

return opponentScore.clamp(-10, 10);
```

#### Home Advantage (+3 points)
```dart
if (opponent.isHomeGame) return 3.0;
return 0.0;
```

#### Statistics Bonus (0-12 points)
Based on season statistics:
```dart
double statsBonus = 0;

// Goals (max 4 pts for 10+ goals)
statsBonus += (stats.goals ?? 0) * 0.4;

// Assists (max 3 pts for 10+ assists)
statsBonus += (stats.assists ?? 0) * 0.3;

// Clean sheets (max 3 pts for 10+ clean sheets)
statsBonus += (stats.cleanSheets ?? 0) * 0.3;

// Saves for goalkeepers
statsBonus += (stats.saves ?? 0) * 0.1;

return statsBonus.clamp(0, 12);
```

### 8.3 Prediction Tiers

```dart
String getTier(int totalPoints) {
  if (totalPoints >= 80) return 'Elite Pick';
  if (totalPoints >= 65) return 'Strong Pick';
  if (totalPoints >= 50) return 'Good Pick';
  if (totalPoints >= 35) return 'Risky Pick';
  return 'Avoid';
}

Color getTierColor(String tier) {
  switch (tier) {
    case 'Elite Pick': return Colors.amber;
    case 'Strong Pick': return Colors.green;
    case 'Good Pick': return Colors.blue;
    case 'Risky Pick': return Colors.orange;
    case 'Avoid': return Colors.red;
  }
}
```

### 8.4 Confidence Calculation

```dart
double calculateConfidence(RecentMatchStats? form, PlayerStatistics? stats) {
  double confidence = 0.5;  // Base 50%
  
  // More recent matches = higher confidence
  if (form != null && form.matchesPlayed >= 5) {
    confidence += 0.2;
  }
  
  // Season stats available
  if (stats != null && (stats.appearances ?? 0) > 10) {
    confidence += 0.15;
  }
  
  // Opponent data available
  if (opponentInfo != null) {
    confidence += 0.15;
  }
  
  return (confidence * 100).clamp(30, 95);
}
```

---

## 9. State Management

### 9.1 Language Cubit

```dart
class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('en'));
  
  static const supportedLocales = ['en', 'es', 'fr', 'pt', 'it', 'ar', 'tr', 'id', 'sw'];
  
  Future<void> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code') ?? 'en';
    emit(Locale(code));
  }
  
  Future<void> setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    emit(Locale(code));
  }
}
```

### 9.2 Widget-Level State

For complex pages, state is managed at the widget level using `StatefulWidget`:

```dart
class _PlayerDetailsPageState extends State<PlayerDetailsPage> {
  // Multiple loading states for parallel data fetching
  bool _isLoading = true;
  bool _isLoadingTeams = false;
  bool _isLoadingNextMatch = false;
  bool _isLoadingRecentForm = false;
  bool _isLoadingTournamentStats = false;
  
  // Data states
  Player? _player;
  MatchInfo? _nextMatch;
  RecentMatchStats? _recentMatchStats;
  RecentMatchStats? _tournamentStats;
  SeasonInfo? _currentSeason;
  
  // Error state
  String? _error;
}
```

---

## 10. Error Handling

### 10.1 API Error Handling

```dart
try {
  final response = await _client.searchPlayers(query);
  return response.data.map(Player.fromJson).toList();
} on SportMonksException catch (e) {
  if (e.statusCode == 429) {
    // Rate limited - use cached data
    return _getCachedPlayers(query) ?? [];
  }
  if (e.statusCode == 401) {
    // Invalid API key - throw to UI
    throw Exception('Invalid API configuration');
  }
  // Log and return empty
  debugPrint('API Error: $e');
  return [];
} catch (e) {
  // Unknown error - log and return empty
  debugPrint('Unexpected error: $e');
  return [];
}
```

### 10.2 Graceful Degradation

When API is unavailable, the app:
1. Returns cached data if available
2. Falls back to mock data for development
3. Shows appropriate error messages to users
4. Continues functioning with reduced features

```dart
Future<List<MatchInfo>> getFixturesByDate(DateTime date) async {
  if (!SportMonksConfig.isConfigured) {
    // API not configured - use mock data
    return _loadMockFixtures();
  }
  
  try {
    final response = await _client.getFixturesByDate(date);
    return response.data.map(MatchInfo.fromJson).toList();
  } catch (e) {
    // API failed - fall back to mock
    return _loadMockFixtures();
  }
}
```

---

## 11. Sequence Diagrams

### 11.1 Player Search Flow

```
┌──────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌───────────┐
│  UI  │    │  SearchPage │    │  Repository │    │   Client    │    │ SportMonks│
└──┬───┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘    └─────┬─────┘
   │               │                   │                  │                 │
   │ Type query    │                   │                  │                 │
   │──────────────►│                   │                  │                 │
   │               │                   │                  │                 │
   │               │ searchPlayers()   │                  │                 │
   │               │──────────────────►│                  │                 │
   │               │                   │                  │                 │
   │               │                   │ Check cache      │                 │
   │               │                   │────────┐         │                 │
   │               │                   │        │         │                 │
   │               │                   │◄───────┘         │                 │
   │               │                   │                  │                 │
   │               │                   │ Cache miss       │                 │
   │               │                   │ searchPlayers()  │                 │
   │               │                   │─────────────────►│                 │
   │               │                   │                  │                 │
   │               │                   │                  │ GET /players/   │
   │               │                   │                  │ search/{query}  │
   │               │                   │                  │────────────────►│
   │               │                   │                  │                 │
   │               │                   │                  │   JSON Response │
   │               │                   │                  │◄────────────────│
   │               │                   │                  │                 │
   │               │                   │   List<Map>      │                 │
   │               │                   │◄─────────────────│                 │
   │               │                   │                  │                 │
   │               │                   │ Cache results    │                 │
   │               │                   │────────┐         │                 │
   │               │                   │        │         │                 │
   │               │                   │◄───────┘         │                 │
   │               │                   │                  │                 │
   │               │  List<Player>     │                  │                 │
   │               │◄──────────────────│                  │                 │
   │               │                   │                  │                 │
   │ Display list  │                   │                  │                 │
   │◄──────────────│                   │                  │                 │
   │               │                   │                  │                 │
```

### 11.2 Player Details Loading Flow

```
┌──────┐    ┌───────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  UI  │    │PlayerDetails  │    │  Fixtures   │    │  Seasons    │    │  Players    │
│      │    │    Page       │    │  Repository │    │  Repository │    │  Repository │
└──┬───┘    └───────┬───────┘    └──────┬──────┘    └──────┬──────┘    └──────┬──────┘
   │                │                   │                  │                  │
   │ Open player    │                   │                  │                  │
   │───────────────►│                   │                  │                  │
   │                │                   │                  │                  │
   │                │ initState()       │                  │                  │
   │                │───────┐           │                  │                  │
   │                │       │           │                  │                  │
   │                │       │ _loadCurrentSeason()         │                  │
   │                │       │──────────────────────────────►                  │
   │                │       │           │                  │                  │
   │                │       │           │      SeasonInfo  │                  │
   │                │       │◄──────────────────────────────                  │
   │                │       │           │                  │                  │
   │                │       │ _loadTournamentStats()       │                  │
   │                │       │───────────►                  │                  │
   │                │       │           │                  │                  │
   │                │       │           │ RecentMatchStats │                  │
   │                │       │◄───────────                  │                  │
   │                │       │           │                  │                  │
   │                │       │ _loadNextMatch()             │                  │
   │                │       │───────────►                  │                  │
   │                │       │           │                  │                  │
   │                │       │           │ MatchInfo        │                  │
   │                │       │◄───────────                  │                  │
   │                │       │           │                  │                  │
   │                │       │ _loadRecentForm()            │                  │
   │                │       │───────────►                  │                  │
   │                │       │           │                  │                  │
   │                │       │           │ RecentMatchStats │                  │
   │                │       │◄───────────                  │                  │
   │                │◄──────┘           │                  │                  │
   │                │                   │                  │                  │
   │ Render UI      │                   │                  │                  │
   │◄───────────────│                   │                  │                  │
   │                │                   │                  │                  │
```

---

## 12. Database Schema

### 12.1 Hive Boxes (NoSQL)

```
┌─────────────────────────────────────────────────────────────┐
│                      players_cache                          │
├─────────────────────────────────────────────────────────────┤
│ Key                              │ Value (JSON String)      │
├──────────────────────────────────┼──────────────────────────┤
│ recent_players                   │ [Player, Player, ...]    │
│ player_search_results_{query}    │ [Player, Player, ...]    │
└──────────────────────────────────┴──────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      fixtures_cache                         │
├─────────────────────────────────────────────────────────────┤
│ Key                              │ Value (JSON String)      │
├──────────────────────────────────┼──────────────────────────┤
│ fixtures_{date}                  │ [MatchInfo, ...]         │
└──────────────────────────────────┴──────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                       teams_cache                           │
├─────────────────────────────────────────────────────────────┤
│ Key                              │ Value (JSON String)      │
├──────────────────────────────────┼──────────────────────────┤
│ teams_{teamId}                   │ Team JSON                │
└──────────────────────────────────┴──────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      general_cache                          │
├─────────────────────────────────────────────────────────────┤
│ Key                              │ Value (String)           │
├──────────────────────────────────┼──────────────────────────┤
│ current_season                   │ SeasonInfo JSON          │
│ language_code                    │ 'en', 'es', etc.         │
└──────────────────────────────────┴──────────────────────────┘
```

---

## Appendix A: API Rate Limits

| Plan | Requests/min | Requests/day |
|------|--------------|--------------|
| Free | 180 | 3,000 |
| Standard | 600 | 50,000 |
| Premium | 3,000 | Unlimited |

## Appendix B: Supported Leagues

| League ID | Name | Country |
|-----------|------|---------|
| 262 | Liga MX | Mexico |
| 564 | Liga Expansión MX | Mexico |

## Appendix C: File Size Limits

| Asset Type | Max Size | Format |
|------------|----------|--------|
| Player Image | 200KB | PNG/JPEG |
| Team Logo | 50KB | PNG |
| Mock Data | 500KB | JSON |

---

*Document Version: 1.0*  
*Last Updated: January 2026*

