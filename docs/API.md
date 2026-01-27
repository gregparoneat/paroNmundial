# Fantasy 11 - API Documentation

## Table of Contents

1. [Overview](#overview)
2. [SportMonks API Integration](#sportmonks-api-integration)
3. [Internal Repository APIs](#internal-repository-apis)
4. [Data Models Reference](#data-models-reference)
5. [Error Handling](#error-handling)
6. [Rate Limiting](#rate-limiting)

---

## Overview

Fantasy 11 integrates with the SportMonks Football API v3 to fetch real-time football data including players, fixtures, teams, and statistics.

### Base Configuration

```dart
// lib/api/sportmonks_config.dart
class SportMonksConfig {
  static const String baseUrl = 'https://api.sportmonks.com/v3/football';
  static const String apiToken = 'YOUR_API_TOKEN';
  static const String timezone = 'America/Mexico_City';
}
```

---

## SportMonks API Integration

### Authentication

All requests include the API token as a query parameter:

```
GET /endpoint?api_token={YOUR_TOKEN}&timezone={TIMEZONE}
```

### Common Includes

Includes allow fetching related data in a single request:

```dart
// Fixture includes
static const List<String> fixtureIncludes = [
  'participants',      // Team details
  'venue',             // Stadium info
  'state',             // Match state (live, finished, etc.)
  'league',            // League info
  'scores',            // Match scores
  'events',            // Goals, cards, substitutions
  'lineups',           // Starting XI and substitutes
  'coaches',           // Team managers
];

// Player includes
static const List<String> playerIncludes = [
  'nationality',       // Player's country
  'position',          // Playing position
  'detailedposition',  // Detailed position (CAM, CDM, etc.)
  'teams.team',        // Current and past teams
  'statistics.details', // Season statistics
  'statistics.season', // Season info
  'trophies',          // Player trophies
  'transfers',         // Transfer history
];
```

---

## Endpoint Reference

### Players

#### Search Players

Search for players by name.

```
GET /players/search/{name}
```

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| name | string | Yes | Player name to search |
| include | string | No | Related data to include |
| per_page | int | No | Results per page (max 50) |
| page | int | No | Page number |

**Example Request:**

```dart
final response = await client.searchPlayers(
  'Paulinho',
  includes: ['nationality', 'position', 'teams.team', 'statistics'],
  perPage: 25,
);
```

**Example Response:**

```json
{
  "data": [
    {
      "id": 1234567,
      "sport_id": 1,
      "country_id": 462,
      "nationality_id": 462,
      "city_id": null,
      "position_id": 27,
      "detailed_position_id": 154,
      "common_name": "Paulinho",
      "firstname": "José Paulo",
      "lastname": "Bezzera Maciel Júnior",
      "name": "José Paulo Bezzera Maciel Júnior",
      "display_name": "Paulinho",
      "image_path": "https://cdn.sportmonks.com/images/...",
      "height": 181,
      "weight": 75,
      "date_of_birth": "1988-07-25",
      "gender": "male",
      "nationality": {
        "id": 462,
        "name": "Brazil",
        "image_path": "..."
      },
      "position": {
        "id": 27,
        "name": "Attacker",
        "developer_name": "ATTACKER"
      },
      "teams": [
        {
          "id": 99,
          "team_id": 15522,
          "player_id": 1234567,
          "position_id": 27,
          "jersey_number": 10,
          "start": "2024-01-01",
          "end": null,
          "team": {
            "id": 15522,
            "name": "Toluca FC",
            "image_path": "..."
          }
        }
      ],
      "statistics": [...]
    }
  ],
  "pagination": {
    "count": 25,
    "per_page": 25,
    "current_page": 1,
    "next_page": null,
    "has_more": false
  }
}
```

---

#### Get Player by ID

Fetch detailed player information.

```
GET /players/{id}
```

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| id | int | Yes | Player ID |
| include | string | No | Related data to include |

**Example Request:**

```dart
final response = await client.getPlayerById(
  1234567,
  includes: SportMonksConfig.playerIncludes,
);
```

---

### Fixtures

#### Get Fixtures by Date

Fetch all fixtures for a specific date.

```
GET /fixtures/date/{date}
```

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| date | string | Yes | Date in YYYY-MM-DD format |
| include | string | No | Related data to include |

**Example Request:**

```dart
final response = await client.getFixturesByDate(
  DateTime.now(),
  includes: SportMonksConfig.fixtureIncludes,
);
```

**Example Response:**

```json
{
  "data": [
    {
      "id": 19150123,
      "sport_id": 1,
      "league_id": 262,
      "season_id": 23744,
      "stage_id": 77471483,
      "name": "Toluca vs Cruz Azul",
      "starting_at": "2026-01-27T20:00:00.000000Z",
      "starting_at_timestamp": 1738008000,
      "result_info": null,
      "leg": "1/1",
      "venue_id": 8912,
      "participants": [
        {
          "id": 15522,
          "sport_id": 1,
          "name": "Toluca FC",
          "image_path": "...",
          "meta": {
            "location": "home",
            "winner": null
          }
        },
        {
          "id": 2649,
          "sport_id": 1,
          "name": "Cruz Azul",
          "image_path": "...",
          "meta": {
            "location": "away",
            "winner": null
          }
        }
      ],
      "scores": [],
      "state": {
        "id": 1,
        "state": "NS",
        "name": "Not Started"
      },
      "venue": {
        "id": 8912,
        "name": "Estadio Nemesio Díez",
        "city_name": "Toluca"
      }
    }
  ]
}
```

---

#### Get Fixtures Between Dates for Team

Fetch fixtures for a specific team within a date range.

```
GET /fixtures/between/{startDate}/{endDate}/{teamId}
```

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| startDate | string | Yes | Start date (YYYY-MM-DD) |
| endDate | string | Yes | End date (YYYY-MM-DD) |
| teamId | int | Yes | Team ID |
| include | string | No | Related data to include |

**Example Request:**

```dart
final response = await client.getFixturesByTeam(
  teamId,
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 7)),
  includes: ['participants', 'state', 'venue'],
);
```

---

#### Get Live Fixtures

Fetch currently live matches.

```
GET /livescores/inplay
```

**Example Request:**

```dart
final response = await client.getLiveFixtures(
  includes: SportMonksConfig.fixtureIncludes,
);
```

---

### Teams

#### Get Team by ID

Fetch detailed team information.

```
GET /teams/{id}
```

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| id | int | Yes | Team ID |
| include | string | No | Related data to include |

**Example Request:**

```dart
final response = await client.getTeamById(
  15522,
  includes: ['players', 'coaches', 'venue', 'league'],
);
```

**Example Response:**

```json
{
  "data": {
    "id": 15522,
    "sport_id": 1,
    "country_id": 402,
    "venue_id": 8912,
    "name": "Toluca FC",
    "short_code": "TOL",
    "image_path": "https://cdn.sportmonks.com/images/...",
    "founded": 1917,
    "type": "domestic",
    "venue": {
      "id": 8912,
      "name": "Estadio Nemesio Díez",
      "city_name": "Toluca",
      "capacity": 27000
    }
  }
}
```

---

### Seasons

#### Get Seasons by League

Fetch all seasons for a league.

```
GET /seasons
```

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| filters[league_id] | int | Yes | League ID |
| include | string | No | Related data (currentStage, stages) |

**Example Request:**

```dart
final response = await client.getSeasonsByLeague(
  262, // Liga MX
  includes: ['currentStage', 'stages'],
);
```

**Example Response:**

```json
{
  "data": [
    {
      "id": 23744,
      "sport_id": 1,
      "league_id": 262,
      "tie_breaker_rule_id": null,
      "name": "2025/2026",
      "finished": false,
      "pending": false,
      "is_current": true,
      "starting_at": "2025-07-01",
      "ending_at": "2026-05-30",
      "currentstage": {
        "id": 77471483,
        "sport_id": 1,
        "league_id": 262,
        "season_id": 23744,
        "name": "Clausura",
        "finished": false,
        "is_current": true,
        "starting_at": "2026-01-10",
        "ending_at": "2026-05-30"
      },
      "stages": [
        {
          "id": 77471482,
          "name": "Apertura",
          "finished": true,
          "is_current": false
        },
        {
          "id": 77471483,
          "name": "Clausura",
          "finished": false,
          "is_current": true
        }
      ]
    }
  ]
}
```

---

#### Get Season by ID

Fetch specific season details.

```
GET /seasons/{id}
```

**Parameters:**

| Name | Type | Required | Description |
|------|------|----------|-------------|
| id | int | Yes | Season ID |
| include | string | No | Related data to include |

---

## Internal Repository APIs

### PlayersRepository

```dart
class PlayersRepository {
  /// Search players by name
  /// @param query - Search term (min 2 characters)
  /// @param page - Page number for pagination
  /// @returns List of matching players
  Future<List<Player>> searchPlayers(String query, {int? page});
  
  /// Get player by ID with full details
  /// @param playerId - SportMonks player ID
  /// @returns Player object or null if not found
  Future<Player?> getPlayerById(int playerId);
  
  /// Get recently viewed players from cache
  /// @returns List of up to 10 recent players
  List<Player> getRecentPlayers();
  
  /// Add player to recent history
  /// @param player - Player to add
  Future<void> addToRecentPlayers(Player player);
  
  /// Get demo player for development
  /// @returns Mock player data
  Future<Player?> getDemoPlayer();
}
```

### FixturesRepository

```dart
class FixturesRepository {
  /// Get fixtures for today
  /// Falls back to upcoming if none today
  Future<List<MatchInfo>> getTodayFixtures();
  
  /// Get fixtures for a specific date
  /// @param date - Target date
  Future<List<MatchInfo>> getFixturesByDate(DateTime date);
  
  /// Get upcoming fixtures
  /// @param days - Number of days ahead (default 7)
  Future<List<MatchInfo>> getUpcomingFixtures({int days = 7});
  
  /// Get live fixtures
  Future<List<MatchInfo>> getLiveFixtures();
  
  /// Get next match for a team
  /// @param teamId - Team ID
  /// @returns Next upcoming fixture or null
  Future<MatchInfo?> getNextMatchForTeam(int teamId);
  
  /// Get player's recent match statistics
  /// @param playerId - Player ID
  /// @param teamId - Team ID
  /// @param matchCount - Number of recent matches (default 5)
  Future<RecentMatchStats?> getPlayerRecentStats(
    int playerId, 
    int teamId, 
    {int matchCount = 5}
  );
  
  /// Get player's tournament-specific statistics
  /// @param playerId - Player ID
  /// @param teamId - Team ID
  /// @param startDate - Tournament start date
  /// @param endDate - Tournament end date (default: now)
  Future<RecentMatchStats?> getPlayerTournamentStats(
    int playerId, 
    int teamId, 
    {required DateTime startDate, DateTime? endDate}
  );
}
```

### SeasonsRepository

```dart
class SeasonsRepository {
  /// Liga MX League ID
  static const int ligaMxLeagueId = 262;
  
  /// Get current Liga MX season with stage info
  /// @param forceRefresh - Bypass cache if true
  /// @returns Current season info or null
  Future<SeasonInfo?> getCurrentLigaMxSeason({bool forceRefresh = false});
  
  /// Get current stage/tournament (e.g., Clausura)
  Future<StageInfo?> getCurrentStage();
  
  /// Get current stage ID
  Future<int?> getCurrentStageId();
  
  /// Get current stage name
  Future<String?> getCurrentStageName();
  
  /// Get season by ID
  /// @param seasonId - Season ID
  Future<SeasonInfo?> getSeasonById(int seasonId);
  
  /// Get current season ID
  Future<int?> getCurrentSeasonId();
  
  /// Clear cached season data
  void clearCache();
}
```

---

## Data Models Reference

### Player

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
  
  // Getters
  String get fullName;
  TeamAssociation? get currentTeam;
  PlayerStatistics? get latestStats;
  bool get isGoalkeeper;
  bool get isDefender;
  bool get isMidfielder;
  bool get isForward;
  int? get age;
  bool get hasRealImage;
  
  // Methods
  PlayerStatistics? getStatsForSeason(int seasonId);
  PlayerStatistics? getStatsForCurrentSeason(int? currentSeasonId);
  
  factory Player.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### PlayerStatistics

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
  
  // Getters
  int? get goalContributions;
  double? get minutesPerGoal;
  String get formattedMinutes;
  
  factory PlayerStatistics.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### MatchInfo

```dart
class MatchInfo {
  final int id;
  final String? name;
  final DateTime? startingAt;
  final int? startingAtTimestamp;
  final int? homeTeamId;
  final int? awayTeamId;
  final String? homeTeamName;
  final String? awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int? homeScore;
  final int? awayScore;
  final String? status;
  final int? stateId;
  final String? venueName;
  final String? venueCity;
  final String? leagueName;
  final int? leagueId;
  final int? seasonId;
  final int? stageId;
  
  // Getters
  bool get isLive;
  bool get isFinished;
  bool get isUpcoming;
  String get scoreDisplay;
  
  // Methods
  String getTimeRemaining();
  
  factory MatchInfo.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### SeasonInfo & StageInfo

```dart
class StageInfo {
  final int id;
  final String name;
  final int seasonId;
  final bool isCurrent;
  final bool isFinished;
  final DateTime? startDate;
  final DateTime? endDate;
  
  bool get isActive;
  
  factory StageInfo.fromJson(Map<String, dynamic> json);
}

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
  
  bool get isActive;
  
  factory SeasonInfo.fromJson(Map<String, dynamic> json);
}
```

### RecentMatchStats

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
  
  // Computed stats
  double get goalsPerMatch;
  double get assistsPerMatch;
  double get contributionsPerMatch;
  double get minutesPerMatch;
  double get cleanSheetRate;
  double get cardsPerMatch;
}
```

### OpponentInfo

```dart
class OpponentInfo {
  final String name;
  final String? logoUrl;
  final int? leaguePosition;
  final int? gamesPlayed;
  final int? goalsScored;
  final int? goalsConceded;
  final int? cleanSheets;
  final int? wins;
  final int? draws;
  final int? losses;
  final bool isHomeGame;
  final DateTime? matchDateTime;
  final String? venueName;
  
  // Computed stats
  double get goalsConcededPerGame;
  double get cleanSheetRate;
  double get winRate;
  String get difficultyRating;
  int get difficultyColorValue;
  String get formattedMatchTime;
  String get timeRemaining;
}
```

### FantasyPrediction

```dart
class FantasyPrediction {
  final int totalPoints;
  final String tier;
  final int tierColorValue;
  final double confidence;
  final String confidenceDescription;
  final double? recentFormScore;
  final String formDescription;
  final int formColorValue;
  final List<PredictionFactor> factors;
  final List<PredictionFactor> topFactors;
}

class PredictionFactor {
  final String key;
  final double value;
}
```

---

## Error Handling

### SportMonks Exception

```dart
class SportMonksException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic response;
}
```

### HTTP Status Codes

| Code | Meaning | Handling |
|------|---------|----------|
| 200 | Success | Parse response |
| 401 | Invalid API token | Show config error |
| 403 | Forbidden | Check subscription |
| 404 | Not found | Return null |
| 429 | Rate limited | Use cache/retry |
| 5xx | Server error | Retry with backoff |

### Error Handling Example

```dart
try {
  final response = await client.getPlayerById(id);
  return Player.fromJson(response.data);
} on SportMonksException catch (e) {
  switch (e.statusCode) {
    case 401:
      throw ConfigurationException('Invalid API key');
    case 429:
      // Rate limited - return cached data
      return _getCachedPlayer(id);
    case 404:
      return null;
    default:
      debugPrint('API Error: ${e.message}');
      return _getMockPlayer(id);
  }
}
```

---

## Rate Limiting

### Limits by Plan

| Plan | Requests/Minute | Requests/Day |
|------|-----------------|--------------|
| Free Tier | 180 | 3,000 |
| Standard | 600 | 50,000 |
| Premium | 3,000 | Unlimited |

### Rate Limit Headers

```
X-RateLimit-Limit: 180
X-RateLimit-Remaining: 175
X-RateLimit-Reset: 1738008000
```

### Handling Rate Limits

```dart
if (response.statusCode == 429) {
  final resetTime = response.headers['X-RateLimit-Reset'];
  final waitTime = _calculateWaitTime(resetTime);
  
  // Option 1: Wait and retry
  await Future.delayed(Duration(seconds: waitTime));
  return _retryRequest();
  
  // Option 2: Return cached data
  return _getCachedData();
  
  // Option 3: Return mock data
  return _getMockData();
}
```

### Caching Strategy to Reduce API Calls

1. **Player Search Results**: Cache for session duration
2. **Player Details**: Cache for 30 minutes
3. **Fixtures**: Cache for 15 minutes (longer for past fixtures)
4. **Seasons**: Cache for 6 hours
5. **Team Details**: Cache for 1 hour

---

## Best Practices

### 1. Use Includes Wisely

Only request data you need:

```dart
// Bad - fetches everything
includes: ['*']

// Good - fetches only needed data
includes: ['nationality', 'position', 'statistics']
```

### 2. Implement Pagination

```dart
Future<List<Player>> getAllPlayers(String query) async {
  final players = <Player>[];
  int page = 1;
  bool hasMore = true;
  
  while (hasMore) {
    final response = await searchPlayers(query, page: page);
    players.addAll(response);
    hasMore = response.pagination?.hasMore ?? false;
    page++;
  }
  
  return players;
}
```

### 3. Cache Aggressively

```dart
Future<Player?> getPlayer(int id) async {
  // 1. Check memory cache
  if (_memoryCache.containsKey(id)) {
    return _memoryCache[id];
  }
  
  // 2. Check persistent cache
  final cached = await _persistentCache.get('player_$id');
  if (cached != null && !_isExpired(cached)) {
    return Player.fromJson(cached);
  }
  
  // 3. Fetch from API
  final player = await _fetchFromApi(id);
  
  // 4. Update caches
  _memoryCache[id] = player;
  await _persistentCache.set('player_$id', player.toJson());
  
  return player;
}
```

### 4. Handle Errors Gracefully

```dart
Future<List<MatchInfo>> getFixtures() async {
  try {
    return await _fetchFromApi();
  } on SportMonksException catch (e) {
    debugPrint('API Error: $e');
    return await _loadMockData();
  } on SocketException {
    debugPrint('Network error');
    return await _loadCachedData();
  }
}
```

---

*Document Version: 1.0*  
*Last Updated: January 2026*

