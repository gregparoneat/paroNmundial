// Trade Service for Draft Leagues
// Handles trade proposals, acceptance, and execution

import 'package:flutter/foundation.dart';
import 'package:fantacy11/features/league/models/draft_models.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:uuid/uuid.dart';

/// Service to manage trades in draft leagues
class TradeService extends ChangeNotifier {
  final League league;
  final String currentUserId;
  
  // In-memory trade storage (would be replaced with repository in production)
  final List<Trade> _trades = [];
  final _uuid = const Uuid();
  
  // Callbacks
  void Function(Trade trade)? onTradeProposed;
  void Function(Trade trade)? onTradeAccepted;
  void Function(Trade trade)? onTradeRejected;
  void Function(Trade trade)? onTradeCompleted;
  void Function(Trade trade)? onTradeVetoed;
  
  TradeService({
    required this.league,
    required this.currentUserId,
    List<Trade>? initialTrades,
  }) {
    if (initialTrades != null) {
      _trades.addAll(initialTrades);
    }
  }
  
  // Getters
  TradeSettings get tradeSettings => league.tradeSettings ?? const TradeSettings();
  bool get isTradingEnabled => !tradeSettings.isDeadlinePassed;
  
  /// Get all trades for this league
  List<Trade> get allTrades => List.unmodifiable(_trades);
  
  /// Get pending trades where current user is involved
  List<Trade> get myPendingTrades => _trades.where((t) =>
    t.isPending && (t.proposerId == currentUserId || t.recipientId == currentUserId)
  ).toList();
  
  /// Get trades proposed to current user
  List<Trade> get incomingTrades => _trades.where((t) =>
    t.status == TradeStatus.pending && t.recipientId == currentUserId
  ).toList();
  
  /// Get trades proposed by current user
  List<Trade> get outgoingTrades => _trades.where((t) =>
    t.status == TradeStatus.pending && t.proposerId == currentUserId
  ).toList();
  
  /// Get trades awaiting league vote
  List<Trade> get tradesAwaitingVote => _trades.where((t) =>
    t.status == TradeStatus.accepted && 
    tradeSettings.approvalType == TradeApproval.leagueVote
  ).toList();
  
  /// Get trades awaiting commissioner approval
  List<Trade> get tradesAwaitingApproval => _trades.where((t) =>
    t.status == TradeStatus.accepted && 
    tradeSettings.approvalType == TradeApproval.commissioner
  ).toList();
  
  /// Get completed trades
  List<Trade> get completedTrades => _trades.where((t) =>
    t.status == TradeStatus.approved
  ).toList();
  
  /// Get trade history for current user
  List<Trade> get myTradeHistory => _trades.where((t) =>
    t.proposerId == currentUserId || t.recipientId == currentUserId
  ).toList()..sort((a, b) => b.proposedAt.compareTo(a.proposedAt));
  
