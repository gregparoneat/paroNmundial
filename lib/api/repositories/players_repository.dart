import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fantacy11/api/firestore_service.dart';
import 'package:fantacy11/api/sportmonks_client.dart';
import 'package:fantacy11/api/sportmonks_config.dart';
import 'package:fantacy11/features/player/models/player_info.dart';
import 'package:fantacy11/services/cache_service.dart';

/// Player with fantasy-related data for team building
class RosterPlayer {
  final int id;
  final String name;
  final String displayName;
  final String? imagePath;
  final String position; // GK, DEF, MID, FWD
  final String positionCode;
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int? jerseyNumber;
  final double credits; // Fantasy credit value
  final double projectedPoints; // Projected fantasy points
  final double selectedByPercent; // % of users who selected
  final Map<String, dynamic>? stats; // Season statistics

  RosterPlayer({
    required this.id,
    required this.name,
    required this.displayName,
    this.imagePath,
    required this.position,
    required this.positionCode,
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.jerseyNumber,
    this.credits = 8.0,
    this.projectedPoints = 5.0,
    this.selectedByPercent = 0,
    this.stats,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'displayName': displayName,
    'imagePath': imagePath,
    'position': position,
    'positionCode': positionCode,
    'teamId': teamId,
    'teamName': teamName,
    'teamLogo': teamLogo,
    'jerseyNumber': jerseyNumber,
    'credits': credits,
    'projectedPoints': projectedPoints,
    'selectedByPercent': selectedByPercent,
    'stats': stats,
  };

  factory RosterPlayer.fromJson(Map<String, dynamic> json) => RosterPlayer(
    id: json['id'] as int,
    name: json['name'] as String,
    displayName: json['displayName'] as String,
    imagePath: json['imagePath'] as String?,
    position: json['position'] as String,
    positionCode: json['positionCode'] as String,
    teamId: json['teamId'] as int,
    teamName: json['teamName'] as String,
    teamLogo: json['teamLogo'] as String?,
    jerseyNumber: json['jerseyNumber'] as int?,
    credits: (json['credits'] as num?)?.toDouble() ?? 8.0,
    projectedPoints: (json['projectedPoints'] as num?)?.toDouble() ?? 5.0,
    selectedByPercent: (json['selectedByPercent'] as num?)?.toDouble() ?? 0,
    stats: json['stats'] as Map<String, dynamic>?,
  );
}

/// Liga MX team with basic info
class LigaMxTeam {
  final int id;
  final String name;
  final String? logo;
  
  LigaMxTeam({
    required this.id,
    required this.name,
    this.logo,
  });
}

/// Result of fetching players for a specific team
class TeamPlayersResult {
  final List<RosterPlayer> players;
  final bool hasMore;
  final int currentPage;
  final int totalPages;
  final int totalPlayers;
  
  TeamPlayersResult({
    required this.players,
    required this.hasMore,
    required this.currentPage,
    required this.totalPages,
    required this.totalPlayers,
  });
}

/// Result of fetching all players across teams
class AllPlayersResult {
  final List<RosterPlayer> players;
  final bool hasMoreInTeam; // More players in current team
  final bool hasMoreTeams; // More teams to load
  final int currentTeamIndex;
  final int currentPage;
  final int totalTeams;
  final LigaMxTeam? currentTeam;
  
  AllPlayersResult({
    required this.players,
    required this.hasMoreInTeam,
    required this.hasMoreTeams,
    required this.currentTeamIndex,
    required this.currentPage,
    required this.totalTeams,
    this.currentTeam,
  });
}

/// Helper class to store team info for a player during roster loading
class _TeamPlayerInfo {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int? jerseyNumber;

  _TeamPlayerInfo({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    this.jerseyNumber,
  });
}

/// Repository for fetching player data
/// Uses Firestore as primary source, falls back to SportMonks API if needed
class PlayersRepository {
  final SportMonksClient _client;
  final FirestoreService _firestoreService;
  
  // Cache for Liga MX roster players
  List<RosterPlayer>? _ligaMxRosterCache;
  DateTime? _ligaMxRosterCacheTime;
  static const Duration _cacheExpiry = Duration(hours: 6);
  
  // Flag to track if Firestore has data
  bool? _firestoreHasData;
  
  PlayersRepository({SportMonksClient? client, FirestoreService? firestoreService}) 
      : _client = client ?? SportMonksClient(),
        _firestoreService = firestoreService ?? FirestoreService();

