import 'package:fantacy11/features/player/models/player_info.dart';

/// Advanced statistics from SportMonks lineup details
/// These are per-match aggregated stats from the last 6 weeks
class AdvancedStats {
  // Passing
  final int accuratePasses;
  final int totalPasses;
  final double? accuratePassesPercentage;
  final int longBalls;
  final int longBallsWon;
  final int throughBalls;
  final int throughBallsWon;

  // Attacking
  final int shotsTotal;
  final int shotsOnTarget;
  final int shotsOffTarget;
  final int bigChancesCreated;
  final int bigChancesMissed;
  final int keyPasses;
  final int hitWoodwork;
  final int hattricks;

  // Dribbling & Possession
  final int successfulDribbles;
  final int dispossessed;
  final int foulsDrawn;

  // Crossing
  final int accurateCrosses;
  final int totalCrosses;
  final int crossesBlocked;

  // Defensive
  final int tackles;
  final int interceptions;
  final int clearances;
  final int blocks;
  final int aerialsWon;
  final int duelsWon;
  final int totalDuels;
  final int dribbledPast;
  final int errorLeadToGoal;

  // Goalkeeper specific
  final int saves;
  final int savesInsideBox;
  final int goalsConceeded;

  // Discipline
  final int fouls;
  final int offsides;

  // Overall
  final List<double> ratings; // Ratings per match for averaging

  const AdvancedStats({
    this.accuratePasses = 0,
    this.totalPasses = 0,
    this.accuratePassesPercentage,
    this.longBalls = 0,
    this.longBallsWon = 0,
    this.throughBalls = 0,
    this.throughBallsWon = 0,
    this.shotsTotal = 0,
    this.shotsOnTarget = 0,
    this.shotsOffTarget = 0,
    this.bigChancesCreated = 0,
    this.bigChancesMissed = 0,
    this.keyPasses = 0,
    this.hitWoodwork = 0,
    this.hattricks = 0,
    this.successfulDribbles = 0,
    this.dispossessed = 0,
    this.foulsDrawn = 0,
    this.accurateCrosses = 0,
    this.totalCrosses = 0,
    this.crossesBlocked = 0,
    this.tackles = 0,
    this.interceptions = 0,
    this.clearances = 0,
    this.blocks = 0,
    this.aerialsWon = 0,
    this.duelsWon = 0,
    this.totalDuels = 0,
    this.dribbledPast = 0,
    this.errorLeadToGoal = 0,
    this.saves = 0,
    this.savesInsideBox = 0,
    this.goalsConceeded = 0,
    this.fouls = 0,
    this.offsides = 0,
    this.ratings = const [],
  });

