import 'package:intl/intl.dart';

/// Player performance in a specific match
class PlayerMatchPerformance {
  final int playerId;
  final String playerName;
  final String? playerImageUrl;
  final int teamId;
  final String teamName;
  final String position; // GK, DEF, MID, FWD
  final int? jerseyNumber;
  final bool isStarter;
  final int minutesPlayed;
  final double? rating;
  
  /// Formation field from SportMonks API - format is "line:position"
  /// Line 1 = GK, Line 2 = DEF, Line 3-4 = MID, Line 5 = FWD
  /// Position is horizontal spot (1 = center/right, increases to left)
  final String? formationField;
  
  /// Parsed line number from formation_field (1-5)
  final int? formationLine;
  
  /// Parsed position within line from formation_field
  final int? formationPosition;
  
  // Basic stats
  final int goals;
  final int assists;
  final int yellowCards;
  final int redCards;
  final int saves;
  
  // Advanced stats
  final int? shotsTotal;
  final int? shotsOnTarget;
  final int? passes;
  final int? passAccuracy;
  final int? keyPasses;
  final int? tackles;
  final int? interceptions;
  final int? clearances;
  final int? blocks;
  final int? duelsWon;
  final int? duelsTotal;
  final int? aerialsWon;
  final int? fouls;
  final int? foulsDrawn;
  final int? dribbles;
  final int? dribblesWon;
  final int? crosses;
  final int? crossesAccurate;
  final int? longBalls;
  final int? longBallsAccurate;
  final int? offsides;
  final int? dispossessed;
  
  // Substitution info
  final int? subInMinute;
  final int? subOutMinute;
  
  const PlayerMatchPerformance({
    required this.playerId,
    required this.playerName,
    this.playerImageUrl,
    required this.teamId,
    required this.teamName,
    required this.position,
    this.jerseyNumber,
    this.isStarter = false,
    this.minutesPlayed = 0,
    this.rating,
    this.formationField,
    this.formationLine,
    this.formationPosition,
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.saves = 0,
    this.shotsTotal,
    this.shotsOnTarget,
    this.passes,
    this.passAccuracy,
    this.keyPasses,
    this.tackles,
    this.interceptions,
    this.clearances,
    this.blocks,
    this.duelsWon,
    this.duelsTotal,
    this.fouls,
    this.foulsDrawn,
    this.dribbles,
    this.dribblesWon,
    this.crosses,
    this.crossesAccurate,
    this.longBalls,
    this.longBallsAccurate,
    this.offsides,
    this.dispossessed,
    this.aerialsWon,
    this.subInMinute,
    this.subOutMinute,
  });
  
  /// Get rating color value as ARGB int
  int get ratingColorValue {
    if (rating == null) return 0xFF9E9E9E; // Grey
    if (rating! >= 8.0) return 0xFF4CAF50; // Green - Excellent
    if (rating! >= 7.0) return 0xFF8BC34A; // Light Green - Good
    if (rating! >= 6.0) return 0xFFFFEB3B; // Yellow - Average
    if (rating! >= 5.0) return 0xFFFF9800; // Orange - Below average
    return 0xFFF44336; // Red - Poor
  }
  
  /// Get formatted rating string
  String get formattedRating => rating?.toStringAsFixed(1) ?? '-';
  
  /// Check if player has meaningful stats
  bool get hasStats => minutesPlayed > 0 || goals > 0 || assists > 0;
  
  /// Get goal contributions
  int get goalContributions => goals + assists;
  
