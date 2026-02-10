import 'package:flutter/foundation.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/features/fixtures/models/predicted_lineup.dart';
import 'package:fantacy11/features/fixtures/models/completed_match.dart';

/// Service for predicting expected lineups based on historical data
class LineupPredictionService {
  final FixturesRepository _repository;
  
  /// Number of recent matches to analyze for predictions
  static const int matchesToAnalyze = 8;
  
  /// Cache for predictions (teamId -> prediction)
  final Map<int, PredictedLineup> _predictionCache = {};
  
  /// Cache for team history
  final Map<int, List<CompletedMatch>> _historyCache = {};
  
  LineupPredictionService({FixturesRepository? repository})
      : _repository = repository ?? FixturesRepository();
  
  /// Generate predicted lineup for a team
  /// 
  /// [teamId] - The team to predict for
  /// [teamName] - Team name for display
  /// [teamLogo] - Optional team logo URL
  /// [matchDate] - The date of the upcoming match (for injury return checks)
  Future<PredictedLineup> predictLineup(
    int teamId,
    String teamName, {
    String? teamLogo,
    DateTime? matchDate,
  }) async {
    // Check cache first
    if (_predictionCache.containsKey(teamId)) {
      final cached = _predictionCache[teamId]!;
      // Cache valid for 1 hour
      if (cached.lastUpdated != null && 
          DateTime.now().difference(cached.lastUpdated!).inHours < 1) {
        return cached;
      }
    }
    
    try {
      debugPrint('LineupPrediction: Generating prediction for team $teamId ($teamName)');
      
      // Get recent matches for the team
      final recentMatches = await _getTeamRecentMatches(teamId);
      
      if (recentMatches.isEmpty) {
        debugPrint('LineupPrediction: No recent matches found for team $teamId');
        return PredictedLineup.empty(teamId, teamName, teamLogo: teamLogo);
      }
      
      debugPrint('LineupPrediction: Found ${recentMatches.length} recent matches');
      
      // Analyze formations
      final formationAnalysis = _analyzeFormations(recentMatches, teamId);
      
      // Get sidelined players (if available)
      final sidelinedPlayers = await _getSidelinedPlayers(teamId, matchDate);
      
      // Build player history
      final playerHistories = _buildPlayerHistories(recentMatches, teamId);
      
      // Predict starting XI
      final prediction = _buildPrediction(
        teamId: teamId,
        teamName: teamName,
        teamLogo: teamLogo,
        formationAnalysis: formationAnalysis,
        playerHistories: playerHistories,
        sidelinedPlayers: sidelinedPlayers,
        matchesAnalyzed: recentMatches.length,
        matchDate: matchDate,
      );
      
      // Cache the prediction
      _predictionCache[teamId] = prediction;
      
      return prediction;
    } catch (e) {
      debugPrint('LineupPrediction: Error predicting lineup: $e');
      return PredictedLineup.empty(teamId, teamName, teamLogo: teamLogo);
    }
  }
  
  /// Get recent completed matches for a team
  Future<List<CompletedMatch>> _getTeamRecentMatches(int teamId) async {
    // Check cache
    if (_historyCache.containsKey(teamId)) {
      return _historyCache[teamId]!;
    }
    
    // Fetch last 60 days of matches
    final pastFixtures = await _repository.getPastFixtures(
      daysBack: 60,
      teamId: teamId,
    );
    
    // Convert to CompletedMatch objects
    final matches = pastFixtures
        .take(matchesToAnalyze)
        .map((json) => CompletedMatch.fromJson(json))
        .where((m) => m.homeLineup != null || m.awayLineup != null)
        .toList();
    
    _historyCache[teamId] = matches;
    return matches;
  }
  
