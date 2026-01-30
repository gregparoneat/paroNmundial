import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Model for the user's favorite team
class FavoriteTeam {
  final int id;
  final String name;
  final String? logo;
  
  const FavoriteTeam({
    required this.id,
    required this.name,
    this.logo,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo': logo,
  };
  
  factory FavoriteTeam.fromJson(Map<String, dynamic> json) => FavoriteTeam(
    id: json['id'] as int,
    name: json['name'] as String,
    logo: json['logo'] as String?,
  );
}

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
  
  // Player form stats cache (per player)
  static String playerFormStats(int playerId) => 'player_form_$playerId';
  static String playerFormTimestamp(int playerId) => 'player_form_ts_$playerId';
  
  // Player tournament stats cache (per player per stage)
  static String playerTournamentStats(int playerId, int stageId) => 'player_tourn_${playerId}_$stageId';
  static String playerTournamentTimestamp(int playerId, int stageId) => 'player_tourn_ts_${playerId}_$stageId';
  
  // Player season stats cache (for pricing - per player)
  static String playerSeasonStats(int playerId) => 'player_season_stats_$playerId';
  static const String allPlayerSeasonStats = 'all_player_season_stats';
  static const String playerSeasonStatsTimestamp = 'player_season_stats_timestamp';
  
  // User preferences
  static const String favoriteTeamId = 'favorite_team_id';
  static const String favoriteTeamName = 'favorite_team_name';
  static const String favoriteTeamLogo = 'favorite_team_logo';
  static const String onboardingCompleted = 'onboarding_completed';
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
  
  /// Clear Liga MX roster cache
  Future<void> clearLigaMxRoster() async {
    await _playersBox.delete(CacheKeys.ligaMxRoster);
    await _playersBox.delete(CacheKeys.ligaMxRosterTimestamp);
    debugPrint('Cleared Liga MX roster cache');
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

  // ==================== PLAYER SEASON STATS CACHE ====================
  
  static const Duration _statsExpiry = Duration(days: 7); // Stats don't change often
  
  /// Get all cached player season stats (for pricing)
  Map<int, Map<String, dynamic>>? getAllPlayerSeasonStats() {
    // Check timestamp
    final timestampStr = _playersBox.get(CacheKeys.playerSeasonStatsTimestamp);
    if (timestampStr != null) {
      try {
        final timestamp = DateTime.parse(timestampStr);
        if (DateTime.now().difference(timestamp) > _statsExpiry) {
          debugPrint('Player season stats cache expired');
          return null;
        }
      } catch (e) {
        return null;
      }
    } else {
      return null;
    }
    
    final data = _playersBox.get(CacheKeys.allPlayerSeasonStats);
    if (data == null) return null;
    
    try {
      final Map<String, dynamic> decoded = json.decode(data);
      final result = <int, Map<String, dynamic>>{};
      decoded.forEach((key, value) {
        final playerId = int.tryParse(key);
        if (playerId != null && value is Map<String, dynamic>) {
          result[playerId] = value;
        }
      });
      debugPrint('Loaded season stats for ${result.length} players from cache');
      return result;
    } catch (e) {
      debugPrint('Error decoding player season stats: $e');
      return null;
    }
  }
  
  /// Get cached season stats for a single player
  Map<String, dynamic>? getPlayerSeasonStats(int playerId) {
    final data = _playersBox.get(CacheKeys.playerSeasonStats(playerId));
    if (data == null) return null;
    
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  /// Save all player season stats to cache
  Future<void> saveAllPlayerSeasonStats(Map<int, Map<String, dynamic>> stats) async {
    final encoded = <String, dynamic>{};
    stats.forEach((playerId, playerStats) {
      encoded[playerId.toString()] = playerStats;
    });
    await _playersBox.put(CacheKeys.allPlayerSeasonStats, json.encode(encoded));
    await _playersBox.put(CacheKeys.playerSeasonStatsTimestamp, DateTime.now().toIso8601String());
    debugPrint('Saved season stats for ${stats.length} players to cache');
  }
  
  /// Save season stats for a single player
  Future<void> savePlayerSeasonStats(int playerId, Map<String, dynamic> stats) async {
    await _playersBox.put(CacheKeys.playerSeasonStats(playerId), json.encode(stats));
  }
  
  /// Clear all player season stats cache (force refresh)
  Future<void> clearPlayerSeasonStats() async {
    await _playersBox.delete(CacheKeys.allPlayerSeasonStats);
    await _playersBox.delete(CacheKeys.playerSeasonStatsTimestamp);
    debugPrint('Cleared player season stats cache');
  }

  // ==================== USER PREFERENCES ====================
  
  /// Get the user's favorite team
  FavoriteTeam? getFavoriteTeam() {
    final teamId = _generalBox.get(CacheKeys.favoriteTeamId);
    final teamName = _generalBox.get(CacheKeys.favoriteTeamName);
    
    if (teamId == null || teamName == null) return null;
    
    return FavoriteTeam(
      id: int.tryParse(teamId) ?? 0,
      name: teamName,
      logo: _generalBox.get(CacheKeys.favoriteTeamLogo),
    );
  }
  
  /// Save the user's favorite team
  Future<void> saveFavoriteTeam(FavoriteTeam team) async {
    await _generalBox.put(CacheKeys.favoriteTeamId, team.id.toString());
    await _generalBox.put(CacheKeys.favoriteTeamName, team.name);
    if (team.logo != null) {
      await _generalBox.put(CacheKeys.favoriteTeamLogo, team.logo!);
    }
    debugPrint('Saved favorite team: ${team.name} (ID: ${team.id})');
  }
  
  /// Clear the user's favorite team
  Future<void> clearFavoriteTeam() async {
    await _generalBox.delete(CacheKeys.favoriteTeamId);
    await _generalBox.delete(CacheKeys.favoriteTeamName);
    await _generalBox.delete(CacheKeys.favoriteTeamLogo);
  }
  
  /// Check if onboarding is completed
  bool isOnboardingCompleted() {
    return _generalBox.get(CacheKeys.onboardingCompleted) == 'true';
  }
  
  /// Mark onboarding as completed
  Future<void> setOnboardingCompleted(bool completed) async {
    await _generalBox.put(CacheKeys.onboardingCompleted, completed.toString());
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

  // ==================== PLAYER FORM STATS CACHE ====================
  
  /// Cache duration for player form stats (6 hours - form changes slowly)
  static const Duration _formStatsCacheDuration = Duration(hours: 6);
  
  /// Get cached player form stats
  /// Returns null if not cached or cache is expired
  Map<String, dynamic>? getPlayerFormStats(int playerId) {
    final key = CacheKeys.playerFormStats(playerId);
    final timestampKey = CacheKeys.playerFormTimestamp(playerId);
    
    final data = _playersBox.get(key);
    final timestampStr = _playersBox.get(timestampKey);
    
    if (data == null || timestampStr == null) {
      return null;
    }
    
    // Check if cache is expired
    final timestamp = int.tryParse(timestampStr);
    if (timestamp != null) {
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedAt) > _formStatsCacheDuration) {
        debugPrint('Player $playerId form stats cache expired');
        return null;
      }
    }
    
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding player form stats: $e');
      return null;
    }
  }
  
