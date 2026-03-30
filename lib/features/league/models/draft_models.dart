// Draft Mode Models for Fantasy League
// These models support the draft-style league where players are uniquely owned

import 'package:fantacy11/features/league/models/league_models.dart';

/// League scoring/gameplay mode
enum LeagueMode {
  classic, // Budget-based, players can be shared across teams
  draft;   // Draft-based, unique player ownership

  String get displayName {
    switch (this) {
      case LeagueMode.classic:
        return 'Classic';
      case LeagueMode.draft:
        return 'Draft';
    }
  }

  String get description {
    switch (this) {
      case LeagueMode.classic:
        return 'Build your team within a budget. Multiple managers can have the same players.';
      case LeagueMode.draft:
        return 'Draft players in turns. Each player can only be owned by one manager.';
    }
  }

  String get iconName {
    switch (this) {
      case LeagueMode.classic:
        return 'account_balance_wallet';
      case LeagueMode.draft:
        return 'format_list_numbered';
    }
  }
}

/// Draft order type
enum DraftOrderType {
  snake,  // 1→10, then 10→1, then 1→10...
  linear; // Always 1→10

  String get displayName {
    switch (this) {
      case DraftOrderType.snake:
        return 'Snake';
      case DraftOrderType.linear:
        return 'Linear';
    }
  }

  String get description {
    switch (this) {
      case DraftOrderType.snake:
        return 'Order reverses each round (1-10, 10-1, 1-10...)';
      case DraftOrderType.linear:
        return 'Same order every round (1-10, 1-10, 1-10...)';
    }
  }
}

/// Draft status
enum DraftStatus {
  scheduled,  // Draft date set, waiting
  inProgress, // Draft is currently happening
  completed,  // Draft finished
  cancelled;  // Draft was cancelled