  /// Analyze formation usage from recent matches
  _FormationAnalysis _analyzeFormations(List<CompletedMatch> matches, int teamId) {
    final formationCounts = <String, int>{};
    
    for (final match in matches) {
      String? formation;
      
      if (match.homeTeamId == teamId && match.homeLineup != null) {
        formation = match.homeLineup!.formation;
      } else if (match.awayTeamId == teamId && match.awayLineup != null) {
        formation = match.awayLineup!.formation;
      }
      
      if (formation != null && formation.isNotEmpty) {
        formationCounts[formation] = (formationCounts[formation] ?? 0) + 1;
      }
    }
    
    if (formationCounts.isEmpty) {
      return _FormationAnalysis(
        mostUsedFormation: '4-4-2',
        confidence: 0.3,
        usageCounts: {},
      );
    }
    
    // Find most used formation
    var mostUsed = formationCounts.entries.first;
    for (final entry in formationCounts.entries) {
      if (entry.value > mostUsed.value) {
        mostUsed = entry;
      }
    }
    
    final totalMatches = matches.length;
    final confidence = mostUsed.value / totalMatches;
    
    debugPrint('LineupPrediction: Most used formation: ${mostUsed.key} '
        '(${mostUsed.value}/$totalMatches matches, confidence: ${(confidence * 100).toStringAsFixed(0)}%)');
    
    return _FormationAnalysis(
      mostUsedFormation: mostUsed.key,
      confidence: confidence,
      usageCounts: formationCounts,
    );
  }
  
  /// Build player appearance histories
  /// Uses formation_field from past matches to determine actual playing position
  Map<int, _PlayerHistory> _buildPlayerHistories(
    List<CompletedMatch> matches, 
    int teamId,
  ) {
    final histories = <int, _PlayerHistory>{};
    
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final lineup = match.homeTeamId == teamId 
          ? match.homeLineup 
          : match.awayLineup;
      
      if (lineup == null) continue;
      
      // Get total formation lines for this match to interpret formation_field correctly
      final totalLines = _getTotalLinesFromFormation(lineup.formation);
      
      // Process starters
      for (final player in lineup.starters) {
        // Determine actual playing position from formation_field
        final actualPosition = _getActualPlayingPosition(
          player.formationLine,
          totalLines,
          player.position, // fallback to official position
        );
        
        final history = histories.putIfAbsent(
          player.playerId,
          () => _PlayerHistory(
            playerId: player.playerId,
            playerName: player.playerName,
            playerImageUrl: player.playerImageUrl,
            officialPosition: player.position,
            jerseyNumber: player.jerseyNumber,
          ),
        );
        
        history.addAppearance(
          matchIndex: i,
          isStarter: true,
          minutesPlayed: player.minutesPlayed,
          formationField: player.formationField,
          formationLine: player.formationLine,
          formationPosition: player.formationPosition,
          actualPosition: actualPosition,
          totalFormationLines: totalLines,
        );
      }
      
      // Process substitutes
      for (final player in lineup.substitutes) {
        final actualPosition = _getActualPlayingPosition(
          player.formationLine,
          totalLines,
          player.position,
        );
        
        final history = histories.putIfAbsent(
          player.playerId,
          () => _PlayerHistory(
            playerId: player.playerId,
            playerName: player.playerName,
            playerImageUrl: player.playerImageUrl,
            officialPosition: player.position,
            jerseyNumber: player.jerseyNumber,
          ),
        );
        
        history.addAppearance(
          matchIndex: i,
          isStarter: false,
          minutesPlayed: player.minutesPlayed,
          formationField: player.formationField,
          formationLine: player.formationLine,
          formationPosition: player.formationPosition,
          actualPosition: actualPosition,
          totalFormationLines: totalLines,
        );
      }
    }
    
