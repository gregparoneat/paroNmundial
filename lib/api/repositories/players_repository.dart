import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fantacy11/api/sportmonks_client.dart';
import 'package:fantacy11/api/sportmonks_config.dart';
import 'package:fantacy11/features/player/models/player_info.dart';

/// Repository for fetching player data
class PlayersRepository {
  final SportMonksClient _client;
  
  PlayersRepository({SportMonksClient? client}) 
      : _client = client ?? SportMonksClient();

  /// Search players by name
  Future<List<Player>> searchPlayers(String query) async {
    if (!SportMonksConfig.isConfigured) {
      // Return mock player for demo
      final mockPlayer = await _loadMockPlayer();
      if (mockPlayer != null && 
          mockPlayer.name.toLowerCase().contains(query.toLowerCase())) {
        return [mockPlayer];
      }
      return [];
    }

    try {
      final response = await _client.searchPlayers(
        query,
        includes: SportMonksConfig.playerIncludes,
      );
      
      return response.data
          .map((json) => Player.fromJson(json))
          .toList();
    } on SportMonksException catch (e) {
      print('SportMonks API Error: $e');
      return [];
    }
  }

  /// Get player by ID
  Future<Player?> getPlayerById(int playerId) async {
    if (!SportMonksConfig.isConfigured) {
      return _loadMockPlayer();
    }

    try {
      final response = await _client.getPlayerById(
        playerId,
        includes: SportMonksConfig.playerIncludes,
      );
      
      return Player.fromJson(response.data);
    } on SportMonksException catch (e) {
      print('SportMonks API Error: $e');
      return null;
    }
  }

  /// Get players for a team (squad)
  Future<List<Player>> getTeamPlayers(int teamId) async {
    if (!SportMonksConfig.isConfigured) {
      final mockPlayer = await _loadMockPlayer();
      return mockPlayer != null ? [mockPlayer] : [];
    }

    try {
      final response = await _client.getTeamSquad(
        teamId,
        includes: ['player.nationality', 'player.position', 'player.detailedposition'],
      );
      
      // Squad endpoint returns squad entries with nested player data
      return response.data
          .where((squad) => squad['player'] != null)
          .map((squad) => Player.fromJson(squad['player'] as Map<String, dynamic>))
          .toList();
    } on SportMonksException catch (e) {
      print('SportMonks API Error: $e');
      return [];
    }
  }

  /// Get demo/mock player
  Future<Player?> getDemoPlayer() async {
    return _loadMockPlayer();
  }

  /// Get team info by ID
  Future<Map<String, dynamic>?> getTeamById(int teamId) async {
    if (!SportMonksConfig.isConfigured) {
      return null;
    }

    try {
      final response = await _client.getTeamById(teamId);
      return response.data;
    } on SportMonksException catch (e) {
      print('SportMonks API Error fetching team $teamId: $e');
      return null;
    } catch (e) {
      print('Unexpected error fetching team $teamId: $e');
      return null;
    }
  }

  /// Cache for team names to avoid repeated API calls
  final Map<int, Map<String, String?>> _teamCache = {};

  /// Get team name and logo by ID (with caching)
  Future<Map<String, String?>> getTeamInfo(int teamId) async {
    // Check cache first
    if (_teamCache.containsKey(teamId)) {
      return _teamCache[teamId]!;
    }

    final teamData = await getTeamById(teamId);
    if (teamData != null) {
      final info = {
        'name': teamData['name'] as String?,
        'shortCode': teamData['short_code'] as String?,
        'logo': teamData['image_path'] as String?,
      };
      _teamCache[teamId] = info;
      return info;
    }

    return {'name': null, 'shortCode': null, 'logo': null};
  }

  /// Populate transfer team names for a player
  Future<void> populateTransferTeamNames(Player player) async {
    if (!SportMonksConfig.isConfigured) return;

    // Collect unique team IDs
    final teamIds = <int>{};
    for (var transfer in player.transfers) {
      if (transfer.fromTeamId != null) teamIds.add(transfer.fromTeamId!);
      if (transfer.toTeamId != null) teamIds.add(transfer.toTeamId!);
    }

    // Fetch team info for each unique team ID
    final teamInfoFutures = teamIds.map((id) async {
      final info = await getTeamInfo(id);
      return MapEntry(id, info);
    });

    final results = await Future.wait(teamInfoFutures);
    final teamInfoMap = Map.fromEntries(results);

    // Populate transfer records with team names
    for (var transfer in player.transfers) {
      if (transfer.fromTeamId != null) {
        final info = teamInfoMap[transfer.fromTeamId];
        transfer.fromTeamName = info?['name'] ?? info?['shortCode'];
        transfer.fromTeamLogo = info?['logo'];
      }
      if (transfer.toTeamId != null) {
        final info = teamInfoMap[transfer.toTeamId];
        transfer.toTeamName = info?['name'] ?? info?['shortCode'];
        transfer.toTeamLogo = info?['logo'];
      }
    }
  }

  /// Load mock player from assets (fallback)
  Future<Player?> _loadMockPlayer() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/MockResponses/player.json',
      );
      final jsonData = json.decode(jsonString);
      final data = jsonData['data'] as List?;
      
      if (data != null && data.isNotEmpty) {
        return Player.fromJson(data.first as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error loading mock player: $e');
    }
    
    return null;
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}

