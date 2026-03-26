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
  final double price; // Price in millions of USD (e.g., 8.5 = $8.5M)
  final double projectedPoints; // Projected fantasy points
  final double selectedByPercent; // % of users who selected
  final Map<String, dynamic>? stats; // Season statistics
  
  /// Backwards compatibility - returns price (previously called credits)
  double get credits => price;

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
    this.price = 5.0,
    this.projectedPoints = 5.0,
    this.selectedByPercent = 0,
    this.stats,
  });
  
  /// Star player: projected points > 7.5 (indicates good recent form)
  bool get isStarPlayer => projectedPoints > 7.5;
  
  /// Elite player: projected points > 10 (indicates excellent form)
  bool get isElitePlayer => projectedPoints > 10.0;
  
  /// Cheeks player: projected points < 2.0 (indicates very poor form) 🍑
  /// Note: This uses the RosterPlayer scale (2-15), not the full prediction scale (0-100)
  bool get isCheeks => projectedPoints < 2.0;
  
  /// Get formatted price string (e.g., "$8.5M")
  String get formattedPrice => '\$${price.toStringAsFixed(1)}M';

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
    'price': price,
    'credits': price, // Backwards compatibility
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
    price: (json['price'] as num?)?.toDouble() ?? 
           (json['credits'] as num?)?.toDouble() ?? 5.0, // Support both
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

  /// Force refresh player stats from SportMonks API
  /// Call this to update player prices based on latest season stats
  Future<List<RosterPlayer>> refreshPlayerStats() async {
    debugPrint('Force refreshing player stats...');
    
    // Clear the stats cache
    await _cacheService.clearPlayerSeasonStats();
    
    // Clear the roster cache to force reload
    await _cacheService.clearLigaMxRoster();
    _ligaMxRosterCache = null;
    _ligaMxRosterCacheTime = null;
    
    // Reload all players from Firestore with fresh stats
    return loadAllPlayersFromFirestore(forceRefresh: true);
  }

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
          
          // Calculate price and projected points
          final stats = _extractPlayerStats(json);
          final projectedPoints = _calculateProjectedPoints(stats, positionCode);
          final price = _calculatePrice(stats, positionCode, projectedPoints);
          
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
            price: price,
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
    // ALWAYS recalculate prices from stats to ensure consistency
    final players = <RosterPlayer>[];
    for (final data in cachedData) {
      try {
        final stats = data['stats'] as Map<String, dynamic>?;
        final positionCode = data['positionCode'] as String;
        
        // Recalculate price and projected points from stats
        // This ensures we use the latest pricing logic
        double price;
        double projectedPoints;
        
        if (stats != null && stats.isNotEmpty) {
          projectedPoints = _calculateProjectedPointsFromStats(stats, positionCode);
          price = _calculatePrice(stats, positionCode, projectedPoints);
        } else {
          // Fallback to cached values if no stats
          price = (data['price'] as num?)?.toDouble() ?? 
                  (data['credits'] as num?)?.toDouble() ?? 5.0;
          projectedPoints = (data['projectedPoints'] as num?)?.toDouble() ?? 5.0;
        }
        
        players.add(RosterPlayer(
          id: data['id'] as int,
          name: data['name'] as String,
          displayName: data['displayName'] as String,
          imagePath: data['imagePath'] as String?,
          position: data['position'] as String,
          positionCode: positionCode,
          teamId: data['teamId'] as int,
          teamName: data['teamName'] as String,
          teamLogo: data['teamLogo'] as String?,
          jerseyNumber: data['jerseyNumber'] as int?,
          price: price,
          projectedPoints: projectedPoints,
          selectedByPercent: (data['selectedByPercent'] as num?)?.toDouble() ?? 0,
          stats: stats,
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
        // Check if cached players have stats - if not, they need enrichment
        final playersNeedStats = cachedPlayers.where((p) => 
          p.stats == null || p.stats!.isEmpty || 
          (p.stats!['goals'] == null && p.stats!['appearances'] == null)
        ).length;
        
        if (playersNeedStats > cachedPlayers.length * 0.5) {
          // More than 50% of players need stats - enrich them
          debugPrint('Found ${cachedPlayers.length} cached players but $playersNeedStats need stats - enriching...');
          final enrichedPlayers = await _enrichPlayersWithStats(cachedPlayers);
          // Save enriched players back to cache
          if (enrichedPlayers.isNotEmpty) {
            await _cacheService.clearLigaMxRoster();
            _addToCache(enrichedPlayers);
          }
          return enrichedPlayers;
        }
        
        debugPrint('Found ${cachedPlayers.length} players in Hive cache (sufficient with stats)');
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
      
      // Now enrich players with stats from SportMonks (for pricing)
      // This uses cached stats if available, otherwise fetches from API
      final enrichedPlayers = await _enrichPlayersWithStats(players);
      
      // Save to Hive cache (replace existing)
      if (enrichedPlayers.isNotEmpty) {
        await _cacheService.clearLigaMxRoster(); // Clear old cache
        _addToCache(enrichedPlayers);
      }
      
      debugPrint('Loaded ${enrichedPlayers.length} players from Firestore (enriched with stats)');
      return enrichedPlayers;
    } catch (e) {
      debugPrint('Error loading players from Firestore: $e');
      return [];
    }
  }
  
  /// Enrich players with season stats from SportMonks
  /// Uses cached stats if available, fetches from API otherwise
  Future<List<RosterPlayer>> _enrichPlayersWithStats(List<RosterPlayer> players) async {
    debugPrint('=== ENRICHING ${players.length} PLAYERS WITH STATS ===');
    
    // First check if we have cached stats
    var cachedStats = _cacheService.getAllPlayerSeasonStats();
    final needsRefresh = cachedStats == null || cachedStats.isEmpty;
    cachedStats ??= <int, Map<String, dynamic>>{};
    
    debugPrint('Cached stats available for ${cachedStats.length} players, needsRefresh: $needsRefresh');
    
    // Identify players that need stats fetched
    final playersNeedingStats = players.where((p) => 
      !cachedStats!.containsKey(p.id) || 
      cachedStats[p.id] == null ||
      cachedStats[p.id]!.isEmpty ||
      (cachedStats[p.id]!['goals'] == null && cachedStats[p.id]!['appearances'] == null)
    ).toList();
    
    debugPrint('${playersNeedingStats.length} players need stats fetched');
    
    if (playersNeedingStats.isNotEmpty) {
      debugPrint('Fetching stats for ${playersNeedingStats.length} players from SportMonks...');
      
      // Fetch stats in batches to avoid overwhelming the API
      const batchSize = 10;
      int fetchedCount = 0;
      int emptyCount = 0;
      
      for (var i = 0; i < playersNeedingStats.length && i < 200; i += batchSize) {
        final batch = playersNeedingStats.skip(i).take(batchSize);
        
        await Future.wait(batch.map((player) async {
          try {
            final stats = await _fetchPlayerStatsFromSportMonks(player.id);
            if (stats != null && stats.isNotEmpty) {
              cachedStats![player.id] = stats;
              fetchedCount++;
              // Log first few successful fetches
              if (fetchedCount <= 3) {
                debugPrint('Player ${player.id} (${player.displayName}) stats: goals=${stats['goals']}, assists=${stats['assists']}, appearances=${stats['appearances']}');
              }
            } else {
              emptyCount++;
            }
          } catch (e) {
            debugPrint('Error fetching stats for player ${player.id}: $e');
          }
        }));
        
        // Log progress every 50 players
        if ((i + batchSize) % 50 == 0) {
          debugPrint('Progress: ${i + batchSize}/${playersNeedingStats.length} players processed');
        }
        
        // Small delay between batches to avoid rate limiting
        if (i + batchSize < playersNeedingStats.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      debugPrint('Fetched stats for $fetchedCount players ($emptyCount had no stats)');
      
      // Save all stats to cache
      if (cachedStats!.isNotEmpty) {
        await _cacheService.saveAllPlayerSeasonStats(cachedStats);
        debugPrint('Saved ${cachedStats.length} player stats to cache');
      }
    } else if (cachedStats!.isNotEmpty) {
      debugPrint('Using cached stats for ${cachedStats.length} players');
    }
    
    // Recalculate prices with the stats
    final enrichedPlayers = <RosterPlayer>[];
    int enrichedCount = 0;
    
    for (final player in players) {
      final stats = cachedStats![player.id];
      if (stats != null && stats.isNotEmpty) {
        final projectedPoints = _calculateProjectedPointsFromStats(stats, player.positionCode);
        final price = _calculatePrice(stats, player.positionCode, projectedPoints);
        enrichedPlayers.add(RosterPlayer(
          id: player.id,
          name: player.name,
          displayName: player.displayName,
          imagePath: player.imagePath,
          position: player.position,
          positionCode: player.positionCode,
          teamId: player.teamId,
          teamName: player.teamName,
          teamLogo: player.teamLogo,
          jerseyNumber: player.jerseyNumber,
          price: price,
          projectedPoints: projectedPoints,
          selectedByPercent: player.selectedByPercent,
          stats: stats,
        ));
        enrichedCount++;
      } else {
        // Keep original player if no stats available
        enrichedPlayers.add(player);
      }
    }
    
    // Log price distribution for debugging
    final forwards = enrichedPlayers.where((p) => p.positionCode == 'FWD').toList();
    final forwardPrices = forwards.map((p) => p.price).toList()..sort();
    if (forwardPrices.isNotEmpty) {
      debugPrint('FWD price range: \$${forwardPrices.first}M - \$${forwardPrices.last}M (${forwards.length} players)');
    }
    
    final midfielders = enrichedPlayers.where((p) => p.positionCode == 'MID').toList();
    final midPrices = midfielders.map((p) => p.price).toList()..sort();
    if (midPrices.isNotEmpty) {
      debugPrint('MID price range: \$${midPrices.first}M - \$${midPrices.last}M (${midfielders.length} players)');
    }
    
    debugPrint('=== ENRICHMENT COMPLETE: $enrichedCount/${players.length} players have stats ===');
    
    return enrichedPlayers;
  }
  
  /// Fetch player season stats from SportMonks API
  Future<Map<String, dynamic>?> _fetchPlayerStatsFromSportMonks(int playerId) async {
    try {
      final response = await _client.getPlayerById(
        playerId,
        includes: ['statistics.details'],
      );
      
      final playerData = response.data;
      final statistics = playerData['statistics'] as List?;
      
      if (statistics == null || statistics.isEmpty) {
        debugPrint('Player $playerId: No statistics array in response');
        return null;
      }
      
      // Find the most recent season with stats
      Map<String, dynamic>? bestStats;
      int highestSeasonId = 0;
      
      for (final stat in statistics) {
        if (stat is! Map<String, dynamic>) continue;
        
        final seasonId = _parseIntValue(stat['season_id']) ?? 0;
        final hasValues = stat['has_values'] == true;
        
        if (seasonId > highestSeasonId) {
          final details = stat['details'] as List?;
          if (details != null && details.isNotEmpty) {
            highestSeasonId = seasonId;
            bestStats = _extractStatsFromDetails(details);
          } else if (hasValues) {
            // Even without details, mark this season as valid
            highestSeasonId = seasonId;
          }
        }
      }
      
      if (bestStats == null || bestStats.isEmpty) {
        // Try to extract stats directly from the statistics array (some API versions)
        for (final stat in statistics) {
          if (stat is! Map<String, dynamic>) continue;
          final seasonId = _parseIntValue(stat['season_id']) ?? 0;
          if (seasonId == highestSeasonId || highestSeasonId == 0) {
            // Check for direct stat fields
            final goals = stat['goals'] ?? stat['total_goals'];
            final assists = stat['assists'] ?? stat['total_assists'];
            if (goals != null || assists != null) {
              bestStats = {
                'goals': goals,
                'assists': assists,
                'appearances': stat['appearances'] ?? stat['total_appearances'],
                'minutes': stat['minutes'] ?? stat['total_minutes'],
                'rating': stat['rating'] ?? stat['average_rating'],
              };
              break;
            }
          }
        }
      }
      
      return bestStats;
    } catch (e) {
      debugPrint('SportMonks stats fetch error for player $playerId: $e');
      return null;
    }
  }
  
  /// Extract stats map from SportMonks statistics.details array
  Map<String, dynamic> _extractStatsFromDetails(List details) {
    final stats = <String, dynamic>{};
    
    for (final detail in details) {
      if (detail is! Map<String, dynamic>) continue;
      
      final typeId = _parseIntValue(detail['type_id']);
      final value = detail['value'];
      
      // SportMonks type IDs for common stats
      switch (typeId) {
        case 52: stats['goals'] = value; break;          // Goals
        case 79: stats['rating'] = value; break;         // Rating
        case 84: stats['assists'] = value; break;        // Assists
        case 119: stats['minutes'] = value; break;       // Minutes
        case 194: 
        case 59: stats['cleanSheets'] = value; break;    // Clean sheets
        case 209:
        case 101: stats['saves'] = value; break;         // Saves
        case 321: 
        case 42: stats['appearances'] = value; break;    // Appearances
        case 56: stats['yellowCards'] = value; break;    // Yellow cards
        case 57: stats['redCards'] = value; break;       // Red cards
      }
    }
    
    return stats;
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
      final price = _calculatePrice(stats.isNotEmpty ? stats : null, positionCode, projectedPoints);
      
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
        price: price,
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
  
  /// Extract numeric value from stats field (handles nested objects like {total: 4, goals: 4})
  double _extractStatValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is Map) {
      // SportMonks nested format: {total: X, goals: X, penalties: X}
      return (value['total'] as num?)?.toDouble() ?? 
             (value['goals'] as num?)?.toDouble() ?? 
             (value['value'] as num?)?.toDouble() ?? 0;
    }
    return double.tryParse(value.toString()) ?? 0;
  }
  
  /// Calculate projected points from stats map
  double _calculateProjectedPointsFromStats(Map<String, dynamic> stats, String positionCode) {
    double points = 2.0; // Base points
    
    final goals = _extractStatValue(stats['goals']).toInt();
    final assists = _extractStatValue(stats['assists']).toInt();
    final cleanSheets = _extractStatValue(stats['cleanSheets']) .toInt() ?? 
                        _extractStatValue(stats['clean_sheets']).toInt();
    final saves = _extractStatValue(stats['saves']).toInt();
    final appearances = _extractStatValue(stats['appearances']).toInt();
    final rating = _extractStatValue(stats['rating']);
    
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
      final price = _calculatePrice(stats, positionCode, projectedPoints);
      
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
        price: price,
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

  /// Calculate player price in millions of USD based on season stats
  /// 
  /// Uses a realistic pricing model where:
  /// - Budget: $100M for 15 players (avg ~$6.67M per player)
  /// - Price range: $1M to $25M
  /// 
  /// Pricing factors:
  /// - Forwards: Goals weighted heavily, assists secondary
  /// - Midfielders: Goals + assists, playmaking ability
  /// - Defenders: Clean sheets, rare goals highly valued
  /// - Goalkeepers: Clean sheets, saves, consistency
  double _calculatePrice(Map<String, dynamic>? stats, String positionCode, double projectedPoints) {
    final normalizedPos = _normalizePositionCode(positionCode);
    
    // Base prices by position (in millions USD)
    double basePrice;
    switch (normalizedPos) {
      case 'GK':
        basePrice = 2.0; // $2M base for goalkeepers
        break;
      case 'DEF':
        basePrice = 2.5; // $2.5M base for defenders
        break;
      case 'MID':
        basePrice = 3.0; // $3M base for midfielders
        break;
      case 'FWD':
        basePrice = 3.5; // $3.5M base for forwards
        break;
      default:
        basePrice = 3.0;
    }
    
    // If no stats, use projected points as fallback
    if (stats == null || stats.isEmpty) {
      // Scale price based on projected points (2-12 range -> 1.5M-8M)
      final priceFromPoints = basePrice + (projectedPoints - 3.0) * 0.8;
      return double.parse(priceFromPoints.clamp(1.5, 10.0).toStringAsFixed(1));
    }
    
    // Extract stats (handles nested SportMonks format like {total: 4, goals: 4})
    final goals = _extractStatValue(stats['goals']);
    final assists = _extractStatValue(stats['assists']);
    final cleanSheets = _extractStatValue(stats['cleanSheets']) + 
                        _extractStatValue(stats['clean_sheets']);
    final saves = _extractStatValue(stats['saves']);
    final appearances = _extractStatValue(stats['appearances']);
    final rating = _extractStatValue(stats['rating']);
    final minutes = _extractStatValue(stats['minutes']);
    
    // Calculate games played (for per-game calculations)
    final gamesPlayed = appearances > 0 ? appearances : (minutes > 0 ? minutes / 70 : 1);
    
    double price = basePrice;
    
    // Position-specific pricing
    switch (normalizedPos) {
      case 'FWD':
        // Forwards: Goals are king
        // 20+ goals = star striker (~$20M+)
        // 10-19 goals = good striker (~$10-15M)
        // 5-9 goals = decent striker (~$6-10M)
        // <5 goals = budget option (~$3-6M)
        if (goals >= 20) {
          price = 18.0 + ((goals - 20) * 0.8);
        } else if (goals >= 15) {
          price = 13.0 + ((goals - 15) * 1.0);
        } else if (goals >= 10) {
          price = 9.0 + ((goals - 10) * 0.8);
        } else if (goals >= 5) {
          price = 5.5 + ((goals - 5) * 0.7);
        } else {
          price = basePrice + (goals * 0.5);
        }
        // Assists add value for forwards
        price += assists * 0.25;
        break;
        
      case 'MID':
        // Midfielders: Goals + assists matter, playmaking valued
        // Goals are more valuable (rarer for mids)
        if (goals >= 10) {
          price = 12.0 + ((goals - 10) * 1.2);
        } else if (goals >= 5) {
          price = 7.0 + ((goals - 5) * 1.0);
        } else {
          price = basePrice + (goals * 0.8);
        }
        // Assists are key for midfielders
        if (assists >= 10) {
          price += 4.0 + ((assists - 10) * 0.5);
        } else if (assists >= 5) {
          price += 2.0 + ((assists - 5) * 0.4);
        } else {
          price += assists * 0.4;
        }
        // Clean sheets bonus for defensive mids
        price += cleanSheets * 0.15;
        break;
        
      case 'DEF':
        // Defenders: Clean sheets + rare goals
        // Goals from defenders are highly valuable
        price += goals * 1.5;
        price += assists * 0.4;
        // Clean sheets are important
        if (cleanSheets >= 15) {
          price += 4.0 + ((cleanSheets - 15) * 0.3);
        } else if (cleanSheets >= 10) {
          price += 2.5 + ((cleanSheets - 10) * 0.3);
        } else {
          price += cleanSheets * 0.25;
        }
        break;
        
      case 'GK':
        // Goalkeepers: Clean sheets and saves
        // Clean sheets are paramount
        if (cleanSheets >= 15) {
          price = 8.0 + ((cleanSheets - 15) * 0.5);
        } else if (cleanSheets >= 10) {
          price = 5.0 + ((cleanSheets - 10) * 0.6);
        } else if (cleanSheets >= 5) {
          price = 3.0 + ((cleanSheets - 5) * 0.4);
        } else {
          price = basePrice + (cleanSheets * 0.2);
        }
        // Saves add value (per game)
        if (gamesPlayed > 0) {
          final savesPerGame = saves / gamesPlayed;
          if (savesPerGame >= 4) {
            price += 1.5;
          } else if (savesPerGame >= 3) {
            price += 1.0;
          } else if (savesPerGame >= 2) {
            price += 0.5;
          }
        }
        break;
    }
    
    // Rating bonus (applies to all positions)
    if (rating > 0) {
      if (rating >= 7.5) price += 1.5;
      else if (rating >= 7.2) price += 1.0;
      else if (rating >= 7.0) price += 0.5;
      else if (rating < 6.5) price -= 0.5; // Penalty for low rating
    }
    
    // Consistency bonus (played most games)
    if (gamesPlayed >= 30) {
      price += 1.0; // Reliable player premium
    } else if (gamesPlayed >= 25) {
      price += 0.5;
    } else if (gamesPlayed < 10) {
      price *= 0.8; // Discount for rarely used players
    }
    
    // Ensure price is within valid range
    // Min: $1.5M (even bench players have value)
    // Max: $25M (nobody should break the bank completely)
    return double.parse(price.clamp(1.5, 25.0).toStringAsFixed(1));
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

  /// Get current squad player IDs for a team from local cache or Firebase
  /// This is faster than making API calls and uses your maintained data
  /// 
  /// Returns a Set of player IDs currently on the team's roster
  Future<Set<int>> getCurrentSquadPlayerIds(int teamId) async {
    // First, try to get from in-memory cache (fastest)
    final cachedPlayers = _playerDetailsCache.values
        .where((p) => p.teamId == teamId)
        .map((p) => p.id)
        .toSet();
    
    if (cachedPlayers.isNotEmpty) {
      debugPrint('PlayersRepository: Found ${cachedPlayers.length} players for team $teamId in memory cache');
      return cachedPlayers;
    }
    
    // Second, try Hive cache
    final hivePlayers = getCachedPlayers()
        .where((p) => p.teamId == teamId)
        .map((p) => p.id)
        .toSet();
    
    if (hivePlayers.isNotEmpty) {
      debugPrint('PlayersRepository: Found ${hivePlayers.length} players for team $teamId in Hive cache');
      return hivePlayers;
    }
    
    // Third, fetch from Firebase (which you've updated with teamId)
    try {
      debugPrint('PlayersRepository: Fetching players for team $teamId from Firebase');
      final firestorePlayers = await _firestoreService.getPlayersByTeam(teamId);
      
      final playerIds = firestorePlayers
          .map((p) {
            // Handle both 'id' field and document ID
            final id = p['id'];
            if (id is int) return id;
            if (id is String) return int.tryParse(id);
            return null;
          })
          .whereType<int>()
          .toSet();
      
      debugPrint('PlayersRepository: Found ${playerIds.length} players for team $teamId in Firebase');
      return playerIds;
    } catch (e) {
      debugPrint('PlayersRepository: Error fetching from Firebase: $e');
    }
    
    // Last resort: fetch from SportMonks API
    try {
      debugPrint('PlayersRepository: Falling back to SportMonks API for team $teamId');
      final squadPlayers = await getTeamSquadPlayers(teamId);
      return squadPlayers.map((p) => p.id).toSet();
    } catch (e) {
      debugPrint('PlayersRepository: Error fetching from API: $e');
      return {};
    }
  }
  
  /// Get team ID for a specific player from local cache or Firebase
  /// Returns null if player not found
  Future<int?> getTeamIdForPlayer(int playerId) async {
    // First, check in-memory cache
    if (_playerDetailsCache.containsKey(playerId)) {
      return _playerDetailsCache[playerId]!.teamId;
    }
    
    // Second, check Hive cache
    final cachedPlayers = getCachedPlayers();
    final cachedPlayer = cachedPlayers.where((p) => p.id == playerId).firstOrNull;
    if (cachedPlayer != null) {
      return cachedPlayer.teamId;
    }
    
    // Third, fetch from Firebase
    try {
      final playerData = await _firestoreService.getPlayerById(playerId);
      if (playerData != null && playerData.containsKey('teamId')) {
        final teamId = playerData['teamId'];
        if (teamId is int) return teamId;
        if (teamId is String) return int.tryParse(teamId);
      }
    } catch (e) {
      debugPrint('PlayersRepository: Error fetching player $playerId from Firebase: $e');
    }
    
    return null;
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}