  /// Calculate average rating from all matches
  double get averageRating {
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  /// Pass accuracy percentage
  double get passAccuracy =>
      totalPasses > 0 ? (accuratePasses / totalPasses) * 100 : 0;

  /// Shot accuracy percentage
  double get shotAccuracy =>
      shotsTotal > 0 ? (shotsOnTarget / shotsTotal) * 100 : 0;

  /// Duel success rate
  double get duelSuccessRate =>
      totalDuels > 0 ? (duelsWon / totalDuels) * 100 : 0;

  /// Cross accuracy
  double get crossAccuracy =>
      totalCrosses > 0 ? (accurateCrosses / totalCrosses) * 100 : 0;

  /// Long ball success rate
  double get longBallSuccessRate =>
      longBalls > 0 ? (longBallsWon / longBalls) * 100 : 0;

  /// Merge stats from a single match into cumulative stats
  AdvancedStats mergeWith(AdvancedStats other) {
    return AdvancedStats(
      accuratePasses: accuratePasses + other.accuratePasses,
      totalPasses: totalPasses + other.totalPasses,
      longBalls: longBalls + other.longBalls,
      longBallsWon: longBallsWon + other.longBallsWon,
      throughBalls: throughBalls + other.throughBalls,
      throughBallsWon: throughBallsWon + other.throughBallsWon,
      shotsTotal: shotsTotal + other.shotsTotal,
      shotsOnTarget: shotsOnTarget + other.shotsOnTarget,
      shotsOffTarget: shotsOffTarget + other.shotsOffTarget,
      bigChancesCreated: bigChancesCreated + other.bigChancesCreated,
      bigChancesMissed: bigChancesMissed + other.bigChancesMissed,
      keyPasses: keyPasses + other.keyPasses,
      hitWoodwork: hitWoodwork + other.hitWoodwork,
      hattricks: hattricks + other.hattricks,
      successfulDribbles: successfulDribbles + other.successfulDribbles,
      dispossessed: dispossessed + other.dispossessed,
      foulsDrawn: foulsDrawn + other.foulsDrawn,
      accurateCrosses: accurateCrosses + other.accurateCrosses,
      totalCrosses: totalCrosses + other.totalCrosses,
      crossesBlocked: crossesBlocked + other.crossesBlocked,
      tackles: tackles + other.tackles,
      interceptions: interceptions + other.interceptions,
      clearances: clearances + other.clearances,
      blocks: blocks + other.blocks,
      aerialsWon: aerialsWon + other.aerialsWon,
      duelsWon: duelsWon + other.duelsWon,
      totalDuels: totalDuels + other.totalDuels,
      dribbledPast: dribbledPast + other.dribbledPast,
      errorLeadToGoal: errorLeadToGoal + other.errorLeadToGoal,
      saves: saves + other.saves,
      savesInsideBox: savesInsideBox + other.savesInsideBox,
      goalsConceeded: goalsConceeded + other.goalsConceeded,
      fouls: fouls + other.fouls,
      offsides: offsides + other.offsides,
      ratings: [...ratings, ...other.ratings],
    );
  }

  /// Parse from SportMonks lineup details array
  /// Structure: detail['data']['value'] contains the stat value
  /// detail['type']['developer_name'] contains the stat code (uppercase with underscores)
  factory AdvancedStats.fromLineupDetails(List<dynamic> details) {
    int accuratePasses = 0, totalPasses = 0, longBalls = 0, longBallsWon = 0;
    int throughBalls = 0, throughBallsWon = 0;
    int shotsTotal = 0, shotsOnTarget = 0, shotsOffTarget = 0;
    int bigChancesCreated = 0,
        bigChancesMissed = 0,
        keyPasses = 0,
        hitWoodwork = 0,
        hattricks = 0;
    int successfulDribbles = 0, dispossessed = 0, foulsDrawn = 0;
    int accurateCrosses = 0, totalCrosses = 0, crossesBlocked = 0;
    int tackles = 0, interceptions = 0, clearances = 0, blocks = 0;
    int aerialsWon = 0,
        duelsWon = 0,
        totalDuels = 0,
        dribbledPast = 0,
        errorLeadToGoal = 0;
    int saves = 0,
        savesInsideBox = 0,
        goalsConceeded = 0,
        fouls = 0,
        offsides = 0;
    double? rating;

    final foundCodes = <String>[];

    for (final detail in details) {
      final type = detail['type'] as Map<String, dynamic>?;
      // Use developer_name which is uppercase with underscores (e.g., "KEY_PASSES")
      final code = type?['developer_name']?.toString().toUpperCase() ?? '';

      // Value is inside data.value, not directly on detail
      final data = detail['data'] as Map<String, dynamic>?;
      final rawValue = data?['value'];

      // Parse the value - can be int, double, or nested map with 'total'
      int intValue = 0;
      double? doubleValue;
      if (rawValue is int) {
        intValue = rawValue;
      } else if (rawValue is double) {
        intValue = rawValue.toInt();
        doubleValue = rawValue;
      } else if (rawValue is Map) {
        intValue = (rawValue['total'] as num?)?.toInt() ?? 0;
      }

      if (code.isNotEmpty) {
        foundCodes.add('$code=$intValue');
      }

      switch (code) {
        case 'ACCURATE_PASSES':
          accuratePasses = intValue;
          break;
        case 'PASSES':
        case 'SUCCESSFUL_PASSES':
          totalPasses = intValue;
          break;
        case 'LONG_BALLS':
          longBalls = intValue;
          break;
        case 'LONG_BALLS_WON':
          longBallsWon = intValue;
          break;
        case 'THROUGH_BALLS':
          throughBalls = intValue;
          break;
        case 'THROUGH_BALLS_WON':
          throughBallsWon = intValue;
          break;
        case 'SHOTS_TOTAL':
          shotsTotal = intValue;
          break;
        case 'SHOTS_ON_TARGET':
          shotsOnTarget = intValue;
          break;
        case 'SHOTS_OFF_TARGET':
          shotsOffTarget = intValue;
          break;
        case 'BIG_CHANCES_CREATED':
          bigChancesCreated = intValue;
          break;
        case 'BIG_CHANCES_MISSED':
          bigChancesMissed = intValue;
          break;
        case 'KEY_PASSES':
          keyPasses = intValue;
          break;
        case 'HIT_WOODWORK':
          hitWoodwork = intValue;
          break;
        case 'HATTRICKS':
          hattricks = intValue;
          break;
        case 'DISPOSSESSED':
          dispossessed = intValue;
          break;
        case 'FOULS_DRAWN':
          foulsDrawn = intValue;
          break;
        case 'ACCURATE_CROSSES':
          accurateCrosses = intValue;
          break;
        case 'TOTAL_CROSSES':
          totalCrosses = intValue;
          break;
        case 'CROSSES_BLOCKED':
          crossesBlocked = intValue;
          break;
        case 'TACKLES':
          tackles = intValue;
          break;
        case 'INTERCEPTIONS':
          interceptions = intValue;
          break;
        case 'CLEARANCES':
          clearances = intValue;
          break;
        case 'BLOCKS':
          blocks = intValue;
          break;
        case 'AERIALS_WON':
          aerialsWon = intValue;
          break;
        case 'DUELS_WON':
          duelsWon = intValue;
          break;
        case 'TOTAL_DUELS':
          totalDuels = intValue;
          break;
        case 'DRIBBLED_PAST':
          dribbledPast = intValue;
          break;
        case 'ERROR_LEAD_TO_GOAL':
          errorLeadToGoal = intValue;
          break;
        case 'SAVES':
          saves = intValue;
          break;
        case 'SAVES_INSIDE_BOX':
          savesInsideBox = intValue;
          break;
        case 'GOALS_CONCEDED':
          goalsConceeded = intValue;
          break;
        case 'FOULS':
          fouls = intValue;
          break;
        case 'OFFSIDES':
          offsides = intValue;
          break;
        case 'RATING':
          rating = doubleValue ?? (intValue > 0 ? intValue.toDouble() : null);
          break;
      }
    }

    print(
      'DEBUG AdvancedStats.fromLineupDetails: Found ${foundCodes.length} stat codes',
    );
    if (foundCodes.isNotEmpty) {
      print(
        'DEBUG AdvancedStats codes: ${foundCodes.take(10).join(', ')}${foundCodes.length > 10 ? '...' : ''}',
      );
    }

    return AdvancedStats(
      accuratePasses: accuratePasses,
      totalPasses: totalPasses,
      longBalls: longBalls,
      longBallsWon: longBallsWon,
      throughBalls: throughBalls,
      throughBallsWon: throughBallsWon,
      shotsTotal: shotsTotal,
      shotsOnTarget: shotsOnTarget,
      shotsOffTarget: shotsOffTarget,
      bigChancesCreated: bigChancesCreated,
      bigChancesMissed: bigChancesMissed,
      keyPasses: keyPasses,
      hitWoodwork: hitWoodwork,
      hattricks: hattricks,
      dispossessed: dispossessed,
      foulsDrawn: foulsDrawn,
      accurateCrosses: accurateCrosses,
      totalCrosses: totalCrosses,
      crossesBlocked: crossesBlocked,
      tackles: tackles,
      interceptions: interceptions,
      clearances: clearances,
      blocks: blocks,
      aerialsWon: aerialsWon,
      duelsWon: duelsWon,
      totalDuels: totalDuels,
      dribbledPast: dribbledPast,
      errorLeadToGoal: errorLeadToGoal,
      saves: saves,
      savesInsideBox: savesInsideBox,
      goalsConceeded: goalsConceeded,
      fouls: fouls,
      offsides: offsides,
      ratings: rating != null ? [rating] : [],
    );
  }
}

/// Recent match statistics for form calculation
/// Now includes advanced statistics from SportMonks
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

  /// Number of fixtures analyzed to get these stats (may differ from matchesPlayed)
  /// A low fixturesAnalyzed with 0 matchesPlayed indicates injured/bench player
  final int? fixturesAnalyzed;

  /// Advanced statistics from lineup details (last 6 weeks)
  final AdvancedStats? advancedStats;

  const RecentMatchStats({
    required this.matchesPlayed,
    this.goals = 0,
    this.assists = 0,
    this.minutesPlayed = 0,
    this.cleanSheets = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.saves = 0,
    this.averageRating,
    this.fixturesAnalyzed,
    this.advancedStats,
  });

  /// Returns true if player appears to be injured or warming the bench
  /// (fixtures were analyzed but player didn't play in any)
  bool get isLikelyInjuredOrBench =>
      fixturesAnalyzed != null && fixturesAnalyzed! > 0 && matchesPlayed == 0;

  /// Check if we have advanced stats available
  bool get hasAdvancedStats => advancedStats != null;

  /// Create from a list of match data (simulated from season stats)
  /// In a real scenario, this would come from per-match API data
  factory RecentMatchStats.fromSeasonStats(
    PlayerStatistics stats, {
    int recentMatches = 5,
  }) {
    if (stats.appearances == null || stats.appearances == 0) {
      return const RecentMatchStats(matchesPlayed: 0);
    }

    final totalGames = stats.appearances!;
    final recentGames = recentMatches.clamp(1, totalGames);
    final ratio = recentGames / totalGames;

    // Estimate recent stats based on season averages
    // In production, this would use actual per-match data
    return RecentMatchStats(
      matchesPlayed: recentGames,
      goals: ((stats.goals ?? 0) * ratio).round(),
      assists: ((stats.assists ?? 0) * ratio).round(),
      minutesPlayed: ((stats.minutesPlayed ?? 0) * ratio).round(),
      cleanSheets: ((stats.cleanSheets ?? 0) * ratio).round(),
      yellowCards: ((stats.yellowCards ?? 0) * ratio).round(),
      redCards: ((stats.redCards ?? 0) * ratio).round(),
      saves: ((stats.saves ?? 0) * ratio).round(),
      averageRating: stats.rating,
    );
  }

