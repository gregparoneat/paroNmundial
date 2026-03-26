import 'package:flutter/foundation.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/features/fixtures/models/predicted_lineup.dart';
import 'package:fantacy11/features/fixtures/models/completed_match.dart';

/// Service for predicting expected lineups based on historical data
class LineupPredictionService {
  final FixturesRepository _repository;
  final PlayersRepository _playersRepository;
  
  /// Number of recent matches to analyze for predictions
  static const int matchesToAnalyze = 8;
  
  /// Cache for predictions (teamId -> prediction)
  final Map<int, PredictedLineup> _predictionCache = {};
  
  /// Cache for team history
  final Map<int, List<CompletedMatch>> _historyCache = {};
  
  /// Cache for current squad player IDs (teamId -> Set<playerId>)
  final Map<int, Set<int>> _currentSquadCache = {};
  
  LineupPredictionService({
    FixturesRepository? repository,
    PlayersRepository? playersRepository,
  })  : _repository = repository ?? FixturesRepository(),
        _playersRepository = playersRepository ?? PlayersRepository();
  
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
      
      // Get current squad to filter out transferred players
      final currentSquadIds = await _getCurrentSquadPlayerIds(teamId);
      
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
        currentSquadIds: currentSquadIds,
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
    
    // Debug: track specific players
    const debugPlayerIds = {333481, 37729734};
    
    debugPrint('LineupPrediction: Building player histories from ${matches.length} matches for team $teamId');
    
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final lineup = match.homeTeamId == teamId 
          ? match.homeLineup 
          : match.awayLineup;
      
      debugPrint('LineupPrediction: Match $i (fixture ${match.fixtureId}, ${match.matchDate.toString().substring(0, 10)}): '
          '${match.homeTeamName} vs ${match.awayTeamName}');
      
      if (lineup == null) {
        debugPrint('  -> No lineup data for team $teamId');
        continue;
      }
      
      debugPrint('  -> Found ${lineup.starters.length} starters, ${lineup.substitutes.length} subs');
      
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
        
        // Debug logging for specific players
        if (debugPlayerIds.contains(player.playerId)) {
          debugPrint('  -> DEBUG: Player ${player.playerId} (${player.playerName}) - '
              'STARTER in match $i, mins=${player.minutesPlayed}');
        }
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
        