  factory PlayerMatchPerformance.fromLineupData(
    Map<String, dynamic> lineup,
    Map<String, dynamic>? playerData,
    int teamId,
    String teamName,
  ) {
    final playerId = lineup['player_id'] as int? ?? 0;
    final isStarter = lineup['type_id'] == 11;
    
    // Extract formation_field for pitch positioning
    // Format: "line:position" (e.g., "3:1" = line 3, position 1)
    final formationField = lineup['formation_field'] as String?;
    int? formationLine;
    int? formationPosition;
    
    if (formationField != null && formationField.contains(':')) {
      final parts = formationField.split(':');
      if (parts.length == 2) {
        formationLine = int.tryParse(parts[0]);
        formationPosition = int.tryParse(parts[1]);
      }
    }
    
    // Extract player info
    String playerName = 'Unknown';
    String? playerImageUrl;
    int? jerseyNumber;
    String? detectedPosition;
    
    if (playerData != null) {
      playerName = playerData['display_name'] ?? 
                   playerData['common_name'] ?? 
                   playerData['name'] ?? 
                   'Unknown';
      playerImageUrl = playerData['image_path'] as String?;
      jerseyNumber = playerData['jersey_number'] as int?;
      
      // Extract position from various possible fields
      final posData = playerData['position'] as Map<String, dynamic>?;
      if (posData != null) {
        final posCode = posData['code']?.toString() ?? '';
        final posName = posData['name']?.toString() ?? '';
        if (posCode.isNotEmpty) {
          detectedPosition = _normalizePosition(posCode);
        } else if (posName.isNotEmpty) {
          detectedPosition = _normalizePosition(posName);
        }
      }
      
      // Check detailed_position as fallback
      final detailedPos = playerData['detailed_position'] as Map<String, dynamic>?;
      if (detectedPosition == null && detailedPos != null) {
        final posCode = detailedPos['code']?.toString() ?? '';
        final posName = detailedPos['name']?.toString() ?? '';
        if (posCode.isNotEmpty) {
          detectedPosition = _normalizePosition(posCode);
        } else if (posName.isNotEmpty) {
          detectedPosition = _normalizePosition(posName);
        }
      }
      
      // Check position_id to map to position
      if (detectedPosition == null) {
        final positionId = playerData['position_id'] as int?;
        if (positionId != null) {
          detectedPosition = _positionFromId(positionId);
        }
      }
    }
    
    // Also check lineup meta for player info
    final player = lineup['player'] as Map<String, dynamic>?;
    if (player != null) {
      playerName = player['display_name'] ?? player['common_name'] ?? playerName;
      playerImageUrl = player['image_path'] ?? playerImageUrl;
      
      // Try to extract position if not already found
      if (detectedPosition == null) {
        final posData = player['position'] as Map<String, dynamic>?;
        if (posData != null) {
          final posCode = posData['code']?.toString() ?? '';
          final posName = posData['name']?.toString() ?? '';
          if (posCode.isNotEmpty) {
            detectedPosition = _normalizePosition(posCode);
          } else if (posName.isNotEmpty) {
            detectedPosition = _normalizePosition(posName);
          }
        }
        
        // Check detailed_position
        final detailedPos = player['detailed_position'] as Map<String, dynamic>?;
        if (detectedPosition == null && detailedPos != null) {
          final posCode = detailedPos['code']?.toString() ?? '';
          final posName = detailedPos['name']?.toString() ?? '';
          if (posCode.isNotEmpty) {
            detectedPosition = _normalizePosition(posCode);
          } else if (posName.isNotEmpty) {
            detectedPosition = _normalizePosition(posName);
          }
        }
        
        // Check position_id
        if (detectedPosition == null) {
          final positionId = player['position_id'] as int? ?? player['detailedposition_id'] as int?;
          if (positionId != null) {
            detectedPosition = _positionFromId(positionId);
          }
        }
      }
    }
    
    // Infer position from formation line if not detected
    // Line 1 = GK, Line 2 = DEF, middle lines = MID, last line = FWD
    if (detectedPosition == null && formationLine != null) {
      detectedPosition = _positionFromFormationLine(formationLine);
    }
    
    // Default to MID if nothing else worked
    final position = detectedPosition ?? 'MID';
    
    // Extract stats from details
    int minutesPlayed = 0;
    double? rating;
    int goals = 0, assists = 0, yellowCards = 0, redCards = 0, saves = 0;
    int? shotsTotal, shotsOnTarget, passes, passAccuracy, keyPasses;
    int? tackles, interceptions, clearances, blocks;
    int? duelsWon, duelsTotal, aerialsWon, fouls, foulsDrawn;
    int? dribbles, dribblesWon, crosses, crossesAccurate;
    int? longBalls, longBallsAccurate, offsides, dispossessed;
    
    final details = lineup['details'] as List?;
    if (details != null) {
      for (final detail in details) {
        if (detail is! Map<String, dynamic>) continue;
        
        final type = detail['type'] as Map<String, dynamic>?;
        final devName = type?['developer_name']?.toString().toUpperCase() ?? '';
        final code = type?['code']?.toString().toUpperCase() ?? '';
        
        final data = detail['data'] as Map<String, dynamic>?;
        final value = data?['value'] ?? detail['value'];
        
        final statName = devName.isNotEmpty ? devName : code;
        
        switch (statName) {
          case 'MINUTES_PLAYED':
          case 'MINUTES':
            minutesPlayed = _parseInt(value) ?? 0;
            break;
          case 'RATING':
            rating = _parseDouble(value);
            break;
          case 'GOALS':
            goals = _parseInt(value) ?? 0;
            break;
          case 'ASSISTS':
            assists = _parseInt(value) ?? 0;
            break;
          case 'YELLOWCARDS':
          case 'YELLOW_CARDS':
            yellowCards = _parseInt(value) ?? 0;
            break;
          case 'REDCARDS':
          case 'RED_CARDS':
            redCards = _parseInt(value) ?? 0;
            break;
          case 'SAVES':
            saves = _parseInt(value) ?? 0;
            break;
          case 'SHOTS_TOTAL':
          case 'SHOTS':
            shotsTotal = _parseInt(value);
            break;
          case 'SHOTS_ON_TARGET':
          case 'SHOTS_ON_GOAL':
            shotsOnTarget = _parseInt(value);
            break;
          case 'PASSES':
          case 'TOTAL_PASSES':
            passes = _parseInt(value);
            break;
          case 'PASSES_ACCURACY':
          case 'PASS_ACCURACY':
            passAccuracy = _parseInt(value);
            break;
          case 'KEY_PASSES':
            keyPasses = _parseInt(value);
            break;
          case 'TACKLES':
            tackles = _parseInt(value);
            break;
          case 'INTERCEPTIONS':
            interceptions = _parseInt(value);
            break;
          case 'CLEARANCES':
            clearances = _parseInt(value);
            break;
          case 'BLOCKS':
            blocks = _parseInt(value);
            break;
          case 'DUELS_WON':
            duelsWon = _parseInt(value);
            break;
          case 'DUELS_TOTAL':
          case 'DUELS':
            duelsTotal = _parseInt(value);
            break;
          case 'AERIALS_WON':
            aerialsWon = _parseInt(value);
            break;
          case 'FOULS':
          case 'FOULS_COMMITTED':
            fouls = _parseInt(value);
            break;
          case 'FOULS_DRAWN':
            foulsDrawn = _parseInt(value);
            break;
          case 'DRIBBLES':
          case 'DRIBBLES_ATTEMPTS':
            dribbles = _parseInt(value);
            break;
          case 'DRIBBLES_SUCCESS':
          case 'DRIBBLES_WON':
            dribblesWon = _parseInt(value);
            break;
          case 'CROSSES':
          case 'TOTAL_CROSSES':
            crosses = _parseInt(value);
            break;
          case 'CROSSES_ACCURATE':
          case 'ACCURATE_CROSSES':
            crossesAccurate = _parseInt(value);
            break;
          case 'LONG_BALLS':
          case 'TOTAL_LONG_BALLS':
            longBalls = _parseInt(value);
            break;
          case 'LONG_BALLS_ACCURATE':
          case 'ACCURATE_LONG_BALLS':
            longBallsAccurate = _parseInt(value);
            break;
          case 'OFFSIDES':
            offsides = _parseInt(value);
            break;
          case 'DISPOSSESSED':
            dispossessed = _parseInt(value);
            break;
        }
      }
    }
    
    // Default minutes for starters if not found
    if (minutesPlayed == 0 && isStarter) {
      minutesPlayed = 90;
    }
    
    return PlayerMatchPerformance(
      playerId: playerId,
      playerName: playerName,
      playerImageUrl: playerImageUrl,
      teamId: teamId,
      teamName: teamName,
      position: position,
      jerseyNumber: jerseyNumber,
      isStarter: isStarter,
      minutesPlayed: minutesPlayed,
      rating: rating,
      formationField: formationField,
      formationLine: formationLine,
      formationPosition: formationPosition,
      goals: goals,
      assists: assists,
      yellowCards: yellowCards,
      redCards: redCards,
      saves: saves,
      shotsTotal: shotsTotal,
      shotsOnTarget: shotsOnTarget,
      passes: passes,
      passAccuracy: passAccuracy,
      keyPasses: keyPasses,
      tackles: tackles,
      interceptions: interceptions,
      clearances: clearances,
      blocks: blocks,
      duelsWon: duelsWon,
      duelsTotal: duelsTotal,
      aerialsWon: aerialsWon,
      fouls: fouls,
      foulsDrawn: foulsDrawn,
      dribbles: dribbles,
      dribblesWon: dribblesWon,
      crosses: crosses,
      crossesAccurate: crossesAccurate,
      longBalls: longBalls,
      longBallsAccurate: longBallsAccurate,
      offsides: offsides,
      dispossessed: dispossessed,
    );
  }
  