  /// Goals per match in recent games
  double get goalsPerMatch => matchesPlayed > 0 ? goals / matchesPlayed : 0;

  /// Assists per match in recent games
  double get assistsPerMatch => matchesPlayed > 0 ? assists / matchesPlayed : 0;

  /// Goal contributions per match
  double get contributionsPerMatch => goalsPerMatch + assistsPerMatch;

  /// Minutes per match (out of 90)
  double get minutesPerMatch =>
      matchesPlayed > 0 ? minutesPlayed / matchesPlayed : 0;

  /// Clean sheet rate
  double get cleanSheetRate =>
      matchesPlayed > 0 ? cleanSheets / matchesPlayed : 0;

  /// Cards per match (weighted: yellow=1, red=3)
  double get cardsPerMatch =>
      matchesPlayed > 0 ? (yellowCards + redCards * 3) / matchesPlayed : 0;

  // ========== ADVANCED STATS GETTERS ==========

  /// Key passes per match (chance creation)
  double get keyPassesPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.keyPasses / matchesPlayed
      : 0;

  /// Big chances created per match
  double get bigChancesCreatedPerMatch =>
      matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.bigChancesCreated / matchesPlayed
      : 0;

  /// Shots per match
  double get shotsPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.shotsTotal / matchesPlayed
      : 0;

  /// Shots on target per match
  double get shotsOnTargetPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.shotsOnTarget / matchesPlayed
      : 0;

  /// Tackles per match
  double get tacklesPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.tackles / matchesPlayed
      : 0;

  /// Interceptions per match
  double get interceptionsPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.interceptions / matchesPlayed
      : 0;

  /// Clearances per match
  double get clearancesPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.clearances / matchesPlayed
      : 0;

  /// Blocks per match
  double get blocksPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.blocks / matchesPlayed
      : 0;

  /// Duels won per match
  double get duelsWonPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.duelsWon / matchesPlayed
      : 0;

  /// Aerials won per match
  double get aerialsWonPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.aerialsWon / matchesPlayed
      : 0;

  /// Accurate crosses per match
  double get accurateCrossesPerMatch =>
      matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.accurateCrosses / matchesPlayed
      : 0;

  /// Fouls drawn per match (good - wins free kicks)
  double get foulsDrawnPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.foulsDrawn / matchesPlayed
      : 0;

  /// Fouls committed per match (bad)
  double get foulsCommittedPerMatch =>
      matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.fouls / matchesPlayed
      : 0;

  /// Pass accuracy from advanced stats
  double? get passAccuracy => advancedStats?.passAccuracy;

  /// Shot accuracy from advanced stats
  double? get shotAccuracy => advancedStats?.shotAccuracy;

  /// Duel success rate from advanced stats
  double? get duelSuccessRate => advancedStats?.duelSuccessRate;

  /// Saves inside box per match (GK specific)
  double get savesInsideBoxPerMatch =>
      matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.savesInsideBox / matchesPlayed
      : 0;

  /// Times dribbled past per match (bad for defenders)
  double get dribbledPastPerMatch => matchesPlayed > 0 && advancedStats != null
      ? advancedStats!.dribbledPast / matchesPlayed
      : 0;

  /// Errors leading to goal (very bad)
  int get errorsLeadingToGoal => advancedStats?.errorLeadToGoal ?? 0;
}

/// Opponent information for matchup analysis
class OpponentInfo {
  final String name;
  final String? logoUrl;
  final int? leaguePosition; // 1 = top of league
  final int? gamesPlayed;
  final int? goalsScored; // Total goals scored
  final int? goalsConceded; // Total goals conceded
  final int? cleanSheets; // Clean sheets kept
  final int? wins;
  final int? draws;
  final int? losses;
  final bool isHomeGame; // Is the player's team playing at home?
  final DateTime? matchDateTime; // When the match is scheduled
  final String? venueName; // Stadium name

  const OpponentInfo({
    required this.name,
    this.logoUrl,
    this.leaguePosition,
    this.gamesPlayed,
    this.goalsScored,
    this.goalsConceded,
    this.cleanSheets,
    this.wins,
    this.draws,
    this.losses,
    this.isHomeGame = true,
    this.matchDateTime,
    this.venueName,
  });

  /// Format match date/time for display
  String get formattedMatchTime {
    if (matchDateTime == null) return 'TBD';
    final now = DateTime.now();
    final diff = matchDateTime!.difference(now);

    if (diff.inDays > 1) {
      return '${_dayName(matchDateTime!.weekday)}, ${_monthName(matchDateTime!.month)} ${matchDateTime!.day}';
    } else if (diff.inDays == 1) {
      return 'Tomorrow, ${_formatTime(matchDateTime!)}';
    } else if (diff.inHours >= 0) {
      return 'Today, ${_formatTime(matchDateTime!)}';
    }
    return 'Completed';
  }

  /// Get short time remaining
  String get timeRemaining {
    if (matchDateTime == null) return '';
    final now = DateTime.now();
    final diff = matchDateTime!.difference(now);

    if (diff.isNegative) return 'LIVE';
    if (diff.inDays > 0) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Soon';
  }

  static String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Goals conceded per game (defensive strength - lower is better defense)
  double get goalsConcededPerGame {
    if (gamesPlayed == null || gamesPlayed == 0 || goalsConceded == null)
      return 1.0;
    return goalsConceded! / gamesPlayed!;
  }

  /// Goals scored per game (attacking strength)
  double get goalsScoredPerGame {
    if (gamesPlayed == null || gamesPlayed == 0 || goalsScored == null)
      return 1.0;
    return goalsScored! / gamesPlayed!;
  }

  /// Clean sheet rate (higher = better defense)
  double get cleanSheetRate {
    if (gamesPlayed == null || gamesPlayed == 0 || cleanSheets == null)
      return 0.3;
    return cleanSheets! / gamesPlayed!;
  }

  /// Win rate
  double get winRate {
    if (gamesPlayed == null || gamesPlayed == 0 || wins == null) return 0.33;
    return wins! / gamesPlayed!;
  }

  /// Defensive difficulty rating (0-100, higher = harder to score against)
  int get defensiveRating {
    double rating = 50.0;

    // Goals conceded factor (fewer = better defense)
    // Liga MX average is about 1.2 goals conceded per game
    rating += (1.2 - goalsConcededPerGame) * 20;

    // Clean sheet factor
    // Liga MX average clean sheet rate is about 25%
    rating += (cleanSheetRate - 0.25) * 40;

    // League position factor (if available)
    if (leaguePosition != null) {
      // Top 4 = strong, bottom 4 = weak (18 teams in Liga MX)
      if (leaguePosition! <= 4) {
        rating += 15;
      } else if (leaguePosition! <= 8) {
        rating += 5;
      } else if (leaguePosition! >= 15) {
        rating -= 15;
      } else if (leaguePosition! >= 12) {
        rating -= 5;
      }
    }

    return rating.clamp(0.0, 100.0).round();
  }