    return histories;
  }
  
  /// Get total number of lines from formation string
  /// e.g., "4-3-3" = 4 lines (GK + 3 outfield), "4-2-3-1" = 5 lines (GK + 4 outfield)
  int _getTotalLinesFromFormation(String formation) {
    final parts = formation.split('-');
    return parts.length + 1; // +1 for goalkeeper
  }
  
  /// Determine actual playing position from formation line
  /// This maps the formation_field line to GK/DEF/MID/FWD
  String _getActualPlayingPosition(int? formationLine, int totalLines, String fallbackPosition) {
    if (formationLine == null) return fallbackPosition;
    
    // Line 1 is always GK
    if (formationLine == 1) return 'GK';
    
    // Line 2 is always DEF
    if (formationLine == 2) return 'DEF';
    
    // Last line is always FWD
    if (formationLine == totalLines) return 'FWD';
    
    // Everything in between is MID
    return 'MID';
  }
  
  /// Get sidelined players for a team
  Future<List<SidelinedPlayer>> _getSidelinedPlayers(
    int teamId, 
    DateTime? matchDate,
  ) async {
    // This would ideally come from a dedicated API endpoint
    // For now, we'll return empty and rely on historical data
    // In the future, we can add a method to fetch current sidelined players
    return [];
  }
  
  /// Build the final prediction
  PredictedLineup _buildPrediction({
    required int teamId,
    required String teamName,
    String? teamLogo,
    required _FormationAnalysis formationAnalysis,
    required Map<int, _PlayerHistory> playerHistories,
    required List<SidelinedPlayer> sidelinedPlayers,
    required int matchesAnalyzed,
    DateTime? matchDate,
  }) {
    final formation = formationAnalysis.mostUsedFormation;
    final formationParts = formation.split('-').map((p) => int.tryParse(p) ?? 0).toList();
    
    // Determine required players per position
    // Formation like "4-3-3" means 4 DEF, 3 MID, 3 FWD
    final requiredByPosition = {
      'GK': 1,
      'DEF': formationParts.isNotEmpty ? formationParts[0] : 4,
      'MID': formationParts.length > 1 ? formationParts.sublist(1, formationParts.length - 1).fold(0, (a, b) => a + b) : 4,
      'FWD': formationParts.isNotEmpty ? formationParts.last : 2,
    };
    
    // Handle complex formations like 4-2-3-1 where midfield has multiple lines
    if (formationParts.length > 3) {
      // Sum all middle parts for midfielders
      requiredByPosition['MID'] = formationParts.sublist(1, formationParts.length - 1).fold(0, (a, b) => a + b);
    }
    
    debugPrint('LineupPrediction: Required by position: $requiredByPosition');
    
    // Set of sidelined player IDs (currently injured/suspended)
    final sidelinedIds = sidelinedPlayers
        .where((p) => p.isCurrentlySidelined && !p.isExpectedBack)
        .map((p) => p.playerId)
        .toSet();
    
    // Set of players returning from injury (for the match)
    final returningIds = sidelinedPlayers
        .where((p) => p.isExpectedBack)
        .map((p) => p.playerId)
        .toSet();
    
    // Group players by their ACTUAL playing position (from formation_field data)
    // NOT their official listed position
    final playersByPosition = <String, List<_PlayerHistory>>{
      'GK': [],
      'DEF': [],
      'MID': [],
      'FWD': [],
    };
    
    for (final history in playerHistories.values) {
      // Skip currently sidelined players
      if (sidelinedIds.contains(history.playerId)) {
        continue;
      }
      
      // Use the actual playing position from formation data, not official position
      final actualPosition = history.mostCommonPlayingPosition;
      playersByPosition[actualPosition]?.add(history);
      
      debugPrint('LineupPrediction: ${history.playerName} - official: ${history.officialPosition}, actual: $actualPosition');
    }
    
    // Sort players by prediction score and select top N for each position
    final starters = <PredictedPlayer>[];
    final bench = <PredictedPlayer>[];
    
    for (final position in ['GK', 'DEF', 'MID', 'FWD']) {
      final players = playersByPosition[position] ?? [];
      
      // Sort by weighted score (recent starts weighted higher)
      players.sort((a, b) => b.predictionScore.compareTo(a.predictionScore));
      
      final required = requiredByPosition[position] ?? 1;
      
      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        final isReturning = returningIds.contains(player.playerId);
        final returningInfo = isReturning 
            ? sidelinedPlayers.firstWhere((p) => p.playerId == player.playerId)
            : null;
        
        // Use actual playing position for display
        final actualPosition = player.mostCommonPlayingPosition;
        
        final predictedPlayer = PredictedPlayer(
          playerId: player.playerId,
          playerName: player.playerName,
          playerImageUrl: player.playerImageUrl,
          position: actualPosition, // Use actual playing position, not official
          jerseyNumber: player.jerseyNumber,
          confidence: player.confidence,
          startCount: player.startCount,
          totalMatches: matchesAnalyzed,
          isReturningFromInjury: isReturning && returningInfo?.type == 'injury',
          isReturningFromSuspension: isReturning && returningInfo?.type == 'suspension',
          injuryNote: returningInfo?.reason,
          formationLine: player.mostCommonFormationLine,
          formationPosition: player.mostCommonFormationPosition,
        );
        
        if (i < required) {
          starters.add(predictedPlayer);
        } else if (bench.length < 7) { // Typical bench size
          bench.add(predictedPlayer);
        }
      }
    }
    
    debugPrint('LineupPrediction: Predicted ${starters.length} starters, ${bench.length} bench');
    
    return PredictedLineup(
      teamId: teamId,
      teamName: teamName,
      teamLogo: teamLogo,
      predictedFormation: formation,
      formationConfidence: formationAnalysis.confidence,
      starters: starters,
      likelyBench: bench,
      matchesAnalyzed: matchesAnalyzed,
      lastUpdated: DateTime.now(),
    );
  }
  
  /// Clear prediction cache
  void clearCache() {
    _predictionCache.clear();
    _historyCache.clear();
  }
  
  /// Clear cache for a specific team
  void clearTeamCache(int teamId) {
    _predictionCache.remove(teamId);
    _historyCache.remove(teamId);
  }
}

