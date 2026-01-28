# Fantasy 11 - API Reference

## Table of Contents

1. [SportMonks API Overview](#sportmonks-api-overview)
2. [Authentication](#authentication)
3. [Endpoints Reference](#endpoints-reference)
4. [Data Models](#data-models)
5. [Error Handling](#error-handling)
6. [Rate Limiting](#rate-limiting)

---

## SportMonks API Overview

Fantasy 11 integrates with the [SportMonks Football API](https://www.sportmonks.com/) for real-time football data. The integration is specifically configured for **Liga MX** (Mexican Football League).

### Base Configuration

```dart
class SportMonksConfig {
  static const String baseUrl = 'https://api.sportmonks.com/v3/football';
  static const String apiToken = 'YOUR_API_TOKEN';
  static const String timezone = 'America/Mexico_City';
  
  // Liga MX specific IDs
  static const int ligaMxLeagueId = 262;
  static const int ligaMxCurrentSeasonId = 25539;
}
```

---

## Authentication

All API requests require an API token passed as a query parameter:

```
GET /players/{id}?api_token=YOUR_TOKEN&timezone=America/Mexico_City
```

### Headers

```http
Accept: application/json
Content-Type: application/json
```

---

## Endpoints Reference

### Player Endpoints

#### Search Players

```http
GET /players/search/{name}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| name | string | Yes | Player name to search |
| include | string | No | Related data to include |

**Recommended Includes:**
```
position;detailedPosition;nationality;teams;statistics.details
```

**Example Request:**
```
GET /players/search/Angel%20Correa?api_token=TOKEN&include=position;detailedPosition;nationality;teams;statistics.details
```

**Example Response:**
```json
{
  "data": [
    {
      "id": 123456,
      "name": "Ángel Correa",
      "display_name": "A. Correa",
      "common_name": "Correa",
      "firstname": "Ángel",
      "lastname": "Correa",
      "image_path": "https://cdn.sportmonks.com/images/players/123456.png",
      "height": 174,
      "weight": 72,
      "date_of_birth": "1995-03-09",
      "position": {
        "id": 25,
        "name": "Attacker",
        "code": "A"
      },
      "nationality": {
        "id": 32,
        "name": "Argentina",
        "image_path": "https://cdn.sportmonks.com/images/flags/ar.png"
      },
      "teams": [
        {
          "team_id": 15522,
          "jersey_number": 10,
          "start": "2023-01-01",
          "end": "2026-12-31",
          "team": {
            "id": 15522,
            "name": "Toluca",
            "image_path": "https://cdn.sportmonks.com/images/teams/15522.png"
          }
        }
      ],
      "statistics": [...]
    }
  ],
  "pagination": {
    "count": 1,
    "total": 1,
    "per_page": 25,
    "current_page": 1,
    "total_pages": 1
  }
}
```

---

#### Get Player by ID

```http
GET /players/{id}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Player ID |
| include | string | No | Related data to include |

**Full Includes for Player Profile:**
```
nationality;position;detailedposition;teams.team;statistics.details;statistics.season;trophies;transfers
```

**Example Response:**
```json
{
  "data": {
    "id": 123456,
    "name": "Paulinho",
    "display_name": "Paulinho",
    "statistics": [
      {
        "id": 98765,
        "season_id": 25539,
        "player_id": 123456,
        "team_id": 15522,
        "details": [
          { "type_id": 321, "value": { "total": 15 } },  // Appearances
          { "type_id": 322, "value": { "total": 14 } },  // Lineups
          { "type_id": 119, "value": { "total": 1245 } }, // Minutes
          { "type_id": 52, "value": { "total": 8 } },    // Goals
          { "type_id": 79, "value": { "total": 3 } },    // Assists
          { "type_id": 84, "value": { "total": 2 } },    // Yellow Cards
          { "type_id": 83, "value": { "total": 0 } }     // Red Cards
        ],
        "season": {
          "id": 25539,
          "name": "2025/2026"
        }
      }
    ]
  }
}
```

---

### Team Endpoints

#### Get Team by ID

```http
GET /teams/{id}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Team ID |
| include | string | No | Related data to include |

**Include for Squad:**
```
players
```

**Example Response:**
```json
{
  "data": {
    "id": 15522,
    "name": "Toluca",
    "short_code": "TOL",
    "image_path": "https://cdn.sportmonks.com/images/teams/15522.png",
    "players": [
      {
        "player_id": 123456,
        "position_id": 25,
        "jersey_number": 10,
        "start": "2023-01-01",
        "end": "2026-12-31"
      }
    ]
  }
}
```

---

### Fixture Endpoints

#### Get Fixtures by Date Range

```http
GET /fixtures/between/{startDate}/{endDate}/{teamId}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| startDate | string | Yes | Start date (YYYY-MM-DD) |
| endDate | string | Yes | End date (YYYY-MM-DD) |
| teamId | integer | Yes | Team ID |
| include | string | No | Related data to include |

**Includes for Match Details:**
```
participants;venue;state;league;scores;events;lineups;coaches
```

**Example Response:**
```json
{
  "data": [
    {
      "id": 987654,
      "starting_at": "2026-01-30T21:00:00.000000Z",
      "starting_at_timestamp": 1738270800,
      "venue_id": 123,
      "state_id": 1,
      "participants": [
        {
          "id": 15522,
          "name": "Toluca",
          "meta": { "location": "home" }
        },
        {
          "id": 15523,
          "name": "América",
          "meta": { "location": "away" }
        }
      ],
      "venue": {
        "id": 123,
        "name": "Estadio Nemesio Diez"
      },
      "scores": [
        { "participant_id": 15522, "score": { "goals": 2 } },
        { "participant_id": 15523, "score": { "goals": 1 } }
      ]
    }
  ]
}
```

---

### Season Endpoints

#### Get Season with Stages

```http
GET /seasons/{id}
```

**Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| id | integer | Yes | Season ID |
| include | string | No | Related data to include |

**Includes for Tournament Info:**
```
groups;currentStage;stages
```

**Example Response:**
```json
{
  "data": {
    "id": 25539,
    "name": "2025/2026",
    "league_id": 262,
    "is_current_season": true,
    "currentstage": {
      "id": 77858922,
      "name": "Clausura 2026",
      "type": "Group Stage",
      "start_date": "2026-01-10",
      "end_date": "2026-05-30"
    },
    "stages": [
      {
        "id": 77858921,
        "name": "Apertura 2025",
        "start_date": "2025-07-10",
        "end_date": "2025-12-15"
      },
      {
        "id": 77858922,
        "name": "Clausura 2026",
        "start_date": "2026-01-10",
        "end_date": "2026-05-30"
      }
    ]
  }
}
```

---

## Data Models

### Statistics Type IDs

| Type ID | Name | Description |
|---------|------|-------------|
| 321 | Appearances | Total matches appeared |
| 322 | Lineups | Matches started |
| 119 | Minutes Played | Total minutes on field |
| 52 | Goals | Goals scored |
| 79 | Assists | Assists made |
| 84 | Yellow Cards | Yellow cards received |
| 85 | Yellow-Red Cards | Second yellow leading to red |
| 83 | Red Cards | Direct red cards |
| 194 | Clean Sheets | Matches without conceding |
| 209 | Saves | Goalkeeper saves |
| 214 | Penalties | Penalties taken |

### Position Codes

| Code | Position | SportMonks Name |
|------|----------|-----------------|
| G | Goalkeeper | Goalkeeper |
| D | Defender | Defender |
| M | Midfielder | Midfielder |
| A / F | Forward | Attacker |

**Note:** The app normalizes various position codes:
- `GK`, `G`, `Goalkeeper` → `GK`
- `D`, `CB`, `LB`, `RB`, `WB` → `DEF`
- `M`, `CM`, `AM`, `DM`, `LM`, `RM` → `MID`
- `A`, `F`, `CF`, `ST`, `LW`, `RW` → `FWD`

---

## Error Handling

### Error Response Format

```json
{
  "message": "Error description",
  "status": 404
}
```

### Common Error Codes

| Status | Description | App Handling |
|--------|-------------|--------------|
| 401 | Invalid API token | Prompt user to check config |
| 404 | Resource not found | Use fallback/cached data |
| 429 | Rate limit exceeded | Use cached data, retry later |
| 500 | Server error | Use cached data, log error |

### App Error Handling

```dart
try {
  final response = await _client.getPlayerById(id);
  return Player.fromJson(response['data']);
} on SportMonksException catch (e) {
  debugPrint('API Error: ${e.message} (status: ${e.statusCode})');
  // Fall back to cached data
  return _getCachedPlayer(id);
} catch (e) {
  debugPrint('Unexpected error: $e');
  rethrow;
}
```

---

## Rate Limiting

### Subscription Limits

| Plan | Requests/minute | Requests/day |
|------|-----------------|--------------|
| Free | 60 | 3,600 |
| Basic | 180 | 10,800 |
| Pro | 1,000 | 100,000 |

### Optimization Strategies

1. **Aggressive Caching**: Cache all responses in Hive
2. **Batch Requests**: Use includes to reduce API calls
3. **Lazy Loading**: Only fetch data when needed
4. **Debouncing**: Delay search queries by 500ms

### Cache-First Pattern

```dart
Future<List<RosterPlayer>> getLigaMxRosterPlayers() async {
  // 1. Check Hive cache first
  final cached = await _cacheService.getLigaMxRoster();
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }
  
  // 2. Fetch from API
  final players = await _fetchFromApi();
  
  // 3. Cache for future use
  await _cacheService.saveLigaMxRoster(players);
  
  return players;
}
```

---

## Liga MX Team IDs

The app uses a curated list of Liga MX first-division teams stored in `assets/Teams/LigaMxTeamIds.csv`:

| Team ID | Team Name |
|---------|-----------|
| 2844 | Club América |
| 538 | Guadalajara (Chivas) |
| 3951 | Cruz Azul |
| 3849 | Pumas UNAM |
| 15522 | Toluca |
| 10036 | Tigres UANL |
| 10836 | Monterrey |
| 247689 | Juárez |
| ... | ... |

---

*Last Updated: January 2026*