  /// Attacking threat rating (0-100, higher = more dangerous attack)
  int get attackingRating {
    double rating = 50.0;

    // Goals scored factor
    // Liga MX average is about 1.2 goals scored per game
    rating += (goalsScoredPerGame - 1.2) * 20;

    // Win rate factor
    rating += (winRate - 0.33) * 30;

    // League position factor
    if (leaguePosition != null) {
      if (leaguePosition! <= 4) {
        rating += 15;
      } else if (leaguePosition! <= 8) {
        rating += 5;
      } else if (leaguePosition! >= 15) {
        rating -= 15;
      } else if (leaguePosition! >= 12) {
        rating -= 5;
      }
    }

    return rating.clamp(0.0, 100.0).round();
  }

  /// Overall difficulty rating (0-100)
  int get overallDifficulty =>
      ((defensiveRating + attackingRating) / 2).round();

  /// Get difficulty label
  String get difficultyLabel {
    final diff = overallDifficulty;
    if (diff >= 75) return 'Very Hard';
    if (diff >= 60) return 'Hard';
    if (diff >= 45) return 'Medium';
    if (diff >= 30) return 'Easy';
    return 'Very Easy';
  }

  /// Get difficulty color value
  int get difficultyColorValue {
    final diff = overallDifficulty;
    if (diff >= 75) return 0xFFF44336; // Red - very hard
    if (diff >= 60) return 0xFFFF9800; // Orange - hard
    if (diff >= 45) return 0xFFFFC107; // Amber - medium
    if (diff >= 30) return 0xFF8BC34A; // Light green - easy
    return 0xFF4CAF50; // Green - very easy
  }
}

/// Fantasy points prediction model
/// Predicts player performance based on season statistics, recent form, and opponent
class FantasyPointsPredictor {
  /// Weight for recent form vs season stats (0.0 = all season, 1.0 = all recent)
  static const double recentFormWeight = 0.6;

  /// Number of recent matches to consider
  static const int recentMatchesCount = 5;

  /// Maximum opponent adjustment (points)
  static const double maxOpponentAdjustment = 12.0;

  /// Predict fantasy points for a player (0-100 scale)
  ///
  /// [player] - The player to predict for
  /// [recentForm] - Optional recent match statistics (last 5 matches)
  /// [opponent] - Optional next opponent info for matchup analysis
  /// [currentSeasonId] - Optional current season/tournament ID to use specific season stats
  static FantasyPrediction predict(
    Player player, {
    RecentMatchStats? recentForm,
    OpponentInfo? opponent,
    int? currentSeasonId,
  }) {
    // Use current season stats if available, otherwise fall back to latest
    final stats = currentSeasonId != null
        ? player.getStatsForCurrentSeason(currentSeasonId)
        : player.latestStats;
    final position = player.position?.name.toLowerCase() ?? '';

    // If no stats available, return a base prediction
    if (stats == null || !stats.hasData) {
      return FantasyPrediction(
        totalPoints: 5.0, // Average default (0-10 scale)
        breakdown: {'No statistics available': 5.0},
        confidence: 0.3,
        playerName: player.displayName,
        position: player.position?.name ?? 'Unknown',
        recentFormScore: null,
        opponent: opponent,
      );
    }

    // Calculate recent form from season stats if not provided
    final recent =
        recentForm ??
        RecentMatchStats.fromSeasonStats(
          stats,
          recentMatches: recentMatchesCount,
        );

    // Determine position category
    final positionCategory = _getPositionCategory(
      position,
      player.position?.code,
    );

    // Calculate points based on position
    switch (positionCategory) {
      case PositionCategory.goalkeeper:
        return _predictGoalkeeper(player, stats, recent, opponent);
      case PositionCategory.defender:
        return _predictDefender(player, stats, recent, opponent);
      case PositionCategory.midfielder:
        return _predictMidfielder(player, stats, recent, opponent);
      case PositionCategory.forward:
        return _predictForward(player, stats, recent, opponent);
    }
  }

  /// Calculate opponent adjustment for attacking players
  /// Negative adjustment for tough defenses, positive for weak defenses
  static double _calculateAttackingOpponentAdjustment(OpponentInfo? opponent) {
    if (opponent == null) return 0.0;

    // Defense rating: 50 = average, higher = better defense = harder to score
    final defenseRating = opponent.defensiveRating;

    // Convert to adjustment: 50 = no adjustment, 80 = -max, 20 = +max
    final adjustment = (50 - defenseRating) / 30 * maxOpponentAdjustment;

    // Home advantage: +2 points if playing at home
    final homeBonus = opponent.isHomeGame ? 2.0 : -1.0;

    return (adjustment + homeBonus).clamp(
      -maxOpponentAdjustment,
      maxOpponentAdjustment,
    );
  }

  /// Calculate opponent adjustment for defensive players
  /// Negative adjustment for strong attacks, positive for weak attacks
  static double _calculateDefensiveOpponentAdjustment(OpponentInfo? opponent) {
    if (opponent == null) return 0.0;

    // Attack rating: 50 = average, higher = stronger attack = harder to keep clean sheet
    final attackRating = opponent.attackingRating;

    // Convert to adjustment
    final adjustment = (50 - attackRating) / 30 * maxOpponentAdjustment;

    // Home advantage for clean sheets
    final homeBonus = opponent.isHomeGame ? 1.5 : -0.5;

    return (adjustment + homeBonus).clamp(
      -maxOpponentAdjustment,
      maxOpponentAdjustment,
    );
  }

  static PositionCategory _getPositionCategory(String position, String? code) {
    final pos = position.toLowerCase();
    final c = code?.toLowerCase() ?? '';

    if (c == 'g' || pos.contains('goalkeeper') || pos.contains('portero')) {
      return PositionCategory.goalkeeper;
    } else if (c == 'd' ||
        pos.contains('defender') ||
        pos.contains('back') ||
        pos.contains('defensa')) {
      return PositionCategory.defender;
    } else if (c == 'm' ||
        pos.contains('midfielder') ||
        pos.contains('medio')) {
      return PositionCategory.midfielder;
    } else {
      return PositionCategory.forward;
    }
  }

  /// Blend season and recent form stats
  static double _blendStats(double seasonValue, double recentValue) {
    return (seasonValue * (1 - recentFormWeight)) +
        (recentValue * recentFormWeight);
  }

