# Fantasy Points Prediction Model

## Overview

paroNfantasyMx uses a sophisticated prediction model to calculate:
1. **Player Recent Form** (0-100 score)
2. **Next Match Predicted Points** (0-10 scale)

The model leverages **SportMonks Advanced Statistics** to provide accurate, position-specific predictions based on the last 6 weeks of match data.

---

## Data Pipeline

### 1. API Data Fetching

```
Player Profile → Get Latest Fixtures → Fetch Detailed Stats per Fixture → Aggregate → Predict
```

#### Endpoints Used

| Step | Endpoint | Includes |
|------|----------|----------|
| Get player's recent fixtures | `/players/{id}?include=latest` | Returns lineup entry IDs for recent matches |
| Get detailed fixture stats | `/fixtures/{id}?include=...` | Full match data with advanced stats |

#### Fixture Include String
```
lineups;lineups.player;lineups.details.type;statistics;statistics.type;events;events.player;participants;scores;state
```

This returns:
- `lineups[].details[]` - Individual player advanced statistics
- `events[]` - Goals, assists, cards, substitutions
- `participants` - Team information
- `scores` - Match result (for clean sheet calculation)
- `state` - Match status (completed, etc.)

### 2. Data Structure

#### Lineup Details (Advanced Stats)
```json
{
  "player_id": 260742,
  "details": [
    {
      "type": {
        "developer_name": "KEY_PASSES",
        "name": "Key Passes"
      },
      "data": {
        "value": 3
      }
    }
  ]
}
```

---

## Advanced Statistics Collected

### Attacking Stats
| Stat | Code | Description |
|------|------|-------------|
| Shots Total | `SHOTS_TOTAL` | Total shots attempted |
| Shots On Target | `SHOTS_ON_TARGET` | Shots that would score without intervention |
| Key Passes | `KEY_PASSES` | Passes leading to a shot |
| Big Chances Created | `BIG_CHANCES_CREATED` | Clear scoring opportunities created |
| Big Chances Missed | `BIG_CHANCES_MISSED` | Clear chances not converted |

### Passing Stats
| Stat | Code | Description |
|------|------|-------------|
| Passes | `PASSES` | Total passes attempted |
| Accurate Passes | `ACCURATE_PASSES` | Successful passes |
| Accurate Passes % | `ACCURATE_PASSES_PERCENTAGE` | Pass completion rate |
| Long Balls | `LONG_BALLS` | Long passes attempted |
| Through Balls | `THROUGH_BALLS` | Passes between defenders |

### Defensive Stats
| Stat | Code | Description |
|------|------|-------------|
| Tackles | `TACKLES` | Successful tackles |
| Interceptions | `INTERCEPTIONS` | Passes intercepted |
| Clearances | `CLEARANCES` | Ball cleared from danger |
| Blocks | `BLOCKS` | Shots/passes blocked |
| Aerials Won | `AERIALS_WON` | Headers won |

### Duel Stats
| Stat | Code | Description |
|------|------|-------------|
| Total Duels | `TOTAL_DUELS` | All 1v1 contests |
| Duels Won | `DUELS_WON` | 1v1 contests won |
| Dispossessed | `DISPOSSESSED` | Times lost possession under pressure |
| Fouls Drawn | `FOULS_DRAWN` | Free kicks won |

### Other Stats
| Stat | Code | Description |
|------|------|-------------|
| Rating | `RATING` | Match rating (0-10) |
| Minutes Played | `MINUTES_PLAYED` | Time on pitch |
| Touches | `TOUCHES` | Ball touches |

---

## Form Calculation Algorithm

### Step 1: Fetch Recent Fixtures (Last 6 Weeks)

```dart
// Get player's latest fixtures (lineup entries)
final playerData = await getPlayerWithLatestFixtures(playerId);
final latestFixtures = playerData['latest'];

// For each fixture, fetch detailed stats
for (fixture in latestFixtures) {
  if (fixtureDate > sixWeeksAgo) {
    final details = await getFixtureWithDetailedStats(fixture.fixture_id);
    // Extract and aggregate stats
  }
}
```

### Step 2: Aggregate Stats Across Matches

```dart
RecentMatchStats {
  matchesPlayed: 5,
  goals: 2,
  assists: 3,
  minutesPlayed: 420,
  cleanSheets: 2,
  yellowCards: 1,
  redCards: 0,
  saves: 0,
  averageRating: 7.2,
  fixturesAnalyzed: 5,
  advancedStats: AdvancedStats { ... }
}
```

### Step 3: Calculate Form Score (0-100)

Base score starts at **35 points**, then position-specific bonuses are added.

#### Playing Time Factor (Max +10)
```dart
playingTimeFactor = (minutesPerMatch / 90).clamp(0, 1) * 10
// 90 mins avg = +10, 45 mins avg = +5
```

#### Participation Rate (Max +6)
```dart
participationRate = (matchesPlayed / fixturesAnalyzed) * 6
// Played all 5 matches = +6, played 3/5 = +3.6
```

---

## Position-Specific Form Scoring

### ⚽ Forwards (Strikers)

| Factor | Weight | Notes |
|--------|--------|-------|
| Goals per match | +40 | Primary metric |
| Assists per match | +22 | Secondary |
| Shots on target/match | +10 | Threat indicator |
| Shot accuracy | +3 | >40% = bonus |
| Big chances created | +8 | Playmaking |
| Key passes | +5 | Link-up play |
| Duels won | +4 | Hold-up play |
| Aerials won | +4 | Target man |
| Fouls drawn | +3 | Wins free kicks |
| Big chances missed | -3 each | Penalty after 2 |