  /// Map position_id to position string
  /// SportMonks uses these IDs: 24 = GK, 25 = DEF, 26 = MID, 27 = FWD (main positions)
  /// Also handles detailed position IDs
  static String? _positionFromId(int positionId) {
    // Main positions
    if (positionId == 24 || positionId == 1) return 'GK';
    if (positionId == 25 || positionId == 2) return 'DEF';
    if (positionId == 26 || positionId == 3) return 'MID';
    if (positionId == 27 || positionId == 4) return 'FWD';
    
    // Detailed positions - Goalkeepers
    if (positionId >= 148 && positionId <= 152) return 'GK';
    
    // Detailed positions - Defenders
    if (positionId >= 153 && positionId <= 162) return 'DEF';
    
    // Detailed positions - Midfielders
    if (positionId >= 163 && positionId <= 175) return 'MID';
    
    // Detailed positions - Forwards
    if (positionId >= 176 && positionId <= 183) return 'FWD';
    
    return null;
  }
  
  /// Infer position from formation line number
  static String _positionFromFormationLine(int line) {
    if (line == 1) return 'GK';
    if (line == 2) return 'DEF';
    // Most formations have 3-5 lines, assume last line is FWD
    // and anything in between is MID
    if (line >= 5) return 'FWD'; // For 4-2-3-1 type formations
    if (line == 4) return 'FWD'; // For 4-3-3 type formations (or could be MID)
    return 'MID'; // Lines 3-4 are typically MID
  }
  