  /// Save player form stats to cache
  Future<void> savePlayerFormStats(int playerId, Map<String, dynamic> stats) async {
    final key = CacheKeys.playerFormStats(playerId);
    final timestampKey = CacheKeys.playerFormTimestamp(playerId);
    
    await _playersBox.put(key, json.encode(stats));
    await _playersBox.put(timestampKey, DateTime.now().millisecondsSinceEpoch.toString());
    
    debugPrint('Cached form stats for player $playerId');
  }
  
  /// Clear form stats cache for a specific player
  Future<void> clearPlayerFormStats(int playerId) async {
    final key = CacheKeys.playerFormStats(playerId);
    final timestampKey = CacheKeys.playerFormTimestamp(playerId);
    
    await _playersBox.delete(key);
    await _playersBox.delete(timestampKey);
  }
  
  // ==================== PLAYER TOURNAMENT STATS CACHE ====================
  
  /// Cache duration for tournament stats (12 hours - updated after each matchday)
  static const Duration _tournamentStatsCacheDuration = Duration(hours: 12);
  
  /// Get cached player tournament stats for a specific stage
  Map<String, dynamic>? getPlayerTournamentStats(int playerId, int stageId) {
    final key = CacheKeys.playerTournamentStats(playerId, stageId);
    final timestampKey = CacheKeys.playerTournamentTimestamp(playerId, stageId);
    
    final data = _playersBox.get(key);
    final timestampStr = _playersBox.get(timestampKey);
    
    if (data == null || timestampStr == null) {
      return null;
    }
    
    // Check if cache is expired
    final timestamp = int.tryParse(timestampStr);
    if (timestamp != null) {
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cachedAt) > _tournamentStatsCacheDuration) {
        debugPrint('Player $playerId tournament stats cache expired');
        return null;
      }
    }
    
    try {
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error decoding player tournament stats: $e');
      return null;
    }
  }
  
  /// Save player tournament stats to cache
  Future<void> savePlayerTournamentStats(int playerId, int stageId, Map<String, dynamic> stats) async {
    final key = CacheKeys.playerTournamentStats(playerId, stageId);
    final timestampKey = CacheKeys.playerTournamentTimestamp(playerId, stageId);
    
    await _playersBox.put(key, json.encode(stats));
    await _playersBox.put(timestampKey, DateTime.now().millisecondsSinceEpoch.toString());
    
    debugPrint('Cached tournament stats for player $playerId (stage $stageId)');
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

