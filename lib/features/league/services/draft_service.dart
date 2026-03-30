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
  List<String> _draftOrder = [];
  List<int> _userQueuedPlayerIds = [];

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
  int get totalPicks =>
      rosterSize *
      (_draftOrder.isNotEmpty ? _draftOrder.length : league.maxMembers);
  List<DraftPick> get picks => _draftState.picks;

  void setUserQueuedPlayers(List<int> playerIds) {
    _userQueuedPlayerIds = List<int>.from(playerIds);
  }

  /// Get available players (not yet drafted)
  List<RosterPlayer> get availablePlayers {
    return allPlayers
        .where((p) => _draftState.isPlayerAvailable(p.id))
        .toList();
  }

  /// Get available players filtered by position
  List<RosterPlayer> getAvailablePlayersByPosition(PlayerPosition? position) {
    var players = availablePlayers;
    if (position != null) {
      players = players
          .where((p) => _mapPosition(p.position) == position)
          .toList();
    }
    return players;
  }

  /// Get my picks
  List<DraftPick> get myPicks => _draftState.getPicksForUser(currentUserId);

  /// Get picks for a specific user
  List<DraftPick> getPicksForUser(String oderId) =>
      _draftState.getPicksForUser(oderId);

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
    final draftOrder =
        league.draftSettings?.draftOrder ??
        members.map((m) => m.oderId).toList();

    // If draft order not set, use join order
    final order = draftOrder.isEmpty
        ? members.map((m) => m.oderId).toList()
        : draftOrder;

    if (order.isEmpty) {
      debugPrint('DraftService: No members to draft with');
      return;
    }

    _draftOrder = List<String>.from(order);

    _draftState = DraftState(
      leagueId: league.id,
      status: DraftStatus.inProgress,
      currentRound: 1,
      currentPick: 1,
      currentPickUserId: order.first,
      pickStartTime: DateTime.now(),
    );

    _remainingSeconds = _timerSecondsForUser(order.first);
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

    if (!_canDraftPlayerForUser(player: player, oderId: currentUserId)) {
      debugPrint(
        'DraftService: Pick would make the roster impossible to complete',
      );
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
    final numTeams = _draftOrder.length;

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
        draftOrder: _draftOrder,
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

      _remainingSeconds = _timerSecondsForUser(nextUserId);
      _startPickTimer();
    }

    onPickMade?.call(pick);
    notifyListeners();

    return true;
  }

  /// Auto-pick best available player using smart ranking algorithm
  Future<void> _autoPick(String oderId, String userName) async {
    if (oderId == currentUserId) {
      for (final queuedPlayerId in _userQueuedPlayerIds) {
        final queuedPlayer = availablePlayers
            .where((p) => p.id == queuedPlayerId)
            .firstOrNull;
        if (queuedPlayer != null) {
          await _executePick(
            player: queuedPlayer,
            oderId: oderId,
            userName: userName,
            isAutoPick: true,
          );
          return;
        }
      }
    }

    // Get user's current picks to determine needs
    final userPicks = _draftState.getPicksForUser(oderId);
    final positionCounts = <PlayerPosition, int>{};

    for (final pick in userPicks) {
      positionCounts[pick.position] = (positionCounts[pick.position] ?? 0) + 1;
    }

    // Minimum viable starting squad:
    // 1 GK, 3 DEF, 3 MID, 1 FWD. Remaining slots are flexible.
    final requirements = _minimumRosterRequirements;

    // Calculate position urgency (higher = more urgent)
    final positionUrgency = <PlayerPosition, double>{};
    for (final entry in requirements.entries) {
      final position = entry.key;
      final (minReq, priorityMult) = entry.value;
      final count = _getPositionCount(positionCounts, position);

      if (count < minReq) {
        // Urgency increases as we get further from minimum
        final deficit = minReq - count;
        positionUrgency[position] = deficit * priorityMult * 2.0;
      } else {
        positionUrgency[position] = 0.0;
      }
    }

    // Get all available players with scores
    final scoredPlayers = <(RosterPlayer, double)>[];

    for (final player in availablePlayers) {
      final position = _mapPosition(player.position);
      if (!_canDraftPlayerForUser(player: player, oderId: oderId)) continue;

      // Calculate player score
      double score = 0.0;

      // 1. Next-match projected points drive the auto-pick baseline.
      final projectedPoints = player.projectedSeasonPoints;
      score += projectedPoints * 25.0;

      // 2. Position urgency bonus
      final urgency = positionUrgency[position] ?? 0.0;
      score += urgency * 12.0;

      // 3. Value-based scoring (best players go early in draft)
      // Higher priced players are generally better
      score += player.price;

      // 4. Scarcity bonus (fewer players available = more valuable)
      final positionAvailable = availablePlayers
          .where((p) => _mapPosition(p.position) == position)
          .length;
      if (positionAvailable < 20) {
        score += (20 - positionAvailable) * 3.0;
      }

      // 5. Early round GK penalty (don't draft GK too early)
      if (position == PlayerPosition.goalkeeper &&
          _draftState.currentRound < 8) {
        score -= 50.0;
      }

      // 6. Late round position needs (ensure we fill minimum requirements)
      final remainingPicks = rosterSize - userPicks.length;
      final remainingNeeded = requirements.entries
          .map(
            (e) => (e.value.$1 - _getPositionCount(positionCounts, e.key))
                .clamp(0, 99),
          )
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
    debugPrint(
      'DraftService: Auto-picking ${bestPlayer.displayName} '
      '(score: ${scoredPlayers.first.$2.toStringAsFixed(1)}, '
      'projectedSeason: ${bestPlayer.projectedSeasonPoints}, '
      'position: ${bestPlayer.position})',
    );

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

  int _timerSecondsForUser(String? userId) {
    if (userId == currentUserId) {
      return pickTimerSeconds < 60 ? 60 : pickTimerSeconds;
    }
    return pickTimerSeconds;
  }

  Map<PlayerPosition, (int minRequired, double priorityMultiplier)>
  get _minimumRosterRequirements => const {
    PlayerPosition.goalkeeper: (1, 0.8),
    PlayerPosition.defender: (3, 1.0),
    PlayerPosition.midfielder: (3, 1.0),
    PlayerPosition.attacker: (1, 1.2),
  };

  bool _canDraftPlayerForUser({
    required RosterPlayer player,
    required String oderId,
  }) {
    final userPicks = _draftState.getPicksForUser(oderId);
    if (userPicks.length >= rosterSize) return false;

    final positionCounts = <PlayerPosition, int>{};
    for (final pick in userPicks) {
      positionCounts[pick.position] = (positionCounts[pick.position] ?? 0) + 1;
    }

    final nextPosition = _mapPosition(player.position);
    positionCounts[nextPosition] =
        _getPositionCount(positionCounts, nextPosition) + 1;

    final remainingSlots = rosterSize - userPicks.length - 1;
    final remainingMinimumNeed = _minimumRosterRequirements.entries
        .map(
          (entry) =>
              (entry.value.$1 - _getPositionCount(positionCounts, entry.key))
                  .clamp(0, rosterSize),
        )
        .fold<int>(0, (sum, deficit) => sum + deficit);

    return remainingMinimumNeed <= remainingSlots;
  }

  int _getPositionCount(
    Map<PlayerPosition, int> positionCounts,
    PlayerPosition position,
  ) {
    if (position == PlayerPosition.attacker ||
        position == PlayerPosition.forward) {
      return (positionCounts[PlayerPosition.attacker] ?? 0) +
          (positionCounts[PlayerPosition.forward] ?? 0);
    }
    return positionCounts[position] ?? 0;
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
    } else if (lower.contains('defender') ||
        lower.contains('def') ||
        lower.contains('back')) {
      return PlayerPosition.defender;
    } else if (lower.contains('midfielder') || lower.contains('mid')) {
      return PlayerPosition.midfielder;
    } else if (lower.contains('forward') ||
        lower.contains('fwd') ||
        lower.contains('attacker') ||
        lower.contains('striker')) {
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