  static String _normalizePosition(String code) {
    final normalizedCode = code.toUpperCase().trim();
    
    // Handle exact matches first
    switch (normalizedCode) {
      case 'G':
      case 'GK':
      case 'GOALKEEPER':
      case 'GOALIE':
      case 'PORTERO':
        return 'GK';
      case 'D':
      case 'DF':
      case 'DEF':
      case 'DEFENDER':
      case 'CB': // Center Back
      case 'LB': // Left Back
      case 'RB': // Right Back
      case 'SW': // Sweeper
      case 'DEFENSOR':
        return 'DEF';
      case 'M':
      case 'MF':
      case 'MID':
      case 'MIDFIELDER':
      case 'CM': // Central Midfielder
      case 'LM': // Left Midfielder
      case 'RM': // Right Midfielder
      case 'DM': // Defensive Midfielder
      case 'AM': // Attacking Midfielder
      case 'CDM':
      case 'CAM':
      case 'MEDIOCAMPISTA':
        return 'MID';
      case 'F':
      case 'FW':
      case 'FWD':
      case 'A':
      case 'AT':
      case 'ATT':
      case 'ST': // Striker
      case 'CF': // Center Forward
      case 'LW': // Left Wing
      case 'RW': // Right Wing
      case 'SS': // Second Striker
      case 'ATTACKER':
      case 'FORWARD':
      case 'STRIKER':
      case 'DELANTERO':
        return 'FWD';
    }
    
    // Handle partial matches for flexibility
    if (normalizedCode.contains('GOAL') || normalizedCode.contains('KEEPER') || normalizedCode.contains('PORTER')) {
      return 'GK';
    }
    if (normalizedCode.contains('DEF') || normalizedCode.contains('BACK')) {
      return 'DEF';
    }
    if (normalizedCode.contains('FORWARD') || normalizedCode.contains('ATTACK') || normalizedCode.contains('STRIKE') || normalizedCode.contains('WING')) {
      return 'FWD';
    }
    if (normalizedCode.contains('MID')) {
      return 'MID';
    }
    
    // Default to MID for unknown positions
    return 'MID';
  }
  
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Team lineup for a match
class TeamLineup {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final String formation;
  final List<PlayerMatchPerformance> starters;
  final List<PlayerMatchPerformance> substitutes;
  final String? coachName;
  final String? coachImageUrl;
  
