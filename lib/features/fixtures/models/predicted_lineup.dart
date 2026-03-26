/// Model classes for predicted lineups

/// Represents a predicted player in the lineup
class PredictedPlayer {
  final int playerId;
  final String playerName;
  final String? playerImageUrl;
  final String position; // GK, DEF, MID, FWD - actual playing position from formation data
  final int? jerseyNumber;
  final double confidence; // 0.0 to 1.0 - how confident we are in this prediction
  final int startCount; // How many times this player started in recent matches
  final int totalMatches; // Total matches analyzed
  final bool isReturningFromInjury;
  final bool isReturningFromSuspension;
  final String? injuryNote;
  final int? formationLine; // Most common formation line (1=GK, 2=DEF, etc.)
  final int? formationPosition; // Most common horizontal position in line
  
  const PredictedPlayer({
    required this.playerId,
    required this.playerName,
    this.playerImageUrl,
    required this.position,
    this.jerseyNumber,
    required this.confidence,
    required this.startCount,
    required this.totalMatches,
    this.isReturningFromInjury = false,
    this.isReturningFromSuspension = false,
    this.injuryNote,
    this.formationLine,
    this.formationPosition,
  });
  
  /// Percentage of starts out of total matches
  double get startPercentage => totalMatches > 0 ? startCount / totalMatches : 0;
  
  /// Formatted confidence level
  String get confidenceLevel {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.5) return 'Medium';
    return 'Low';
  }
  
  /// Color value for confidence level (ARGB)
  int get confidenceColorValue {
    if (confidence >= 0.8) return 0xFF4CAF50; // Green
    if (confidence >= 0.5) return 0xFFFFC107; // Amber
    return 0xFFFF5722; // Deep orange
  }
  
  /// Clone with updated values
  PredictedPlayer copyWith({
    int? playerId,
    String? playerName,
    String? playerImageUrl,
    String? position,
    int? jerseyNumber,
    double? confidence,
    int? startCount,
    int? totalMatches,
    bool? isReturningFromInjury,
    bool? isReturningFromSuspension,
    String? injuryNote,
    int? formationLine,
    int? formationPosition,
  }) {
    return PredictedPlayer(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerImageUrl: playerImageUrl ?? this.playerImageUrl,
      position: position ?? this.position,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      confidence: confidence ?? this.confidence,
      startCount: startCount ?? this.startCount,
      totalMatches: totalMatches ?? this.totalMatches,
      isReturningFromInjury: isReturningFromInjury ?? this.isReturningFromInjury,
      isReturningFromSuspension: isReturningFromSuspension ?? this.isReturningFromSuspension,
      injuryNote: injuryNote ?? this.injuryNote,
      formationLine: formationLine ?? this.formationLine,
      formationPosition: formationPosition ?? this.formationPosition,
    );
  }
}

/// Represents a predicted team lineup
class PredictedLineup {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final String predictedFormation;
  final double formationConfidence; // How confident we are in the formation
  final List<PredictedPlayer> starters;
  final List<PredictedPlayer> likelyBench;
  final int matchesAnalyzed;
  final DateTime? lastUpdated;
  
  const PredictedLineup({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.predictedFormation,
    required this.formationConfidence,
    this.starters = const [],
    this.likelyBench = const [],
    required this.matchesAnalyzed,
    this.lastUpdated,
  });
  
  /// Get starters by position
  List<PredictedPlayer> get goalkeepers => 
      starters.where((p) => p.position == 'GK').toList();
  List<PredictedPlayer> get defenders => 
      starters.where((p) => p.position == 'DEF').toList();
  List<PredictedPlayer> get midfielders => 
      starters.where((p) => p.position == 'MID').toList();
  List<PredictedPlayer> get forwards => 
      starters.where((p) => p.position == 'FWD').toList();
  
  /// Parse formation into lines [DEF, MID, FWD] counts
  List<int> get formationLines {
    final parts = predictedFormation.split('-');
    return parts.map((p) => int.tryParse(p) ?? 0).toList();
  }
  
  /// Overall lineup confidence (average of all starters)
  double get overallConfidence {
    if (starters.isEmpty) return 0;
    return starters.map((p) => p.confidence).reduce((a, b) => a + b) / starters.length;
  }
  
  /// Formatted confidence
  String get overallConfidenceLabel {
    final conf = overallConfidence;
    if (conf >= 0.8) return 'High';
    if (conf >= 0.5) return 'Medium';
    return 'Low';
  }
  
  /// Players returning from injury/suspension
  List<PredictedPlayer> get returningPlayers => 
      starters.where((p) => p.isReturningFromInjury || p.isReturningFromSuspension).toList();
  
  /// Check if lineup has any predicted players
  bool get hasPrediction => starters.isNotEmpty;
  
