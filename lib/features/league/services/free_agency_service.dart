// Free Agency Service for Draft Leagues
// Handles player drops and pickups from the available pool

import 'package:flutter/foundation.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/features/league/models/draft_models.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:uuid/uuid.dart';

/// Service to manage free agency in draft leagues
class FreeAgencyService extends ChangeNotifier {
  final League league;
  final String currentUserId;
  final List<RosterPlayer> allPlayers;

  // Players owned by teams in this league (player ID -> user ID)
  final Map<int, String> _ownedPlayers = {};

  // Transaction history
  final List<FreeAgentTransaction> _transactions = [];

  // Fixture repository for checking locked players
  final FixturesRepository _fixturesRepository;

  final _uuid = const Uuid();

  // Callbacks
  void Function(FreeAgentTransaction transaction)? onPlayerDropped;
  void Function(FreeAgentTransaction transaction)? onPlayerAdded;
  void Function(FreeAgentTransaction transaction)? onPlayerSwapped;

  FreeAgencyService({
    required this.league,
    required this.currentUserId,
    required this.allPlayers,
    FixturesRepository? fixturesRepository,
    Map<int, String>? initialOwnedPlayers,
    List<FreeAgentTransaction>? initialTransactions,
  }) : _fixturesRepository = fixturesRepository ?? FixturesRepository() {
    if (initialOwnedPlayers != null) {
      _ownedPlayers.addAll(initialOwnedPlayers);
    }
    if (initialTransactions != null) {
      _transactions.addAll(initialTransactions);
    }
  }

  // Getters

  /// Get all available players (not owned by any team)
  List<RosterPlayer> get availablePlayers =>
      allPlayers.where((p) => !_ownedPlayers.containsKey(p.id)).toList();

  /// Get available players by position
  List<RosterPlayer> getAvailableByPosition(PlayerPosition? position) {
    var players = availablePlayers;
    if (position != null) {
      players = players
          .where((p) => _mapPosition(p.position) == position)
          .toList();
    }
    // Sort by projected points (highest first)
    players.sort(
      (a, b) => (b.projectedPoints ?? 0).compareTo(a.projectedPoints ?? 0),
    );
    return players;
  }

  /// Get my roster players
  List<RosterPlayer> get myRoster {
    final myPlayerIds = _ownedPlayers.entries
        .where((e) => e.value == currentUserId)
        .map((e) => e.key)
        .toSet();
    return allPlayers.where((p) => myPlayerIds.contains(p.id)).toList();
  }

  /// Get roster for a specific user
  List<RosterPlayer> getRosterForUser(String userId) {
    final playerIds = _ownedPlayers.entries
        .where((e) => e.value == userId)
        .map((e) => e.key)
        .toSet();
    return allPlayers.where((p) => playerIds.contains(p.id)).toList();
  }

  /// Get all transactions
  List<FreeAgentTransaction> get transactions {
    final sortedTransactions = List<FreeAgentTransaction>.from(_transactions)
      ..sort((a, b) => b.transactionAt.compareTo(a.transactionAt));
    return List.unmodifiable(sortedTransactions);
  }

  /// Get my transactions
  List<FreeAgentTransaction> get myTransactions =>
      _transactions.where((t) => t.userId == currentUserId).toList();

  /// Check if a player is available
  bool isPlayerAvailable(int playerId) => !_ownedPlayers.containsKey(playerId);

  /// Get owner of a player
  String? getPlayerOwner(int playerId) => _ownedPlayers[playerId];

  /// Check if current user owns a player
  bool doIOwn(int playerId) => _ownedPlayers[playerId] == currentUserId;

  /// Get my roster size
  int get myRosterSize => myRoster.length;

  /// Get max roster size
  int get maxRosterSize => league.draftSettings?.rosterSize ?? 18;

  /// Check if I can add a player
  bool get canAddPlayer => myRosterSize < maxRosterSize;

