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