  const TeamLineup({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.formation = '4-4-2',
    this.starters = const [],
    this.substitutes = const [],
    this.coachName,
    this.coachImageUrl,
  });
  
  /// Get all players (starters + subs)
  List<PlayerMatchPerformance> get allPlayers => [...starters, ...substitutes];
  
  /// Get starters by position
  List<PlayerMatchPerformance> get goalkeepers => 
      starters.where((p) => p.position == 'GK').toList();
  List<PlayerMatchPerformance> get defenders => 
      starters.where((p) => p.position == 'DEF').toList();
  List<PlayerMatchPerformance> get midfielders => 
      starters.where((p) => p.position == 'MID').toList();
  List<PlayerMatchPerformance> get forwards => 
      starters.where((p) => p.position == 'FWD').toList();
  
  /// Get average team rating
  double? get averageRating {
    final ratings = starters.where((p) => p.rating != null).map((p) => p.rating!).toList();
    if (ratings.isEmpty) return null;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
  
  /// Get total goals
  int get totalGoals => starters.fold(0, (sum, p) => sum + p.goals);
}

/// Completed match with full details
class CompletedMatch {
  final int fixtureId;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int homeTeamId;
  final int awayTeamId;
  final int homeScore;
  final int awayScore;
  final String leagueName;
  final DateTime matchDate;
  final String? venueName;
  final String? venueCity;
  final TeamLineup? homeLineup;
  final TeamLineup? awayLineup;
  
  const CompletedMatch({
    required this.fixtureId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeScore,
    required this.awayScore,
    required this.leagueName,
    required this.matchDate,
    this.venueName,
    this.venueCity,
    this.homeLineup,
    this.awayLineup,
  });
  
  /// Get formatted date
  String get formattedDate => DateFormat('EEE, MMM d, yyyy').format(matchDate);
  
  /// Get formatted time
  String get formattedTime => DateFormat('HH:mm').format(matchDate);
  
  /// Get result string (e.g., "2 - 1")
  String get resultString => '$homeScore - $awayScore';
  
  /// Check if home team won
  bool get isHomeWin => homeScore > awayScore;
  
  /// Check if away team won
  bool get isAwayWin => awayScore > homeScore;
  
  /// Check if it's a draw
  bool get isDraw => homeScore == awayScore;
  
  /// Get winner name or "Draw"
  String get winner {
    if (isDraw) return 'Draw';
    return isHomeWin ? homeTeamName : awayTeamName;
  }
  