/// Internal class for formation analysis
class _FormationAnalysis {
  final String mostUsedFormation;
  final double confidence;
  final Map<String, int> usageCounts;
  
  const _FormationAnalysis({
    required this.mostUsedFormation,
    required this.confidence,
    required this.usageCounts,
  });
}

/// Internal class for tracking player history
class _PlayerHistory {
  final int playerId;
  final String playerName;
  final String? playerImageUrl;
  final String officialPosition; // The position listed in player profile
  final int? jerseyNumber;
  
  final List<_Appearance> _appearances = [];
  
  _PlayerHistory({
    required this.playerId,
    required this.playerName,
    this.playerImageUrl,
    required this.officialPosition,
    this.jerseyNumber,
  });
  
  void addAppearance({
    required int matchIndex,
    required bool isStarter,
    required int minutesPlayed,
    String? formationField,
    int? formationLine,
    int? formationPosition,
    required String actualPosition,
    int? totalFormationLines,
  }) {
    _appearances.add(_Appearance(
      matchIndex: matchIndex,
      isStarter: isStarter,
      minutesPlayed: minutesPlayed,
      formationField: formationField,
      formationLine: formationLine,
      formationPosition: formationPosition,
      actualPosition: actualPosition,
      totalFormationLines: totalFormationLines,
    ));
  }
  
  /// Number of starts
  int get startCount => _appearances.where((a) => a.isStarter).length;
  
  /// Total appearances
  int get totalAppearances => _appearances.length;
  
