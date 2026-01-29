import 'package:fantacy11/features/player/models/player_info.dart';

/// Recent match statistics for form calculation
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
  });
  
  /// Returns true if player appears to be injured or warming the bench
  /// (fixtures were analyzed but player didn't play in any)
  bool get isLikelyInjuredOrBench => 
      fixturesAnalyzed != null && fixturesAnalyzed! > 0 && matchesPlayed == 0;

  /// Create from a list of match data (simulated from season stats)
  /// In a real scenario, this would come from per-match API data
  factory RecentMatchStats.fromSeasonStats(PlayerStatistics stats, {int recentMatches = 5}) {
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
  double get minutesPerMatch => matchesPlayed > 0 ? minutesPlayed / matchesPlayed : 0;

  /// Clean sheet rate
  double get cleanSheetRate => matchesPlayed > 0 ? cleanSheets / matchesPlayed : 0;

  /// Cards per match (weighted: yellow=1, red=3)
  double get cardsPerMatch => matchesPlayed > 0 ? (yellowCards + redCards * 3) / matchesPlayed : 0;
}

/// Opponent information for matchup analysis
class OpponentInfo {
  final String name;
  final String? logoUrl;
  final int? leaguePosition;        // 1 = top of league
  final int? gamesPlayed;
  final int? goalsScored;           // Total goals scored
  final int? goalsConceded;         // Total goals conceded
  final int? cleanSheets;           // Clean sheets kept
  final int? wins;
  final int? draws;
  final int? losses;
  final bool isHomeGame;            // Is the player's team playing at home?
  final DateTime? matchDateTime;    // When the match is scheduled
  final String? venueName;          // Stadium name

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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  static String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Goals conceded per game (defensive strength - lower is better defense)
  double get goalsConcededPerGame {
    if (gamesPlayed == null || gamesPlayed == 0 || goalsConceded == null) return 1.0;
    return goalsConceded! / gamesPlayed!;
  }

  /// Goals scored per game (attacking strength)
  double get goalsScoredPerGame {
    if (gamesPlayed == null || gamesPlayed == 0 || goalsScored == null) return 1.0;
    return goalsScored! / gamesPlayed!;
  }

