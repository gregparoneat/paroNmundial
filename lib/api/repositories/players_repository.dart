import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
class PlayersRepository {
  final SportMonksClient _client;
  
  // Cache for Liga MX roster players
  List<RosterPlayer>? _ligaMxRosterCache;
  DateTime? _ligaMxRosterCacheTime;
  static const Duration _cacheExpiry = Duration(hours: 6);
  
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
      debugPrint('SportMonks API Error: $e');
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
      debugPrint('SportMonks API Error: $e');
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

  /// Get all players currently in Liga MX teams
  /// Strategy: 
  /// 1. Call /teams?include=players to get all Liga MX teams with their current player IDs
  ///    (API plan only covers Liga MX, so this returns only Liga MX teams)
  /// 2. Call /players to get detailed player info
  /// 3. Filter players by IDs from step 1 to get only active Liga MX players
  Future<List<RosterPlayer>> getLigaMxRosterPlayers({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && 
        _ligaMxRosterCache != null && 
        _ligaMxRosterCacheTime != null &&
        DateTime.now().difference(_ligaMxRosterCacheTime!) < _cacheExpiry) {
      debugPrint('Returning cached Liga MX roster (${_ligaMxRosterCache!.length} players)');
      return _ligaMxRosterCache!;
    }

    if (!SportMonksConfig.isConfigured) {
      debugPrint('API not configured, returning demo roster players');
      return _generateDemoRosterPlayers();
    }

    try {
      debugPrint('Step 1: Fetching all Liga MX teams with players...');
      
      // Map to store player ID -> team info for quick lookup
      final Map<int, _TeamPlayerInfo> validPlayerIds = {};
      
      // Fetch all teams with players (paginated)
      int page = 1;
      bool hasMore = true;
      
      while (hasMore) {
        final teamsResponse = await _client.getAllTeamsWithPlayers(
          page: page,
          perPage: 50,
        );
        
        debugPrint('Fetched page $page of teams: ${teamsResponse.data.length} teams');
        
        // Extract player IDs and team info from each team
        for (final team in teamsResponse.data) {
          final teamId = _parseIntValue(team['id']);
          final teamName = team['name']?.toString() ?? 'Unknown Team';
          final teamLogo = team['image_path']?.toString();
          
          // Get players array from team
          final playersData = team['players'];
          if (playersData is List) {
            for (final playerEntry in playersData) {
              final playerId = _parseIntValue(playerEntry['player_id'] ?? playerEntry['id']);
              if (playerId != null && teamId != null) {
                validPlayerIds[playerId] = _TeamPlayerInfo(
                  teamId: teamId,
                  teamName: teamName,
                  teamLogo: teamLogo,
                  jerseyNumber: _parseIntValue(playerEntry['jersey_number']),
                );
              }
            }
          }
        }
        
        hasMore = teamsResponse.hasMore;
        page++;
        
        // Safety limit
        if (page > 10) break;
      }
      
      debugPrint('Found ${validPlayerIds.length} valid player IDs from Liga MX teams');
      
      if (validPlayerIds.isEmpty) {
        debugPrint('No player IDs found, returning demo players');
        return _generateDemoRosterPlayers();
      }
      
      // Step 2: Fetch all players with details
      debugPrint('Step 2: Fetching all players with details...');
      final List<RosterPlayer> rosterPlayers = [];
      
      page = 1;
      hasMore = true;
      int totalPlayersProcessed = 0;
      
      while (hasMore) {
        final playersResponse = await _client.getAllPlayers(
          page: page,
          perPage: 50,
          includes: [
            'nationality',
            'position',
            'detailedPosition', 
            'currentTeam',
            'statistics.details',
          ],
        );
        
        debugPrint('Fetched page $page of players: ${playersResponse.data.length} players');
        totalPlayersProcessed += playersResponse.data.length;
        
        // Filter and parse players that are in our valid IDs list
        for (final playerData in playersResponse.data) {
          final playerId = _parseIntValue(playerData['id']);
          
          if (playerId != null && validPlayerIds.containsKey(playerId)) {
            final teamInfo = validPlayerIds[playerId]!;
            
            final rosterPlayer = _parsePlayerToRosterPlayer(
              playerData,
              teamInfo,
            );
            
            if (rosterPlayer != null) {
              rosterPlayers.add(rosterPlayer);
            }
          }
        }
        
        hasMore = playersResponse.hasMore;
        page++;
        
        // Safety limit - most leagues won't have more than 1000 players
        if (page > 30 || totalPlayersProcessed > 1500) {
          debugPrint('Reached safety limit at page $page');
          break;
        }
      }
      
      debugPrint('Loaded ${rosterPlayers.length} Liga MX roster players from $totalPlayersProcessed total players');
      
      // Update cache
      _ligaMxRosterCache = rosterPlayers;
      _ligaMxRosterCacheTime = DateTime.now();
      
      // Also save to persistent cache
      await _saveRosterToCache(rosterPlayers);
      
      return rosterPlayers;
      
    } on SportMonksException catch (e) {
      debugPrint('SportMonks API Error: $e');
      
      // Try to load from persistent cache
      final cached = await _loadRosterFromCache();
      if (cached != null && cached.isNotEmpty) {
        debugPrint('Returning ${cached.length} players from persistent cache');
        return cached;
      }
      
      return _generateDemoRosterPlayers();
    } catch (e) {
      debugPrint('Error fetching Liga MX rosters: $e');
      return _generateDemoRosterPlayers();
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

  /// Search players in Liga MX roster by name
  Future<List<RosterPlayer>> searchRosterPlayers(String query) async {
    final allPlayers = await getLigaMxRosterPlayers();
    
    if (query.isEmpty) return allPlayers;
    
    final lowerQuery = query.toLowerCase();
    return allPlayers.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
             p.displayName.toLowerCase().contains(lowerQuery) ||
             p.teamName.toLowerCase().contains(lowerQuery);
    }).toList();
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

  /// Calculate projected fantasy points based on stats
  double _calculateProjectedPoints(Map<String, dynamic>? stats, String positionCode) {
    if (stats == null) {
      // Default points by position
      switch (_normalizePositionCode(positionCode)) {
        case 'GK':
          return 4.0;
        case 'DEF':
          return 4.5;
        case 'MID':
          return 5.0;
        case 'FWD':
          return 5.5;
        default:
          return 5.0;
      }
    }
    
    double points = 2.0; // Base points for playing
    
    final goals = _parseDoubleValue(stats['goals']) ?? 0;
    final assists = _parseDoubleValue(stats['assists']) ?? 0;
    final cleanSheets = _parseDoubleValue(stats['cleanSheets']) ?? 0;
    final saves = _parseDoubleValue(stats['saves']) ?? 0;
    final appearances = _parseDoubleValue(stats['appearances']) ?? 1;
    final yellowCards = _parseDoubleValue(stats['yellowCards']) ?? 0;
    final redCards = _parseDoubleValue(stats['redCards']) ?? 0;
    
    final normalizedPos = _normalizePositionCode(positionCode);
    
    // Points per stat based on position
    if (normalizedPos == 'GK') {
      points += (goals * 6) + (assists * 3) + (cleanSheets * 4) + (saves * 0.5);
      points -= (yellowCards * 1) + (redCards * 3);
    } else if (normalizedPos == 'DEF') {
      points += (goals * 6) + (assists * 3) + (cleanSheets * 4);
      points -= (yellowCards * 1) + (redCards * 3);
    } else if (normalizedPos == 'MID') {
      points += (goals * 5) + (assists * 3) + (cleanSheets * 1);
      points -= (yellowCards * 1) + (redCards * 3);
    } else { // FWD
      points += (goals * 4) + (assists * 3);
      points -= (yellowCards * 1) + (redCards * 3);
    }
    
    // Average per game
    if (appearances > 0) {
      points = points / appearances;
    }
    
    return double.parse(points.clamp(1.0, 15.0).toStringAsFixed(1));
  }

  /// Calculate fantasy credits (price) based on projected points
  double _calculateCredits(double projectedPoints, String positionCode) {
    // Base credit calculation
    double credits = 5.0 + (projectedPoints * 0.8);
    
    // Position adjustments
    switch (_normalizePositionCode(positionCode)) {
      case 'GK':
        credits *= 0.85; // GKs are typically cheaper
        break;
      case 'FWD':
        credits *= 1.1; // Forwards are typically more expensive
        break;
    }
    
    return double.parse(credits.clamp(4.0, 12.0).toStringAsFixed(1));
  }

  /// Generate demo roster players for when API is not available
  List<RosterPlayer> _generateDemoRosterPlayers() {
    final players = <RosterPlayer>[];
    
    // Liga MX teams with sample players
    final teams = [
      {'id': 15522, 'name': 'Club América', 'code': 'AME'},
      {'id': 2025, 'name': 'Guadalajara', 'code': 'GDL'},
      {'id': 2031, 'name': 'Cruz Azul', 'code': 'CAZ'},
      {'id': 2032, 'name': 'Pumas UNAM', 'code': 'PUM'},
      {'id': 2028, 'name': 'Monterrey', 'code': 'MTY'},
      {'id': 2033, 'name': 'Tigres UANL', 'code': 'TIG'},
      {'id': 2026, 'name': 'Toluca', 'code': 'TOL'},
      {'id': 2027, 'name': 'Santos Laguna', 'code': 'SAN'},
    ];
    
    // Sample players per team
    final playerTemplates = [
      // Goalkeepers
      {'pos': 'GK', 'names': ['G. Ochoa', 'R. Cota', 'C. Acevedo', 'L. Rodriguez', 'O. Talavera', 'J. Corona', 'A. Gudino', 'G. Martinez']},
      // Defenders
      {'pos': 'DEF', 'names': ['J. Sanchez', 'N. Araujo', 'C. Montes', 'J. Angulo', 'K. Alvarez', 'L. Reyes', 'I. Dominguez', 'E. Aguirre', 'B. Valdez', 'S. Caceres', 'H. Martin', 'J. Gallardo']},
      // Midfielders
      {'pos': 'MID', 'names': ['A. Vega', 'R. Sanchez', 'L. Romo', 'O. Rodriguez', 'F. Beltran', 'J. Gonzalez', 'C. Antuna', 'E. Lainez', 'D. Valdes', 'J. Dos Santos', 'C. Rodriguez', 'L. Chavez']},
      // Forwards
      {'pos': 'FWD', 'names': ['S. Gimenez', 'H. Martin', 'R. Funes Mori', 'A. Canelo', 'G. Berterame', 'U. Antuna', 'J. Quinones', 'A. Gignac', 'R. De La Rosa', 'M. Meza']},
    ];
    
    int idCounter = 10000;
    
    for (int teamIdx = 0; teamIdx < teams.length; teamIdx++) {
      final team = teams[teamIdx];
      
      for (final template in playerTemplates) {
        final pos = template['pos'] as String;
        final names = template['names'] as List<String>;
        
        // Add 1-4 players per position per team
        final count = pos == 'GK' ? 1 : (pos == 'FWD' ? 2 : 3);
        for (int i = 0; i < count && (teamIdx * 3 + i) < names.length; i++) {
          final nameIdx = (teamIdx * 3 + i) % names.length;
          final basePoints = 4.0 + (idCounter % 7);
          final credits = 5.0 + (basePoints * 0.7);
          
          players.add(RosterPlayer(
            id: idCounter++,
            name: names[nameIdx],
            displayName: names[nameIdx],
            position: _normalizePosition(pos),
            positionCode: pos,
            teamId: team['id'] as int,
            teamName: team['name'] as String,
            jerseyNumber: (idCounter % 30) + 1,
            credits: double.parse(credits.toStringAsFixed(1)),
            projectedPoints: double.parse(basePoints.toStringAsFixed(1)),
            selectedByPercent: (idCounter % 40).toDouble(),
          ));
        }
      }
    }
    
    return players;
  }

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