  /// Get the most common actual playing position from recent starts
  /// This is based on formation_field data, not the official position
  String get mostCommonPlayingPosition {
    // Only consider starts where we have actual position data
    final starterAppearances = _appearances.where((a) => a.isStarter).toList();
    
    if (starterAppearances.isEmpty) {
      return officialPosition; // Fallback to official if no starts
    }
    
    // Count positions from actual playing data
    final positionCounts = <String, int>{};
    for (final app in starterAppearances) {
      final pos = app.actualPosition;
      positionCounts[pos] = (positionCounts[pos] ?? 0) + 1;
    }
    
    if (positionCounts.isEmpty) {
      return officialPosition;
    }
    
    // Find most common
    var mostCommon = positionCounts.entries.first;
    for (final entry in positionCounts.entries) {
      if (entry.value > mostCommon.value) {
        mostCommon = entry;
      }
    }
    
    return mostCommon.key;
  }
  
  /// Get the most common formation line from recent starts
  int? get mostCommonFormationLine {
    final starterAppearances = _appearances.where((a) => a.isStarter && a.formationLine != null).toList();
    
    if (starterAppearances.isEmpty) return null;
    
    final lineCounts = <int, int>{};
    for (final app in starterAppearances) {
      if (app.formationLine != null) {
        lineCounts[app.formationLine!] = (lineCounts[app.formationLine!] ?? 0) + 1;
      }
    }
    
    if (lineCounts.isEmpty) return null;
    
    var mostCommon = lineCounts.entries.first;
    for (final entry in lineCounts.entries) {
      if (entry.value > mostCommon.value) {
        mostCommon = entry;
      }
    }
    
    return mostCommon.key;
  }
  
  /// Get the most common formation position (horizontal) from recent starts
  int? get mostCommonFormationPosition {
    final starterAppearances = _appearances.where((a) => a.isStarter && a.formationPosition != null).toList();
    
    if (starterAppearances.isEmpty) return null;
    
    final posCounts = <int, int>{};
    for (final app in starterAppearances) {
      if (app.formationPosition != null) {
        posCounts[app.formationPosition!] = (posCounts[app.formationPosition!] ?? 0) + 1;
      }
    }
    
    if (posCounts.isEmpty) return null;
    
    var mostCommon = posCounts.entries.first;
    for (final entry in posCounts.entries) {
      if (entry.value > mostCommon.value) {
        mostCommon = entry;
      }
    }
    
    return mostCommon.key;
  }
  
  /// Prediction score (0-1) based on weighted recent starts
  double get predictionScore {
    if (_appearances.isEmpty) return 0;
    
    double score = 0;
    double maxScore = 0;
    
    for (final app in _appearances) {
      // Weight more recent matches higher
      // Match index 0 = most recent = weight 1.0
      // Match index 7 = oldest = weight 0.3
      final weight = (1.0 - (app.matchIndex * 0.1)).clamp(0.3, 1.0);
      maxScore += weight;
      
      if (app.isStarter) {
        score += weight;
      } else if (app.minutesPlayed > 45) {
        // If subbed in and played significant minutes, give partial credit
        score += weight * 0.3;
      }
    }
    
    return maxScore > 0 ? score / maxScore : 0;
  }
  
  /// Confidence level (0-1)
  double get confidence {
    if (_appearances.isEmpty) return 0;
    
    // Base confidence on:
    // 1. Start percentage
    // 2. Recency of starts
    // 3. Number of appearances
    
    final startPct = startCount / _appearances.length;
    final recencyBonus = _appearances.isNotEmpty && _appearances.first.isStarter ? 0.2 : 0;
    final volumeBonus = (_appearances.length / LineupPredictionService.matchesToAnalyze).clamp(0, 0.2);
    
    return (startPct * 0.6 + recencyBonus + volumeBonus).clamp(0, 1);
  }
}

/// Internal appearance record
class _Appearance {
  final int matchIndex;
  final bool isStarter;
  final int minutesPlayed;
  final String? formationField;
  final int? formationLine;
  final int? formationPosition;
  final String actualPosition; // Derived from formation_field
  final int? totalFormationLines;
  
  const _Appearance({
    required this.matchIndex,
    required this.isStarter,
    required this.minutesPlayed,
    this.formationField,
    this.formationLine,
    this.formationPosition,
    required this.actualPosition,
    this.totalFormationLines,
  });
}

