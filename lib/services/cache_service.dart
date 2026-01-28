import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Cache keys for different data types
class CacheKeys {
  static const String recentPlayers = 'recent_players';
  static const String playerSearchResults = 'player_search_results';
  static const String fixtures = 'fixtures';
  static const String teams = 'teams';
  static const String leagues = 'leagues';
  static const String ligaMxRoster = 'liga_mx_roster';
  static const String ligaMxRosterTimestamp = 'liga_mx_roster_timestamp';
  static const String ligaMxTeams = 'liga_mx_teams';
}

/// Cache box names
class CacheBoxes {
  static const String players = 'players_cache';
  static const String fixtures = 'fixtures_cache';
  static const String teams = 'teams_cache';
  static const String general = 'general_cache';
}

/// Service for managing cached data using Hive
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  bool _initialized = false;
  
  late Box<String> _playersBox;
  late Box<String> _fixturesBox;
  late Box<String> _teamsBox;
  late Box<String> _generalBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();
    
    _playersBox = await Hive.openBox<String>(CacheBoxes.players);
    _fixturesBox = await Hive.openBox<String>(CacheBoxes.fixtures);
    _teamsBox = await Hive.openBox<String>(CacheBoxes.teams);
    _generalBox = await Hive.openBox<String>(CacheBoxes.general);
    
    _initialized = true;
    debugPrint('CacheService initialized');
  }

  // ==================== PLAYERS CACHE ====================

  /// Get recent players from cache
  List<Map<String, dynamic>> getRecentPlayers() {
    final data = _playersBox.get(CacheKeys.recentPlayers);
    if (data == null) return [];
    
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding recent players: $e');
      return [];
    }
  }

  /// Save recent players to cache
  Future<void> saveRecentPlayers(List<Map<String, dynamic>> players) async {
    await _playersBox.put(CacheKeys.recentPlayers, json.encode(players));
  }

  /// Add a player to recent players (keeps last 10)
  Future<void> addRecentPlayer(Map<String, dynamic> player) async {
    final players = getRecentPlayers();
    
    // Remove if already exists (by id)
    final playerId = player['id'];
    players.removeWhere((p) => p['id'] == playerId);
    
    // Add to front
    players.insert(0, player);
    
    // Keep only last 10
    final trimmed = players.take(10).toList();
    await saveRecentPlayers(trimmed);
  }

  /// Get cached player search results
  List<Map<String, dynamic>>? getPlayerSearchResults(String query) {
    final key = '${CacheKeys.playerSearchResults}_${query.toLowerCase().trim()}';
    final data = _playersBox.get(key);
    if (data == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding search results: $e');
      return null;
    }
  }

  /// Cache player search results
  Future<void> cachePlayerSearchResults(String query, List<Map<String, dynamic>> results) async {
    final key = '${CacheKeys.playerSearchResults}_${query.toLowerCase().trim()}';
    await _playersBox.put(key, json.encode(results));
  }

  // ==================== FIXTURES CACHE ====================

  /// Get cached fixtures for a date
  List<Map<String, dynamic>>? getFixtures(String dateKey) {
    final key = '${CacheKeys.fixtures}_$dateKey';
    final data = _fixturesBox.get(key);
    if (data == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding fixtures: $e');
      return null;
    }
  }

  /// Cache fixtures for a date
  Future<void> cacheFixtures(String dateKey, List<Map<String, dynamic>> fixtures) async {
    final key = '${CacheKeys.fixtures}_$dateKey';
    await _fixturesBox.put(key, json.encode(fixtures));
  }

  // ==================== TEAMS CACHE ====================

  /// Get cached team by ID
  Map<String, dynamic>? getTeam(int teamId) {
    final key = '${CacheKeys.teams}_$teamId';
    final data = _teamsBox.get(key);
    if (data == null) return null;
    
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding team: $e');
      return null;
    }
  }

  /// Cache a team
  Future<void> cacheTeam(int teamId, Map<String, dynamic> team) async {
    final key = '${CacheKeys.teams}_$teamId';
    await _teamsBox.put(key, json.encode(team));
  }

  /// Get multiple teams from cache
  Map<int, Map<String, dynamic>> getTeams(List<int> teamIds) {
    final result = <int, Map<String, dynamic>>{};
    for (final id in teamIds) {
      final team = getTeam(id);
      if (team != null) {
        result[id] = team;
      }
    }
    return result;
  }

  // ==================== LIGA MX ROSTER CACHE ====================
  
  static const Duration _rosterCacheExpiry = Duration(hours: 6);
  
  /// Get cached Liga MX roster players
  List<Map<String, dynamic>>? getLigaMxRoster() {
    // Check timestamp first
    final timestampStr = _playersBox.get(CacheKeys.ligaMxRosterTimestamp);
    if (timestampStr != null) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        if (DateTime.now().difference(timestamp) > _rosterCacheExpiry) {
          debugPrint('Liga MX roster cache expired');
          return null;
        }
      } catch (e) {
        debugPrint('Error parsing roster timestamp: $e');
        return null;
      }
    } else {
      return null;
    }
    
    final data = _playersBox.get(CacheKeys.ligaMxRoster);
    if (data == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(data);
      debugPrint('Loaded ${decoded.length} players from Hive cache');
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding Liga MX roster: $e');
      return null;
    }
  }
  
  /// Save Liga MX roster players to cache
  Future<void> saveLigaMxRoster(List<Map<String, dynamic>> players) async {
    await _playersBox.put(CacheKeys.ligaMxRoster, json.encode(players));
    await _playersBox.put(CacheKeys.ligaMxRosterTimestamp, DateTime.now().toIso8601String());
    debugPrint('Saved ${players.length} Liga MX roster players to Hive cache');
  }
  
  /// Add players to Liga MX roster cache (merge with existing)
  Future<void> addToLigaMxRoster(List<Map<String, dynamic>> newPlayers) async {
    final existing = getLigaMxRoster() ?? [];
    
    // Merge - add new players that don't exist
    for (final player in newPlayers) {
      final playerId = player['id'];
      if (!existing.any((p) => p['id'] == playerId)) {
        existing.add(player);
      }
    }
    
    await saveLigaMxRoster(existing);
  }
  
  /// Get cached Liga MX teams
  List<Map<String, dynamic>>? getLigaMxTeams() {
    final data = _teamsBox.get(CacheKeys.ligaMxTeams);
    if (data == null) return null;
    
    try {
      final List<dynamic> decoded = json.decode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error decoding Liga MX teams: $e');
      return null;
    }
  }
  
  /// Save Liga MX teams to cache
  Future<void> saveLigaMxTeams(List<Map<String, dynamic>> teams) async {
    await _teamsBox.put(CacheKeys.ligaMxTeams, json.encode(teams));
    debugPrint('Saved ${teams.length} Liga MX teams to Hive cache');
  }

  // ==================== GENERAL CACHE ====================

  /// Get a general cache value
  String? get(String key) {
    return _generalBox.get(key);
  }

  /// Set a general cache value
  Future<void> set(String key, String value) async {
    await _generalBox.put(key, value);
  }

  /// Delete a cache key
  Future<void> delete(String key) async {
    await _generalBox.delete(key);
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all player caches
  Future<void> clearPlayersCache() async {
    await _playersBox.clear();
    debugPrint('Players cache cleared');
  }

  /// Clear all fixtures caches
  Future<void> clearFixturesCache() async {
    await _fixturesBox.clear();
    debugPrint('Fixtures cache cleared');
  }

  /// Clear all teams caches
  Future<void> clearTeamsCache() async {
    await _teamsBox.clear();
    debugPrint('Teams cache cleared');
  }

  /// Clear all caches
  Future<void> clearAll() async {
    await _playersBox.clear();
    await _fixturesBox.clear();
    await _teamsBox.clear();
    await _generalBox.clear();
    debugPrint('All caches cleared');
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'players': _playersBox.length,
      'fixtures': _fixturesBox.length,
      'teams': _teamsBox.length,
      'general': _generalBox.length,
    };
  }
}