  /// Propose a new trade
  Future<Trade?> proposeTrade({
    required String recipientId,
    required String recipientName,
    required List<TradePlayer> playersOffered,
    required List<TradePlayer> playersRequested,
    String? message,
  }) async {
    // Validate trading is enabled
    if (!isTradingEnabled) {
      debugPrint('TradeService: Trading deadline has passed');
      return null;
    }
    
    // Validate players
    if (playersOffered.isEmpty && playersRequested.isEmpty) {
      debugPrint('TradeService: Trade must include at least one player');
      return null;
    }
    
    // Check multi-player trade setting
    if (!tradeSettings.allowMultiPlayerTrades) {
      if (playersOffered.length > 1 || playersRequested.length > 1) {
        debugPrint('TradeService: Multi-player trades not allowed in this league');
        return null;
      }
    }
    
    final trade = Trade(
      id: _uuid.v4(),
      leagueId: league.id,
      proposerId: currentUserId,
      proposerName: 'You', // Would be fetched from user profile
      recipientId: recipientId,
      recipientName: recipientName,
      proposerPlayers: playersOffered,
      recipientPlayers: playersRequested,
      message: message,
      status: TradeStatus.pending,
      proposedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 48)), // 48 hour expiry
    );
    
    _trades.add(trade);
    onTradeProposed?.call(trade);
    notifyListeners();
    
    debugPrint('TradeService: Trade proposed to $recipientName');
    return trade;
  }
  
  /// Accept a trade proposal
  Future<bool> acceptTrade(String tradeId) async {
    final tradeIndex = _trades.indexWhere((t) => t.id == tradeId);
    if (tradeIndex == -1) {
      debugPrint('TradeService: Trade not found');
      return false;
    }
    
    final trade = _trades[tradeIndex];
    
    // Validate user is recipient
    if (trade.recipientId != currentUserId) {
      debugPrint('TradeService: Only recipient can accept trade');
      return false;
    }
    
    // Validate trade is pending
    if (trade.status != TradeStatus.pending) {
      debugPrint('TradeService: Trade is not pending');
      return false;
    }
    
    // Check if trade has expired
    if (trade.isExpired) {
      _trades[tradeIndex] = trade.copyWith(status: TradeStatus.expired);
      notifyListeners();
      debugPrint('TradeService: Trade has expired');
      return false;
    }
    
    // Determine next status based on approval type
    final newStatus = tradeSettings.approvalType == TradeApproval.none
        ? TradeStatus.approved
        : TradeStatus.accepted;
    
    _trades[tradeIndex] = trade.copyWith(
      status: newStatus,
      respondedAt: DateTime.now(),
    );
    
    onTradeAccepted?.call(_trades[tradeIndex]);
    
    // If no approval needed, execute trade immediately
    if (newStatus == TradeStatus.approved) {
      await _executeTrade(_trades[tradeIndex]);
      onTradeCompleted?.call(_trades[tradeIndex]);
    }
    
    notifyListeners();
    debugPrint('TradeService: Trade accepted (status: ${newStatus.displayName})');
    return true;
  }
  
  /// Reject a trade proposal
  Future<bool> rejectTrade(String tradeId) async {
    final tradeIndex = _trades.indexWhere((t) => t.id == tradeId);
    if (tradeIndex == -1) return false;
    
    final trade = _trades[tradeIndex];
    
    // Validate user is recipient
    if (trade.recipientId != currentUserId) {
      debugPrint('TradeService: Only recipient can reject trade');
      return false;
    }
    
    if (trade.status != TradeStatus.pending) {
      debugPrint('TradeService: Trade is not pending');
      return false;
    }
    
    _trades[tradeIndex] = trade.copyWith(
      status: TradeStatus.rejected,
      respondedAt: DateTime.now(),
    );
    
    onTradeRejected?.call(_trades[tradeIndex]);
    notifyListeners();
    
    debugPrint('TradeService: Trade rejected');
    return true;
  }
  
  /// Cancel a trade proposal (by proposer)
  Future<bool> cancelTrade(String tradeId) async {
    final tradeIndex = _trades.indexWhere((t) => t.id == tradeId);
    if (tradeIndex == -1) return false;
    
    final trade = _trades[tradeIndex];
    
    // Validate user is proposer
    if (trade.proposerId != currentUserId) {
      debugPrint('TradeService: Only proposer can cancel trade');
      return false;
    }
    
    if (trade.status != TradeStatus.pending) {
      debugPrint('TradeService: Trade is not pending');
      return false;
    }
    
    _trades[tradeIndex] = trade.copyWith(
      status: TradeStatus.cancelled,
      respondedAt: DateTime.now(),
    );
    
    notifyListeners();
    debugPrint('TradeService: Trade cancelled');
    return true;
  }
  
  /// Approve a trade (commissioner only)
  Future<bool> approveTrade(String tradeId, {bool isCommissioner = false}) async {
    if (!isCommissioner && tradeSettings.approvalType == TradeApproval.commissioner) {
      debugPrint('TradeService: Only commissioner can approve trades');
      return false;
    }
    
    final tradeIndex = _trades.indexWhere((t) => t.id == tradeId);
    if (tradeIndex == -1) return false;
    
    final trade = _trades[tradeIndex];
    
    if (trade.status != TradeStatus.accepted) {
      debugPrint('TradeService: Trade must be accepted before approval');
      return false;
    }
    
    _trades[tradeIndex] = trade.copyWith(
      status: TradeStatus.approved,
      respondedAt: DateTime.now(),
    );
    
    await _executeTrade(_trades[tradeIndex]);
    onTradeCompleted?.call(_trades[tradeIndex]);
    notifyListeners();
    
    debugPrint('TradeService: Trade approved by commissioner');
    return true;
  }
  
  /// Veto a trade (commissioner only)
  Future<bool> vetoTrade(String tradeId, {bool isCommissioner = false}) async {
    if (!isCommissioner) {
      debugPrint('TradeService: Only commissioner can veto trades');
      return false;
    }
    
    final tradeIndex = _trades.indexWhere((t) => t.id == tradeId);
    if (tradeIndex == -1) return false;
    
    final trade = _trades[tradeIndex];
    
    _trades[tradeIndex] = trade.copyWith(
      status: TradeStatus.vetoed,
      respondedAt: DateTime.now(),
    );
    
    onTradeVetoed?.call(_trades[tradeIndex]);
    notifyListeners();
    
    debugPrint('TradeService: Trade vetoed');
    return true;
  }
  
  /// Vote on a trade (for league vote approval)
  Future<bool> voteOnTrade(String tradeId, {required bool approve}) async {
    if (tradeSettings.approvalType != TradeApproval.leagueVote) {
      debugPrint('TradeService: League vote not enabled');
      return false;
    }
    
    final tradeIndex = _trades.indexWhere((t) => t.id == tradeId);
    if (tradeIndex == -1) return false;
    
    final trade = _trades[tradeIndex];
    
    if (trade.status != TradeStatus.accepted) {
      debugPrint('TradeService: Trade must be accepted before voting');
      return false;
    }
    
    // Check if user already voted
    if (trade.voters?.contains(currentUserId) ?? false) {
      debugPrint('TradeService: User already voted');
      return false;
    }
    
    // Can't vote on own trade
    if (trade.proposerId == currentUserId || trade.recipientId == currentUserId) {
      debugPrint('TradeService: Cannot vote on your own trade');
      return false;
    }
    
    final newVoters = <String>[...(trade.voters ?? []), currentUserId];
    final newVotesFor = (trade.votesFor ?? 0) + (approve ? 1 : 0);
    final newVotesAgainst = (trade.votesAgainst ?? 0) + (approve ? 0 : 1);
    
    _trades[tradeIndex] = trade.copyWith(
      votesFor: newVotesFor,
      votesAgainst: newVotesAgainst,
      voters: newVoters,
    );
    
    // Check if voting is complete (majority rule)
    final totalMembers = league.maxMembers - 2; // Exclude trade participants
    final votesNeeded = (totalMembers / 2).ceil();
    
    if (newVotesFor >= votesNeeded) {
      // Trade approved by league vote
      _trades[tradeIndex] = _trades[tradeIndex].copyWith(status: TradeStatus.approved);
      await _executeTrade(_trades[tradeIndex]);
      onTradeCompleted?.call(_trades[tradeIndex]);
    } else if (newVotesAgainst >= votesNeeded) {
      // Trade vetoed by league vote
      _trades[tradeIndex] = _trades[tradeIndex].copyWith(status: TradeStatus.vetoed);
      onTradeVetoed?.call(_trades[tradeIndex]);
    }
    
    notifyListeners();
    debugPrint('TradeService: Vote recorded (${approve ? "for" : "against"})');
    return true;
  }
  
  /// Execute a trade (swap players between teams)
  Future<void> _executeTrade(Trade trade) async {
    // This would update the actual team rosters in the repository
    // For now, just log it
    debugPrint('TradeService: Executing trade ${trade.id}');
    debugPrint('  ${trade.proposerName} receives: ${trade.recipientPlayers.map((p) => p.playerName).join(", ")}');
    debugPrint('  ${trade.recipientName} receives: ${trade.proposerPlayers.map((p) => p.playerName).join(", ")}');
    
    // TODO: Actually update team rosters via LeagueRepository
    // await leagueRepository.swapPlayers(
    //   leagueId: trade.leagueId,
    //   fromUserId: trade.proposerId,
    //   toUserId: trade.recipientId,
    //   fromPlayers: trade.proposerPlayers,
    //   toPlayers: trade.recipientPlayers,
    // );
  }
  
  /// Check for expired trades and update their status
  void checkExpiredTrades() {
    bool updated = false;
    
    for (int i = 0; i < _trades.length; i++) {
      final trade = _trades[i];
      if (trade.isPending && trade.isExpired) {
        _trades[i] = trade.copyWith(status: TradeStatus.expired);
        updated = true;
      }
    }
    
    if (updated) {
      notifyListeners();
    }
  }
  
  /// Load trades from repository
  Future<void> loadTrades(List<Trade> trades) async {
    _trades.clear();
    _trades.addAll(trades);
    checkExpiredTrades();
    notifyListeners();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}