        // Debug logging for specific players
        if (debugPlayerIds.contains(player.playerId)) {
          debugPrint('  -> DEBUG: Player ${player.playerId} (${player.playerName}) - '
              'SUB in match $i, mins=${player.minutesPlayed}');
        }
      }
    }
    
    // Final summary for debug players
    for (final playerId in debugPlayerIds) {
      if (histories.containsKey(playerId)) {
        final h = histories[playerId]!;
        debugPrint('LineupPrediction: DEBUG SUMMARY for player $playerId (${h.playerName}):');
        debugPrint('  - Total appearances: ${h.totalAppearances}');
        debugPrint('  - Starts: ${h.startCount}');
        debugPrint('  - Started last match: ${h.startedLastMatch}');
        debugPrint('  - Started last 2: ${h.startedLastTwoMatches}');
        debugPrint('  - Recent streak: ${h.recentStartStreak}');
        debugPrint('  - Prediction score: ${h.predictionScore.toStringAsFixed(3)}');
      } else {
        debugPrint('LineupPrediction: DEBUG - Player $playerId NOT FOUND in any lineup!');
      }
    }
    
    debugPrint('LineupPrediction: Built histories for ${histories.length} players');
    
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
  
  /// Get sidelined players for a team (injured/suspended)
  /// 
  /// Fetches current sidelined players from SportMonks API.
  /// Returns empty list if API call fails (graceful degradation).
  Future<List<SidelinedPlayer>> _getSidelinedPlayers(
    int teamId, 
    DateTime? matchDate,
  ) async {
    try {
      debugPrint('LineupPrediction: Fetching sidelined players for team $teamId');
      final sidelinedData = await _repository.getSidelinedPlayers(
        teamId,
        matchDate: matchDate,
      );
      
      if (sidelinedData.isEmpty) {
        debugPrint('LineupPrediction: No sidelined players found');
        return [];
      }
      
      final sidelinedPlayers = sidelinedData
          .map((data) => SidelinedPlayer.fromJson(data, matchDate: matchDate))
          .where((p) => p.playerId > 0)
          .toList();
      
      debugPrint('LineupPrediction: Found ${sidelinedPlayers.length} sidelined players');
      for (final player in sidelinedPlayers) {
        debugPrint('  - ${player.playerName}: ${player.type} (${player.reason ?? "no reason"})');
      }
      
      return sidelinedPlayers;
    } catch (e) {
      debugPrint('LineupPrediction: Error fetching sidelined players: $e');
      return [];
    }
  }
  
  /// Get current squad player IDs for a team (to filter out transferred players)
  /// Uses local cache or Firebase (faster than API calls)
  Future<Set<int>> _getCurrentSquadPlayerIds(int teamId) async {
    // Check cache first
    if (_currentSquadCache.containsKey(teamId)) {
      final cached = _currentSquadCache[teamId]!;
      debugPrint('LineupPrediction: Using cached squad (${cached.length} players)');
      // Debug: check specific players
      debugPrint('LineupPrediction: DEBUG - Player 333481 in squad: ${cached.contains(333481)}');
      debugPrint('LineupPrediction: DEBUG - Player 37729734 in squad: ${cached.contains(37729734)}');
      return cached;
    }
    
    try {
      debugPrint('LineupPrediction: Fetching current squad for team $teamId');
      
      // Use the new method that checks local cache, Hive, Firebase, then API
      final playerIds = await _playersRepository.getCurrentSquadPlayerIds(teamId);
      
      // Cache the result
      _currentSquadCache[teamId] = playerIds;
      debugPrint('LineupPrediction: Found ${playerIds.length} players in current squad');
      
      // Debug: check specific players
      debugPrint('LineupPrediction: DEBUG - Player 333481 in squad: ${playerIds.contains(333481)}');
      debugPrint('LineupPrediction: DEBUG - Player 37729734 in squad: ${playerIds.contains(37729734)}');
      
      return playerIds;
    } catch (e) {
      debugPrint('LineupPrediction: Error fetching current squad: $e');
      // Return empty set on error - will not filter any players
      return {};
    }
  }
  
  /// Build the final prediction
  /// 
  /// NEW ALGORITHM IMPROVEMENTS:
  /// - Players who started last 2 matches are heavily favored
  /// - Players with few appearances are penalized
  /// - Detects potential injuries from appearance patterns
  /// - Better logging for debugging predictions
  PredictedLineup _buildPrediction({
    required int teamId,
    required String teamName,
    String? teamLogo,
    required _FormationAnalysis formationAnalysis,
    required Map<int, _PlayerHistory> playerHistories,
    required List<SidelinedPlayer> sidelinedPlayers,
    required int matchesAnalyzed,
    DateTime? matchDate,
    Set<int>? currentSquadIds,
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
    
    debugPrint('LineupPrediction: Formation $formation - Required by position: $requiredByPosition');
    
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
    
    // Detect potential injuries from appearance patterns
    // Players who were starting consistently but suddenly stopped appearing
    final potentiallyInjuredIds = <int>{};
    for (final history in playerHistories.values) {
      if (_isPotentiallyInjured(history, matchesAnalyzed)) {
        potentiallyInjuredIds.add(history.playerId);
        debugPrint('LineupPrediction: ${history.playerName} might be injured (was starting, stopped appearing)');
      }
    }
    
    // Group players by their ACTUAL playing position (from formation_field data)
    // NOT their official listed position
    final playersByPosition = <String, List<_PlayerHistory>>{
      'GK': [],
      'DEF': [],
      'MID': [],
      'FWD': [],
    };
    
    for (final history in playerHistories.values) {
      // Check if player appeared in recent matches (last 3)
      // If they played recently, they ARE on the team regardless of squad list
      final hasRecentAppearance = history._appearances.any((a) => a.matchIndex <= 2);
      
      // Skip players who are no longer on the team (transferred out)
      // BUT only if they haven't appeared in recent matches
      if (!hasRecentAppearance && 
          currentSquadIds != null && currentSquadIds.isNotEmpty && 
          !currentSquadIds.contains(history.playerId)) {
        debugPrint('LineupPrediction: Skipping ${history.playerName} (${history.playerId}) - '
            'no recent appearances and not in current squad');
        continue;
      }
      
      // Skip currently sidelined players
      if (sidelinedIds.contains(history.playerId)) {
        debugPrint('LineupPrediction: Skipping ${history.playerName} (${history.playerId}) - currently sidelined');
        continue;
      }
      
      // Skip potentially injured players (inferred from patterns)
      if (potentiallyInjuredIds.contains(history.playerId)) {
        debugPrint('LineupPrediction: Skipping ${history.playerName} (${history.playerId}) - potentially injured');
        continue;
      }
      
      // Log player being considered
      debugPrint('LineupPrediction: Considering ${history.playerName} (${history.playerId}) - '
          'apps=${history.totalAppearances}, starts=${history.startCount}, '
          'recentApp=$hasRecentAppearance, score=${history.predictionScore.toStringAsFixed(2)}');
      
      // Use the actual playing position from formation data, not official position
      final actualPosition = history.mostCommonPlayingPosition;
      playersByPosition[actualPosition]?.add(history);
    }
    
    // Sort players by prediction score and select top N for each position
    final starters = <PredictedPlayer>[];
    final bench = <PredictedPlayer>[];
    
    for (final position in ['GK', 'DEF', 'MID', 'FWD']) {
      final players = playersByPosition[position] ?? [];
      
      // Sort by weighted score (recent starts weighted higher)
      players.sort((a, b) => b.predictionScore.compareTo(a.predictionScore));
      
      final required = requiredByPosition[position] ?? 1;
      
      // Log top candidates for this position
      debugPrint('LineupPrediction: Top $position candidates:');
      for (int i = 0; i < players.length && i < 5; i++) {
        final p = players[i];
        debugPrint('  ${i + 1}. ${p.playerName}: score=${p.predictionScore.toStringAsFixed(2)}, '
            'conf=${p.confidence.toStringAsFixed(2)}, starts=${p.startCount}/${p.totalAppearances}, '
            'last2=${p.startedLastTwoMatches ? "YES" : "no"}, streak=${p.recentStartStreak}');
      }
      
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
  
  /// Detect if a player might be injured based on their appearance pattern
  /// 
  /// Signs of potential injury:
  /// - Was starting consistently (3+ starts in older matches)
  /// - Has NOT appeared in recent matches (0-1 appearances in last 3)
  bool _isPotentiallyInjured(_PlayerHistory history, int matchesAnalyzed) {
    if (history.totalAppearances < 3) return false;
    
    // Count starts in older matches (index 3-7)
    int olderStarts = 0;
    for (int i = 3; i < matchesAnalyzed; i++) {
      if (history._appearances.any((a) => a.matchIndex == i && a.isStarter)) {
        olderStarts++;
      }
    }
    
    // Count appearances in recent matches (index 0-2)
    int recentAppearances = 0;
    for (int i = 0; i < 3; i++) {
      if (history._appearances.any((a) => a.matchIndex == i)) {
        recentAppearances++;
      }
    }
    
    // Pattern: Was starting consistently (3+ older starts) but hasn't appeared recently (0-1)
    return olderStarts >= 3 && recentAppearances <= 1;
  }
  
  /// Clear prediction cache
  void clearCache() {
    _predictionCache.clear();
    _historyCache.clear();
    _currentSquadCache.clear();
  }
  
  /// Clear cache for a specific team
  void clearTeamCache(int teamId) {
    _predictionCache.remove(teamId);
    _historyCache.remove(teamId);
    _currentSquadCache.remove(teamId);
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
  
  /// Count consecutive starts from most recent match (match index 0)
  /// Returns 0 if most recent match was not a start
  int get recentStartStreak {
    // Sort by match index to ensure we're checking from most recent
    final sorted = List<_Appearance>.from(_appearances)
      ..sort((a, b) => a.matchIndex.compareTo(b.matchIndex));
    
    int streak = 0;
    for (final app in sorted) {
      if (app.isStarter) {
        streak++;
      } else {
        break; // Streak broken
      }
    }
    return streak;
  }
  
  /// Check if player started the most recent match
  bool get startedLastMatch {
    if (_appearances.isEmpty) return false;
    // Find the appearance with matchIndex 0 (most recent)
    return _appearances.any((a) => a.matchIndex == 0 && a.isStarter);
  }
  
  /// Check if player started the last 2 matches
  bool get startedLastTwoMatches {
    if (_appearances.length < 2) return false;
    final startedMatch0 = _appearances.any((a) => a.matchIndex == 0 && a.isStarter);
    final startedMatch1 = _appearances.any((a) => a.matchIndex == 1 && a.isStarter);
    return startedMatch0 && startedMatch1;
  }
  
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
  /// 
  /// NEW ALGORITHM:
  /// - MASSIVE bonus for starting last 2 matches (strongest predictor)
  /// - Heavy weight on recent matches (steeper decay for older matches)
  /// - Penalty for players with very few appearances (likely not regular starters)
  /// - Bonus for consistent starters
  double get predictionScore {
    if (_appearances.isEmpty) return 0;
    
    double score = 0;
    double maxScore = 0;
    
    // CRITICAL: If player started last 2 matches, they're very likely to start
    // This is the strongest predictor in football
    if (startedLastTwoMatches) {
      score += 2.0; // Massive bonus
      maxScore += 2.0;
    } else if (startedLastMatch) {
      // Started last match but not the one before - still a good sign
      score += 1.0;
      maxScore += 1.0;
    }
    
    // Weight each appearance with STEEP decay for older matches
    // Match 0 (most recent) = weight 1.0
    // Match 1 = weight 0.7
    // Match 2 = weight 0.5
    // Match 3+ = rapidly decreasing
    for (final app in _appearances) {
      // Steeper exponential decay: recent matches matter MUCH more
      final weight = switch (app.matchIndex) {
        0 => 1.0,   // Most recent
        1 => 0.7,   // Second most recent
        2 => 0.5,   // Third
        3 => 0.35,
        4 => 0.25,
        5 => 0.15,
        6 => 0.1,
        _ => 0.05,  // Older matches barely count
      };
      
      maxScore += weight;
      
      if (app.isStarter) {
        score += weight;
      } else if (app.minutesPlayed > 60) {
        // Came on as sub but played significant minutes (60+)
        score += weight * 0.4;
      } else if (app.minutesPlayed > 30) {
        // Brief sub appearance
        score += weight * 0.2;
      }
      // On bench but didn't play = 0 contribution
    }
    
    // PENALTY for players with very few appearances in analyzed period
    // If they only appeared 1-2 times in 8 matches, they're likely not regular
    final totalMatches = LineupPredictionService.matchesToAnalyze;
    if (_appearances.length == 1) {
      // Only 1 appearance - could be new signing or injury return
      // Check if it was recent (match 0 or 1)
      final wasRecent = _appearances.first.matchIndex <= 1;
      if (!wasRecent) {
        // Old single appearance - heavily penalize
        score *= 0.3;
      } else if (_appearances.first.isStarter) {
        // Recent single start - could be new starter, give benefit of doubt
        score *= 0.8;
      }
    } else if (_appearances.length == 2 && startCount == 1) {
      // 2 appearances but only 1 start - inconsistent
      score *= 0.7;
    }
    
    // BONUS for consistency - players who start most games they appear in
    if (_appearances.length >= 3) {
      final startRate = startCount / _appearances.length;
      if (startRate >= 0.9) {
        score *= 1.15; // 15% bonus for very consistent starters
      } else if (startRate >= 0.75) {
        score *= 1.08; // 8% bonus
      }
    }
    
    return maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0;
  }
  
  /// Confidence level (0-1) - how confident we are in this prediction
  /// 
  /// NEW ALGORITHM:
  /// - High confidence if player has been starting consistently recently
  /// - Low confidence for sporadic players or those with few appearances
  double get confidence {
    if (_appearances.isEmpty) return 0;
    
    double conf = 0;
    
    // 1. Recent start streak is the best indicator (40% weight)
    // Started last 3+ matches = very high confidence
    final streak = recentStartStreak;
    if (streak >= 3) {
      conf += 0.4;
    } else if (streak == 2) {
      conf += 0.32;
    } else if (streak == 1) {
      conf += 0.2;
    } else {
      // Didn't start most recent match
      conf += 0.05;
    }
    
    // 2. Overall start percentage (30% weight)
    final startPct = startCount / _appearances.length;
    conf += startPct * 0.3;
    
    // 3. Volume of data - more appearances = more confidence (20% weight)
    final dataVolume = (_appearances.length / LineupPredictionService.matchesToAnalyze).clamp(0.0, 1.0);
    conf += dataVolume * 0.2;
    
    // 4. Consistency bonus (10% weight)
    // Players who either always start or never start are more predictable
    if (startPct >= 0.85 || startPct <= 0.15) {
      conf += 0.1; // Very consistent pattern
    } else if (startPct >= 0.7 || startPct <= 0.3) {
      conf += 0.05; // Somewhat consistent
    }
    // Rotation players (40-60% start rate) don't get consistency bonus
    
    // PENALTY: Very few appearances means less confidence
    if (_appearances.length == 1) {
      conf *= 0.5; // Halve confidence for single appearance
    } else if (_appearances.length == 2) {
      conf *= 0.7;
    }
    
    return conf.clamp(0.0, 1.0);
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