  /// Search players by name (returns Player objects)
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
      debugPrint('SportMonks API Error: $e');
      return [];
    }
  }
  
  /// Search players by name and return RosterPlayer objects for team builder
  Future<List<RosterPlayer>> searchRosterPlayers(String query) async {
    if (!SportMonksConfig.isConfigured) {
      return [];
    }
    
    try {
      debugPrint('Searching for roster players: $query');
      final response = await _client.searchPlayers(
        query,
        includes: ['position', 'detailedPosition', 'nationality', 'teams', 'statistics.details'],
      );
      
      final players = <RosterPlayer>[];
      
      for (final json in response.data) {
        try {
          final playerId = json['id'] as int;
          
          // Check if already in cache
          if (_playerDetailsCache.containsKey(playerId)) {
            players.add(_playerDetailsCache[playerId]!);
            continue;
          }
          
          // Parse player data
          final name = json['display_name']?.toString() ?? 
                       json['common_name']?.toString() ?? 
                       json['name']?.toString() ?? 'Unknown';
          
          final positionData = json['position'] as Map<String, dynamic>?;
          final detailedPositionData = json['detailedPosition'] as Map<String, dynamic>?;
          String positionCode = 'MID';
          String positionName = 'Midfielder';
          
          if (positionData != null) {
            // Use detailed position if available for more accuracy
            final rawCode = detailedPositionData?['code']?.toString() ?? 
                           positionData['code']?.toString() ?? 'MID';
            // Normalize to our standard codes (GK, DEF, MID, FWD)
            positionCode = _normalizePositionCode(rawCode);
            positionName = _normalizePosition(rawCode);
            debugPrint('   Position: raw="$rawCode" -> normalized="$positionCode"');
          }
          
          // Get team info from teams array - find current team by furthest end date
          int teamId = 0;
          String teamName = 'Unknown Team';
          String? teamLogo;
          int? jerseyNumber;
          
          final teamsArray = json['teams'] as List?;
          if (teamsArray != null && teamsArray.isNotEmpty) {
            // Find current team (the one with the furthest end date)
            Map<String, dynamic>? currentTeamEntry;
            DateTime? furthestEndDate;
            
            for (final teamEntry in teamsArray) {
              if (teamEntry is Map<String, dynamic>) {
                final endStr = teamEntry['end']?.toString();
                if (endStr != null && endStr.isNotEmpty) {
                  try {
                    final endDate = DateTime.parse(endStr);
                    if (furthestEndDate == null || endDate.isAfter(furthestEndDate)) {
                      furthestEndDate = endDate;
                      currentTeamEntry = teamEntry;
                    }
                  } catch (_) {}
                }
              }
            }
            
            // If no team with end date found, use the first one
            currentTeamEntry ??= teamsArray.first as Map<String, dynamic>?;
            
            if (currentTeamEntry != null) {
              teamId = currentTeamEntry['team_id'] as int? ?? 0;
              jerseyNumber = currentTeamEntry['jersey_number'] as int?;
              
              // Try to get team details from cache
              if (teamId > 0) {
                final cachedTeam = _cacheService.getTeam(teamId);
                if (cachedTeam != null) {
                  teamName = cachedTeam['name']?.toString() ?? 'Team $teamId';
                  teamLogo = cachedTeam['image_path']?.toString();
                } else {
                  // Check if it's a Liga MX team we know about
                  final ligaMxTeams = _cacheService.getLigaMxTeams();
                  if (ligaMxTeams != null) {
                    final matchingTeam = ligaMxTeams.firstWhere(
                      (t) => t['id'] == teamId,
                      orElse: () => <String, dynamic>{},
                    );
                    if (matchingTeam.isNotEmpty) {
                      teamName = matchingTeam['name']?.toString() ?? 'Team $teamId';
                      teamLogo = matchingTeam['logo']?.toString();
                    }
                  }
                }
              }
            }
          }
          
          // Calculate credits and projected points
          final stats = _extractPlayerStats(json);
          final projectedPoints = _calculateProjectedPoints(stats, positionCode);
          final credits = _calculateCredits(projectedPoints, positionCode);
          
          final rosterPlayer = RosterPlayer(
            id: playerId,
            name: json['name']?.toString() ?? name,
            displayName: name,
            imagePath: json['image_path']?.toString(),
            position: positionName,
            positionCode: positionCode,
            teamId: teamId,
            teamName: teamName,
            teamLogo: teamLogo,
            jerseyNumber: jerseyNumber ?? json['jersey_number'] as int?,
            credits: credits,
            projectedPoints: projectedPoints,
            stats: stats,
          );
          
          players.add(rosterPlayer);
          _playerDetailsCache[playerId] = rosterPlayer;
        } catch (e) {
          debugPrint('Error parsing search result: $e');
        }
      }
      
      // Filter out players with "Unknown Team"
      final filteredPlayers = players.where((p) => p.teamName != 'Unknown Team').toList();
      
      // Add to Hive cache
      if (filteredPlayers.isNotEmpty) {
        _addToCache(filteredPlayers);
      }
      
      debugPrint('Search returned ${filteredPlayers.length} roster players (filtered from ${players.length})');
      return filteredPlayers;
    } on SportMonksException catch (e) {
      debugPrint('SportMonks API Error during search: $e');
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
      debugPrint('SportMonks API Error: $e');
      return null;
    }
  }

  /// Get players for a team (squad) - returns basic Player objects
  Future<List<Player>> getTeamSquadPlayers(int teamId) async {
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
      debugPrint('SportMonks API Error: $e');
      return [];
    }
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
      debugPrint('SportMonks API Error fetching team $teamId: $e');
      return null;
    } catch (e) {
      debugPrint('Unexpected error fetching team $teamId: $e');
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
        'name': teamData['name']?.toString(),
        'shortCode': teamData['short_code']?.toString(),
        'logo': teamData['image_path']?.toString(),
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
      debugPrint('Error loading mock player: $e');
    }
    
    return null;
  }

  // ==================== LIGA MX ROSTER METHODS ====================
  
  final CacheService _cacheService = CacheService();
  
  // In-memory cache for current session (faster than Hive for repeated access)
  List<LigaMxTeam>? _teamsMemoryCache;
  final Map<int, List<Map<String, dynamic>>> _teamPlayerIdsCache = {};
  final Map<int, RosterPlayer> _playerDetailsCache = {};
  
  /// Get all cached players from Hive (returns empty list if no cache)
  List<RosterPlayer> getCachedPlayers() {
    final cachedData = _cacheService.getLigaMxRoster();
    if (cachedData == null || cachedData.isEmpty) {
      return [];
    }
    
    // Convert cached JSON to RosterPlayer objects
    final players = <RosterPlayer>[];
    for (final data in cachedData) {
      try {
        players.add(RosterPlayer(
          id: data['id'] as int,
          name: data['name'] as String,
          displayName: data['displayName'] as String,
          imagePath: data['imagePath'] as String?,
          position: data['position'] as String,
          positionCode: data['positionCode'] as String,
          teamId: data['teamId'] as int,
          teamName: data['teamName'] as String,
          teamLogo: data['teamLogo'] as String?,
          jerseyNumber: data['jerseyNumber'] as int?,
          credits: (data['credits'] as num).toDouble(),
          projectedPoints: (data['projectedPoints'] as num).toDouble(),
          selectedByPercent: (data['selectedByPercent'] as num?)?.toDouble() ?? 0,
          stats: data['stats'] as Map<String, dynamic>?,
        ));
      } catch (e) {
        debugPrint('Error parsing cached player: $e');
      }
    }
    
    // Filter out any "Unknown Team" players that might be in old cache
    final validPlayers = players.where((p) => p.teamName != 'Unknown Team').toList();
    debugPrint('Loaded ${validPlayers.length} valid players from Hive cache (filtered from ${players.length})');
    return validPlayers;
  }
  
  /// Add players to Hive cache (filters out "Unknown Team" players)
  Future<void> _addToCache(List<RosterPlayer> players) async {
    if (players.isEmpty) return;
    
    // Filter out players with "Unknown Team" before caching
    final validPlayers = players.where((p) => p.teamName != 'Unknown Team').toList();
    if (validPlayers.isEmpty) return;
    
    final jsonList = validPlayers.map((p) => p.toJson()).toList();
    await _cacheService.addToLigaMxRoster(jsonList);
    
    // Also update in-memory cache for faster access
    for (final player in validPlayers) {
      _playerDetailsCache[player.id] = player;
    }
  }

  /// Get all Liga MX teams - first from Hive cache, then Firestore, then API
  Future<List<LigaMxTeam>> getLigaMxTeams() async {
    // Check in-memory cache first
    if (_teamsMemoryCache != null) {
      return _teamsMemoryCache!;
    }
    
    // Check Hive cache
    final cachedTeams = _cacheService.getLigaMxTeams();
    if (cachedTeams != null && cachedTeams.isNotEmpty) {
      _teamsMemoryCache = cachedTeams.map((t) => LigaMxTeam(
        id: t['id'] as int,
        name: t['name'] as String,
        logo: t['logo'] as String?,
      )).toList();
      debugPrint('Loaded ${_teamsMemoryCache!.length} teams from Hive cache');
      return _teamsMemoryCache!;
    }
    
    // Try Firestore first
    try {
      final firestoreTeams = await _loadTeamsFromFirestore();
      if (firestoreTeams.isNotEmpty) {
        _teamsMemoryCache = firestoreTeams;
        // Save to Hive cache
        await _cacheService.saveLigaMxTeams(
          firestoreTeams.map((t) => {'id': t.id, 'name': t.name, 'logo': t.logo}).toList(),
        );
        debugPrint('Loaded ${firestoreTeams.length} teams from Firestore');
        return firestoreTeams;
      }
    } catch (e) {
      debugPrint('Firestore teams fetch failed, falling back to API: $e');
    }
    
    // Fall back to CSV + SportMonks API
    if (!SportMonksConfig.isConfigured) {
      throw Exception('No data source available - Firestore empty and SportMonks not configured');
    }
    
    final csvTeams = await _loadLigaMxTeamsFromCsv();
    final teams = <LigaMxTeam>[];
    
    for (final team in csvTeams) {
      final teamId = team['id'] as int;
      final teamName = team['name'] as String;
      String? teamLogo;
      
      try {
        final teamResponse = await _client.getTeamById(teamId);
        teamLogo = teamResponse.data?['image_path']?.toString();
      } catch (e) {
        debugPrint('Error fetching logo for $teamName: $e');
      }
      
      teams.add(LigaMxTeam(
        id: teamId,
        name: teamName,
        logo: teamLogo,
      ));
    }
    
    // Save to in-memory cache
    _teamsMemoryCache = teams;
    
    // Save to Hive cache
    await _cacheService.saveLigaMxTeams(
      teams.map((t) => {'id': t.id, 'name': t.name, 'logo': t.logo}).toList(),
    );
    
    debugPrint('Loaded ${teams.length} Liga MX teams from CSV/API');
    return teams;
  }
  
  /// Load teams from Firestore (SportMonks format)
  Future<List<LigaMxTeam>> _loadTeamsFromFirestore() async {
    final teamsData = await _firestoreService.getTeams();
    
    return teamsData.map((t) => LigaMxTeam(
      id: _parseIntValue(t['id']) ?? 0,
      name: t['name']?.toString() ?? t['short_code']?.toString() ?? 'Unknown',
      logo: t['image_path']?.toString() ?? t['logo']?.toString(),
    )).where((t) => t.id > 0).toList();
  }
  
  /// Load all players from Firestore and cache them
  /// This is the preferred method as it loads all data in one call
  /// Pass forceRefresh=true to bypass cache and reload from Firestore
  Future<List<RosterPlayer>> loadAllPlayersFromFirestore({bool forceRefresh = false}) async {
    debugPrint('Loading all players from Firestore (forceRefresh: $forceRefresh)...');
    
    // Check Hive cache first (only if not forcing refresh and cache has substantial data)
    if (!forceRefresh) {
      final cachedPlayers = getCachedPlayers();
      // Only use cache if it has a substantial number of players (Liga MX has ~500+ players)
      if (cachedPlayers.length >= 300) {
        debugPrint('Found ${cachedPlayers.length} players in Hive cache (sufficient)');
        return cachedPlayers;
      }
      debugPrint('Cache has ${cachedPlayers.length} players (insufficient, need 300+)');
    }
    
    try {
      // Load teams first so we can look up team names when parsing players
      await getLigaMxTeams();
      
      final playersData = await _firestoreService.getPlayers();
      
      if (playersData.isEmpty) {
        debugPrint('No players found in Firestore');
        // Return cached players if Firestore is empty
        return getCachedPlayers();
      }
      
      debugPrint('Firestore returned ${playersData.length} player documents');
      
      // Debug: Log first document structure
      if (playersData.isNotEmpty) {
        final firstDoc = playersData.first;
        debugPrint('First document keys: ${firstDoc.keys.toList()}');
        if (firstDoc.containsKey('data')) {
          final data = firstDoc['data'];
          if (data is Map) {
            debugPrint('data field keys: ${data.keys.toList()}');
          }
        }
        if (firstDoc.containsKey('id')) {
          debugPrint('Direct id field: ${firstDoc['id']}');
        }
        if (firstDoc.containsKey('statistics')) {
          debugPrint('Has statistics: ${(firstDoc['statistics'] as List?)?.length ?? 0} entries');
        }
      }
      
      final players = <RosterPlayer>[];
      int parseErrors = 0;
      
      for (final data in playersData) {
        final player = _parseFirestorePlayer(data);
        if (player != null) {
          players.add(player);
          _playerDetailsCache[player.id] = player;
        } else {
          parseErrors++;
          // Log first 3 parse errors for debugging
          if (parseErrors <= 3) {
            debugPrint('Parse error #$parseErrors - doc keys: ${data.keys.toList()}');
          }
        }
      }
      
      debugPrint('Parsed ${players.length} valid players from Firestore ($parseErrors parse errors)');
      
      // Save to Hive cache (replace existing)
      if (players.isNotEmpty) {
        await _cacheService.clearLigaMxRoster(); // Clear old cache
        _addToCache(players);
      }
      
      debugPrint('Loaded ${players.length} players from Firestore');
      return players;
    } catch (e) {
      debugPrint('Error loading players from Firestore: $e');
      return [];
    }
  }
  
  /// Parse a Firestore player document into RosterPlayer
  /// Handles SportMonks API field format (snake_case)
  RosterPlayer? _parseFirestorePlayer(Map<String, dynamic> data) {
    try {
      // The data might be nested under a 'data' key from Firestore
      final playerData = data['data'] is Map<String, dynamic> 
          ? data['data'] as Map<String, dynamic> 
          : data;
      
      final id = _parseIntValue(playerData['id']) ?? _parseIntValue(playerData['player_id']);
      if (id == null || id <= 0) {
        debugPrint('Parse error: No valid ID in player document');
        return null;
      }
      
      // SportMonks uses display_name, common_name, name
      final name = playerData['name']?.toString() ?? 
                   playerData['common_name']?.toString() ?? 
                   'Unknown';
      final displayName = playerData['display_name']?.toString() ?? 
                          playerData['common_name']?.toString() ?? 
                          name;
      
      // Parse position - SportMonks includes position object
      String positionCode = 'MID';
      String position = 'Midfielder';
      final positionData = playerData['position'];
      if (positionData is String) {
        positionCode = _normalizePositionCode(positionData);
        position = _getPositionName(positionCode);
      } else if (positionData is Map) {
        // SportMonks position object has 'code', 'developer_name', 'name'
        positionCode = _normalizePositionCode(
          positionData['developer_name']?.toString() ?? 
          positionData['code']?.toString() ?? 
          positionData['name']?.toString() ?? 
          'MID'
        );
        position = positionData['name']?.toString() ?? _getPositionName(positionCode);
      }
      
      // Parse team info from statistics array (most recent season)
      int teamId = 0;
      String teamName = 'Unknown Team';
      String? teamLogo;
      int? jerseyNumber;
      Map<String, dynamic> stats = {};
      
      // Statistics array contains team_id for each season
      final statistics = playerData['statistics'] as List?;
      if (statistics != null && statistics.isNotEmpty) {
        // Find the most recent season (highest season_id usually = most recent)
        Map<String, dynamic>? latestStat;
        int latestSeasonId = 0;
        
        for (final stat in statistics) {
          if (stat is! Map<String, dynamic>) continue;
          final seasonId = _parseIntValue(stat['season_id']) ?? 0;
          if (seasonId > latestSeasonId) {
            latestSeasonId = seasonId;
            latestStat = stat;
          }
        }
        
        if (latestStat != null) {
          teamId = _parseIntValue(latestStat['team_id']) ?? 0;
          jerseyNumber = _parseIntValue(latestStat['jersey_number']);
          
          // Parse detailed stats if available
          final details = latestStat['details'] as List?;
          if (details != null) {
            for (final detail in details) {
              if (detail is! Map<String, dynamic>) continue;
              final typeId = _parseIntValue(detail['type_id']);
              final value = detail['value'];
              
              switch (typeId) {
                case 52: stats['goals'] = value; break;
                case 79: stats['rating'] = value; break;
                case 84: stats['assists'] = value; break;
                case 119: stats['minutes'] = value; break;
                case 194: stats['cleanSheets'] = value; break;
                case 209: stats['saves'] = value; break;
                case 321: stats['appearances'] = value; break;
              }
            }
          }
        }
      }
      
      // Look up team name from our cached teams
      if (teamId > 0) {
        final cachedTeams = _cacheService.getLigaMxTeams();
        if (cachedTeams != null) {
          final matchingTeam = cachedTeams.firstWhere(
            (t) => t['id'] == teamId,
            orElse: () => <String, dynamic>{},
          );
          if (matchingTeam.isNotEmpty) {
            teamName = matchingTeam['name']?.toString() ?? 'Team $teamId';
            teamLogo = matchingTeam['logo']?.toString();
          }
        }
        
        // Fallback - use team ID as name if not found in cache
        if (teamName == 'Unknown Team') {
          teamName = 'Team $teamId';
        }
      }
      
      // Skip players without a valid team - but log first one for debugging
      if (teamId == 0) {
        // Log first few failures for debugging
        debugPrint('Parse skip: Player $id ($displayName) has no team_id in statistics');
        return null;
      }
      
      final projectedPoints = _calculateProjectedPointsFromStats(stats, positionCode);
      final credits = _calculateCredits(projectedPoints, positionCode);
      
      return RosterPlayer(
        id: id,
        name: name,
        displayName: displayName,
        imagePath: playerData['image_path']?.toString(),
        position: position,
        positionCode: positionCode,
        teamId: teamId,
        teamName: teamName,
        teamLogo: teamLogo,
        jerseyNumber: jerseyNumber ?? _parseIntValue(playerData['jersey_number']),
        credits: credits,
        projectedPoints: projectedPoints,
        selectedByPercent: 0,
        stats: stats.isNotEmpty ? stats : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Firestore player: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Calculate projected points from stats map
  double _calculateProjectedPointsFromStats(Map<String, dynamic> stats, String positionCode) {
    double points = 2.0; // Base points
    
    final goals = _parseIntValue(stats['goals']) ?? 0;
    final assists = _parseIntValue(stats['assists']) ?? 0;
    final cleanSheets = _parseIntValue(stats['cleanSheets']) ?? _parseIntValue(stats['clean_sheets']) ?? 0;
    final saves = _parseIntValue(stats['saves']) ?? 0;
    final appearances = _parseIntValue(stats['appearances']) ?? 0;
    final rating = _parseDoubleSafe(stats['rating']) ?? 0;
    
    // Position-based scoring
    switch (positionCode) {
      case 'GK':
        points += goals * 10;
        points += cleanSheets * 4;
        points += saves * 0.5;
        points += rating > 7 ? (rating - 7) * 2 : 0;
        break;
      case 'DEF':
        points += goals * 6;
        points += assists * 3;
        points += cleanSheets * 4;
        break;
      case 'MID':
        points += goals * 5;
        points += assists * 3;
        points += cleanSheets * 1;
        break;
      case 'FWD':
        points += goals * 4;
        points += assists * 3;
        break;
    }
    
    // Normalize by appearances
    if (appearances > 0) {
      points = points / appearances * 5; // Normalize to ~5 matches
    }
    
    return points.clamp(1.0, 15.0);
  }
  
  /// Helper to safely parse double
  double? _parseDoubleSafe(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// Get position name from code
  String _getPositionName(String code) {
    switch (code) {
      case 'GK': return 'Goalkeeper';
      case 'DEF': return 'Defender';
      case 'MID': return 'Midfielder';
      case 'FWD': return 'Forward';
      default: return 'Unknown';
    }
  }
  
  /// Get player IDs for a specific team (cached)
  Future<List<Map<String, dynamic>>> _getTeamPlayerIds(int teamId, String teamName, String? teamLogo) async {
    if (_teamPlayerIdsCache.containsKey(teamId)) {
      return _teamPlayerIdsCache[teamId]!;
    }
    
    final teamResponse = await _client.getTeamById(teamId, includes: ['players']);
    final teamData = teamResponse.data;
    
    if (teamData == null) {
      throw Exception('Team not found');
    }
    
    final playersData = teamData['players'] as List? ?? [];
    final playerInfoList = <Map<String, dynamic>>[];
    
    for (final entry in playersData) {
      final playerId = _parseIntValue(entry['player_id'] ?? entry['id']);
      if (playerId != null) {
        playerInfoList.add({
          'playerId': playerId,
          'jerseyNumber': _parseIntValue(entry['jersey_number']),
          'teamId': teamId,
          'teamName': teamName,
          'teamLogo': teamLogo,
        });
      }
    }
    
    _teamPlayerIdsCache[teamId] = playerInfoList;
    debugPrint('Cached ${playerInfoList.length} player IDs for $teamName');
    return playerInfoList;
  }
  
  /// Get players for a specific team with pagination
  /// page starts at 1, pageSize is number of players per page
  Future<TeamPlayersResult> getTeamPlayers({
    required int teamId,
    required String teamName,
    String? teamLogo,
    int page = 1,
    int pageSize = 20,
  }) async {
    if (!SportMonksConfig.isConfigured) {
      throw Exception('SportMonks API is not configured.');
    }
    
    // Get all player IDs for this team (cached)
    final playerInfoList = await _getTeamPlayerIds(teamId, teamName, teamLogo);
    
    // Calculate pagination
    final totalPlayers = playerInfoList.length;
    final totalPages = (totalPlayers / pageSize).ceil();
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalPlayers);
    
    if (startIndex >= totalPlayers) {
      return TeamPlayersResult(
        players: [],
        hasMore: false,
        currentPage: page,
        totalPages: totalPages,
        totalPlayers: totalPlayers,
      );
    }
    
    final pagePlayerInfos = playerInfoList.sublist(startIndex, endIndex);
    final players = <RosterPlayer>[];
    
    debugPrint('Fetching page $page for $teamName: players $startIndex-$endIndex of $totalPlayers');
    
    for (final info in pagePlayerInfos) {
      final playerId = info['playerId'] as int;
      
      // Check cache first
      if (_playerDetailsCache.containsKey(playerId)) {
        players.add(_playerDetailsCache[playerId]!);
        continue;
      }
      
      try {
        final playerResponse = await _client.getPlayerById(
          playerId,
          includes: ['position', 'detailedPosition', 'nationality', 'statistics.details'],
        );
        
        if (playerResponse.data != null) {
          final teamInfo = _TeamPlayerInfo(
            teamId: info['teamId'] as int,
            teamName: info['teamName'] as String,
            teamLogo: info['teamLogo'] as String?,
            jerseyNumber: info['jerseyNumber'] as int?,
          );
          
          final rosterPlayer = _parsePlayerToRosterPlayer(playerResponse.data!, teamInfo);
          // Filter out players with "Unknown Team"
          if (rosterPlayer != null && rosterPlayer.teamName != 'Unknown Team') {
            _playerDetailsCache[playerId] = rosterPlayer;
            players.add(rosterPlayer);
          }
        }
      } catch (e) {
        debugPrint('Error fetching player $playerId: $e');
      }
    }
    
    // Add loaded players to Hive cache (don't await - run in background)
    _addToCache(players);
    
    return TeamPlayersResult(
      players: players,
      hasMore: page < totalPages,
      currentPage: page,
      totalPages: totalPages,
      totalPlayers: totalPlayers,
    );
  }
  
  /// Get players from all teams with pagination (loads one team at a time)
  /// Prioritizes the user's favorite team if set
  /// teamIndex: which team to load (0-17 for Liga MX)
  /// page: page within that team
  Future<AllPlayersResult> getAllPlayersPage({
    int teamIndex = 0,
    int page = 1,
    int pageSize = 20,
  }) async {
    final teams = await getLigaMxTeamsWithFavoriteFirst();
    
    if (teamIndex >= teams.length) {
      return AllPlayersResult(
        players: [],
        hasMoreInTeam: false,
        hasMoreTeams: false,
        currentTeamIndex: teamIndex,
        currentPage: page,
        totalTeams: teams.length,
      );
    }
    
    final team = teams[teamIndex];
    debugPrint('Loading players: Team ${team.name} (${teamIndex + 1}/${teams.length}), page $page');
    
    final result = await getTeamPlayers(
      teamId: team.id,
      teamName: team.name,
      teamLogo: team.logo,
      page: page,
      pageSize: pageSize,
    );
    
    return AllPlayersResult(
      players: result.players,
      hasMoreInTeam: result.hasMore,
      hasMoreTeams: teamIndex < teams.length - 1,
      currentTeamIndex: teamIndex,
      currentPage: page,
      totalTeams: teams.length,
      currentTeam: team,
    );
  }
  
  /// Get Liga MX teams with the user's favorite team first
  /// If no favorite team is set, returns teams in default order
  Future<List<LigaMxTeam>> getLigaMxTeamsWithFavoriteFirst() async {
    final teams = await getLigaMxTeams();
    final favoriteTeam = _cacheService.getFavoriteTeam();
    
    if (favoriteTeam == null) {
      return teams;
    }
    
    // Find the favorite team index
    final favoriteIndex = teams.indexWhere((t) => t.id == favoriteTeam.id);
    
    if (favoriteIndex <= 0) {
      // Already first or not found
      return teams;
    }
    
    // Move favorite team to the front
    final reorderedTeams = List<LigaMxTeam>.from(teams);
    final favorite = reorderedTeams.removeAt(favoriteIndex);
    reorderedTeams.insert(0, favorite);
    
    debugPrint('Reordered teams - favorite team ${favorite.name} is now first');
    return reorderedTeams;
  }
  
  /// Get players from the user's favorite team
  /// Returns empty list if no favorite team is set
  Future<TeamPlayersResult> getFavoriteTeamPlayers({
    int page = 1,
    int pageSize = 20,
  }) async {
    final favoriteTeam = _cacheService.getFavoriteTeam();
    
    if (favoriteTeam == null) {
      debugPrint('No favorite team set');
      return TeamPlayersResult(
        players: [],
        hasMore: false,
        currentPage: 1,
        totalPages: 0,
        totalPlayers: 0,
      );
    }
    
    debugPrint('Loading players from favorite team: ${favoriteTeam.name}');
    return getTeamPlayers(
      teamId: favoriteTeam.id,
      teamName: favoriteTeam.name,
      teamLogo: favoriteTeam.logo,
      page: page,
      pageSize: pageSize,
    );
  }
  
  /// Clear all caches (both in-memory and Hive)
  Future<void> clearCache() async {
    _teamsMemoryCache = null;
    _teamPlayerIdsCache.clear();
    _playerDetailsCache.clear();
    _ligaMxRosterCache = null;
    _ligaMxRosterCacheTime = null;
    
    // Clear Hive caches
    await _cacheService.clearPlayersCache();
    await _cacheService.clearTeamsCache();
  }
  
  /// Legacy method - kept for backward compatibility
  @Deprecated('Use getTeamPlayers() or getAllPlayersPage() instead for lazy loading')
  Future<List<RosterPlayer>> getLigaMxRosterPlayers({bool forceRefresh = false}) async {
    // Return cached if available
    if (!forceRefresh && _playerDetailsCache.isNotEmpty) {
      return _playerDetailsCache.values.toList();
    }
    // Otherwise return empty - UI should use new paginated methods
    return [];
  }
  
  /// Load Liga MX team IDs from local CSV file
  /// Returns list of maps with 'id' and 'name' keys
  Future<List<Map<String, dynamic>>> _loadLigaMxTeamsFromCsv() async {
    try {
      final csvString = await rootBundle.loadString('assets/Teams/LigaMXTeamIds.csv');
      final lines = csvString.split('\n');
      
      final teams = <Map<String, dynamic>>[];
      
      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(',');
        if (parts.length >= 2) {
          final teamName = parts[0].trim();
          final teamId = int.tryParse(parts[1].trim());
          
          if (teamId != null && teamName.isNotEmpty) {
            teams.add({
              'id': teamId,
              'name': teamName,
            });
          }
        }
      }
      
      return teams;
    } catch (e) {
      debugPrint('Error loading Liga MX teams from CSV: $e');
      return [];
    }
  }

  /// Parse full player data into RosterPlayer
  RosterPlayer? _parsePlayerToRosterPlayer(
    Map<String, dynamic> playerData,
    _TeamPlayerInfo teamInfo,
  ) {
    try {
      final id = _parseIntValue(playerData['id']);
      final name = playerData['name']?.toString();
      
      if (id == null || name == null) return null;
      
      // Parse position
      String positionCode = 'MID';
      final positionRaw = playerData['position'];
      if (positionRaw is Map<String, dynamic>) {
        positionCode = positionRaw['code']?.toString().toUpperCase() ?? 'MID';
      } else if (positionRaw is String) {
        positionCode = positionRaw.toUpperCase();
      }
      final positionName = _normalizePosition(positionCode);
      
      // Parse statistics
      final stats = _extractPlayerStats(playerData);
      final projectedPoints = _calculateProjectedPoints(stats, positionCode);
      final credits = _calculateCredits(projectedPoints, positionCode);
      
      return RosterPlayer(
        id: id,
        name: name,
        displayName: playerData['display_name']?.toString() ?? playerData['common_name']?.toString() ?? name,
        imagePath: playerData['image_path']?.toString(),
        position: positionName,
        positionCode: _normalizePositionCode(positionCode),
        teamId: teamInfo.teamId,
        teamName: teamInfo.teamName,
        teamLogo: teamInfo.teamLogo,
        jerseyNumber: teamInfo.jerseyNumber,
        credits: credits,
        projectedPoints: projectedPoints,
        stats: stats,
      );
    } catch (e) {
      debugPrint('Error parsing player to roster player: $e');
      return null;
    }
  }

  /// Get players filtered by position
  Future<List<RosterPlayer>> getRosterPlayersByPosition(String positionCode) async {
    final allPlayers = await getLigaMxRosterPlayers();
    
    // Handle FWD which includes both attacker and forward
    if (positionCode.toUpperCase() == 'FWD') {
      return allPlayers.where((p) {
        final pos = p.positionCode.toUpperCase();
        return pos == 'FWD' || pos == 'ATT' || pos == 'ST' || pos == 'CF';
      }).toList();
    }
    
    return allPlayers.where((p) => 
      p.positionCode.toUpperCase() == positionCode.toUpperCase()
    ).toList();
  }

  /// Get players for a specific team
  Future<List<RosterPlayer>> getRosterPlayersByTeam(int teamId) async {
    final allPlayers = await getLigaMxRosterPlayers();
    return allPlayers.where((p) => p.teamId == teamId).toList();
  }


  /// Safely parse an integer value from various types
  int? _parseIntValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Safely parse a double value from various types
  double? _parseDoubleValue(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Normalize position code to standard values (GK, DEF, MID, FWD)
  String _normalizePositionCode(String code) {
    switch (code.toUpperCase()) {
      case 'G':
      case 'GK':
      case 'GOALKEEPER':
        return 'GK';
      case 'D':
      case 'DEF':
      case 'DEFENDER':
      case 'CB':
      case 'LB':
      case 'RB':
      case 'LWB':
      case 'RWB':
        return 'DEF';
      case 'M':
      case 'MID':
      case 'MIDFIELDER':
      case 'CM':
      case 'DM':
      case 'CDM':
      case 'CAM':
      case 'LM':
      case 'RM':
        return 'MID';
      case 'F':
      case 'FWD':
      case 'ATT':
      case 'ATTACKER':
      case 'FORWARD':
      case 'ST':
      case 'CF':
      case 'LW':
      case 'RW':
        return 'FWD';
      default:
        return 'MID';
    }
  }

  /// Get human-readable position name
  String _normalizePosition(String code) {
    final normalized = _normalizePositionCode(code);
    switch (normalized) {
      case 'GK':
        return 'Goalkeeper';
      case 'DEF':
        return 'Defender';
      case 'MID':
        return 'Midfielder';
      case 'FWD':
        return 'Forward';
      default:
        return 'Midfielder';
    }
  }

  /// Extract relevant stats from player data
  Map<String, dynamic>? _extractPlayerStats(Map<String, dynamic> playerData) {
    try {
      final statisticsRaw = playerData['statistics'];
      if (statisticsRaw == null) return null;
      
      List<dynamic>? statisticsList;
      if (statisticsRaw is List) {
        statisticsList = statisticsRaw;
      } else if (statisticsRaw is Map) {
        // Sometimes API returns a single stats object as a map
        statisticsList = [statisticsRaw];
      }
      
      if (statisticsList == null || statisticsList.isEmpty) return null;
      
      // Get latest season statistics
      final latestStatsRaw = statisticsList.first;
      if (latestStatsRaw is! Map<String, dynamic>) return null;
      final latestStats = latestStatsRaw;
      
      final detailsRaw = latestStats['details'];
      if (detailsRaw == null) return null;
      
      List<dynamic>? details;
      if (detailsRaw is List) {
        details = detailsRaw;
      }
      if (details == null) return null;
      
      final stats = <String, dynamic>{};
      for (final detail in details) {
        if (detail is! Map<String, dynamic>) continue;
        
        final typeId = _parseIntValue(detail['type_id']);
        final value = _parseDoubleValue(detail['value']) ?? detail['value'];
        
        // Map type IDs to stat names (based on SportMonks documentation)
        switch (typeId) {
          case 52: // Goals
            stats['goals'] = value;
            break;
          case 79: // Assists
            stats['assists'] = value;
            break;
          case 45: // Minutes played
            stats['minutes'] = value;
            break;
          case 56: // Yellow cards
            stats['yellowCards'] = value;
            break;
          case 57: // Red cards
            stats['redCards'] = value;
            break;
          case 59: // Clean sheets
            stats['cleanSheets'] = value;
            break;
          case 101: // Saves
            stats['saves'] = value;
            break;
          case 118: // Rating
            stats['rating'] = value;
            break;
          case 42: // Appearances
            stats['appearances'] = value;
            break;
        }
      }
      
      return stats.isNotEmpty ? stats : null;
    } catch (e) {
      debugPrint('Error extracting player stats: $e');
      return null;
    }
  }

  /// Calculate projected fantasy points based on stats (per game average)
  double _calculateProjectedPoints(Map<String, dynamic>? stats, String positionCode) {
    if (stats == null) {
      // Default points by position for players without stats
      switch (_normalizePositionCode(positionCode)) {
        case 'GK':
          return 3.5;
        case 'DEF':
          return 3.8;
        case 'MID':
          return 4.0;
        case 'FWD':
          return 4.2;
        default:
          return 3.8;
      }
    }
    
    final goals = _parseDoubleValue(stats['goals']) ?? 0;
    final assists = _parseDoubleValue(stats['assists']) ?? 0;
    final cleanSheets = _parseDoubleValue(stats['cleanSheets']) ?? 0;
    final saves = _parseDoubleValue(stats['saves']) ?? 0;
    final appearances = _parseDoubleValue(stats['appearances']) ?? 0;
    final minutes = _parseDoubleValue(stats['minutes']) ?? 0;
    final yellowCards = _parseDoubleValue(stats['yellowCards']) ?? 0;
    final redCards = _parseDoubleValue(stats['redCards']) ?? 0;
    final rating = _parseDoubleValue(stats['rating']) ?? 0;
    
    // Calculate games played (estimate if not available)
    final gamesPlayed = appearances > 0 ? appearances : (minutes > 0 ? minutes / 70 : 1);
    if (gamesPlayed < 1) return _calculateProjectedPoints(null, positionCode);
    
    final normalizedPos = _normalizePositionCode(positionCode);
    double points = 0;
    
    // Fantasy points calculation based on position
    if (normalizedPos == 'GK') {
      // GK: Clean sheets, saves, and penalties saved are key
      final cleanSheetBonus = (cleanSheets / gamesPlayed) * 4.0;
      final savesBonus = (saves / gamesPlayed) * 0.3;
      final goalsBonus = goals * 6.0 / gamesPlayed;
      final assistsBonus = assists * 3.0 / gamesPlayed;
      points = 2.0 + cleanSheetBonus + savesBonus + goalsBonus + assistsBonus;
      
    } else if (normalizedPos == 'DEF') {
      // DEF: Clean sheets, goals, and assists
      final cleanSheetBonus = (cleanSheets / gamesPlayed) * 4.0;
      final goalsBonus = (goals / gamesPlayed) * 6.0;
      final assistsBonus = (assists / gamesPlayed) * 3.0;
      points = 2.0 + cleanSheetBonus + goalsBonus + assistsBonus;
      
    } else if (normalizedPos == 'MID') {
      // MID: Goals, assists, and some clean sheet bonus
      final goalsBonus = (goals / gamesPlayed) * 5.0;
      final assistsBonus = (assists / gamesPlayed) * 3.0;
      final cleanSheetBonus = (cleanSheets / gamesPlayed) * 1.0;
      points = 2.0 + goalsBonus + assistsBonus + cleanSheetBonus;
      
    } else { // FWD
      // FWD: Goals and assists are everything
      final goalsBonus = (goals / gamesPlayed) * 4.0;
      final assistsBonus = (assists / gamesPlayed) * 3.0;
      points = 2.0 + goalsBonus + assistsBonus;
    }
    
    // Deductions
    final cardsDeduction = ((yellowCards * 1.0) + (redCards * 3.0)) / gamesPlayed;
    points -= cardsDeduction;
    
    // Bonus for high rating (if available)
    if (rating > 0) {
      if (rating >= 7.5) points += 0.5;
      if (rating >= 8.0) points += 0.5;
    }
    
    // Clamp to reasonable range
    return double.parse(points.clamp(2.0, 12.0).toStringAsFixed(1));
  }

  /// Calculate fantasy credits (price) based on player value
  /// Uses a tiered pricing model to ensure budget diversity
  /// Target: 15 players within 100 credits (avg ~6.67 per player)
  double _calculateCredits(double projectedPoints, String positionCode) {
    final normalizedPos = _normalizePositionCode(positionCode);
    
    // Base price depends heavily on projected points
    // We want a good spread: 4.5 to 11.0 credits
    double credits;
    
    if (projectedPoints >= 8.0) {
      // Elite players (top scorers, premium picks)
      credits = 9.0 + ((projectedPoints - 8.0) * 1.0);
    } else if (projectedPoints >= 6.0) {
      // Premium players
      credits = 7.0 + ((projectedPoints - 6.0) * 1.0);
    } else if (projectedPoints >= 4.5) {
      // Mid-range players
      credits = 5.5 + ((projectedPoints - 4.5) * 1.0);
    } else if (projectedPoints >= 3.0) {
      // Budget players
      credits = 4.5 + ((projectedPoints - 3.0) * 0.67);
    } else {
      // Bargain players
      credits = 4.5;
    }
    
    // Position-based adjustments (slight)
    switch (normalizedPos) {
      case 'GK':
        // GKs are generally cheaper (only need 2)
        credits *= 0.9;
        break;
      case 'DEF':
        // Defenders slightly cheaper
        credits *= 0.95;
        break;
      case 'MID':
        // Midfielders standard
        credits *= 1.0;
        break;
      case 'FWD':
        // Forwards slightly more expensive (high demand, only need 3)
        credits *= 1.05;
        break;
    }
    
    // Ensure price is within valid range
    // Min: 4.5 (allows building full team)
    // Max: 11.0 (prevents single player from breaking budget)
    return double.parse(credits.clamp(4.5, 11.0).toStringAsFixed(1));
  }

  // NOTE: Demo data generator removed - we now always use real API data
  // and throw errors if API fails (to help debug during development)

  /// Save roster to persistent cache
  Future<void> _saveRosterToCache(List<RosterPlayer> players) async {
    try {
      final cacheService = CacheService();
      final data = players.map((p) => p.toJson()).toList();
      await cacheService.set('liga_mx_roster', json.encode(data));
      await cacheService.set('liga_mx_roster_time', DateTime.now().toIso8601String());
      debugPrint('Saved ${players.length} roster players to cache');
    } catch (e) {
      debugPrint('Error saving roster to cache: $e');
    }
  }

  /// Load roster from persistent cache
  Future<List<RosterPlayer>?> _loadRosterFromCache() async {
    try {
      final cacheService = CacheService();
      final data = cacheService.get('liga_mx_roster');
      final timeStr = cacheService.get('liga_mx_roster_time');
      
      if (data == null || timeStr == null) return null;
      
      final cacheTime = DateTime.parse(timeStr);
      if (DateTime.now().difference(cacheTime) > const Duration(hours: 24)) {
        return null; // Cache expired
      }
      
      final List<dynamic> decoded = json.decode(data);
      return decoded
          .map((d) => RosterPlayer.fromJson(d as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading roster from cache: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}