### 🎯 Midfielders

| Factor | Weight | Notes |
|--------|--------|-------|
| Assists per match | +30 | Primary for creators |
| Goals per match | +35 | Super bonus |
| Key passes/match | +12 | **Most important** |
| Big chances created | +15 | High value |
| Pass accuracy | +4 | >80% = bonus |
| Accurate crosses | +5 | Wide players |
| Duels won | +5 | Box-to-box |
| Fouls drawn | +3 | Wins set pieces |
| Clean sheets | +4 | Defensive mids |
| Rating bonus | +6 | 7.0+ rating |
| Rating penalty | -4 | <6.0 rating |
| Dispossessed often | -3 | Loses ball too much |

### 🛡️ Defenders

| Factor | Weight | Notes |
|--------|--------|-------|
| Clean sheets | +15 | Core metric |
| Goals per match | +40 | Rare & valuable |
| Assists per match | +25 | Set piece threat |
| Tackles/match | +8 | Active defending |
| Interceptions/match | +8 | Reading the game |
| Clearances/match | +6 | Center backs |
| Blocks/match | +5 | Brave defending |
| Aerials won/match | +6 | Set piece dominance |
| Duel success rate | +9 | >55% = bonus |
| Rating bonus | +6 | Solid performances |
| Dribbled past | -5/match | Penalty |
| Errors to goals | -15 each | Severe penalty |

### 🧤 Goalkeepers

| Factor | Weight | Notes |
|--------|--------|-------|
| Clean sheets | +20 | Primary metric |
| Saves (normalized) | +12 | 4+ saves/game = max |
| Saves inside box | +10 | Reflexes indicator |
| Rating bonus | +6 | >6.5 rating |

### Universal Penalties
- Yellow cards: -4 per match average
- Fouls committed: -2 per match (if >2/match)

---

## Fantasy Points Prediction (0-10 Scale)

### Prediction Components

```
Total Points = (Base + Form + Season + Opponent) / 10
```

| Component | Weight | Description |
|-----------|--------|-------------|
| Base Points | 30% | Position baseline |
| Form Score | 40% | Recent 6-week performance |
| Season Stats | 20% | Overall season contribution |
| Opponent Factor | 10% | Difficulty adjustment |

### Position Baselines

| Position | Base | Description |
|----------|------|-------------|
| Goalkeeper | 4.0 | Clean sheet dependent |
| Defender | 4.5 | Clean sheet + bonus events |
| Midfielder | 5.0 | Most consistent scorers |
| Forward | 5.5 | Goal dependent, high variance |

### Prediction Tiers

| Tier | Points | Color |
|------|--------|-------|
| Elite | ≥8.5 | Gold |
| Excellent | ≥7.0 | Green |
| Good | ≥5.5 | Blue |
| Average | ≥4.0 | Gray |
| Poor | <4.0 | Red |

---

## Player Badges

Based on predicted points:

| Badge | Condition | Icon |
|-------|-----------|------|
| 🌟 Elite | ≥7.0 points | Gold star |
| ⭐ Star | ≥5.0 points | Orange star |
| 🍑 Cheeks | <2.0 points | Peach emoji |

---

## Injury/Bench Detection

```dart
bool isLikelyInjuredOrBench = 
    fixturesAnalyzed > 0 && matchesPlayed == 0;
```

If a player has fixtures analyzed but 0 minutes played, they're flagged as potentially injured or consistently benched, resulting in a **form score of 0**.

---

## Caching Strategy

### Cache Structure (Hive)
```dart
playerFormStats: {
  playerId: {
    'matchesPlayed': 5,
    'goals': 2,
    'assists': 3,
    'minutesPlayed': 420,
    'advancedStats': {
      'keyPasses': 8,
      'tackles': 12,
      'shotsTotal': 15,
      // ... all advanced stats
    }
  }
}
```

### Cache Invalidation
- Cache is bypassed if no `advancedStats` field exists (forces API refresh)
- Recommended TTL: 24 hours for active players

---

## Example Calculation

### Player: Gabriel Fernández (Striker)
**Recent 5 matches:**
- Goals: 2 (0.4/match)
- Assists: 1 (0.2/match)
- Minutes: 420 (84/match)
- Shots on target: 8 (1.6/match)
- Key passes: 5 (1.0/match)
- Rating: 7.1 avg

**Form Score:**
```
Base:                     35.0
Playing time (84/90):     +9.3
Participation (5/5):      +6.0
Goals (0.4 × 40):        +16.0
Assists (0.2 × 22):       +4.4
Shots on target:          +8.0
Key passes:               +3.3
Rating bonus (7.1):       +2.4
────────────────────────
Total:                    84.4/100
```

**Predicted Points:**
```
Base (Forward):           5.5
Form modifier (84.4%):   +0.8
Season contribution:     +0.5
────────────────────────
Prediction:              6.8/10 (Excellent)
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `lib/features/fantasy/fantasy_points_predictor.dart` | Core prediction logic |
| `lib/api/sportmonks_client.dart` | API calls with includes |
| `lib/api/repositories/fixtures_repository.dart` | Form calculation & stat extraction |
| `lib/features/player/ui/widgets/advanced_stats_dialog.dart` | Advanced stats display |

---

## Future Improvements

1. **xG Integration** - Expected goals data for better forward prediction
2. **Opponent Strength Model** - Team-level defensive/offensive ratings
3. **Home/Away Factor** - Venue-based adjustments
4. **Weather/Pitch Conditions** - Environmental factors
5. **Historical H2H** - Player performance against specific opponents