  /// Check if a player's fixture has started (locked for pickup)
  /// Returns true if the player's team has a fixture that has already started
  Future<bool> isPlayerLocked(int playerId) async {
    try {
      // Find the player's team
      final player = allPlayers.firstWhere(
        (p) => p.id == playerId,
        orElse: () => throw Exception('Player not found'),
      );

      final now = DateTime.now();

      // Check today's fixtures and a few days ahead
      for (int daysAhead = 0; daysAhead <= 3; daysAhead++) {
        final date = now.add(Duration(days: daysAhead));
        final fixtures = await _fixturesRepository.getFixturesByDate(date);

        // Check if any fixture involving the player's team has started
        for (final fixture in fixtures) {
          final homeTeamId = fixture.homeTeam?.id;
          final awayTeamId = fixture.awayTeam?.id;
          final isPlayerTeam =
              homeTeamId == player.teamId || awayTeamId == player.teamId;

          if (isPlayerTeam) {
            // Check if fixture has started based on timestamp
            final fixtureTimestamp = fixture.startingAtTimestamp;
            if (fixtureTimestamp != null) {
              final fixtureTime = DateTime.fromMillisecondsSinceEpoch(
                fixtureTimestamp * 1000,
              );
              if (now.isAfter(fixtureTime)) {
                debugPrint(
                  'FreeAgency: Player ${player.name} is locked - fixture already started',
                );
                return true;
              }
            }
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('FreeAgency: Error checking player lock status: $e');
      return false; // Allow pickup if we can't determine lock status
    }
  }

  /// Drop a player from my roster
  Future<FreeAgentTransaction?> dropPlayer(int playerId) async {
    // Validate ownership
    if (!doIOwn(playerId)) {
      debugPrint('FreeAgency: Cannot drop player - not on your roster');
      return null;
    }

    final player = allPlayers.firstWhere(
      (p) => p.id == playerId,
      orElse: () => throw Exception('Player not found'),
    );

    // Remove from owned
    _ownedPlayers.remove(playerId);

    // Create transaction
    final transaction = FreeAgentTransaction(
      id: _uuid.v4(),
      leagueId: league.id,
      userId: currentUserId,
      userName: 'You', // Would be fetched from user profile
      droppedPlayerId: playerId,
      droppedPlayerName: player.displayName,
      transactionAt: DateTime.now(),
    );

    _transactions.add(transaction);
    onPlayerDropped?.call(transaction);
    notifyListeners();

    debugPrint('FreeAgency: Dropped ${player.displayName}');
    return transaction;
  }

  /// Add a player to my roster
  Future<FreeAgentTransaction?> addPlayer(int playerId) async {
    // Check roster space
    if (!canAddPlayer) {
      debugPrint('FreeAgency: Roster is full');
      return null;
    }

    // Check availability
    if (!isPlayerAvailable(playerId)) {
      debugPrint('FreeAgency: Player not available');
      return null;
    }

    // Check if player is locked
    final locked = await isPlayerLocked(playerId);
    if (locked) {
      debugPrint('FreeAgency: Player is locked - fixture has started');
      return null;
    }

    final player = allPlayers.firstWhere(
      (p) => p.id == playerId,
      orElse: () => throw Exception('Player not found'),
    );

    // Add to owned
    _ownedPlayers[playerId] = currentUserId;

    // Create transaction
    final transaction = FreeAgentTransaction(
      id: _uuid.v4(),
      leagueId: league.id,
      userId: currentUserId,
      userName: 'You',
      addedPlayerId: playerId,
      addedPlayerName: player.displayName,
      transactionAt: DateTime.now(),
    );

    _transactions.add(transaction);
    onPlayerAdded?.call(transaction);
    notifyListeners();

    debugPrint('FreeAgency: Added ${player.displayName}');
    return transaction;
  }

  /// Swap players (drop one, add another)
  Future<FreeAgentTransaction?> swapPlayers({
    required int dropPlayerId,
    required int addPlayerId,
  }) async {
    // Validate ownership
    if (!doIOwn(dropPlayerId)) {
      debugPrint('FreeAgency: Cannot swap - you don\'t own the player to drop');
      return null;
    }

    // Check availability
    if (!isPlayerAvailable(addPlayerId)) {
      debugPrint('FreeAgency: Cannot swap - target player not available');
      return null;
    }

    // Check if add player is locked
    final locked = await isPlayerLocked(addPlayerId);
    if (locked) {
      debugPrint('FreeAgency: Cannot swap - target player is locked');
      return null;
    }

    final dropPlayer = allPlayers.firstWhere(
      (p) => p.id == dropPlayerId,
      orElse: () => throw Exception('Drop player not found'),
    );

    final addPlayer = allPlayers.firstWhere(
      (p) => p.id == addPlayerId,
      orElse: () => throw Exception('Add player not found'),
    );

    // Execute swap
    _ownedPlayers.remove(dropPlayerId);
    _ownedPlayers[addPlayerId] = currentUserId;

    // Create transaction
    final transaction = FreeAgentTransaction(
      id: _uuid.v4(),
      leagueId: league.id,
      userId: currentUserId,
      userName: 'You',
      droppedPlayerId: dropPlayerId,
      droppedPlayerName: dropPlayer.displayName,
      addedPlayerId: addPlayerId,
      addedPlayerName: addPlayer.displayName,
      transactionAt: DateTime.now(),
    );

    _transactions.add(transaction);
    onPlayerSwapped?.call(transaction);
    notifyListeners();

    debugPrint(
      'FreeAgency: Swapped ${dropPlayer.displayName} for ${addPlayer.displayName}',
    );
    return transaction;
  }

  /// Load ownership data
  void loadOwnership(Map<int, String> ownership) {
    _ownedPlayers.clear();
    _ownedPlayers.addAll(ownership);
    notifyListeners();
  }

  /// Load transactions
  void loadTransactions(List<FreeAgentTransaction> transactions) {
    _transactions.clear();
    _transactions.addAll(transactions);
    notifyListeners();
  }

  /// Map position string to enum
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
}