  /// Create empty prediction
  factory PredictedLineup.empty(int teamId, String teamName, {String? teamLogo}) {
    return PredictedLineup(
      teamId: teamId,
      teamName: teamName,
      teamLogo: teamLogo,
      predictedFormation: '4-4-2',
      formationConfidence: 0,
      starters: [],
      likelyBench: [],
      matchesAnalyzed: 0,
    );
  }
}

/// Sidelined player info (injury/suspension)
class SidelinedPlayer {
  final int playerId;
  final String playerName;
  final String? playerImageUrl;
  final String type; // 'injury' or 'suspension'
  final String? reason;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isExpectedBack; // If expected to be back for this match
  
  const SidelinedPlayer({
    required this.playerId,
    required this.playerName,
    this.playerImageUrl,
    required this.type,
    this.reason,
    this.startDate,
    this.endDate,
    this.isExpectedBack = false,
  });
  
  factory SidelinedPlayer.fromJson(Map<String, dynamic> json, {DateTime? matchDate}) {
    final sidelineInfo = json['sideline'] as Map<String, dynamic>?;
    final playerInfo = json['player'] as Map<String, dynamic>?;
    
    // Extract player ID - could be in different places
    final playerId = json['player_id'] as int? ?? 
                    playerInfo?['id'] as int? ?? 0;
    
    // Extract dates - check both sideline object and root level
    DateTime? endDate;
    final endDateStr = sidelineInfo?['end_date'] as String? ?? 
                       json['end_date'] as String?;
    if (endDateStr != null && endDateStr.isNotEmpty) {
      endDate = DateTime.tryParse(endDateStr);
    }
    
    DateTime? startDate;
    final startDateStr = sidelineInfo?['start_date'] as String? ?? 
                         json['start_date'] as String?;
    if (startDateStr != null && startDateStr.isNotEmpty) {
      startDate = DateTime.tryParse(startDateStr);
    }
    
    // Check if player is expected back before the match
    bool isExpectedBack = false;
    if (endDate != null && matchDate != null) {
      isExpectedBack = endDate.isBefore(matchDate) || endDate.isAtSameMomentAs(matchDate);
    }
    
    // Extract category - check both sideline object and root level
    final category = sidelineInfo?['category'] as String? ?? 
                    sidelineInfo?['type'] as String? ??
                    json['category'] as String?;
    
    // Extract description/reason
    final reason = sidelineInfo?['description'] as String? ?? 
                   json['description'] as String? ??
                   json['reason'] as String?;
    
    // Player name - fallback to "Player {id}" if no info available
    final playerName = playerInfo?['display_name'] as String? ?? 
                       playerInfo?['common_name'] as String? ?? 
                       playerInfo?['name'] as String? ??
                       (playerId > 0 ? 'Player $playerId' : 'Unknown');
    
    return SidelinedPlayer(
      playerId: playerId,
      playerName: playerName,
      playerImageUrl: playerInfo?['image_path'] as String?,
      type: _determineType(category),
      reason: reason,
      startDate: startDate,
      endDate: endDate,
      isExpectedBack: isExpectedBack,
    );
  }
  
  static String _determineType(String? category) {
    if (category == null) return 'injury';
    final cat = category.toLowerCase();
    if (cat.contains('suspend') || cat.contains('card') || cat.contains('ban')) {
      return 'suspension';
    }
    return 'injury';
  }
  
  /// Check if currently sidelined
  bool get isCurrentlySidelined {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
}

/// Player appearance history for prediction
class PlayerAppearanceHistory {
  final int playerId;
  final String playerName;
  final String? playerImageUrl;
  final String position;
  final int? jerseyNumber;
  final List<AppearanceRecord> appearances;
  
  const PlayerAppearanceHistory({
    required this.playerId,
    required this.playerName,
    this.playerImageUrl,
    required this.position,
    this.jerseyNumber,
    this.appearances = const [],
  });
  
  /// Number of starts in recent matches
  int get startCount => appearances.where((a) => a.isStarter).length;
  
  /// Number of substitute appearances
  int get subCount => appearances.where((a) => !a.isStarter && a.minutesPlayed > 0).length;
  
  /// Total appearances
  int get totalAppearances => appearances.length;
  
  /// Recent form weight (more recent matches weighted higher)
  double get recentFormWeight {
    if (appearances.isEmpty) return 0;
    
    double weight = 0;
    for (int i = 0; i < appearances.length; i++) {
      // Most recent match = 1.0, decreasing by 0.1 for each older match
      final matchWeight = 1.0 - (i * 0.1);
      if (appearances[i].isStarter) {
        weight += matchWeight.clamp(0.3, 1.0);
      }
    }
    return weight;
  }
}

/// Single match appearance record
class AppearanceRecord {
  final int fixtureId;
  final DateTime matchDate;
  final bool isStarter;
  final int minutesPlayed;
  final String? formationPosition; // e.g., "3:2" for line 3, position 2
  
  const AppearanceRecord({
    required this.fixtureId,
    required this.matchDate,
    required this.isStarter,
    required this.minutesPlayed,
    this.formationPosition,
  });
}

