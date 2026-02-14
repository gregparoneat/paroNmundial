import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:uuid/uuid.dart';

/// Service to manage draft state and operations
class DraftService extends ChangeNotifier {
  final League league;
  final String currentUserId;
  final List<RosterPlayer> allPlayers;
  
  DraftState _draftState;
  Timer? _pickTimer;
  int _remainingSeconds = 0;
  
  final _uuid = const Uuid();
  
  // Callbacks
  VoidCallback? onDraftComplete;
  void Function(DraftPick pick)? onPickMade;
  
  DraftService({
    required this.league,
    required this.currentUserId,
    required this.allPlayers,
  }) : _draftState = DraftState(
         leagueId: league.id,
         status: DraftStatus.scheduled,
       );
  
  // Getters
  DraftState get draftState => _draftState;
  int get remainingSeconds => _remainingSeconds;
  bool get isMyTurn => _draftState.currentPickUserId == currentUserId;
  bool get isDraftInProgress => _draftState.status == DraftStatus.inProgress;
  bool get isDraftComplete => _draftState.status == DraftStatus.completed;
  
  int get pickTimerSeconds => league.draftSettings?.pickTimerSeconds ?? 90;
  int get rosterSize => league.draftSettings?.rosterSize ?? 18;
  int get totalPicks => rosterSize * (league.draftSettings?.draftOrder.length ?? league.maxMembers);
  
  /// Get available players (not yet drafted)
  List<RosterPlayer> get availablePlayers {
    return allPlayers.where((p) => _draftState.isPlayerAvailable(p.id)).toList();
  }
  
  /// Get available players filtered by position
  List<RosterPlayer> getAvailablePlayersByPosition(PlayerPosition? position) {
    var players = availablePlayers;
    if (position != null) {
      players = players.where((p) => _mapPosition(p.position) == position).toList();
    }
    return players;
  }
  
  /// Get my picks
  List<DraftPick> get myPicks => _draftState.getPicksForUser(currentUserId);
  
  /// Get picks for a specific user
  List<DraftPick> getPicksForUser(String oderId) => _draftState.getPicksForUser(oderId);
  
  /// Get current picking user info
  String? get currentPickingUserId => _draftState.currentPickUserId;
  
  /// Get current round
  int get currentRound => _draftState.currentRound;
  
  /// Get current pick in round
  int get currentPickInRound => _draftState.currentPick;
  
  /// Get overall pick number
  int get overallPickNumber => _draftState.totalPicksMade + 1;
  
  /// Initialize draft with member list
  Future<void> initializeDraft(List<LeagueMember> members) async {
    final draftOrder = league.draftSettings?.draftOrder ?? 
        members.map((m) => m.oderId).toList();
    
    // If draft order not set, use join order
    final order = draftOrder.isEmpty 
        ? members.map((m) => m.oderId).toList()
        : draftOrder;
    
    if (order.isEmpty) {
      debugPrint('DraftService: No members to draft with');
      return;
    }
    
    _draftState = DraftState(
      leagueId: league.id,
      status: DraftStatus.inProgress,
      currentRound: 1,
      currentPick: 1,
      currentPickUserId: order.first,
      pickStartTime: DateTime.now(),
    );
    
    _remainingSeconds = pickTimerSeconds;
    _startPickTimer();
    
    notifyListeners();
  }
  
  /// Start the draft (called when draft time arrives)
  Future<void> startDraft(List<LeagueMember> members) async {
    await initializeDraft(members);
  }
  
  /// Make a pick
  Future<bool> makePick(RosterPlayer player) async {
    if (!isDraftInProgress) {
      debugPrint('DraftService: Draft not in progress');
      return false;
    }
    
    if (!isMyTurn) {
      debugPrint('DraftService: Not your turn to pick');
      return false;
    }
    
    if (!_draftState.isPlayerAvailable(player.id)) {
      debugPrint('DraftService: Player already drafted');
      return false;
    }
    
    return await _executePick(
      player: player,
      oderId: currentUserId,
      userName: 'You', // Will be replaced with actual name
      isAutoPick: false,
    );
  }
  