  /// Clean sheet rate (higher = better defense)
  double get cleanSheetRate {
    if (gamesPlayed == null || gamesPlayed == 0 || cleanSheets == null) return 0.3;
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
  int get overallDifficulty => ((defensiveRating + attackingRating) / 2).round();

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
        totalPoints: 50, // Average default
        breakdown: {
          'No statistics available': 50.0,
        },
        confidence: 0.3,
        playerName: player.displayName,
        position: player.position?.name ?? 'Unknown',
        recentFormScore: null,
        opponent: opponent,
      );
    }

    // Calculate recent form from season stats if not provided
    final recent = recentForm ?? RecentMatchStats.fromSeasonStats(stats, recentMatches: recentMatchesCount);

    // Determine position category
    final positionCategory = _getPositionCategory(position, player.position?.code);
    
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
    
    return (adjustment + homeBonus).clamp(-maxOpponentAdjustment, maxOpponentAdjustment);
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
    
    return (adjustment + homeBonus).clamp(-maxOpponentAdjustment, maxOpponentAdjustment);
  }

  static PositionCategory _getPositionCategory(String position, String? code) {
    final pos = position.toLowerCase();
    final c = code?.toLowerCase() ?? '';
    
    if (c == 'g' || pos.contains('goalkeeper') || pos.contains('portero')) {
      return PositionCategory.goalkeeper;
    } else if (c == 'd' || pos.contains('defender') || pos.contains('back') || pos.contains('defensa')) {
      return PositionCategory.defender;
    } else if (c == 'm' || pos.contains('midfielder') || pos.contains('medio')) {
      return PositionCategory.midfielder;
    } else {
      return PositionCategory.forward;
    }
  }

  /// Blend season and recent form stats
  static double _blendStats(double seasonValue, double recentValue) {
    return (seasonValue * (1 - recentFormWeight)) + (recentValue * recentFormWeight);
  }

  /// Calculate recent form score (0-100)
  /// 
  /// Form scoring:
  /// - 0: Player is injured or bench warmer (no playtime in last 6 weeks)
  /// - 25: Very low form (few minutes, no contributions)
  /// - 50: Average/neutral form
  /// - 75+: Great form (regular starter with good contributions)
  static double _calculateFormScore(RecentMatchStats recent, PositionCategory position) {
    // Check if player is injured or bench warmer (fixtures analyzed but didn't play)
    if (recent.isLikelyInjuredOrBench) {
      return 0.0; // Severely penalize - player unlikely to play
    }
    
    // No data available - use neutral score
    if (recent.matchesPlayed == 0) {
      return 50.0;
    }

    double score = 50.0; // Base score

    // Playing time factor - heavily weighted
    // Regular starter (80+ mins avg) = +15, sub (30 mins avg) = +5
    final playingTimeFactor = (recent.minutesPerMatch / 90).clamp(0.0, 1.0);
    score += playingTimeFactor * 15;
    
    // Participation rate bonus (played in most of the analyzed fixtures)
    if (recent.fixturesAnalyzed != null && recent.fixturesAnalyzed! > 0) {
      final participationRate = recent.matchesPlayed / recent.fixturesAnalyzed!;
      score += participationRate * 10; // Max +10 for playing every game
    }

    // Position-specific factors
    switch (position) {
      case PositionCategory.goalkeeper:
        score += recent.cleanSheetRate * 25;
        score += (recent.saves / recent.matchesPlayed / 4).clamp(0.0, 1.0) * 15;
        break;
      case PositionCategory.defender:
        score += recent.cleanSheetRate * 20;
        score += recent.goalsPerMatch * 30; // Goals are rare/valuable
        score += recent.assistsPerMatch * 15;
        break;
      case PositionCategory.midfielder:
        score += recent.goalsPerMatch * 25;
        score += recent.assistsPerMatch * 25;
        break;
      case PositionCategory.forward:
        score += recent.goalsPerMatch * 35;
        score += recent.assistsPerMatch * 20;
        break;
    }

    // Card penalty
    score -= recent.cardsPerMatch * 5;

    return score.clamp(0.0, 100.0);
  }

  /// Predict for Goalkeeper
  static FantasyPrediction _predictGoalkeeper(Player player, PlayerStatistics stats, RecentMatchStats recent, OpponentInfo? opponent) {
    final breakdown = <String, double>{};
    double total = 0;

    // Calculate form score
    final formScore = _calculateFormScore(recent, PositionCategory.goalkeeper);
    
    // Calculate opponent adjustment (defensive-focused for GK)
    final opponentAdjustment = _calculateDefensiveOpponentAdjustment(opponent);

    // Base points for playing (max 15)
    final seasonAppearanceRate = _calculateAppearanceRate(stats);
    final recentPlayingRate = recent.matchesPlayed > 0 ? (recent.minutesPerMatch / 90).clamp(0.0, 1.0) : seasonAppearanceRate;
    final playingPoints = _blendStats(seasonAppearanceRate, recentPlayingRate) * 15;
    breakdown['Playing Time'] = playingPoints;
    total += playingPoints;

    // Clean sheets (max 35) - most important for GK
    if (stats.cleanSheets != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonCleanSheetRate = stats.cleanSheets! / stats.appearances!;
      final recentCleanSheetRate = recent.cleanSheetRate;
      final cleanSheetPoints = _blendStats(seasonCleanSheetRate, recentCleanSheetRate) * 35;
      breakdown['Clean Sheets'] = cleanSheetPoints;
      total += cleanSheetPoints;
    }

    // Saves (max 25)
    if (stats.saves != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonSavesPerGame = stats.saves! / stats.appearances!;
      final recentSavesPerGame = recent.matchesPlayed > 0 ? recent.saves / recent.matchesPlayed : seasonSavesPerGame;
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
    if (stats.lineups != null && stats.appearances != null && stats.appearances! > 0) {
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
      totalPoints: total.clamp(0.0, 100.0).round(),
      breakdown: breakdown,
      confidence: _calculateConfidence(stats, recent),
      playerName: player.displayName,
      position: 'Goalkeeper',
      recentFormScore: formScore.round(),
      opponent: opponent,
    );
  }

  /// Predict for Defender
  static FantasyPrediction _predictDefender(Player player, PlayerStatistics stats, RecentMatchStats recent, OpponentInfo? opponent) {
    final breakdown = <String, double>{};
    double total = 0;

    final formScore = _calculateFormScore(recent, PositionCategory.defender);
    
    // Defenders benefit from both defensive and some attacking adjustments
    final defenseAdjustment = _calculateDefensiveOpponentAdjustment(opponent) * 0.7;
    final attackAdjustment = _calculateAttackingOpponentAdjustment(opponent) * 0.3;
    final opponentAdjustment = defenseAdjustment + attackAdjustment;

    // Base points for playing (max 12)
    final seasonAppearanceRate = _calculateAppearanceRate(stats);
    final recentPlayingRate = recent.matchesPlayed > 0 ? (recent.minutesPerMatch / 90).clamp(0.0, 1.0) : seasonAppearanceRate;
    final playingPoints = _blendStats(seasonAppearanceRate, recentPlayingRate) * 12;
    breakdown['Playing Time'] = playingPoints;
    total += playingPoints;

    // Clean sheets (max 25)
    if (stats.cleanSheets != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonCleanSheetRate = stats.cleanSheets! / stats.appearances!;
      final cleanSheetPoints = _blendStats(seasonCleanSheetRate, recent.cleanSheetRate) * 25;
      breakdown['Clean Sheets'] = cleanSheetPoints;
      total += cleanSheetPoints;
    }

    // Goals (max 20)
    if (stats.goals != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonGoalsPerGame = stats.goals! / stats.appearances!;
      final goalsPerGame = _blendStats(seasonGoalsPerGame, recent.goalsPerMatch);
      final goalPoints = (goalsPerGame / 0.15).clamp(0.0, 1.0) * 20;
      breakdown['Goals'] = goalPoints;
      total += goalPoints;
    }

    // Assists (max 15)
    if (stats.assists != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonAssistsPerGame = stats.assists! / stats.appearances!;
      final assistsPerGame = _blendStats(seasonAssistsPerGame, recent.assistsPerMatch);
      final assistPoints = (assistsPerGame / 0.12).clamp(0.0, 1.0) * 15;
      breakdown['Assists'] = assistPoints;
      total += assistPoints;
    }

    // Recent Form Bonus/Penalty (max ±12)
    final formBonus = (formScore - 50) / 4;
    breakdown['Recent Form (Last $recentMatchesCount)'] = formBonus.clamp(-12.0, 12.0);
    total += formBonus.clamp(-12.0, 12.0);

    // Consistency bonus (max 8)
    if (stats.lineups != null && stats.appearances != null && stats.appearances! > 0) {
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
      totalPoints: total.clamp(0.0, 100.0).round(),
      breakdown: breakdown,
      confidence: _calculateConfidence(stats, recent),
      playerName: player.displayName,
      position: 'Defender',
      recentFormScore: formScore.round(),
      opponent: opponent,
    );
  }

  /// Predict for Midfielder
  static FantasyPrediction _predictMidfielder(Player player, PlayerStatistics stats, RecentMatchStats recent, OpponentInfo? opponent) {
    final breakdown = <String, double>{};
    double total = 0;

    final formScore = _calculateFormScore(recent, PositionCategory.midfielder);
    
    // Midfielders: balanced between attacking and defensive adjustments
    final attackAdjustment = _calculateAttackingOpponentAdjustment(opponent) * 0.6;
    final defenseAdjustment = _calculateDefensiveOpponentAdjustment(opponent) * 0.4;
    final opponentAdjustment = attackAdjustment + defenseAdjustment;

    // Base points for playing (max 10)
    final seasonAppearanceRate = _calculateAppearanceRate(stats);
    final recentPlayingRate = recent.matchesPlayed > 0 ? (recent.minutesPerMatch / 90).clamp(0.0, 1.0) : seasonAppearanceRate;
    final playingPoints = _blendStats(seasonAppearanceRate, recentPlayingRate) * 10;
    breakdown['Playing Time'] = playingPoints;
    total += playingPoints;

    // Goals (max 28)
    if (stats.goals != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonGoalsPerGame = stats.goals! / stats.appearances!;
      final goalsPerGame = _blendStats(seasonGoalsPerGame, recent.goalsPerMatch);
      final goalPoints = (goalsPerGame / 0.35).clamp(0.0, 1.0) * 28;
      breakdown['Goals'] = goalPoints;
      total += goalPoints;
    }

    // Assists (max 26)
    if (stats.assists != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonAssistsPerGame = stats.assists! / stats.appearances!;
      final assistsPerGame = _blendStats(seasonAssistsPerGame, recent.assistsPerMatch);
      final assistPoints = (assistsPerGame / 0.30).clamp(0.0, 1.0) * 26;
      breakdown['Assists'] = assistPoints;
      total += assistPoints;
    }

    // Recent Form Bonus/Penalty (max ±15) - very important for midfielders
    final formBonus = (formScore - 50) / 3.3;
    breakdown['Recent Form (Last $recentMatchesCount)'] = formBonus.clamp(-15.0, 15.0);
    total += formBonus.clamp(-15.0, 15.0);

    // Minutes played bonus (max 10)
    if (stats.minutesPlayed != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonMinsPerGame = stats.minutesPlayed! / stats.appearances!;
      final minsPerGame = _blendStats(seasonMinsPerGame, recent.minutesPerMatch);
      final minutesPoints = (minsPerGame / 75).clamp(0.0, 1.0) * 10;
      breakdown['Minutes Played'] = minutesPoints;
      total += minutesPoints;
    }

    // Consistency bonus (max 8)
    if (stats.lineups != null && stats.appearances != null && stats.appearances! > 0) {
      final startRate = stats.lineups! / stats.appearances!;
      final consistencyPoints = startRate * 8;
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
      totalPoints: total.clamp(0.0, 100.0).round(),
      breakdown: breakdown,
      confidence: _calculateConfidence(stats, recent),
      playerName: player.displayName,
      position: 'Midfielder',
      recentFormScore: formScore.round(),
      opponent: opponent,
    );
  }

  /// Predict for Forward
  static FantasyPrediction _predictForward(Player player, PlayerStatistics stats, RecentMatchStats recent, OpponentInfo? opponent) {
    final breakdown = <String, double>{};
    double total = 0;

    final formScore = _calculateFormScore(recent, PositionCategory.forward);
    
    // Forwards: primarily affected by opponent's defensive strength
    final opponentAdjustment = _calculateAttackingOpponentAdjustment(opponent);

    // Base points for playing (max 8)
    final seasonAppearanceRate = _calculateAppearanceRate(stats);
    final recentPlayingRate = recent.matchesPlayed > 0 ? (recent.minutesPerMatch / 90).clamp(0.0, 1.0) : seasonAppearanceRate;
    final playingPoints = _blendStats(seasonAppearanceRate, recentPlayingRate) * 8;
    breakdown['Playing Time'] = playingPoints;
    total += playingPoints;

    // Goals (max 35) - most important for forwards
    if (stats.goals != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonGoalsPerGame = stats.goals! / stats.appearances!;
      final goalsPerGame = _blendStats(seasonGoalsPerGame, recent.goalsPerMatch);
      final goalPoints = (goalsPerGame / 0.5).clamp(0.0, 1.0) * 35;
      breakdown['Goals'] = goalPoints;
      total += goalPoints;
    }

    // Assists (max 22)
    if (stats.assists != null && stats.appearances != null && stats.appearances! > 0) {
      final seasonAssistsPerGame = stats.assists! / stats.appearances!;
      final assistsPerGame = _blendStats(seasonAssistsPerGame, recent.assistsPerMatch);
      final assistPoints = (assistsPerGame / 0.25).clamp(0.0, 1.0) * 22;
      breakdown['Assists'] = assistPoints;
      total += assistPoints;
    }

    // Recent Form Bonus/Penalty (max ±18) - crucial for forwards
    final formBonus = (formScore - 50) / 2.8;
    breakdown['Recent Form (Last $recentMatchesCount)'] = formBonus.clamp(-18.0, 18.0);
    total += formBonus.clamp(-18.0, 18.0);

    // Goal contributions per 90 bonus (max 10)
    if (stats.minutesPlayed != null && stats.minutesPlayed! > 0) {
      final seasonContributions = (stats.goals ?? 0) + (stats.assists ?? 0);
      final seasonPer90 = seasonContributions / (stats.minutesPlayed! / 90);
      final recentPer90 = recent.minutesPerMatch > 0 
          ? recent.contributionsPerMatch * (90 / recent.minutesPerMatch)
          : seasonPer90;
      final per90 = _blendStats(seasonPer90, recentPer90);
      final per90Points = (per90 / 0.8).clamp(0.0, 1.0) * 10;
      breakdown['G+A per 90'] = per90Points;
      total += per90Points;
    }

    // Consistency bonus (max 6)
    if (stats.lineups != null && stats.appearances != null && stats.appearances! > 0) {
      final startRate = stats.lineups! / stats.appearances!;
      final consistencyPoints = startRate * 6;
      breakdown['Consistency'] = consistencyPoints;
      total += consistencyPoints;
    }

    // Penalty for cards
    final seasonCardPenalty = _calculateCardPenalty(stats) * 0.8;
    final recentCardPenalty = recent.cardsPerMatch * 2.5;
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
      totalPoints: total.clamp(0.0, 100.0).round(),
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
  static double _calculateConfidence(PlayerStatistics stats, RecentMatchStats recent) {
    final appearances = stats.appearances ?? 0;
    final minutes = stats.minutesPlayed ?? 0;
    final recentMatches = recent.matchesPlayed;
    
    double confidence = 0.25; // Base confidence
    
    // Season stats confidence
    if (appearances >= 5) confidence += 0.1;
    if (appearances >= 10) confidence += 0.1;
    if (appearances >= 15) confidence += 0.05;
    
    if (minutes >= 450) confidence += 0.05;
    if (minutes >= 900) confidence += 0.05;
    
    // Recent form confidence boost
    if (recentMatches >= 3) confidence += 0.15;
    if (recentMatches >= 5) confidence += 0.15;
    
    return confidence.clamp(0.25, 1.0);
  }
}

/// Position categories for prediction
enum PositionCategory {
  goalkeeper,
  defender,
  midfielder,
  forward,
}

/// Fantasy points prediction result
class FantasyPrediction {
  final int totalPoints;
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

  /// Get rating tier based on points
  String get tier {
    if (totalPoints >= 85) return 'Elite';
    if (totalPoints >= 70) return 'Excellent';
    if (totalPoints >= 55) return 'Good';
    if (totalPoints >= 40) return 'Average';
    if (totalPoints >= 25) return 'Below Average';
    return 'Poor';
  }

  /// Get color for the rating
  int get tierColorValue {
    if (totalPoints >= 85) return 0xFFFFD700; // Gold
    if (totalPoints >= 70) return 0xFF4CAF50; // Green
    if (totalPoints >= 55) return 0xFF8BC34A; // Light Green
    if (totalPoints >= 40) return 0xFFFFC107; // Amber
    if (totalPoints >= 25) return 0xFFFF9800; // Orange
    return 0xFFF44336; // Red
  }

  /// Get confidence description
  String get confidenceDescription {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.6) return 'Medium';
    if (confidence >= 0.4) return 'Low';
    return 'Very Low';
  }

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