  /// Calculate recent form score (0-100)
  ///
  /// Form scoring using ADVANCED STATISTICS:
  /// - 0: Player is injured or bench warmer (no playtime in last 6 weeks)
  /// - 25: Very low form (few minutes, no contributions)
  /// - 50: Average/neutral form
  /// - 75+: Great form (regular starter with good contributions)
  ///
  /// Position-specific weighting with advanced stats:
  /// - Forwards: Goals, shots on target, big chances, xG-related metrics
  /// - Midfielders: Key passes, big chances created, pass accuracy, assists
  /// - Defenders: Tackles, interceptions, clearances, aerial duels, clean sheets
  /// - Goalkeepers: Saves, saves inside box, clean sheets, distribution
  static double _calculateFormScore(
    RecentMatchStats recent,
    PositionCategory position,
  ) {
    // Check if player is injured or bench warmer (fixtures analyzed but didn't play)
    if (recent.isLikelyInjuredOrBench) {
      return 0.0; // Severely penalize - player unlikely to play
    }

    // No data available - use neutral score
    if (recent.matchesPlayed == 0) {
      return 50.0;
    }

    double score =
        35.0; // Base score (lower to allow more room for advanced stats bonuses)
    final hasAdvanced = recent.hasAdvancedStats;

    // Playing time factor - heavily weighted
    // Regular starter (80+ mins avg) = +10, sub (30 mins avg) = +3
    final playingTimeFactor = (recent.minutesPerMatch / 90).clamp(0.0, 1.0);
    score += playingTimeFactor * 10;

    // Participation rate bonus (played in most of the analyzed fixtures)
    if (recent.fixturesAnalyzed != null && recent.fixturesAnalyzed! > 0) {
      final participationRate = recent.matchesPlayed / recent.fixturesAnalyzed!;
      score += participationRate * 6; // Max +6 for playing every game
    }

    // Position-specific factors with ADVANCED STATS
    switch (position) {
      case PositionCategory.goalkeeper:
        // Clean sheets are key for GKs
        score += recent.cleanSheetRate * 20;
        // Saves bonus (normalized: 4+ saves per game is excellent)
        score += (recent.saves / recent.matchesPlayed / 4).clamp(0.0, 1.0) * 12;

        // ADVANCED: Saves inside box (crucial, shows reflexes)
        if (hasAdvanced) {
          score +=
              recent.savesInsideBoxPerMatch *
              10; // Max ~10 for 1 save inside box/match
        }

        // Rating bonus
        if (recent.averageRating != null && recent.averageRating! > 6.5) {
          score += (recent.averageRating! - 6.5) * 6;
        }
        break;

      case PositionCategory.defender:
        // Clean sheets are crucial for defenders
        score += recent.cleanSheetRate * 15;
        // Goals from defenders are RARE and HUGE
        score += recent.goalsPerMatch * 40;
        // Assists from defenders are also very valuable
        score += recent.assistsPerMatch * 25;

        // ADVANCED DEFENSIVE STATS
        if (hasAdvanced) {
          // Tackles (good - 2+ per game is solid)
          score += (recent.tacklesPerMatch / 3).clamp(0.0, 1.0) * 8;
          // Interceptions (excellent reading of game)
          score += (recent.interceptionsPerMatch / 2).clamp(0.0, 1.0) * 8;
          // Clearances (important for center backs)
          score += (recent.clearancesPerMatch / 4).clamp(0.0, 1.0) * 6;
          // Blocks (brave defending)
          score += (recent.blocksPerMatch / 1.5).clamp(0.0, 1.0) * 5;
          // Aerial duels won (important for set pieces)
          score += (recent.aerialsWonPerMatch / 3).clamp(0.0, 1.0) * 6;
          // Duel success rate bonus
          final duelRate = recent.duelSuccessRate ?? 0;
          if (duelRate > 55)
            score += (duelRate - 55) / 5 * 5; // Max +9 for 100%
          // PENALTY: Dribbled past (bad for defenders)
          score -= recent.dribbledPastPerMatch * 5;
          // PENALTY: Errors leading to goals (very bad)
          score -= recent.errorsLeadingToGoal * 15;
        }

        // Rating bonus for solid performances
        if (recent.averageRating != null && recent.averageRating! > 6.5) {
          score += (recent.averageRating! - 6.5) * 6;
        }
        break;

      case PositionCategory.midfielder:
        // Assists are the bread and butter for midfielders
        score += recent.assistsPerMatch * 30;
        // Goals are a SUPER bonus for midfielders
        score += recent.goalsPerMatch * 35;

        // ADVANCED CREATIVE STATS (key for midfielders!)
        if (hasAdvanced) {
          // Key passes (chance creation - most important for mids)
          score += (recent.keyPassesPerMatch / 2).clamp(0.0, 1.0) * 12;
          // Big chances created (even more valuable)
          score += recent.bigChancesCreatedPerMatch * 15;
          // Pass accuracy bonus (shows control)
          final passAcc = recent.passAccuracy ?? 0;
          if (passAcc > 80) score += (passAcc - 80) / 5 * 5; // Max +4 for 100%
          // Accurate crosses (for wide mids/wingers)
          score += (recent.accurateCrossesPerMatch / 2).clamp(0.0, 1.0) * 5;
          // Duels won (important for box-to-box mids)
          score += (recent.duelsWonPerMatch / 5).clamp(0.0, 1.0) * 5;
          // Fouls drawn (wins free kicks, shows ability to draw contact)
          score += (recent.foulsDrawnPerMatch / 2).clamp(0.0, 1.0) * 3;
          // PENALTY: Dispossessed too often
          if (recent.advancedStats!.dispossessed > recent.matchesPlayed * 2) {
            score -= 3; // Loses ball too often
          }
        }

        // Rating bonus for playmakers
        if (recent.averageRating != null) {
          if (recent.averageRating! >= 7.0) {
            score += (recent.averageRating! - 6.5) * 6;
          } else if (recent.averageRating! < 6.0) {
            score -= (6.0 - recent.averageRating!) * 4;
          }
        }

        // Small clean sheet contribution for defensive midfielders
        score += recent.cleanSheetRate * 4;
        break;

      case PositionCategory.forward:
        // Goals are KING for strikers
        score += recent.goalsPerMatch * 40;
        // Assists are important but secondary
        score += recent.assistsPerMatch * 22;

        // ADVANCED ATTACKING STATS
        if (hasAdvanced) {
          // Shots on target (shows threat even without scoring)
          score += (recent.shotsOnTargetPerMatch / 2).clamp(0.0, 1.0) * 10;
          // Shot accuracy bonus
          final shotAcc = recent.shotAccuracy ?? 0;
          if (shotAcc > 40) score += (shotAcc - 40) / 10 * 5; // Max +3 for 70%+
          // Big chances missed penalty (should be finishing)
          if (recent.advancedStats!.bigChancesMissed > 2) {
            score -= (recent.advancedStats!.bigChancesMissed - 2) * 3;
          }
          // Big chances created (playmaking forwards)
          score += recent.bigChancesCreatedPerMatch * 8;
          // Key passes (link-up play)
          score += (recent.keyPassesPerMatch / 1.5).clamp(0.0, 1.0) * 5;
          // Duels won (hold-up play)
          score += (recent.duelsWonPerMatch / 5).clamp(0.0, 1.0) * 4;
          // Aerials won (target man bonus)
          score += (recent.aerialsWonPerMatch / 3).clamp(0.0, 1.0) * 4;
          // Fouls drawn (wins penalties, free kicks)
          score += (recent.foulsDrawnPerMatch / 2).clamp(0.0, 1.0) * 3;
        }

        // Rating bonus
        if (recent.averageRating != null && recent.averageRating! >= 7.0) {
          score += (recent.averageRating! - 6.5) * 4;
        }
        break;
    }

    // Card penalty (affects all positions)
    score -= recent.cardsPerMatch * 4;

    // ADVANCED: Extra foul penalty if committing too many fouls
    if (hasAdvanced && recent.foulsCommittedPerMatch > 2) {
      score -= (recent.foulsCommittedPerMatch - 2) * 2;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Predict for Goalkeeper
  static FantasyPrediction _predictGoalkeeper(
    Player player,
    PlayerStatistics stats,
    RecentMatchStats recent,
    OpponentInfo? opponent,
  ) {
    final breakdown = <String, double>{};
    double total = 0;

    // Calculate form score
    final formScore = _calculateFormScore(recent, PositionCategory.goalkeeper);

    // Calculate opponent adjustment (defensive-focused for GK)
    final opponentAdjustment = _calculateDefensiveOpponentAdjustment(opponent);

    // Base points for playing (max 15)
    final seasonAppearanceRate = _calculateAppearanceRate(stats);
    final recentPlayingRate = recent.matchesPlayed > 0
        ? (recent.minutesPerMatch / 90).clamp(0.0, 1.0)
        : seasonAppearanceRate;
    final playingPoints =
        _blendStats(seasonAppearanceRate, recentPlayingRate) * 15;
    breakdown['Playing Time'] = playingPoints;
    total += playingPoints;

    // Clean sheets (max 35) - most important for GK
    if (stats.cleanSheets != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final seasonCleanSheetRate = stats.cleanSheets! / stats.appearances!;
      final recentCleanSheetRate = recent.cleanSheetRate;
      final cleanSheetPoints =
          _blendStats(seasonCleanSheetRate, recentCleanSheetRate) * 35;
      breakdown['Clean Sheets'] = cleanSheetPoints;
      total += cleanSheetPoints;
    }

    // Saves (max 25)
    if (stats.saves != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final seasonSavesPerGame = stats.saves! / stats.appearances!;
      final recentSavesPerGame = recent.matchesPlayed > 0
          ? recent.saves / recent.matchesPlayed
          : seasonSavesPerGame;
      final savesPerGame = _blendStats(seasonSavesPerGame, recentSavesPerGame);
      final savePoints = (savesPerGame / 4).clamp(0.0, 1.0) * 25;
      breakdown['Saves'] = savePoints;
      total += savePoints;
    }

    // Recent Form Bonus/Penalty (max ±10)
    final formBonus = (formScore - 50) / 5; // -10 to +10 based on form
    breakdown['Recent Form (Last $recentMatchesCount)'] = formBonus;
    total += formBonus;

    // Consistency bonus (max 10)
    if (stats.lineups != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final startRate = stats.lineups! / stats.appearances!;
      final consistencyPoints = startRate * 10;
      breakdown['Consistency'] = consistencyPoints;
      total += consistencyPoints;
    }

    // Penalty for cards
    final seasonCardPenalty = _calculateCardPenalty(stats);
    final recentCardPenalty = recent.cardsPerMatch * 3;
    final cardPenalty = _blendStats(seasonCardPenalty, recentCardPenalty);
    if (cardPenalty > 0) {
      breakdown['Card Penalty'] = -cardPenalty.clamp(0.0, 10.0);
      total -= cardPenalty.clamp(0.0, 10.0);
    }

    // Opponent adjustment
    if (opponent != null) {
      breakdown['vs ${opponent.name}'] = opponentAdjustment;
      total += opponentAdjustment;
    }

    return FantasyPrediction(
      totalPoints: (total / 10).clamp(0.0, 10.0), // Convert to 0-10 scale
      breakdown: breakdown,
      confidence: _calculateConfidence(stats, recent),
      playerName: player.displayName,
      position: 'Goalkeeper',
      recentFormScore: formScore.round(),
      opponent: opponent,
    );
  }

  /// Predict for Defender
  /// - Clean sheets are crucial
  /// - Goals/assists are RARE so they're worth MORE than for attackers
  static FantasyPrediction _predictDefender(
    Player player,
    PlayerStatistics stats,
    RecentMatchStats recent,
    OpponentInfo? opponent,
  ) {
    final breakdown = <String, double>{};
    double total = 0;

    final formScore = _calculateFormScore(recent, PositionCategory.defender);

    // Defenders benefit from both defensive and some attacking adjustments
    final defenseAdjustment =
        _calculateDefensiveOpponentAdjustment(opponent) * 0.7;
    final attackAdjustment =
        _calculateAttackingOpponentAdjustment(opponent) * 0.3;
    final opponentAdjustment = defenseAdjustment + attackAdjustment;

    // Base points for playing (max 10)
    final seasonAppearanceRate = _calculateAppearanceRate(stats);
    final recentPlayingRate = recent.matchesPlayed > 0
        ? (recent.minutesPerMatch / 90).clamp(0.0, 1.0)
        : seasonAppearanceRate;
    final playingPoints =
        _blendStats(seasonAppearanceRate, recentPlayingRate) * 10;
    breakdown['Playing Time'] = playingPoints;
    total += playingPoints;

    // Clean sheets (max 30) - CRUCIAL for defenders
    if (stats.cleanSheets != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final seasonCleanSheetRate = stats.cleanSheets! / stats.appearances!;
      final cleanSheetPoints =
          _blendStats(seasonCleanSheetRate, recent.cleanSheetRate) * 30;
      breakdown['Clean Sheets'] = cleanSheetPoints;
      total += cleanSheetPoints;
    }

    // Goals (max 25) - RARE for defenders, so worth MORE than strikers!
    // A defender scoring 0.1 goals/game is exceptional
    if (stats.goals != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final seasonGoalsPerGame = stats.goals! / stats.appearances!;
      final goalsPerGame = _blendStats(
        seasonGoalsPerGame,
        recent.goalsPerMatch,
      );
      // 0.1 goals/game = max points (1 goal in 10 games is great for a defender)
      final goalPoints = (goalsPerGame / 0.1).clamp(0.0, 1.0) * 25;
      breakdown['Goals'] = goalPoints;
      total += goalPoints;
    }

    // Assists (max 18) - Also valuable for defenders
    if (stats.assists != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final seasonAssistsPerGame = stats.assists! / stats.appearances!;
      final assistsPerGame = _blendStats(
        seasonAssistsPerGame,
        recent.assistsPerMatch,
      );
      // 0.1 assists/game = max points
      final assistPoints = (assistsPerGame / 0.1).clamp(0.0, 1.0) * 18;
      breakdown['Assists'] = assistPoints;
      total += assistPoints;
    }

    // Recent Form Bonus/Penalty (max ±12)
    final formBonus = (formScore - 50) / 4;
    breakdown['Recent Form (Last $recentMatchesCount)'] = formBonus.clamp(
      -12.0,
      12.0,
    );
    total += formBonus.clamp(-12.0, 12.0);

    // Consistency bonus (max 8)
    if (stats.lineups != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final startRate = stats.lineups! / stats.appearances!;
      final consistencyPoints = startRate * 8;
      breakdown['Consistency'] = consistencyPoints;
      total += consistencyPoints;
    }

    // Penalty for cards (defenders get more cards)
    final seasonCardPenalty = _calculateCardPenalty(stats) * 1.2;
    final recentCardPenalty = recent.cardsPerMatch * 4;
    final cardPenalty = _blendStats(seasonCardPenalty, recentCardPenalty);
    if (cardPenalty > 0) {
      breakdown['Card Penalty'] = -cardPenalty.clamp(0.0, 12.0);
      total -= cardPenalty.clamp(0.0, 12.0);
    }

    // Opponent adjustment
    if (opponent != null) {
      breakdown['vs ${opponent.name}'] = opponentAdjustment;
      total += opponentAdjustment;
    }

    return FantasyPrediction(
      totalPoints: (total / 10).clamp(0.0, 10.0), // Convert to 0-10 scale
      breakdown: breakdown,
      confidence: _calculateConfidence(stats, recent),
      playerName: player.displayName,
      position: 'Defender',
      recentFormScore: formScore.round(),
      opponent: opponent,
    );
  }

  /// Predict for Midfielder
  /// - Assists are the bread and butter
  /// - Goals are a SUPER bonus (not their main job)
  /// - Rating matters for playmakers who control games without G/A
  static FantasyPrediction _predictMidfielder(
    Player player,
    PlayerStatistics stats,
    RecentMatchStats recent,
    OpponentInfo? opponent,
  ) {
    final breakdown = <String, double>{};
    double total = 0;

    final formScore = _calculateFormScore(recent, PositionCategory.midfielder);

    // Midfielders: balanced between attacking and defensive adjustments
    final attackAdjustment =
        _calculateAttackingOpponentAdjustment(opponent) * 0.6;
    final defenseAdjustment =
        _calculateDefensiveOpponentAdjustment(opponent) * 0.4;
    final opponentAdjustment = attackAdjustment + defenseAdjustment;

    // Base points for playing (max 8)
    final seasonAppearanceRate = _calculateAppearanceRate(stats);
    final recentPlayingRate = recent.matchesPlayed > 0
        ? (recent.minutesPerMatch / 90).clamp(0.0, 1.0)
        : seasonAppearanceRate;
    final playingPoints =
        _blendStats(seasonAppearanceRate, recentPlayingRate) * 8;
    breakdown['Playing Time'] = playingPoints;
    total += playingPoints;

    // Assists (max 30) - PRIMARY stat for midfielders
    if (stats.assists != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final seasonAssistsPerGame = stats.assists! / stats.appearances!;
      final assistsPerGame = _blendStats(
        seasonAssistsPerGame,
        recent.assistsPerMatch,
      );
      // 0.3 assists/game = max points (very good for a midfielder)
      final assistPoints = (assistsPerGame / 0.3).clamp(0.0, 1.0) * 30;
      breakdown['Assists'] = assistPoints;
      total += assistPoints;
    }

    // Goals (max 25) - SUPER BONUS for midfielders
    if (stats.goals != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final seasonGoalsPerGame = stats.goals! / stats.appearances!;
      final goalsPerGame = _blendStats(
        seasonGoalsPerGame,
        recent.goalsPerMatch,
      );
      // 0.25 goals/game = max points (scoring mids are very valuable)
      final goalPoints = (goalsPerGame / 0.25).clamp(0.0, 1.0) * 25;
      breakdown['Goals'] = goalPoints;
      total += goalPoints;
    }

    // Game Control Rating (max 15) - for playmakers who don't score/assist but control the game
    // This is KEY for midfielders who might not have G/A but have high ratings
    if (stats.rating != null && stats.rating! > 0) {
      final seasonRating = stats.rating!;
      final recentRating = recent.averageRating ?? seasonRating;
      final avgRating = _blendStats(seasonRating, recentRating);
      // Rating above 6.5 gives bonus, below gives penalty
      if (avgRating >= 6.5) {
        final ratingPoints =
            ((avgRating - 6.5) / 1.5).clamp(0.0, 1.0) * 15; // 8.0 rating = max
        breakdown['Game Control'] = ratingPoints;
        total += ratingPoints;
      } else {
        final ratingPenalty = ((6.5 - avgRating) / 1.5).clamp(0.0, 1.0) * 8;
        breakdown['Game Control'] = -ratingPenalty;
        total -= ratingPenalty;
      }
    }

    // Recent Form Bonus/Penalty (max ±12)
    final formBonus = (formScore - 50) / 4;
    breakdown['Recent Form (Last $recentMatchesCount)'] = formBonus.clamp(
      -12.0,
      12.0,
    );
    total += formBonus.clamp(-12.0, 12.0);

    // Consistency bonus (max 6)
    if (stats.lineups != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final startRate = stats.lineups! / stats.appearances!;
      final consistencyPoints = startRate * 6;
      breakdown['Consistency'] = consistencyPoints;
      total += consistencyPoints;
    }

    // Penalty for cards
    final seasonCardPenalty = _calculateCardPenalty(stats);
    final recentCardPenalty = recent.cardsPerMatch * 3;
    final cardPenalty = _blendStats(seasonCardPenalty, recentCardPenalty);
    if (cardPenalty > 0) {
      breakdown['Card Penalty'] = -cardPenalty.clamp(0.0, 10.0);
      total -= cardPenalty.clamp(0.0, 10.0);
    }

    // Opponent adjustment
    if (opponent != null) {
      breakdown['vs ${opponent.name}'] = opponentAdjustment;
      total += opponentAdjustment;
    }

    return FantasyPrediction(
      totalPoints: (total / 10).clamp(0.0, 10.0), // Convert to 0-10 scale
      breakdown: breakdown,
      confidence: _calculateConfidence(stats, recent),
      playerName: player.displayName,
      position: 'Midfielder',
      recentFormScore: formScore.round(),
      opponent: opponent,
    );
  }

  /// Predict for Forward
  /// - Goals are KING - this is their primary job
  /// - Assists are important but secondary
  /// - Form matters a lot for strikers
  static FantasyPrediction _predictForward(
    Player player,
    PlayerStatistics stats,
    RecentMatchStats recent,
    OpponentInfo? opponent,
  ) {
    final breakdown = <String, double>{};
    double total = 0;

    final formScore = _calculateFormScore(recent, PositionCategory.forward);

    // Forwards: primarily affected by opponent's defensive strength
    final opponentAdjustment = _calculateAttackingOpponentAdjustment(opponent);

    // Base points for playing (max 6) - less base for forwards, they need to produce
    final seasonAppearanceRate = _calculateAppearanceRate(stats);
    final recentPlayingRate = recent.matchesPlayed > 0
        ? (recent.minutesPerMatch / 90).clamp(0.0, 1.0)
        : seasonAppearanceRate;
    final playingPoints =
        _blendStats(seasonAppearanceRate, recentPlayingRate) * 6;
    breakdown['Playing Time'] = playingPoints;
    total += playingPoints;

    // Goals (max 40) - THE most important stat for forwards
    if (stats.goals != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final seasonGoalsPerGame = stats.goals! / stats.appearances!;
      final goalsPerGame = _blendStats(
        seasonGoalsPerGame,
        recent.goalsPerMatch,
      );
      // 0.5 goals/game = max points (world class striker level)
      final goalPoints = (goalsPerGame / 0.5).clamp(0.0, 1.0) * 40;
      breakdown['Goals'] = goalPoints;
      total += goalPoints;
    }

    // Assists (max 20) - important but secondary to goals
    if (stats.assists != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final seasonAssistsPerGame = stats.assists! / stats.appearances!;
      final assistsPerGame = _blendStats(
        seasonAssistsPerGame,
        recent.assistsPerMatch,
      );
      // 0.25 assists/game = max points
      final assistPoints = (assistsPerGame / 0.25).clamp(0.0, 1.0) * 20;
      breakdown['Assists'] = assistPoints;
      total += assistPoints;
    }

    // Recent Form Bonus/Penalty (max ±15) - crucial for forwards
    final formBonus = (formScore - 50) / 3.3;
    breakdown['Recent Form (Last $recentMatchesCount)'] = formBonus.clamp(
      -15.0,
      15.0,
    );
    total += formBonus.clamp(-15.0, 15.0);

    // Goal contributions per 90 bonus (max 12) - efficiency metric
    if (stats.minutesPlayed != null && stats.minutesPlayed! > 0) {
      final seasonContributions = (stats.goals ?? 0) + (stats.assists ?? 0);
      final seasonPer90 = seasonContributions / (stats.minutesPlayed! / 90);
      final recentPer90 = recent.minutesPerMatch > 0
          ? recent.contributionsPerMatch * (90 / recent.minutesPerMatch)
          : seasonPer90;
      final per90 = _blendStats(seasonPer90, recentPer90);
      // 0.7 G+A per 90 = max points
      final per90Points = (per90 / 0.7).clamp(0.0, 1.0) * 12;
      breakdown['G+A per 90'] = per90Points;
      total += per90Points;
    }

    // Consistency bonus (max 5) - less important for strikers if they're scoring
    if (stats.lineups != null &&
        stats.appearances != null &&
        stats.appearances! > 0) {
      final startRate = stats.lineups! / stats.appearances!;
      final consistencyPoints = startRate * 5;
      breakdown['Consistency'] = consistencyPoints;
      total += consistencyPoints;
    }

    // Penalty for cards (less impactful for forwards)
    final seasonCardPenalty = _calculateCardPenalty(stats) * 0.7;
    final recentCardPenalty = recent.cardsPerMatch * 2;
    final cardPenalty = _blendStats(seasonCardPenalty, recentCardPenalty);
    if (cardPenalty > 0) {
      breakdown['Card Penalty'] = -cardPenalty.clamp(0.0, 8.0);
      total -= cardPenalty.clamp(0.0, 8.0);
    }

    // Opponent adjustment (most impactful for forwards)
    if (opponent != null) {
      breakdown['vs ${opponent.name}'] = opponentAdjustment;
      total += opponentAdjustment;
    }

    return FantasyPrediction(
      totalPoints: (total / 10).clamp(0.0, 10.0), // Convert to 0-10 scale
      breakdown: breakdown,
      confidence: _calculateConfidence(stats, recent),
      playerName: player.displayName,
      position: 'Forward',
      recentFormScore: formScore.round(),
      opponent: opponent,
    );
  }

  /// Calculate appearance rate (0-1)
  static double _calculateAppearanceRate(PlayerStatistics stats) {
    if (stats.appearances == null || stats.appearances == 0) return 0;
    // Assume 17 games in Liga MX tournament
    return (stats.appearances! / 17).clamp(0.0, 1.0);
  }

  /// Calculate card penalty (0-10)
  static double _calculateCardPenalty(PlayerStatistics stats) {
    final yellows = stats.yellowCards ?? 0;
    final reds = stats.redCards ?? 0;
    final yellowReds = stats.yellowRedCards ?? 0;

    final penalty = (yellows * 1.0) + (yellowReds * 2.5) + (reds * 3.0);
    return penalty.clamp(0.0, 10.0);
  }

  /// Calculate prediction confidence based on sample size
  static double _calculateConfidence(
    PlayerStatistics stats,
    RecentMatchStats recent,
  ) {
    final appearances = stats.appearances ?? 0;
    final minutes = stats.minutesPlayed ?? 0;
    final recentMatches = recent.matchesPlayed;

    double confidence = 0.25; // Base confidence

    if (recent.isLikelyInjuredOrBench) {
      return 0.35;
    }

    // Season stats confidence
    if (appearances >= 5) confidence += 0.1;
    if (appearances >= 10) confidence += 0.1;
    if (appearances >= 15) confidence += 0.05;

    if (minutes >= 450) confidence += 0.05;
    if (minutes >= 900) confidence += 0.05;

    // Recent form confidence boost
    if (recentMatches >= 3) confidence += 0.15;
    if (recentMatches >= 5) confidence += 0.15;

    // Strong recent-form signal should increase reliability even if the
    // upcoming matchup suppresses the final next-match projection.
    if (recentMatches >= 3 && recent.minutesPerMatch >= 60) confidence += 0.1;
    if ((recent.averageRating ?? 0) >= 7.2) confidence += 0.05;
    if ((recent.averageRating ?? 0) >= 7.8) confidence += 0.05;

    return confidence.clamp(0.35, 1.0);
  }
}

/// Position categories for prediction
enum PositionCategory { goalkeeper, defender, midfielder, forward }

/// Fantasy points prediction result (0-10 scale)
class FantasyPrediction {
  final double totalPoints; // Score on 0-10 scale
  final Map<String, double> breakdown;
  final double confidence;
  final String playerName;
  final String position;
  final int? recentFormScore;
  final OpponentInfo? opponent;

  const FantasyPrediction({
    required this.totalPoints,
    required this.breakdown,
    required this.confidence,
    required this.playerName,
    required this.position,
    this.recentFormScore,
    this.opponent,
  });

  /// Check if opponent analysis is included
  bool get hasOpponentAnalysis => opponent != null;

  /// Get rating tier based on points (0-10 scale)
  String get tier {
    if (totalPoints >= 8.5) return 'Elite';
    if (totalPoints >= 7.0) return 'Excellent';
    if (totalPoints >= 5.5) return 'Good';
    if (totalPoints >= 4.0) return 'Average';
    if (totalPoints >= 2.5) return 'Below Average';
    return 'Poor';
  }

  /// Get color for the rating (0-10 scale)
  int get tierColorValue {
    if (totalPoints >= 8.5) return 0xFFFFD700; // Gold
    if (totalPoints >= 7.0) return 0xFF4CAF50; // Green
    if (totalPoints >= 5.5) return 0xFF8BC34A; // Light Green
    if (totalPoints >= 4.0) return 0xFFFFC107; // Amber
    if (totalPoints >= 2.5) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Get confidence description
  String get confidenceDescription {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    if (confidence >= 0.4) return 'Low';
    return 'Very Low';
  }

  double get opponentImpact {
    if (opponent == null) return 0.0;

    for (final entry in breakdown.entries) {
      if (entry.key.startsWith('vs ')) return entry.value;
    }
    return 0.0;
  }

  bool get hasNegativeOpponentImpact => opponentImpact < -0.4;

  bool get hasStrongRecentForm =>
      recentFormScore != null && recentFormScore! >= 70;

  /// Get recent form description
  String get formDescription {
    if (recentFormScore == null) return 'N/A';
    if (recentFormScore! >= 70) return '🔥 Hot';
    if (recentFormScore! >= 55) return '📈 Good';
    if (recentFormScore! >= 45) return '➡️ Average';
    if (recentFormScore! >= 30) return '📉 Poor';
    return '❄️ Cold';
  }

  /// Get form color
  int get formColorValue {
    if (recentFormScore == null) return 0xFF9E9E9E;
    if (recentFormScore! >= 70) return 0xFFFF5722; // Deep Orange (hot)
    if (recentFormScore! >= 55) return 0xFF4CAF50; // Green
    if (recentFormScore! >= 45) return 0xFFFFC107; // Amber
    if (recentFormScore! >= 30) return 0xFFFF9800; // Orange
    return 0xFF2196F3; // Blue (cold)
  }

  /// Get top 3 contributing factors
  List<MapEntry<String, double>> get topFactors {
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return sorted.take(3).toList();
  }
}