  /// Execute a pick (internal)
  Future<bool> _executePick({
    required RosterPlayer player,
    required String oderId,
    required String userName,
    required bool isAutoPick,
  }) async {
    _stopPickTimer();
    
    final pick = DraftPick(
      id: _uuid.v4(),
      leagueId: league.id,
      userId: oderId,
      userName: userName,
      playerId: player.id,
      playerName: player.displayName,
      playerImageUrl: player.imagePath,
      teamName: player.teamName,
      position: _mapPosition(player.position),
      round: _draftState.currentRound,
      pickNumber: _draftState.totalPicksMade + 1,
      pickedAt: DateTime.now(),
      isAutoPick: isAutoPick,
    );
    
    // Update draft state
    final newPicks = [..._draftState.picks, pick];
    final newDraftedIds = [..._draftState.draftedPlayerIds, player.id];
    
    // Calculate next pick
    final draftOrder = league.draftSettings?.draftOrder ?? [];
    final numTeams = draftOrder.length;
    
    if (numTeams == 0) {
      debugPrint('DraftService: No draft order set');
      return false;
    }
    
    final totalPicksMade = newPicks.length;
    final isComplete = totalPicksMade >= totalPicks;
    
    if (isComplete) {
      _draftState = _draftState.copyWith(
        status: DraftStatus.completed,
        picks: newPicks,
        draftedPlayerIds: newDraftedIds,
        currentPickUserId: null,
      );
      onDraftComplete?.call();
    } else {
      // Calculate next round and pick
      final nextOverallPick = totalPicksMade + 1;
      final (nextRound, nextPickInRound) = DraftOrderCalculator.getRoundAndPick(
        overallPick: nextOverallPick,
        teamsCount: numTeams,
      );
      
      final nextUserId = DraftOrderCalculator.getPickingUser(
        draftOrder: draftOrder,
        round: nextRound,
        pickInRound: nextPickInRound,
        orderType: league.draftSettings?.orderType ?? DraftOrderType.snake,
      );
      
      _draftState = _draftState.copyWith(
        currentRound: nextRound,
        currentPick: nextPickInRound,
        currentPickUserId: nextUserId,
        pickStartTime: DateTime.now(),
        picks: newPicks,
        draftedPlayerIds: newDraftedIds,
      );
      
      _remainingSeconds = pickTimerSeconds;
      _startPickTimer();
    }
    
    onPickMade?.call(pick);
    notifyListeners();
    
    return true;
  }
  