  factory CompletedMatch.fromJson(Map<String, dynamic> json) {
    // Parse participants
    String homeTeamName = '';
    String awayTeamName = '';
    String? homeTeamLogo;
    String? awayTeamLogo;
    int homeTeamId = 0;
    int awayTeamId = 0;
    int homeScore = 0;
    int awayScore = 0;
    
    final participants = json['participants'] as List?;
    if (participants != null) {
      for (final p in participants) {
        if (p is! Map<String, dynamic>) continue;
        final meta = p['meta'] as Map<String, dynamic>?;
        final location = meta?['location']?.toString();
        
        if (location == 'home') {
          homeTeamId = p['id'] as int? ?? 0;
          homeTeamName = p['name']?.toString() ?? '';
          homeTeamLogo = p['image_path'] as String?;
          homeScore = _parseInt(meta?['winner']) == true 
              ? (meta?['goals'] as int? ?? 0)
              : (meta?['goals'] as int? ?? 0);
        } else if (location == 'away') {
          awayTeamId = p['id'] as int? ?? 0;
          awayTeamName = p['name']?.toString() ?? '';
          awayTeamLogo = p['image_path'] as String?;
          awayScore = meta?['goals'] as int? ?? 0;
        }
      }
    }
    
    // Get scores from scores array (more reliable)
    final scores = json['scores'] as List?;
    if (scores != null) {
      for (final score in scores) {
        if (score is! Map<String, dynamic>) continue;
        final description = score['description']?.toString().toUpperCase() ?? '';
        
        if (description == 'CURRENT' || description.contains('FINAL') || description == '2ND_HALF') {
          final participantId = score['participant_id'] as int?;
          final scoreData = score['score'] as Map<String, dynamic>?;
          final goals = scoreData?['goals'] as int? ?? _parseInt(score['goals']) ?? 0;
          
          if (participantId == homeTeamId) {
            homeScore = goals;
          } else if (participantId == awayTeamId) {
            awayScore = goals;
          }
        }
      }
    }
    
    // Parse league name
    String leagueName = '';
    if (json['league'] is Map) {
      leagueName = json['league']['name']?.toString() ?? '';
    } else if (json['league_name'] is String) {
      leagueName = json['league_name'];
    }
    
    // Parse match date
    DateTime matchDate = DateTime.now();
    final timestamp = json['starting_at_timestamp'] as int?;
    if (timestamp != null) {
      matchDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    } else if (json['starting_at'] is String) {
      matchDate = DateTime.tryParse(json['starting_at']) ?? DateTime.now();
    }
    
    // Parse venue
    String? venueName;
    String? venueCity;
    if (json['venue'] is Map) {
      venueName = json['venue']['name'] as String?;
      venueCity = json['venue']['city_name'] as String?;
    }
    
    // Parse formations
    String homeFormation = '4-4-2'; // Default
    String awayFormation = '4-4-2'; // Default
    
    final formations = json['formations'] as List?;
    if (formations != null) {
      for (final formation in formations) {
        if (formation is! Map<String, dynamic>) continue;
        final participantId = formation['participant_id'] as int?;
        final formationStr = formation['formation'] as String?;
        
        if (formationStr != null) {
          if (participantId == homeTeamId) {
            homeFormation = formationStr;
          } else if (participantId == awayTeamId) {
            awayFormation = formationStr;
          }
        }
      }
    }
    
    // Parse lineups
    TeamLineup? homeLineup;
    TeamLineup? awayLineup;
    
    final lineups = json['lineups'] as List?;
    if (lineups != null && lineups.isNotEmpty) {
      final homeStarters = <PlayerMatchPerformance>[];
      final homeSubs = <PlayerMatchPerformance>[];
      final awayStarters = <PlayerMatchPerformance>[];
      final awaySubs = <PlayerMatchPerformance>[];
      
      for (final lineup in lineups) {
        if (lineup is! Map<String, dynamic>) continue;
        
        final teamId = lineup['team_id'] as int? ?? 
                       lineup['participant_id'] as int?;
        final isStarter = lineup['type_id'] == 11;
        
        final teamName = teamId == homeTeamId ? homeTeamName : awayTeamName;
        final performance = PlayerMatchPerformance.fromLineupData(
          lineup, 
          lineup['player'] as Map<String, dynamic>?,
          teamId ?? 0,
          teamName,
        );
        
        if (teamId == homeTeamId) {
          if (isStarter) {
            homeStarters.add(performance);
          } else {
            homeSubs.add(performance);
          }
        } else if (teamId == awayTeamId) {
          if (isStarter) {
            awayStarters.add(performance);
          } else {
            awaySubs.add(performance);
          }
        }
      }
      
      if (homeStarters.isNotEmpty) {
        homeLineup = TeamLineup(
          teamId: homeTeamId,
          teamName: homeTeamName,
          teamLogo: homeTeamLogo,
          formation: homeFormation,
          starters: homeStarters,
          substitutes: homeSubs,
        );
      }
      
      if (awayStarters.isNotEmpty) {
        awayLineup = TeamLineup(
          teamId: awayTeamId,
          teamName: awayTeamName,
          teamLogo: awayTeamLogo,
          formation: awayFormation,
          starters: awayStarters,
          substitutes: awaySubs,
        );
      }
    }
    
    return CompletedMatch(
      fixtureId: json['id'] as int? ?? 0,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      homeTeamLogo: homeTeamLogo,
      awayTeamLogo: awayTeamLogo,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeScore: homeScore,
      awayScore: awayScore,
      leagueName: leagueName,
      matchDate: matchDate,
      venueName: venueName,
      venueCity: venueCity,
      homeLineup: homeLineup,
      awayLineup: awayLineup,
    );
  }
  
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    if (value is bool) return value ? 1 : 0;
    return null;
  }
}