  String get displayName {
    switch (this) {
      case DraftStatus.scheduled:
        return 'Scheduled';
      case DraftStatus.inProgress:
        return 'In Progress';
      case DraftStatus.completed:
        return 'Completed';
      case DraftStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get colorValue {
    switch (this) {
      case DraftStatus.scheduled:
        return 0xFFFF9800; // Orange
      case DraftStatus.inProgress:
        return 0xFF4CAF50; // Green
      case DraftStatus.completed:
        return 0xFF2196F3; // Blue
      case DraftStatus.cancelled:
        return 0xFFF44336; // Red
    }
  }
}

/// Trade approval type
enum TradeApproval {
  none,        // No approval needed
  commissioner, // Commissioner must approve
  leagueVote;  // League members vote

  String get displayName {
    switch (this) {
      case TradeApproval.none:
        return 'No Approval';
      case TradeApproval.commissioner:
        return 'Commissioner Approval';
      case TradeApproval.leagueVote:
        return 'League Vote';
    }
  }

  String get description {
    switch (this) {
      case TradeApproval.none:
        return 'Trades are processed immediately';
      case TradeApproval.commissioner:
        return 'Commissioner must approve all trades';
      case TradeApproval.leagueVote:
        return 'League members vote on trades (majority wins)';
    }
  }
}

/// Trade status
enum TradeStatus {
  pending,   // Waiting for response
  accepted,  // Trade accepted, waiting for approval (if needed)
  approved,  // Approved and executed
  rejected,  // Rejected by recipient
  vetoed,    // Vetoed by commissioner or league vote
  cancelled, // Cancelled by proposer
  expired;   // Time ran out

  String get displayName {
    switch (this) {
      case TradeStatus.pending:
        return 'Pending';
      case TradeStatus.accepted:
        return 'Accepted';
      case TradeStatus.approved:
        return 'Completed';
      case TradeStatus.rejected:
        return 'Rejected';
      case TradeStatus.vetoed:
        return 'Vetoed';
      case TradeStatus.cancelled:
        return 'Cancelled';
      case TradeStatus.expired:
        return 'Expired';
    }
  }
}

/// Draft settings configured by commissioner
class DraftSettings {
  final DraftOrderType orderType;
  final List<String> draftOrder; // User IDs in draft order
  final int pickTimerSeconds; // Seconds per pick (60, 90, 120, etc.)
  final DateTime? draftDateTime; // Scheduled draft time
  final bool autoPick; // Auto-pick if timer runs out
  final int rosterSize; // Total roster slots (default 18)

  const DraftSettings({
    this.orderType = DraftOrderType.snake,
    this.draftOrder = const [],
    this.pickTimerSeconds = 90,
    this.draftDateTime,
    this.autoPick = true,
    this.rosterSize = 18,
  });

  DraftSettings copyWith({
    DraftOrderType? orderType,
    List<String>? draftOrder,
    int? pickTimerSeconds,
    DateTime? draftDateTime,
    bool? autoPick,
    int? rosterSize,
  }) {
    return DraftSettings(
      orderType: orderType ?? this.orderType,
      draftOrder: draftOrder ?? this.draftOrder,
      pickTimerSeconds: pickTimerSeconds ?? this.pickTimerSeconds,
      draftDateTime: draftDateTime ?? this.draftDateTime,
      autoPick: autoPick ?? this.autoPick,
      rosterSize: rosterSize ?? this.rosterSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderType': orderType.name,
      'draftOrder': draftOrder,
      'pickTimerSeconds': pickTimerSeconds,
      'draftDateTime': draftDateTime?.toIso8601String(),
      'autoPick': autoPick,
      'rosterSize': rosterSize,
    };
  }

  factory DraftSettings.fromJson(Map<String, dynamic> json) {
    return DraftSettings(
      orderType: DraftOrderType.values.firstWhere(
        (e) => e.name == json['orderType'],
        orElse: () => DraftOrderType.snake,
      ),
      draftOrder: (json['draftOrder'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      pickTimerSeconds: json['pickTimerSeconds'] as int? ?? 90,
      draftDateTime: json['draftDateTime'] != null
          ? DateTime.parse(json['draftDateTime'] as String)
          : null,
      autoPick: json['autoPick'] as bool? ?? true,
      rosterSize: json['rosterSize'] as int? ?? 18,
    );
  }

  /// Get formatted timer duration
  String get formattedTimer {
    if (pickTimerSeconds >= 60) {
      final minutes = pickTimerSeconds ~/ 60;
      final seconds = pickTimerSeconds % 60;
      if (seconds == 0) {
        return '$minutes min';
      }
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    return '$pickTimerSeconds sec';
  }
}

/// Trade settings configured by commissioner
class TradeSettings {
  final TradeApproval approvalType;
  final DateTime? tradeDeadline; // No trades after this date
  final int votingPeriodHours; // Hours for league vote (if applicable)
  final bool allowMultiPlayerTrades; // Can trades include multiple players

  const TradeSettings({
    this.approvalType = TradeApproval.none,
    this.tradeDeadline,
    this.votingPeriodHours = 24,
    this.allowMultiPlayerTrades = true,
  });

  bool get hasDeadline => tradeDeadline != null;
  
  bool get isDeadlinePassed {
    if (tradeDeadline == null) return false;
    return DateTime.now().isAfter(tradeDeadline!);
  }

  TradeSettings copyWith({
    TradeApproval? approvalType,
    DateTime? tradeDeadline,
    int? votingPeriodHours,
    bool? allowMultiPlayerTrades,
  }) {
    return TradeSettings(
      approvalType: approvalType ?? this.approvalType,
      tradeDeadline: tradeDeadline ?? this.tradeDeadline,
      votingPeriodHours: votingPeriodHours ?? this.votingPeriodHours,
      allowMultiPlayerTrades: allowMultiPlayerTrades ?? this.allowMultiPlayerTrades,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'approvalType': approvalType.name,
      'tradeDeadline': tradeDeadline?.toIso8601String(),
      'votingPeriodHours': votingPeriodHours,
      'allowMultiPlayerTrades': allowMultiPlayerTrades,
    };
  }

  factory TradeSettings.fromJson(Map<String, dynamic> json) {
    return TradeSettings(
      approvalType: TradeApproval.values.firstWhere(
        (e) => e.name == json['approvalType'],
        orElse: () => TradeApproval.none,
      ),
      tradeDeadline: json['tradeDeadline'] != null
          ? DateTime.parse(json['tradeDeadline'] as String)
          : null,
      votingPeriodHours: json['votingPeriodHours'] as int? ?? 24,
      allowMultiPlayerTrades: json['allowMultiPlayerTrades'] as bool? ?? true,
    );
  }
}

/// Draft state - tracks the current state of the draft
class DraftState {
  final String leagueId;
  final DraftStatus status;
  final int currentRound; // 1-based round number
  final int currentPick; // 1-based pick in current round
  final String? currentPickUserId; // User who is currently picking
  final DateTime? pickStartTime; // When current pick timer started
  final List<DraftPick> picks; // All picks made so far
  final List<int> draftedPlayerIds; // IDs of players already drafted

  const DraftState({
    required this.leagueId,
    this.status = DraftStatus.scheduled,
    this.currentRound = 1,
    this.currentPick = 1,
    this.currentPickUserId,
    this.pickStartTime,
    this.picks = const [],
    this.draftedPlayerIds = const [],
  });

  /// Total picks made
  int get totalPicksMade => picks.length;

  /// Check if a player is available (not drafted)
  bool isPlayerAvailable(int playerId) {
    return !draftedPlayerIds.contains(playerId);
  }

  /// Get picks for a specific user
  List<DraftPick> getPicksForUser(String userId) {
    return picks.where((p) => p.userId == userId).toList();
  }

  /// Get remaining seconds for current pick
  int getRemainingSeconds(int pickTimerSeconds) {
    if (pickStartTime == null) return pickTimerSeconds;
    final elapsed = DateTime.now().difference(pickStartTime!).inSeconds;
    return (pickTimerSeconds - elapsed).clamp(0, pickTimerSeconds);
  }

  DraftState copyWith({
    String? leagueId,
    DraftStatus? status,
    int? currentRound,
    int? currentPick,
    String? currentPickUserId,
    DateTime? pickStartTime,
    List<DraftPick>? picks,
    List<int>? draftedPlayerIds,
  }) {
    return DraftState(
      leagueId: leagueId ?? this.leagueId,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
      currentPick: currentPick ?? this.currentPick,
      currentPickUserId: currentPickUserId ?? this.currentPickUserId,
      pickStartTime: pickStartTime ?? this.pickStartTime,
      picks: picks ?? this.picks,
      draftedPlayerIds: draftedPlayerIds ?? this.draftedPlayerIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leagueId': leagueId,
      'status': status.name,
      'currentRound': currentRound,
      'currentPick': currentPick,
      'currentPickUserId': currentPickUserId,
      'pickStartTime': pickStartTime?.toIso8601String(),
      'picks': picks.map((p) => p.toJson()).toList(),
      'draftedPlayerIds': draftedPlayerIds,
    };
  }

  factory DraftState.fromJson(Map<String, dynamic> json) {
    return DraftState(
      leagueId: json['leagueId'] as String,
      status: DraftStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DraftStatus.scheduled,
      ),
      currentRound: json['currentRound'] as int? ?? 1,
      currentPick: json['currentPick'] as int? ?? 1,
      currentPickUserId: json['currentPickUserId'] as String?,
      pickStartTime: json['pickStartTime'] != null
          ? DateTime.parse(json['pickStartTime'] as String)
          : null,
      picks: (json['picks'] as List<dynamic>?)
          ?.map((p) => DraftPick.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      draftedPlayerIds: (json['draftedPlayerIds'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
    );
  }
}

/// Individual draft pick record
class DraftPick {
  final String id;
  final String leagueId;
  final String userId;
  final String userName;
  final int playerId;
  final String playerName;
  final String? playerImageUrl;
  final String? teamName;
  final PlayerPosition position;
  final int round;
  final int pickNumber; // Overall pick number (1, 2, 3...)
  final DateTime pickedAt;
  final bool isAutoPick; // Was this an auto-pick?

  const DraftPick({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.userName,
    required this.playerId,
    required this.playerName,
    this.playerImageUrl,
    this.teamName,
    required this.position,
    required this.round,
    required this.pickNumber,
    required this.pickedAt,
    this.isAutoPick = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leagueId': leagueId,
      'userId': userId,
      'userName': userName,
      'playerId': playerId,
      'playerName': playerName,
      'playerImageUrl': playerImageUrl,
      'teamName': teamName,
      'position': position.name,
      'round': round,
      'pickNumber': pickNumber,
      'pickedAt': pickedAt.toIso8601String(),
      'isAutoPick': isAutoPick,
    };
  }

  factory DraftPick.fromJson(Map<String, dynamic> json) {
    return DraftPick(
      id: json['id'] as String,
      leagueId: json['leagueId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      playerId: json['playerId'] as int,
      playerName: json['playerName'] as String,
      playerImageUrl: json['playerImageUrl'] as String?,
      teamName: json['teamName'] as String?,
      position: PlayerPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => PlayerPosition.midfielder,
      ),
      round: json['round'] as int,
      pickNumber: json['pickNumber'] as int,
      pickedAt: DateTime.parse(json['pickedAt'] as String),
      isAutoPick: json['isAutoPick'] as bool? ?? false,
    );
  }
}

/// Trade proposal between two teams
class Trade {
  final String id;
  final String leagueId;
  final String proposerId; // User proposing the trade
  final String proposerName;
  final String recipientId; // User receiving the proposal
  final String recipientName;
  final List<TradePlayer> proposerPlayers; // Players offered by proposer
  final List<TradePlayer> recipientPlayers; // Players requested from recipient
  final String? message; // Optional message with trade
  final TradeStatus status;
  final DateTime proposedAt;
  final DateTime? respondedAt;
  final DateTime? expiresAt;
  final int? votesFor; // For league vote approval
  final int? votesAgainst;
  final List<String>? voters; // User IDs who have voted

  const Trade({
    required this.id,
    required this.leagueId,
    required this.proposerId,
    required this.proposerName,
    required this.recipientId,
    required this.recipientName,
    this.proposerPlayers = const [],
    this.recipientPlayers = const [],
    this.message,
    this.status = TradeStatus.pending,
    required this.proposedAt,
    this.respondedAt,
    this.expiresAt,
    this.votesFor,
    this.votesAgainst,
    this.voters,
  });

  /// Check if trade is still pending
  bool get isPending => status == TradeStatus.pending;

  /// Check if trade has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Get remaining time for response
  Duration? get timeRemaining {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Trade copyWith({
    String? id,
    String? leagueId,
    String? proposerId,
    String? proposerName,
    String? recipientId,
    String? recipientName,
    List<TradePlayer>? proposerPlayers,
    List<TradePlayer>? recipientPlayers,
    String? message,
    TradeStatus? status,
    DateTime? proposedAt,
    DateTime? respondedAt,
    DateTime? expiresAt,
    int? votesFor,
    int? votesAgainst,
    List<String>? voters,
  }) {
    return Trade(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      proposerId: proposerId ?? this.proposerId,
      proposerName: proposerName ?? this.proposerName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      proposerPlayers: proposerPlayers ?? this.proposerPlayers,
      recipientPlayers: recipientPlayers ?? this.recipientPlayers,
      message: message ?? this.message,
      status: status ?? this.status,
      proposedAt: proposedAt ?? this.proposedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      votesFor: votesFor ?? this.votesFor,
      votesAgainst: votesAgainst ?? this.votesAgainst,
      voters: voters ?? this.voters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leagueId': leagueId,
      'proposerId': proposerId,
      'proposerName': proposerName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'proposerPlayers': proposerPlayers.map((p) => p.toJson()).toList(),
      'recipientPlayers': recipientPlayers.map((p) => p.toJson()).toList(),
      'message': message,
      'status': status.name,
      'proposedAt': proposedAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'votesFor': votesFor,
      'votesAgainst': votesAgainst,
      'voters': voters,
    };
  }

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as String,
      leagueId: json['leagueId'] as String,
      proposerId: json['proposerId'] as String,
      proposerName: json['proposerName'] as String,
      recipientId: json['recipientId'] as String,
      recipientName: json['recipientName'] as String,
      proposerPlayers: (json['proposerPlayers'] as List<dynamic>?)
          ?.map((p) => TradePlayer.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      recipientPlayers: (json['recipientPlayers'] as List<dynamic>?)
          ?.map((p) => TradePlayer.fromJson(p as Map<String, dynamic>))
          .toList() ?? [],
      message: json['message'] as String?,
      status: TradeStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TradeStatus.pending,
      ),
      proposedAt: DateTime.parse(json['proposedAt'] as String),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      votesFor: json['votesFor'] as int?,
      votesAgainst: json['votesAgainst'] as int?,
      voters: (json['voters'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

/// Player in a trade
class TradePlayer {
  final int playerId;
  final String playerName;
  final String? playerImageUrl;
  final String? teamName;
  final PlayerPosition position;

  const TradePlayer({
    required this.playerId,
    required this.playerName,
    this.playerImageUrl,
    this.teamName,
    required this.position,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'playerImageUrl': playerImageUrl,
      'teamName': teamName,
      'position': position.name,
    };
  }

  factory TradePlayer.fromJson(Map<String, dynamic> json) {
    return TradePlayer(
      playerId: json['playerId'] as int,
      playerName: json['playerName'] as String,
      playerImageUrl: json['playerImageUrl'] as String?,
      teamName: json['teamName'] as String?,
      position: PlayerPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => PlayerPosition.midfielder,
      ),
    );
  }

  /// Convert from FantasyTeamPlayer
  factory TradePlayer.fromFantasyTeamPlayer(FantasyTeamPlayer player) {
    return TradePlayer(
      playerId: player.playerId,
      playerName: player.playerName,
      playerImageUrl: player.playerImageUrl,
      teamName: player.teamName,
      position: player.position,
    );
  }
}

/// Free agent transaction (pickup/drop)
class FreeAgentTransaction {
  final String id;
  final String leagueId;
  final String userId;
  final String userName;
  final int? droppedPlayerId;
  final String? droppedPlayerName;
  final int? addedPlayerId;
  final String? addedPlayerName;
  final DateTime transactionAt;

  const FreeAgentTransaction({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.userName,
    this.droppedPlayerId,
    this.droppedPlayerName,
    this.addedPlayerId,
    this.addedPlayerName,
    required this.transactionAt,
  });

  bool get isDrop => droppedPlayerId != null && addedPlayerId == null;
  bool get isAdd => addedPlayerId != null && droppedPlayerId == null;
  bool get isSwap => droppedPlayerId != null && addedPlayerId != null;

  String get description {
    if (isSwap) {
      return '$userName dropped $droppedPlayerName, added $addedPlayerName';
    } else if (isDrop) {
      return '$userName dropped $droppedPlayerName';
    } else if (isAdd) {
      return '$userName added $addedPlayerName';
    }
    return 'Transaction';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leagueId': leagueId,
      'userId': userId,
      'userName': userName,
      'droppedPlayerId': droppedPlayerId,
      'droppedPlayerName': droppedPlayerName,
      'addedPlayerId': addedPlayerId,
      'addedPlayerName': addedPlayerName,
      'transactionAt': transactionAt.toIso8601String(),
    };
  }

  factory FreeAgentTransaction.fromJson(Map<String, dynamic> json) {
    return FreeAgentTransaction(
      id: json['id'] as String,
      leagueId: json['leagueId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      droppedPlayerId: json['droppedPlayerId'] as int?,
      droppedPlayerName: json['droppedPlayerName'] as String?,
      addedPlayerId: json['addedPlayerId'] as int?,
      addedPlayerName: json['addedPlayerName'] as String?,
      transactionAt: DateTime.parse(json['transactionAt'] as String),
    );
  }
}

/// Helper to calculate draft pick order
class DraftOrderCalculator {
  /// Calculate the user ID for a given pick in snake draft
  static String getPickingUser({
    required List<String> draftOrder,
    required int round,
    required int pickInRound,
    required DraftOrderType orderType,
  }) {
    if (draftOrder.isEmpty) {
      throw ArgumentError('Draft order cannot be empty');
    }

    final numTeams = draftOrder.length;
    
    if (orderType == DraftOrderType.linear) {
      // Linear: same order every round
      return draftOrder[(pickInRound - 1) % numTeams];
    }

    // Snake draft: reverse order on odd rounds (2nd, 4th, 6th...)
    final isReversedRound = round % 2 == 0;
    final index = pickInRound - 1;

    if (isReversedRound) {
      // Reversed: last to first
      return draftOrder[numTeams - 1 - (index % numTeams)];
    } else {
      // Normal: first to last
      return draftOrder[index % numTeams];
    }
  }

  /// Get the overall pick number from round and pick in round
  static int getOverallPickNumber({
    required int round,
    required int pickInRound,
    required int teamsCount,
  }) {
    return ((round - 1) * teamsCount) + pickInRound;
  }

  /// Get round and pick from overall pick number
  static (int round, int pickInRound) getRoundAndPick({
    required int overallPick,
    required int teamsCount,
  }) {
    final round = ((overallPick - 1) ~/ teamsCount) + 1;
    final pickInRound = ((overallPick - 1) % teamsCount) + 1;
    return (round, pickInRound);
  }
}