  /// Auto-pick best available player using smart ranking algorithm
  Future<void> _autoPick(String oderId, String userName) async {
    // Get user's current picks to determine needs
    final userPicks = _draftState.getPicksForUser(oderId);
    final positionCounts = <PlayerPosition, int>{};
    
    for (final pick in userPicks) {
      positionCounts[pick.position] = (positionCounts[pick.position] ?? 0) + 1;
    }
    
    // Roster requirements with priority weights
    // Format: position -> (minRequired, maxRequired, priorityMultiplier)
    final requirements = <PlayerPosition, (int, int, double)>{
      PlayerPosition.goalkeeper: (2, 2, 0.8),   // Need exactly 2 GK
      PlayerPosition.defender: (5, 6, 1.0),     // Need 5-6 DEF
      PlayerPosition.midfielder: (5, 6, 1.0),   // Need 5-6 MID
      PlayerPosition.attacker: (3, 4, 1.2),     // Need 3-4 FWD (premium position)
    };
    
    // Calculate position urgency (higher = more urgent)
    final positionUrgency = <PlayerPosition, double>{};
    for (final entry in requirements.entries) {
      final position = entry.key;
      final (minReq, _, priorityMult) = entry.value;
      final count = positionCounts[position] ?? 0;
      
      if (count < minReq) {
        // Urgency increases as we get further from minimum
        final deficit = minReq - count;
        positionUrgency[position] = deficit * priorityMult * 2.0;
      } else {
        positionUrgency[position] = 0.0;
      }
    }
    
    // For forwards, combine attacker and forward counts
    final fwdCount = (positionCounts[PlayerPosition.attacker] ?? 0) + 
                     (positionCounts[PlayerPosition.forward] ?? 0);
    if (fwdCount < 3) {
      positionUrgency[PlayerPosition.forward] = (3 - fwdCount) * 1.2 * 2.0;
    }
    
    // Get all available players with scores
    final scoredPlayers = <(RosterPlayer, double)>[];
    
    for (final player in availablePlayers) {
      final position = _mapPosition(player.position);
      final posCount = positionCounts[position] ?? 0;
      final (_, maxReq, _) = requirements[position] ?? (0, 99, 1.0);
      
      // Skip if we already have max of this position
      if (posCount >= maxReq) continue;
      
      // Calculate player score
      double score = 0.0;
      
      // 1. Projected points (primary factor)
      final projectedPoints = player.projectedPoints ?? 0.0;
      score += projectedPoints * 10.0;
      
      // 2. Position urgency bonus
      final urgency = positionUrgency[position] ?? 0.0;
      score += urgency * 20.0;
      
      // 3. Value-based scoring (best players go early in draft)
      // Higher priced players are generally better
      score += player.price * 2.0;
      
      // 4. Scarcity bonus (fewer players available = more valuable)
      final positionAvailable = availablePlayers.where(
        (p) => _mapPosition(p.position) == position
      ).length;
      if (positionAvailable < 20) {
        score += (20 - positionAvailable) * 3.0;
      }
      
      // 5. Early round GK penalty (don't draft GK too early)
      if (position == PlayerPosition.goalkeeper && _draftState.currentRound < 8) {
        score -= 50.0;
      }
      
      // 6. Late round position needs (ensure we fill minimum requirements)
      final remainingPicks = rosterSize - userPicks.length;
      final remainingNeeded = requirements.entries
          .map((e) => (e.value.$1 - (positionCounts[e.key] ?? 0)).clamp(0, 99))
          .fold(0, (a, b) => a + b);
      
      if (remainingPicks <= remainingNeeded + 2 && urgency > 0) {
        // We need to prioritize filling requirements
        score += urgency * 30.0;
      }
      
      scoredPlayers.add((player, score));
    }
    
    if (scoredPlayers.isEmpty) {
      debugPrint('DraftService: No players available for auto-pick');
      return;
    }
    
    // Sort by score (highest first)
    scoredPlayers.sort((a, b) => b.$2.compareTo(a.$2));
    
    // Pick the best player
    final bestPlayer = scoredPlayers.first.$1;
    debugPrint('DraftService: Auto-picking ${bestPlayer.displayName} '
        '(score: ${scoredPlayers.first.$2.toStringAsFixed(1)}, '
        'projected: ${bestPlayer.projectedPoints}, '
        'position: ${bestPlayer.position})');
    
    await _executePick(
      player: bestPlayer,
      oderId: oderId,
      userName: userName,
      isAutoPick: true,
    );
  }
  
  /// Start pick timer
  void _startPickTimer() {
    _stopPickTimer();
    
    _pickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // Time's up - auto-pick
        _stopPickTimer();
        if (_draftState.currentPickUserId != null) {
          // Find user name from draft order
          // For simplicity, using "Auto" as name - should be fetched from members
          _autoPick(_draftState.currentPickUserId!, 'Auto');
        }
      }
    });
  }
  
  /// Stop pick timer
  void _stopPickTimer() {
    _pickTimer?.cancel();
    _pickTimer = null;
  }
  
  /// Pause draft (commissioner only)
  void pauseDraft() {
    _stopPickTimer();
    notifyListeners();
  }
  
  /// Resume draft (commissioner only)
  void resumeDraft() {
    if (isDraftInProgress) {
      _startPickTimer();
      notifyListeners();
    }
  }
  
  /// Map position string to PlayerPosition enum
  PlayerPosition _mapPosition(String positionName) {
    final lower = positionName.toLowerCase();
    if (lower.contains('goalkeeper') || lower.contains('gk')) {
      return PlayerPosition.goalkeeper;
    } else if (lower.contains('defender') || lower.contains('def') || lower.contains('back')) {
      return PlayerPosition.defender;
    } else if (lower.contains('midfielder') || lower.contains('mid')) {
      return PlayerPosition.midfielder;
    } else if (lower.contains('forward') || lower.contains('fwd') || 
               lower.contains('attacker') || lower.contains('striker')) {
      return PlayerPosition.attacker;
    }
    return PlayerPosition.midfielder;
  }
  
  @override
  void dispose() {
    _stopPickTimer();
    super.dispose();
  }
}

