import 'dart:convert';
import 'dart:math' show log;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fantacy11/api/firestore_service.dart';
import 'package:fantacy11/api/sportmonks_client.dart';
import 'package:fantacy11/api/sportmonks_config.dart';
import 'package:fantacy11/api/world_cup_market_tiers.dart';
import 'package:fantacy11/api/world_cup_market_values.dart';
import 'package:fantacy11/features/fantasy/fantasy_points_predictor.dart';
import 'package:fantacy11/features/player/models/player_info.dart';
import 'package:fantacy11/services/cache_service.dart';

/// Player with fantasy-related data for team building
class RosterPlayer {
  static const int seasonMatchesProjection = 18;
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
  final double?
  seasonProjectedPointsPerMatch; // Season-based per-match baseline
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
    this.seasonProjectedPointsPerMatch,
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

  String? get statSourceLabel {
    final seasonName = stats?['seasonName']?.toString().trim();
    if (seasonName == null || seasonName.isEmpty) return null;

    if (seasonName.contains('World Cup')) return seasonName;
    if (seasonName.contains('Qualification') ||
        seasonName.contains('Qualifiers')) {
      return seasonName
          .replaceAll('WC Qualification', 'WCQ')
          .replaceAll('World Cup Qualifiers', 'WCQ')
          .replaceAll('Qualification', 'Qualifiers');
    }

    return seasonName;
  }

  String get projectionSummary {
    final source = statSourceLabel;
    if (source == null) {
      return '${projectedPoints.toStringAsFixed(1)} next • ${projectedSeasonPoints.toStringAsFixed(1)} season';
    }
    return '${projectedPoints.toStringAsFixed(1)} next • ${projectedSeasonPoints.toStringAsFixed(1)} $source';
  }

  /// Estimated season total based on the per-match projection.
  double get projectedSeasonPoints {
    final seasonPerMatchProjection =
        seasonProjectedPointsPerMatch ?? projectedPoints;
    final appearances = _statAsDouble(stats?['appearances']);
    final lineups = _statAsDouble(stats?['lineups']);
    final minutes = _statAsDouble(stats?['minutes']);
    final gamesPlayed = appearances > 0
        ? appearances
        : (lineups > 0 ? lineups : (minutes > 0 ? minutes / 70.0 : 0.0));
    final minutesPerAppearance = gamesPlayed > 0
        ? (minutes > 0 ? minutes / gamesPlayed : 75.0)
        : 0.0;

    // Keep next-match projection intact, but discount season totals for
    // low-usage players so bench pieces do not project like full-time starters.
    final seasonRoleFactor =
        (0.15 +
                0.85 *
                    (gamesPlayed / seasonMatchesProjection).clamp(0.0, 1.0) *
                    (minutesPerAppearance / 75.0).clamp(0.0, 1.0))
            .clamp(0.15, 1.0);

    return seasonPerMatchProjection *
        seasonMatchesProjection *
        seasonRoleFactor;
  }

  double _statAsDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is Map<String, dynamic>) {
      final total = value['total'];
      if (total is num) return total.toDouble();
      if (total != null) return double.tryParse(total.toString()) ?? 0.0;
    }
    return double.tryParse(value.toString()) ?? 0.0;
  }

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
    'seasonProjectedPointsPerMatch': seasonProjectedPointsPerMatch,
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
    price:
        (json['price'] as num?)?.toDouble() ??
        (json['credits'] as num?)?.toDouble() ??
        5.0, // Support both
    projectedPoints: (json['projectedPoints'] as num?)?.toDouble() ?? 5.0,
    seasonProjectedPointsPerMatch:
        (json['seasonProjectedPointsPerMatch'] as num?)?.toDouble(),
    selectedByPercent: (json['selectedByPercent'] as num?)?.toDouble() ?? 0,
    stats: json['stats'] as Map<String, dynamic>?,
  );
}

/// Liga MX team with basic info
class LigaMxTeam {
  final int id;
  final String name;
  final String? logo;

  LigaMxTeam({required this.id, required this.name, this.logo});
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
  Future<List<RosterPlayer>>? _loadAllPlayersFuture;

  PlayersRepository({
    SportMonksClient? client,
    FirestoreService? firestoreService,
  }) : _client = client ?? SportMonksClient(),
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

      return response.data.map((json) => Player.fromJson(json)).toList();
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
        includes: [
          'position',
          'detailedPosition',
          'nationality',
          'teams',
          'statistics.details',
        ],
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
          final name =
              json['display_name']?.toString() ??
              json['common_name']?.toString() ??
              json['name']?.toString() ??
              'Unknown';

          final positionData = json['position'] as Map<String, dynamic>?;
          final detailedPositionData =
              json['detailedPosition'] as Map<String, dynamic>?;
          String positionCode = 'MID';
          String positionName = 'Midfielder';

          if (positionData != null) {
            // Use detailed position if available for more accuracy
            final rawCode =
                detailedPositionData?['code']?.toString() ??
                positionData['code']?.toString() ??
                'MID';
            // Normalize to our standard codes (GK, DEF, MID, FWD)
            positionCode = _normalizePositionCode(rawCode);
            positionName = _normalizePosition(rawCode);
            debugPrint(
              '   Position: raw="$rawCode" -> normalized="$positionCode"',
            );
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
                    if (furthestEndDate == null ||
                        endDate.isAfter(furthestEndDate)) {
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
                      teamName =
                          matchingTeam['name']?.toString() ?? 'Team $teamId';
                      teamLogo = matchingTeam['logo']?.toString();
                    }
                  }
                }
              }
            }
          }

          // Calculate price and projected points
          final stats = _extractPlayerStats(json);
          final seasonProjectedPoints = _calculateProjectedPoints(
            stats,
            positionCode,
          );
          final projectedPoints = _calculateNextMatchProjectedPoints(
            playerId: playerId,
            playerName: json['name']?.toString() ?? name,
            displayName: name,
            positionCode: positionCode,
            seasonProjectedPoints: seasonProjectedPoints,
            seasonStats: stats,
            teamId: teamId,
          );
          final price = _calculatePrice(
            stats,
            positionCode,
            seasonProjectedPoints,
            playerName: json['name']?.toString() ?? name,
            displayName: name,
          );

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
            seasonProjectedPointsPerMatch: seasonProjectedPoints,
            stats: stats,
          );

          players.add(rosterPlayer);
          _playerDetailsCache[playerId] = rosterPlayer;
        } catch (e) {
          debugPrint('Error parsing search result: $e');
        }
      }

      // Filter out players with "Unknown Team"
      final filteredPlayers = players
          .where((p) => p.teamName != 'Unknown Team')
          .toList();

      // Add to Hive cache
      if (filteredPlayers.isNotEmpty) {
        _addToCache(filteredPlayers);
      }

      debugPrint(
        'Search returned ${filteredPlayers.length} roster players (filtered from ${players.length})',
      );
      return filteredPlayers;
    } on SportMonksException catch (e) {
      debugPrint('SportMonks API Error during search: $e');
      return [];
    }
  }

  /// Get player by ID
  Future<Player?> getPlayerById(int playerId) async {
    if (!SportMonksConfig.isConfigured) {
      return await _buildFallbackPlayerById(playerId) ?? _loadMockPlayer();
    }

    try {
      final response = await _client.getPlayerById(
        playerId,
        includes: SportMonksConfig.playerIncludes,
      );

      return Player.fromJson(response.data);
    } on SportMonksException catch (e) {
      debugPrint('SportMonks API Error: $e');
    } catch (e) {
      debugPrint('Unexpected error fetching player $playerId: $e');
    }

    return _buildFallbackPlayerById(playerId);
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
        includes: [
          'player.nationality',
          'player.position',
          'player.detailedposition',
        ],
      );

      // Squad endpoint returns squad entries with nested player data
      return response.data
          .where((squad) => squad['player'] != null)
          .map(
            (squad) => Player.fromJson(squad['player'] as Map<String, dynamic>),
          )
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
        double seasonProjectedPoints;

        if (stats != null && stats.isNotEmpty) {
          seasonProjectedPoints = _calculateProjectedPointsFromStats(
            stats,
            positionCode,
          );
          price = _calculatePrice(
            stats,
            positionCode,
            seasonProjectedPoints,
            playerName: data['name'] as String,
            displayName: data['displayName'] as String,
          );
        } else {
          // Fallback to cached values if no stats
          price =
              (data['price'] as num?)?.toDouble() ??
              (data['credits'] as num?)?.toDouble() ??
              5.0;
          seasonProjectedPoints =
              (data['seasonProjectedPointsPerMatch'] as num?)?.toDouble() ??
              (data['projectedPoints'] as num?)?.toDouble() ??
              5.0;
        }

        final projectedPoints = _calculateNextMatchProjectedPoints(
          playerId: data['id'] as int,
          playerName: data['name'] as String,
          displayName: data['displayName'] as String,
          positionCode: positionCode,
          seasonProjectedPoints: seasonProjectedPoints,
          seasonStats: stats,
          teamId: data['teamId'] as int,
        );

        players.add(
          RosterPlayer(
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
            seasonProjectedPointsPerMatch: seasonProjectedPoints,
            selectedByPercent:
                (data['selectedByPercent'] as num?)?.toDouble() ?? 0,
            stats: stats,
          ),
        );
      } catch (e) {
        debugPrint('Error parsing cached player: $e');
      }
    }

    // Filter out any "Unknown Team" players that might be in old cache
    final validPlayers = players
        .where((p) => p.teamName != 'Unknown Team')
        .toList();
    debugPrint(
      'Loaded ${validPlayers.length} valid players from Hive cache (filtered from ${players.length})',
    );
    return validPlayers;
  }

  RosterPlayer _recalculateRosterPlayer(RosterPlayer player) {
    final stats = player.stats;
    if (stats == null || stats.isEmpty) return player;

    final seasonProjectedPoints = _calculateProjectedPointsFromStats(
      stats,
      player.positionCode,
    );
    final projectedPoints = _calculateNextMatchProjectedPoints(
      playerId: player.id,
      playerName: player.name,
      displayName: player.displayName,
      positionCode: player.positionCode,
      seasonProjectedPoints: seasonProjectedPoints,
      seasonStats: stats,
      teamId: player.teamId,
    );
    final price = _calculatePrice(
      stats,
      player.positionCode,
      seasonProjectedPoints,
      playerName: player.name,
      displayName: player.displayName,
    );

    return RosterPlayer(
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
      seasonProjectedPointsPerMatch: seasonProjectedPoints,
      selectedByPercent: player.selectedByPercent,
      stats: stats,
    );
  }

  /// Add players to Hive cache (filters out "Unknown Team" players)
  Future<void> _addToCache(List<RosterPlayer> players) async {
    if (players.isEmpty) return;

    // Filter out players with "Unknown Team" before caching
    final validPlayers = players
        .where((p) => p.teamName != 'Unknown Team')
        .toList();
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

    // Prefer the configured competition teams from SportMonks so we only use
    // actual World Cup participants and avoid stale cloned-league data.
    if (SportMonksConfig.isConfigured) {
      try {
        final apiTeams = await _loadCompetitionTeamsFromApi();
        if (apiTeams.isNotEmpty) {
          _teamsMemoryCache = apiTeams;
          await _cacheService.saveLigaMxTeams(
            apiTeams
                .map((t) => {'id': t.id, 'name': t.name, 'logo': t.logo})
                .toList(),
          );
          debugPrint(
            'Loaded ${apiTeams.length} ${SportMonksConfig.competitionName} teams from SportMonks',
          );
          return apiTeams;
        }
      } catch (e) {
        debugPrint(
          'Competition teams fetch failed, falling back to Firestore: $e',
        );
      }
    }

    // Check Hive cache only after the live competition source.
    final cachedTeams = _cacheService.getLigaMxTeams();
    if (cachedTeams != null && cachedTeams.isNotEmpty) {
      _teamsMemoryCache = cachedTeams
          .map(
            (t) => LigaMxTeam(
              id: t['id'] as int,
              name: t['name'] as String,
              logo: t['logo'] as String?,
            ),
          )
          .toList();
      debugPrint('Loaded ${_teamsMemoryCache!.length} teams from Hive cache');
      return _teamsMemoryCache!;
    }

    // Try Firestore next
    try {
      final firestoreTeams = await _loadTeamsFromFirestore();
      if (firestoreTeams.isNotEmpty) {
        _teamsMemoryCache = firestoreTeams;
        // Save to Hive cache
        await _cacheService.saveLigaMxTeams(
          firestoreTeams
              .map((t) => {'id': t.id, 'name': t.name, 'logo': t.logo})
              .toList(),
        );
        debugPrint('Loaded ${firestoreTeams.length} teams from Firestore');
        return firestoreTeams;
      }
    } catch (e) {
      debugPrint('Firestore teams fetch failed, falling back to API: $e');
    }

    // Fall back to CSV + SportMonks API
    if (!SportMonksConfig.isConfigured) {
      throw Exception(
        'No data source available - Firestore empty and SportMonks not configured',
      );
    }

    final response = await _client.getTeamsBySeason(
      SportMonksConfig.fallbackSeasonId,
    );
    final teams = response.data
        .map(
          (team) => LigaMxTeam(
            id: _parseIntValue(team['id']) ?? 0,
            name: team['name']?.toString() ?? 'Unknown',
            logo:
                team['image_path']?.toString() ?? team['logo_path']?.toString(),
          ),
        )
        .where((team) => team.id > 0)
        .toList();

    // Save to in-memory cache
    _teamsMemoryCache = teams;

    // Save to Hive cache
    await _cacheService.saveLigaMxTeams(
      teams.map((t) => {'id': t.id, 'name': t.name, 'logo': t.logo}).toList(),
    );
    debugPrint(
      'Loaded ${teams.length} ${SportMonksConfig.competitionName} teams from API',
    );
    return teams;
  }

  /// Load teams from Firestore (SportMonks format)
  Future<List<LigaMxTeam>> _loadTeamsFromFirestore() async {
    final teamsData = await _firestoreService.getTeams();

    return teamsData
        .map(
          (t) => LigaMxTeam(
            id: _parseIntValue(t['id']) ?? 0,
            name:
                t['name']?.toString() ??
                t['short_code']?.toString() ??
                'Unknown',
            logo: t['image_path']?.toString() ?? t['logo']?.toString(),
          ),
        )
        .where((t) => t.id > 0)
        .toList();
  }

  Future<List<LigaMxTeam>> _loadCompetitionTeamsFromApi() async {
    final teams = <LigaMxTeam>[];
    final seenIds = <int>{};
    final standingsResponse = await _client.getStandingsBySeason(
      SportMonksConfig.fallbackSeasonId,
      includes: ['participant'],
    );

    for (final standing in standingsResponse.data) {
      final participant = standing['participant'];
      if (participant is! Map<String, dynamic>) continue;
      if (!_isConfiguredCompetitionTeam(participant)) continue;

      final teamId = _parseIntValue(participant['id']);
      if (teamId == null || teamId <= 0 || !seenIds.add(teamId)) continue;

      teams.add(
        LigaMxTeam(
          id: teamId,
          name:
              participant['name']?.toString() ??
              participant['short_code']?.toString() ??
              'Team $teamId',
          logo:
              participant['image_path']?.toString() ??
              participant['logo_path']?.toString(),
        ),
      );
    }

    if (teams.isNotEmpty) {
      return teams;
    }

    // Fallback to the season teams endpoint if standings are unavailable.
    final response = await _client.getTeamsBySeason(
      SportMonksConfig.fallbackSeasonId,
      page: 1,
      perPage: 100,
    );

    for (final team in response.data) {
      if (!_isConfiguredCompetitionTeam(team)) continue;

      final teamId = _parseIntValue(team['id']);
      if (teamId == null || teamId <= 0 || !seenIds.add(teamId)) continue;

      teams.add(
        LigaMxTeam(
          id: teamId,
          name:
              team['name']?.toString() ??
              team['short_code']?.toString() ??
              'Team $teamId',
          logo: team['image_path']?.toString() ?? team['logo_path']?.toString(),
        ),
      );
    }

    return teams;
  }

  /// Load all players from Firestore and cache them
  /// This is the preferred method as it loads all data in one call
  /// Pass forceRefresh=true to bypass cache and reload from Firestore
  Future<List<RosterPlayer>> loadAllPlayersFromFirestore({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _loadAllPlayersFuture != null) {
      debugPrint('Reusing in-flight roster load');
      return _loadAllPlayersFuture!;
    }

    final future = _loadAllPlayersFromFirestoreInternal(
      forceRefresh: forceRefresh,
    );
    _loadAllPlayersFuture = future;

    try {
      return await future;
    } finally {
      if (identical(_loadAllPlayersFuture, future)) {
        _loadAllPlayersFuture = null;
      }
    }
  }

  Future<List<RosterPlayer>> _loadAllPlayersFromFirestoreInternal({
    required bool forceRefresh,
  }) async {
    debugPrint(
      'Loading all players from Firestore (forceRefresh: $forceRefresh)...',
    );

    await WorldCupMarketValues.ensureLoaded();

    // Load competition teams first so both cached and Firestore players can be
    // validated against the World Cup team pool.
    await getLigaMxTeams();

    // Check Hive cache first (only if not forcing refresh and cache has substantial data)
    if (!forceRefresh) {
      final cachedPlayers = _filterPlayersToCompetitionTeams(
        getCachedPlayers(),
      );
      // Only use cache if it has a substantial number of players (Liga MX has ~500+ players)
      if (cachedPlayers.length >= 300) {
        // Check if cached players have stats - if not, they need enrichment
        final playersNeedStats = cachedPlayers
            .where(
              (p) =>
                  p.stats == null ||
                  p.stats!.isEmpty ||
                  (p.stats!['goals'] == null &&
                      p.stats!['appearances'] == null),
            )
            .length;

        if (playersNeedStats > cachedPlayers.length * 0.5) {
          // More than 50% of players need stats - enrich them
          debugPrint(
            'Found ${cachedPlayers.length} cached players but $playersNeedStats need stats - enriching...',
          );
          final enrichedPlayers = await _enrichPlayersWithStats(cachedPlayers);
          // Save enriched players back to cache
          if (enrichedPlayers.isNotEmpty) {
            await _cacheService.clearLigaMxRoster();
            _addToCache(enrichedPlayers);
          }
          return enrichedPlayers;
        }

        debugPrint(
          'Found ${cachedPlayers.length} players in Hive cache (sufficient with stats)',
        );
        return cachedPlayers;
      }
      debugPrint(
        'Cache has ${cachedPlayers.length} players (insufficient, need 300+)',
      );
    }

    if (SportMonksConfig.isConfigured) {
      try {
        final competitionPlayers = await _loadAllPlayersFromCompetitionSquads();
        if (competitionPlayers.isNotEmpty) {
          final enrichedPlayers = await _enrichPlayersWithStats(
            competitionPlayers,
          );
          if (enrichedPlayers.isNotEmpty) {
            await _cacheService.clearLigaMxRoster();
            _addToCache(enrichedPlayers);
          }
          debugPrint(
            'Loaded ${enrichedPlayers.length} players from ${SportMonksConfig.competitionName} squads',
          );
          return enrichedPlayers;
        }
      } catch (e) {
        debugPrint(
          'Competition squad load failed, falling back to Firestore player documents: $e',
        );
      }
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
          debugPrint(
            'Has statistics: ${(firstDoc['statistics'] as List?)?.length ?? 0} entries',
          );
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
            debugPrint(
              'Parse error #$parseErrors - doc keys: ${data.keys.toList()}',
            );
          }
        }
      }

      debugPrint(
        'Parsed ${players.length} valid players from Firestore ($parseErrors parse errors)',
      );

      // Now enrich players with stats from SportMonks (for pricing)
      // This uses cached stats if available, otherwise fetches from API
      final enrichedPlayers = await _enrichPlayersWithStats(players);

      // Save to Hive cache (replace existing)
      if (enrichedPlayers.isNotEmpty) {
        await _cacheService.clearLigaMxRoster(); // Clear old cache
        _addToCache(enrichedPlayers);
      }

      debugPrint(
        'Loaded ${enrichedPlayers.length} players from Firestore (enriched with stats)',
      );
      return enrichedPlayers;
    } catch (e) {
      debugPrint('Error loading players from Firestore: $e');
      return [];
    }
  }

  Future<List<RosterPlayer>> _loadAllPlayersFromCompetitionSquads() async {
    final teams = await getLigaMxTeams();
    if (teams.isEmpty) {
      return [];
    }

    final players = <RosterPlayer>[];
    final seenPlayerIds = <int>{};
    var totalEntries = 0;

    for (final team in teams) {
      final response = await _client.getTeamSquad(
        team.id,
        includes: [
          'player.position',
          'player.detailedposition',
          'player.nationality',
          'player.statistics.details',
          'player.statistics.season',
        ],
      );

      for (final squadEntry in response.data) {
        totalEntries++;
        final playerData = squadEntry['player'] as Map<String, dynamic>?;
        if (playerData == null) continue;

        final playerId = _parseIntValue(playerData['id']);
        if (playerId == null || playerId <= 0 || !seenPlayerIds.add(playerId)) {
          continue;
        }

        final teamInfo = _TeamPlayerInfo(
          teamId: team.id,
          teamName: team.name,
          teamLogo: team.logo,
          jerseyNumber: _parseIntValue(squadEntry['jersey_number']),
        );

        final rosterPlayer = _parsePlayerToRosterPlayer(playerData, teamInfo);
        if (rosterPlayer != null) {
          players.add(rosterPlayer);
          _playerDetailsCache[rosterPlayer.id] = rosterPlayer;
        }
      }
    }

    debugPrint(
      'Built ${players.length} unique players from $totalEntries ${SportMonksConfig.competitionName} squad entries',
    );
    return players;
  }

  /// Enrich players with season stats from SportMonks
  /// Uses cached stats if available, fetches from API otherwise
  Future<List<RosterPlayer>> _enrichPlayersWithStats(
    List<RosterPlayer> players,
  ) async {
    debugPrint('=== ENRICHING ${players.length} PLAYERS WITH STATS ===');

    // First check if we have cached stats
    var cachedStats = _cacheService.getAllPlayerSeasonStats();
    final needsRefresh = cachedStats == null || cachedStats.isEmpty;
    cachedStats ??= <int, Map<String, dynamic>>{};

    debugPrint(
      'Cached stats available for ${cachedStats.length} players, needsRefresh: $needsRefresh',
    );

    // Identify players that need stats fetched
    final playersNeedingStats = players
        .where(
          (p) =>
              !cachedStats!.containsKey(p.id) ||
              cachedStats[p.id] == null ||
              cachedStats[p.id]!.isEmpty ||
              (cachedStats[p.id]!['goals'] == null &&
                  cachedStats[p.id]!['appearances'] == null),
        )
        .toList();

    debugPrint('${playersNeedingStats.length} players need stats fetched');

    if (playersNeedingStats.isNotEmpty) {
      debugPrint(
        'Fetching stats for ${playersNeedingStats.length} players from SportMonks...',
      );

      // Fetch stats in batches to avoid overwhelming the API
      const batchSize = 10;
      int fetchedCount = 0;
      int emptyCount = 0;

      for (
        var i = 0;
        i < playersNeedingStats.length && i < 200;
        i += batchSize
      ) {
        final batch = playersNeedingStats.skip(i).take(batchSize);

        await Future.wait(
          batch.map((player) async {
            try {
              final stats = await _fetchPlayerStatsFromSportMonks(player.id);
              if (stats != null && stats.isNotEmpty) {
                cachedStats![player.id] = stats;
                fetchedCount++;
                // Log first few successful fetches
                if (fetchedCount <= 3) {
                  debugPrint(
                    'Player ${player.id} (${player.displayName}) stats: goals=${stats['goals']}, assists=${stats['assists']}, appearances=${stats['appearances']}',
                  );
                }
              } else {
                emptyCount++;
              }
            } catch (e) {
              debugPrint('Error fetching stats for player ${player.id}: $e');
            }
          }),
        );

        // Log progress every 50 players
        if ((i + batchSize) % 50 == 0) {
          debugPrint(
            'Progress: ${i + batchSize}/${playersNeedingStats.length} players processed',
          );
        }

        // Small delay between batches to avoid rate limiting
        if (i + batchSize < playersNeedingStats.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      debugPrint(
        'Fetched stats for $fetchedCount players ($emptyCount had no stats)',
      );

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
        final seasonProjectedPoints = _calculateProjectedPointsFromStats(
          stats,
          player.positionCode,
        );
        final price = _calculatePrice(
          stats,
          player.positionCode,
          seasonProjectedPoints,
          playerName: player.name,
          displayName: player.displayName,
        );
        final projectedPoints = _calculateNextMatchProjectedPoints(
          playerId: player.id,
          playerName: player.name,
          displayName: player.displayName,
          positionCode: player.positionCode,
          seasonProjectedPoints: seasonProjectedPoints,
          seasonStats: stats,
          teamId: player.teamId,
        );
        enrichedPlayers.add(
          RosterPlayer(
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
            seasonProjectedPointsPerMatch: seasonProjectedPoints,
            selectedByPercent: player.selectedByPercent,
            stats: stats,
          ),
        );
        enrichedCount++;
      } else {
        // Keep original player if no stats available
        enrichedPlayers.add(player);
      }
    }

    // Log price distribution for debugging
    final forwards = enrichedPlayers
        .where((p) => p.positionCode == 'FWD')
        .toList();
    final forwardPrices = forwards.map((p) => p.price).toList()..sort();
    if (forwardPrices.isNotEmpty) {
      debugPrint(
        'FWD price range: \$${forwardPrices.first}M - \$${forwardPrices.last}M (${forwards.length} players)',
      );
    }

    final midfielders = enrichedPlayers
        .where((p) => p.positionCode == 'MID')
        .toList();
    final midPrices = midfielders.map((p) => p.price).toList()..sort();
    if (midPrices.isNotEmpty) {
      debugPrint(
        'MID price range: \$${midPrices.first}M - \$${midPrices.last}M (${midfielders.length} players)',
      );
    }

    debugPrint(
      '=== ENRICHMENT COMPLETE: $enrichedCount/${players.length} players have stats ===',
    );

    return enrichedPlayers;
  }

  /// Fetch player season stats from SportMonks API
  Future<Map<String, dynamic>?> _fetchPlayerStatsFromSportMonks(
    int playerId,
  ) async {
    try {
      final response = await _client.getPlayerById(
        playerId,
        includes: ['statistics.details', 'statistics.season'],
      );

      final playerData = response.data;
      final statistics = playerData['statistics'] as List?;

      if (statistics == null || statistics.isEmpty) {
        debugPrint('Player $playerId: No statistics array in response');
        return null;
      }

      final selectedStat = _selectPreferredStatisticsEntry(statistics);
      final selectedSeasonId = _parseIntValue(selectedStat?['season_id']) ?? 0;
      Map<String, dynamic>? bestStats;
      final internationalStat = _selectBestInternationalStatisticsEntry(
        statistics,
      );
      final clubStat = _selectBestClubStatisticsEntry(statistics);

      if (selectedStat != null) {
        final details = selectedStat['details'] as List?;
        if (details != null && details.isNotEmpty) {
          bestStats = _extractStatsFromDetails(details);
        }
      }

      if (bestStats == null || bestStats.isEmpty) {
        // Try to extract stats directly from the statistics array (some API versions)
        for (final stat in statistics) {
          if (stat is! Map<String, dynamic>) continue;
          final seasonId = _parseIntValue(stat['season_id']) ?? 0;
          if (seasonId == selectedSeasonId || selectedSeasonId == 0) {
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
                'seasonId': seasonId,
                'seasonName': stat['season']?['name']?.toString(),
              };
              break;
            }
          }
        }
      }

      if (bestStats != null && bestStats.isNotEmpty && selectedStat != null) {
        bestStats['seasonId'] = _parseIntValue(selectedStat['season_id']);
        bestStats['seasonName'] = selectedStat['season']?['name']?.toString();
      }

      final internationalStats = _extractStatsFromStatisticsEntry(
        internationalStat,
      );
      final clubStats = _extractStatsFromStatisticsEntry(clubStat);
      if (bestStats != null && bestStats.isNotEmpty) {
        if (internationalStats != null && internationalStats.isNotEmpty) {
          bestStats['projectionInternational'] = internationalStats;
        }
        if (clubStats != null && clubStats.isNotEmpty) {
          bestStats['projectionClub'] = clubStats;
        }
      }

      if (bestStats == null || bestStats.isEmpty) {
        bestStats = await _fetchPlayerStatsFromDetailedEndpoint(playerId);
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
        case 52:
          stats['goals'] = value;
          break; // Goals
        case 79:
          stats['assists'] = value;
          break; // Assists
        case 119:
          stats['minutes'] = value;
          break; // Minutes
        case 194:
        case 59:
          stats['cleanSheets'] = value;
          break; // Clean sheets
        case 209:
        case 101:
          stats['saves'] = value;
          break; // Saves
        case 321:
        case 42:
          stats['appearances'] = value;
          break; // Appearances
        case 322:
          stats['lineups'] = value;
          break; // Lineups
        case 84:
          stats['yellowCards'] = value;
          break; // Yellow cards
        case 83:
        case 85:
          stats['redCards'] = value;
          break; // Red cards
      }
    }

    return stats;
  }

  Map<String, dynamic>? _selectPreferredStatisticsEntry(List statistics) {
    Map<String, dynamic>? preferred;
    int preferredScore = -1;
    int preferredSeasonId = -1;

    for (final stat in statistics) {
      if (stat is! Map<String, dynamic>) continue;

      final seasonId = _parseIntValue(stat['season_id']) ?? 0;
      final score = _statisticsPriorityScore(stat);
      if (score < 0) continue;

      if (score > preferredScore ||
          (score == preferredScore && seasonId > preferredSeasonId)) {
        preferred = stat;
        preferredScore = score;
        preferredSeasonId = seasonId;
      }
    }

    return preferred;
  }

  Map<String, dynamic>? _selectBestInternationalStatisticsEntry(
    List statistics,
  ) {
    return _selectStatisticsEntryByFilter(
      statistics,
      allowInternational: true,
      allowClub: false,
    );
  }

  Map<String, dynamic>? _selectBestClubStatisticsEntry(List statistics) {
    return _selectStatisticsEntryByFilter(
      statistics,
      allowInternational: false,
      allowClub: true,
    );
  }

  Map<String, dynamic>? _selectStatisticsEntryByFilter(
    List statistics, {
    required bool allowInternational,
    required bool allowClub,
  }) {
    Map<String, dynamic>? preferred;
    int preferredScore = -1;
    int preferredSeasonId = -1;

    for (final stat in statistics) {
      if (stat is! Map<String, dynamic>) continue;
      final seasonId = _parseIntValue(stat['season_id']) ?? 0;
      final season = stat['season'] as Map<String, dynamic>?;
      final leagueId = _parseIntValue(season?['league_id']);
      final isInternational = SportMonksConfig.preferredInternationalSeasonIds
          .contains(seasonId);
      final isClub =
          leagueId != null &&
          SportMonksConfig.preferredClubLeagueIds.contains(leagueId);

      if ((isInternational && !allowInternational) ||
          (isClub && !allowClub) ||
          (!isInternational && !isClub)) {
        continue;
      }

      final score = _statisticsPriorityScore(stat);
      if (score < 0) continue;

      if (score > preferredScore ||
          (score == preferredScore && seasonId > preferredSeasonId)) {
        preferred = stat;
        preferredScore = score;
        preferredSeasonId = seasonId;
      }
    }

    return preferred;
  }

  int _statisticsPriorityScore(Map<String, dynamic> stat) {
    final seasonId = _parseIntValue(stat['season_id']) ?? 0;
    final preferredIndex = SportMonksConfig.preferredInternationalSeasonIds
        .indexOf(seasonId);
    final season = stat['season'] as Map<String, dynamic>?;
    final leagueId = _parseIntValue(season?['league_id']);
    final preferredClubIndex = leagueId == null
        ? -1
        : SportMonksConfig.preferredClubLeagueIds.indexOf(leagueId);
    final details = stat['details'] as List?;
    final hasDetails = details != null && details.isNotEmpty;
    final hasValues = stat['has_values'] == true;
    final hasDirectStats =
        stat['goals'] != null ||
        stat['total_goals'] != null ||
        stat['assists'] != null ||
        stat['total_assists'] != null ||
        stat['minutes'] != null ||
        stat['total_minutes'] != null;

    if (!hasDetails && !hasValues && !hasDirectStats) {
      return -1;
    }

    if (preferredIndex >= 0) {
      return 1000 - preferredIndex;
    }

    if (preferredClubIndex >= 0) {
      return 500 - preferredClubIndex;
    }

    return seasonId;
  }

  Map<String, dynamic>? _extractStatsFromStatisticsEntry(
    Map<String, dynamic>? stat,
  ) {
    if (stat == null) return null;

    Map<String, dynamic>? extracted;
    final details = stat['details'] as List?;
    if (details != null && details.isNotEmpty) {
      extracted = _extractStatsFromDetails(details);
    }

    if (extracted == null || extracted.isEmpty) {
      final goals = stat['goals'] ?? stat['total_goals'];
      final assists = stat['assists'] ?? stat['total_assists'];
      final appearances = stat['appearances'] ?? stat['total_appearances'];
      final minutes = stat['minutes'] ?? stat['total_minutes'];

      if (goals != null || assists != null || appearances != null || minutes != null) {
        extracted = {
          'goals': goals,
          'assists': assists,
          'appearances': appearances,
          'minutes': minutes,
          'rating': stat['rating'] ?? stat['average_rating'],
        };
      }
    }

    if (extracted == null || extracted.isEmpty) {
      return null;
    }

    extracted['seasonId'] = _parseIntValue(stat['season_id']);
    extracted['seasonName'] = stat['season']?['name']?.toString();
    return extracted;
  }

  Future<Map<String, dynamic>?> _fetchPlayerStatsFromDetailedEndpoint(
    int playerId,
  ) async {
    try {
      final response = await _client.getPlayerById(
        playerId,
        includes: [
          'statistics',
          'statistics.details.type',
          'statistics.season',
          'lineups.details.type',
        ],
      );

      final playerData = response.data;
      final statistics = playerData['statistics'] as List?;
      if (statistics != null && statistics.isNotEmpty) {
        final selectedStat = _selectPreferredStatisticsEntry(statistics);
        if (selectedStat != null) {
          final details = selectedStat['details'] as List?;
          if (details != null && details.isNotEmpty) {
            final stats = _extractStatsFromTypedDetails(details);
            if (stats.isNotEmpty) {
              stats['seasonId'] = _parseIntValue(selectedStat['season_id']);
              stats['seasonName'] = selectedStat['season']?['name']?.toString();
              return stats;
            }
          }
        }
      }

      final lineups = playerData['lineups'] as List?;
      if (lineups == null || lineups.isEmpty) return null;

      final aggregated = _aggregateStatsFromLineups(lineups);
      return aggregated.isEmpty ? null : aggregated;
    } catch (e) {
      debugPrint(
        'Detailed SportMonks stats fetch error for player $playerId: $e',
      );
      return null;
    }
  }

  Map<String, dynamic> _extractStatsFromTypedDetails(List details) {
    final stats = <String, dynamic>{};

    for (final detail in details) {
      if (detail is! Map<String, dynamic>) continue;

      final type = detail['type'] as Map<String, dynamic>?;
      final developerName = type?['developer_name']?.toString().toUpperCase();
      final value = detail['value'];

      switch (developerName) {
        case 'GOALS':
          stats['goals'] = value;
          break;
        case 'ASSISTS':
          stats['assists'] = value;
          break;
        case 'MINUTES_PLAYED':
          stats['minutes'] = value;
          break;
        case 'CLEANSHEET':
          stats['cleanSheets'] = value;
          break;
        case 'SAVES':
          stats['saves'] = value;
          break;
        case 'APPEARANCES':
          stats['appearances'] = value;
          break;
        case 'LINEUPS':
          stats['lineups'] = value;
          break;
        case 'YELLOWCARDS':
          stats['yellowCards'] = value;
          break;
        case 'REDCARDS':
          stats['redCards'] = value;
          break;
        case 'RATING':
          stats['rating'] = value is Map<String, dynamic>
              ? value['average']
              : value;
          break;
      }
    }

    return stats;
  }

  Map<String, dynamic> _aggregateStatsFromLineups(List lineups) {
    final stats = <String, dynamic>{};
    var appearances = 0;
    var minutes = 0.0;
    var goals = 0.0;
    var assists = 0.0;
    var yellowCards = 0.0;
    var redCards = 0.0;
    var saves = 0.0;
    var cleanSheets = 0.0;
    var ratingTotal = 0.0;
    var ratingCount = 0;

    for (final lineup in lineups) {
      if (lineup is! Map<String, dynamic>) continue;
      final details = lineup['details'] as List?;
      if (details == null || details.isEmpty) continue;

      appearances++;

      for (final detail in details) {
        if (detail is! Map<String, dynamic>) continue;
        final type = detail['type'] as Map<String, dynamic>?;
        final developerName = type?['developer_name']?.toString().toUpperCase();
        final data = detail['data'] as Map<String, dynamic>?;
        final value = data?['value'];
        final numericValue = _parseDoubleValue(value) ?? 0.0;

        switch (developerName) {
          case 'GOALS':
            goals += numericValue;
            break;
          case 'ASSISTS':
            assists += numericValue;
            break;
          case 'MINUTES_PLAYED':
            minutes += numericValue;
            break;
          case 'YELLOWCARDS':
            yellowCards += numericValue;
            break;
          case 'REDCARDS':
            redCards += numericValue;
            break;
          case 'SAVES':
            saves += numericValue;
            break;
          case 'CLEANSHEET':
          case 'CLEANSHEETS':
            cleanSheets += numericValue;
            break;
          case 'RATING':
            if (numericValue > 0) {
              ratingTotal += numericValue;
              ratingCount++;
            }
            break;
        }
      }
    }

    if (appearances == 0) return stats;

    stats['appearances'] = {'total': appearances};
    stats['lineups'] = {'total': appearances};
    stats['minutes'] = {'total': minutes.round()};
    if (goals > 0) stats['goals'] = {'total': goals.round()};
    if (assists > 0) stats['assists'] = {'total': assists.round()};
    if (yellowCards > 0) stats['yellowCards'] = {'total': yellowCards.round()};
    if (redCards > 0) stats['redCards'] = {'total': redCards.round()};
    if (saves > 0) stats['saves'] = {'total': saves.round()};
    if (cleanSheets > 0) {
      stats['cleanSheets'] = {'total': cleanSheets.round()};
    }
    if (ratingCount > 0) {
      stats['rating'] = double.parse(
        (ratingTotal / ratingCount).toStringAsFixed(2),
      );
    }
    stats['seasonName'] = 'Recent club form';

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

      final id =
          _parseIntValue(playerData['id']) ??
          _parseIntValue(playerData['player_id']);
      if (id == null || id <= 0) {
        debugPrint('Parse error: No valid ID in player document');
        return null;
      }

      // SportMonks uses display_name, common_name, name
      final name =
          playerData['name']?.toString() ??
          playerData['common_name']?.toString() ??
          'Unknown';
      final displayName =
          playerData['display_name']?.toString() ??
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
              'MID',
        );
        position =
            positionData['name']?.toString() ?? _getPositionName(positionCode);
      }

      // Parse team info from statistics array (most recent season)
      int? statsTeamId;
      int? jerseyNumber;
      Map<String, dynamic> stats = {};

      // Statistics array contains team_id for each season
      final statistics = playerData['statistics'] as List?;
      if (statistics != null && statistics.isNotEmpty) {
        final latestStat = _selectPreferredStatisticsEntry(statistics);

        if (latestStat != null) {
          statsTeamId = _parseIntValue(latestStat['team_id']);
          jerseyNumber = _parseIntValue(latestStat['jersey_number']);

          // Parse detailed stats if available
          final details = latestStat['details'] as List?;
          if (details != null) {
            for (final detail in details) {
              if (detail is! Map<String, dynamic>) continue;
              final typeId = _parseIntValue(detail['type_id']);
              final value = detail['value'];

              switch (typeId) {
                case 52:
                  stats['goals'] = value;
                  break;
                case 79:
                  stats['assists'] = value;
                  break;
                case 119:
                  stats['minutes'] = value;
                  break;
                case 194:
                  stats['cleanSheets'] = value;
                  break;
                case 209:
                  stats['saves'] = value;
                  break;
                case 321:
                  stats['appearances'] = value;
                  break;
                case 322:
                  stats['lineups'] = value;
                  break;
                case 84:
                  stats['yellowCards'] = value;
                  break;
                case 83:
                case 85:
                  stats['redCards'] = value;
                  break;
              }
            }
          }
          final seasonRating = _parseDoubleValue(latestStat['rating']);
          if (seasonRating != null) {
            stats['rating'] = seasonRating;
          }
          stats['seasonId'] = _parseIntValue(latestStat['season_id']);
          stats['seasonName'] = latestStat['season']?['name']?.toString();
        }
      }

      final competitionTeam = _resolveCompetitionTeam(playerData, statsTeamId);
      if (competitionTeam == null) {
        debugPrint(
          'Parse skip: Player $id ($displayName) is not assigned to a configured competition team',
        );
        return null;
      }
      final teamId = competitionTeam.id;
      final teamName = competitionTeam.name;
      final teamLogo = competitionTeam.logo;

      final seasonProjectedPoints = _calculateProjectedPointsFromStats(
        stats,
        positionCode,
      );
      final price = _calculatePrice(
        stats.isNotEmpty ? stats : null,
        positionCode,
        seasonProjectedPoints,
        playerName: name,
        displayName: displayName,
      );
      final projectedPoints = _calculateNextMatchProjectedPoints(
        playerId: id,
        playerName: name,
        displayName: displayName,
        positionCode: positionCode,
        seasonProjectedPoints: seasonProjectedPoints,
        seasonStats: stats.isNotEmpty ? stats : null,
        teamId: teamId,
      );

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
        jerseyNumber:
            jerseyNumber ?? _parseIntValue(playerData['jersey_number']),
        price: price,
        projectedPoints: projectedPoints,
        seasonProjectedPointsPerMatch: seasonProjectedPoints,
        selectedByPercent: 0,
        stats: stats.isNotEmpty ? stats : null,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Firestore player: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  List<RosterPlayer> _filterPlayersToCompetitionTeams(
    List<RosterPlayer> players,
  ) {
    final competitionTeamIds = _getConfiguredCompetitionTeamIds();
    if (competitionTeamIds.isEmpty) {
      return players;
    }

    final filtered = players
        .where((player) => competitionTeamIds.contains(player.teamId))
        .toList();
    if (filtered.length != players.length) {
      debugPrint(
        'Filtered roster to ${filtered.length} configured competition players (removed ${players.length - filtered.length})',
      );
    }
    return filtered;
  }

  Set<int> _getConfiguredCompetitionTeamIds() {
    final cachedTeams = _cacheService.getLigaMxTeams();
    if (cachedTeams == null || cachedTeams.isEmpty) {
      return const <int>{};
    }

    return cachedTeams
        .map((team) => _parseIntValue(team['id']))
        .whereType<int>()
        .where((id) => id > 0)
        .toSet();
  }

  LigaMxTeam? _resolveCompetitionTeam(
    Map<String, dynamic> playerData,
    int? statsTeamId,
  ) {
    final cachedTeams = _cacheService.getLigaMxTeams();
    if (cachedTeams == null || cachedTeams.isEmpty) {
      return null;
    }

    final competitionTeamsById = <int, LigaMxTeam>{};
    for (final team in cachedTeams) {
      final id = _parseIntValue(team['id']);
      if (id == null || id <= 0) continue;
      competitionTeamsById[id] = LigaMxTeam(
        id: id,
        name: team['name']?.toString() ?? 'Team $id',
        logo: team['logo']?.toString(),
      );
    }

    final candidateIds = <int>[
      ..._extractTeamCandidates(playerData),
      if (statsTeamId != null && statsTeamId > 0) statsTeamId,
    ];

    for (final candidateId in candidateIds) {
      final team = competitionTeamsById[candidateId];
      if (team != null) {
        return team;
      }
    }

    return null;
  }

  bool _isConfiguredCompetitionTeam(Map<String, dynamic> teamData) {
    final teamId = _parseIntValue(teamData['id']);
    if (teamId == null || teamId <= 0) {
      return false;
    }

    final name = teamData['name']?.toString().trim().toLowerCase() ?? '';
    if (name.isEmpty) {
      return false;
    }

    final type = teamData['type']?.toString().trim().toLowerCase() ?? '';
    if (type.isNotEmpty && type != 'national_team' && type != 'national') {
      return false;
    }

    final placeholderFlags = [
      teamData['placeholder'],
      teamData['is_placeholder'],
      teamData['isPlaceholder'],
    ];
    if (placeholderFlags.any((flag) => flag == true)) {
      return false;
    }

    final badNamePatterns = [
      'winner',
      'runner-up',
      'runners-up',
      'to be announced',
      'tbd',
      'unknown',
    ];
    if (badNamePatterns.any(name.contains)) {
      return false;
    }

    return true;
  }

  List<int> _extractTeamCandidates(Map<String, dynamic> playerData) {
    final candidates = <int>{};

    void addCandidate(dynamic value) {
      final id = _parseIntValue(value);
      if (id != null && id > 0) {
        candidates.add(id);
      }
    }

    addCandidate(playerData['teamId']);
    addCandidate(playerData['team_id']);

    final teamData = playerData['team'];
    if (teamData is Map<String, dynamic>) {
      addCandidate(teamData['id']);
      addCandidate(teamData['team_id']);
    }

    final teams = playerData['teams'];
    if (teams is List) {
      for (final entry in teams) {
        if (entry is! Map<String, dynamic>) continue;
        addCandidate(entry['team_id']);
        final nestedTeam = entry['team'];
        if (nestedTeam is Map<String, dynamic>) {
          addCandidate(nestedTeam['id']);
          addCandidate(nestedTeam['team_id']);
        }
      }
    }

    return candidates.toList();
  }

  /// Extract numeric value from stats field (handles nested objects like {total: 4, goals: 4})
  double _extractStatValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is Map) {
      // SportMonks nested format: {total: X, goals: X, penalties: X}
      return (value['total'] as num?)?.toDouble() ??
          (value['goals'] as num?)?.toDouble() ??
          (value['value'] as num?)?.toDouble() ??
          0;
    }
    return double.tryParse(value.toString()) ?? 0;
  }

  /// Calculate projected points from stats map
  double _calculateProjectedPointsFromStats(
    Map<String, dynamic> stats,
    String positionCode,
  ) {
    return _calculateProjectedPoints(stats, positionCode);
  }

  double _calculateNextMatchProjectedPoints({
    required int playerId,
    required String playerName,
    required String displayName,
    required String positionCode,
    required double seasonProjectedPoints,
    Map<String, dynamic>? seasonStats,
    int? teamId,
  }) {
    final recentForm = _getCachedRecentForm(playerId);
    final recentProjection =
        recentForm == null || recentForm.isLikelyInjuredOrBench
        ? null
        : _calculateProjectedPointsFromRecentForm(recentForm, positionCode);
    final internationalProjectionStats = _nestedProjectionStats(
      seasonStats,
      'projectionInternational',
    );
    final clubProjectionStats = _nestedProjectionStats(
      seasonStats,
      'projectionClub',
    );
    final internationalPredictorProjection =
        internationalProjectionStats == null
        ? null
        : _predictNextMatchPoints(
            playerId: playerId,
            playerName: playerName,
            displayName: displayName,
            positionCode: positionCode,
            seasonStats: _buildSeasonStatistics(
              playerId: playerId,
              teamId: teamId,
              stats: internationalProjectionStats,
            ),
            recentForm: recentForm,
          );
    final clubPredictorProjection = clubProjectionStats == null
        ? null
        : _predictNextMatchPoints(
            playerId: playerId,
            playerName: playerName,
            displayName: displayName,
            positionCode: positionCode,
            seasonStats: _buildSeasonStatistics(
              playerId: playerId,
              teamId: teamId,
              stats: clubProjectionStats,
            ),
            recentForm: recentForm,
          );
    final predictorProjection =
        internationalPredictorProjection != null && clubPredictorProjection != null
        ? (internationalPredictorProjection * 0.72) +
              (clubPredictorProjection * 0.28)
        : internationalPredictorProjection ??
              clubPredictorProjection ??
              _predictNextMatchPoints(
                playerId: playerId,
                playerName: playerName,
                displayName: displayName,
                positionCode: positionCode,
                seasonStats: _buildSeasonStatistics(
                  playerId: playerId,
                  teamId: teamId,
                  stats: seasonStats,
                ),
                recentForm: recentForm,
              );
    final blendedSeasonBaseline = _blendedSeasonProjection(
      positionCode: positionCode,
      defaultProjection: seasonProjectedPoints,
      internationalStats: internationalProjectionStats,
      clubStats: clubProjectionStats,
    );

    if (predictorProjection != null) {
      final boostedPredictor = _expandProjectionRange(predictorProjection);
      final baseline = blendedSeasonBaseline;
      final blendedProjection = recentProjection != null
          ? (boostedPredictor * 0.45) +
                (recentProjection * 0.35) +
                (baseline * 0.20) +
                _recentFormMomentumBonus(recentForm, positionCode)
          : (boostedPredictor * 0.70) + (baseline * 0.30);
      return double.parse(
        blendedProjection.clamp(1.2, 10.0).toStringAsFixed(1),
      );
    }

    if (recentForm == null) {
      return double.parse(
        _expandProjectionRange(
          blendedSeasonBaseline,
        ).clamp(2.4, 10.0).toStringAsFixed(1),
      );
    }

    if (recentForm.isLikelyInjuredOrBench) {
      return _inactiveNextMatchProjection(positionCode);
    }

    final safeRecentProjection =
        recentProjection ?? _defaultNextMatchProjection(positionCode);
    final sampleWeight = (recentForm.matchesPlayed / 5.0).clamp(0.35, 1.0);
    final blendedProjection =
        (blendedSeasonBaseline * (1 - sampleWeight)) +
        (safeRecentProjection * sampleWeight);

    return double.parse(
      _expandProjectionRange(
        blendedProjection + _recentFormMomentumBonus(recentForm, positionCode),
      ).clamp(1.2, 10.0).toStringAsFixed(1),
    );
  }

  Map<String, dynamic>? _nestedProjectionStats(
    Map<String, dynamic>? stats,
    String key,
  ) {
    if (stats == null || stats.isEmpty) return null;
    final nested = stats[key];
    return nested is Map<String, dynamic> && nested.isNotEmpty ? nested : null;
  }

  double _blendedSeasonProjection({
    required String positionCode,
    required double defaultProjection,
    Map<String, dynamic>? internationalStats,
    Map<String, dynamic>? clubStats,
  }) {
    final internationalProjection = internationalStats == null
        ? null
        : _calculateProjectedPointsFromStats(internationalStats, positionCode);
    final clubProjection = clubStats == null
        ? null
        : _calculateProjectedPointsFromStats(clubStats, positionCode);

    if (internationalProjection != null && clubProjection != null) {
      return (internationalProjection * 0.72) + (clubProjection * 0.28);
    }

    return internationalProjection ?? clubProjection ?? defaultProjection;
  }

  double _expandProjectionRange(double projection) {
    // Stretch the middle aggressively so top players can separate, while
    // still allowing low-activity players to fall into the 1-3 band.
    final expanded = 5.0 + ((projection - 5.0) * 2.25);
    return expanded.clamp(1.0, 10.0);
  }

  PlayerStatistics? _buildSeasonStatistics({
    required int playerId,
    required Map<String, dynamic>? stats,
    int? teamId,
  }) {
    if (stats == null || stats.isEmpty) return null;

    return PlayerStatistics(
      id: playerId,
      playerId: playerId,
      teamId: teamId,
      appearances: _parseIntValue(stats['appearances']),
      lineups: _parseIntValue(stats['lineups']),
      minutesPlayed:
          _parseIntValue(stats['minutes']) ??
          _parseIntValue(stats['minutesPlayed']),
      goals: _parseIntValue(stats['goals']),
      assists: _parseIntValue(stats['assists']),
      yellowCards: _parseIntValue(stats['yellowCards']),
      redCards: _parseIntValue(stats['redCards']),
      cleanSheets: _parseIntValue(stats['cleanSheets']),
      saves: _parseIntValue(stats['saves']),
      rating: _parseDoubleValue(stats['rating']),
      seasonName: stats['seasonName']?.toString() ?? 'Current Season',
    );
  }

  double? _predictNextMatchPoints({
    required int playerId,
    required String playerName,
    required String displayName,
    required String positionCode,
    required PlayerStatistics? seasonStats,
    required RecentMatchStats? recentForm,
  }) {
    if (seasonStats == null && recentForm == null) return null;

    final position = PositionInfo(
      id: 0,
      name: _positionNameFromCode(positionCode),
      code: _positionInfoCode(positionCode),
    );

    final syntheticPlayer = Player(
      id: playerId,
      name: playerName,
      displayName: displayName,
      commonName: displayName,
      position: position,
      detailedPosition: position,
      statistics: seasonStats != null ? [seasonStats] : const [],
    );

    final prediction = FantasyPointsPredictor.predict(
      syntheticPlayer,
      recentForm: recentForm,
    );
    return prediction.totalPoints;
  }

  RecentMatchStats? _getCachedRecentForm(int playerId) {
    final cachedForm = _cacheService.getPlayerFormStats(playerId);
    if (cachedForm == null) return null;

    return RecentMatchStats(
      matchesPlayed: cachedForm['matchesPlayed'] as int? ?? 0,
      goals: cachedForm['goals'] as int? ?? 0,
      assists: cachedForm['assists'] as int? ?? 0,
      minutesPlayed: cachedForm['minutesPlayed'] as int? ?? 0,
      cleanSheets: cachedForm['cleanSheets'] as int? ?? 0,
      yellowCards: cachedForm['yellowCards'] as int? ?? 0,
      redCards: cachedForm['redCards'] as int? ?? 0,
      saves: cachedForm['saves'] as int? ?? 0,
      averageRating: (cachedForm['averageRating'] as num?)?.toDouble(),
      fixturesAnalyzed: cachedForm['fixturesAnalyzed'] as int?,
    );
  }

  double _calculateProjectedPointsFromRecentForm(
    RecentMatchStats form,
    String positionCode,
  ) {
    if (form.matchesPlayed < 1) {
      return _defaultNextMatchProjection(positionCode);
    }

    final gamesPlayed = form.matchesPlayed.toDouble();
    final minutesFactor = (form.minutesPerMatch / 75.0).clamp(0.45, 1.1);
    final normalizedPos = _normalizePositionCode(positionCode);

    double points;
    if (normalizedPos == 'GK') {
      points =
          2.0 +
          (form.cleanSheets / gamesPlayed) * 4.0 +
          (form.saves / gamesPlayed) * 0.3 +
          (form.goals / gamesPlayed) * 6.0 +
          (form.assists / gamesPlayed) * 3.0;
    } else if (normalizedPos == 'DEF') {
      points =
          2.0 +
          (form.cleanSheets / gamesPlayed) * 4.0 +
          (form.goals / gamesPlayed) * 6.0 +
          (form.assists / gamesPlayed) * 3.0;
    } else if (normalizedPos == 'MID') {
      points =
          2.0 +
          (form.goals / gamesPlayed) * 5.0 +
          (form.assists / gamesPlayed) * 3.0 +
          (form.cleanSheets / gamesPlayed) * 1.0;
    } else {
      points =
          2.0 +
          (form.goals / gamesPlayed) * 4.0 +
          (form.assists / gamesPlayed) * 3.0;
    }

    points -= (form.yellowCards + (form.redCards * 3)) / gamesPlayed;

    final rating = form.averageRating ?? 0.0;
    if (rating >= 7.5) points += 0.5;
    if (rating >= 8.0) points += 0.5;

    points *= minutesFactor;

    return double.parse(points.clamp(1.4, 10.0).toStringAsFixed(1));
  }

  double _defaultNextMatchProjection(String positionCode) {
    switch (_normalizePositionCode(positionCode)) {
      case 'GK':
        return 3.1;
      case 'DEF':
        return 3.3;
      case 'MID':
        return 3.7;
      case 'FWD':
        return 3.9;
      default:
        return 3.5;
    }
  }

  double _inactiveNextMatchProjection(String positionCode) {
    switch (_normalizePositionCode(positionCode)) {
      case 'GK':
        return 1.4;
      case 'DEF':
        return 1.5;
      case 'MID':
        return 1.8;
      case 'FWD':
        return 2.0;
      default:
        return 1.7;
    }
  }

  double _recentFormMomentumBonus(RecentMatchStats? form, String positionCode) {
    if (form == null || form.matchesPlayed < 1 || form.isLikelyInjuredOrBench) {
      return 0.0;
    }

    final gamesPlayed = form.matchesPlayed.toDouble();
    final normalizedPos = _normalizePositionCode(positionCode);
    double bonus = 0.0;

    if (form.minutesPerMatch >= 70) bonus += 0.45;
    if (form.minutesPerMatch >= 82) bonus += 0.25;

    final rating = form.averageRating ?? 0.0;
    if (rating >= 7.1) bonus += 0.35;
    if (rating >= 7.7) bonus += 0.35;

    if (normalizedPos == 'GK') {
      bonus += (form.cleanSheets / gamesPlayed) * 0.9;
      bonus += ((form.saves / gamesPlayed) / 4.0).clamp(0.0, 1.0) * 0.5;
    } else if (normalizedPos == 'DEF') {
      bonus += (form.cleanSheets / gamesPlayed) * 0.8;
      bonus +=
          ((form.goals + form.assists) / gamesPlayed).clamp(0.0, 1.0) * 0.9;
    } else {
      bonus +=
          ((form.goals + form.assists) / gamesPlayed).clamp(0.0, 1.2) * 1.2;
    }

    return bonus.clamp(0.0, 2.0);
  }

  String _positionNameFromCode(String positionCode) {
    switch (_normalizePositionCode(positionCode)) {
      case 'GK':
        return 'Goalkeeper';
      case 'DEF':
        return 'Defender';
      case 'MID':
        return 'Midfielder';
      case 'FWD':
        return 'Forward';
      default:
        return 'Player';
    }
  }

  String _positionInfoCode(String positionCode) {
    switch (_normalizePositionCode(positionCode)) {
      case 'GK':
        return 'goalkeeper';
      case 'DEF':
        return 'defender';
      case 'MID':
        return 'midfielder';
      case 'FWD':
        return 'attacker';
      default:
        return positionCode.toLowerCase();
    }
  }

  Future<Player?> _buildFallbackPlayerById(int playerId) async {
    final cachedRosterPlayer =
        _playerDetailsCache[playerId] ??
        getCachedPlayers().where((player) => player.id == playerId).firstOrNull;
    if (cachedRosterPlayer != null) {
      return _buildPlayerFromRosterPlayer(cachedRosterPlayer);
    }

    try {
      final playerData = await _firestoreService.getPlayerById(playerId);
      if (playerData != null) {
        final rawPlayerData = playerData['data'] is Map<String, dynamic>
            ? playerData['data'] as Map<String, dynamic>
            : playerData;
        return Player.fromJson(rawPlayerData);
      }
    } catch (e) {
      debugPrint(
        'PlayersRepository: Error building fallback player $playerId from Firestore: $e',
      );
    }

    return null;
  }

  Player _buildPlayerFromRosterPlayer(RosterPlayer rosterPlayer) {
    final normalizedPositionCode = _normalizePositionCode(
      rosterPlayer.positionCode,
    );

    final position = PositionInfo(
      id: 0,
      name: _positionNameFromCode(normalizedPositionCode),
      code: _positionInfoCode(normalizedPositionCode),
    );

    final team = PlayerTeamInfo(
      teamId: rosterPlayer.teamId,
      jerseyNumber: rosterPlayer.jerseyNumber,
      teamName: rosterPlayer.teamName,
      teamLogo: rosterPlayer.teamLogo,
    );

    final stats = rosterPlayer.stats;
    final statistics = stats == null || stats.isEmpty
        ? const <PlayerStatistics>[]
        : [
            PlayerStatistics(
              id: rosterPlayer.id,
              playerId: rosterPlayer.id,
              seasonId: _parseIntValue(stats['seasonId']),
              teamId: rosterPlayer.teamId,
              appearances: _extractStatValue(stats['appearances']).round(),
              lineups: _extractStatValue(stats['lineups']).round(),
              minutesPlayed: _extractStatValue(stats['minutes']).round(),
              goals: _extractStatValue(stats['goals']).round(),
              assists: _extractStatValue(stats['assists']).round(),
              yellowCards: _extractStatValue(stats['yellowCards']).round(),
              redCards: _extractStatValue(stats['redCards']).round(),
              cleanSheets: _extractStatValue(stats['cleanSheets']).round(),
              saves: _extractStatValue(stats['saves']).round(),
              rating: _parseDoubleValue(stats['rating']),
              seasonName: stats['seasonName']?.toString(),
            ),
          ];

    return Player(
      id: rosterPlayer.id,
      name: rosterPlayer.name,
      displayName: rosterPlayer.displayName,
      commonName: rosterPlayer.displayName,
      imagePath: rosterPlayer.imagePath,
      position: position,
      detailedPosition: position,
      teams: [team],
      statistics: statistics,
    );
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
      case 'GK':
        return 'Goalkeeper';
      case 'DEF':
        return 'Defender';
      case 'MID':
        return 'Midfielder';
      case 'FWD':
        return 'Forward';
      default:
        return 'Unknown';
    }
  }

  /// Get player IDs for a specific team (cached)
  Future<List<Map<String, dynamic>>> _getTeamPlayerIds(
    int teamId,
    String teamName,
    String? teamLogo,
  ) async {
    if (_teamPlayerIdsCache.containsKey(teamId)) {
      return _teamPlayerIdsCache[teamId]!;
    }

    final teamResponse = await _client.getTeamById(
      teamId,
      includes: ['players'],
    );
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

    debugPrint(
      'Fetching page $page for $teamName: players $startIndex-$endIndex of $totalPlayers',
    );

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
          includes: [
            'position',
            'detailedPosition',
            'nationality',
            'statistics.details',
          ],
        );

        if (playerResponse.data != null) {
          final teamInfo = _TeamPlayerInfo(
            teamId: info['teamId'] as int,
            teamName: info['teamName'] as String,
            teamLogo: info['teamLogo'] as String?,
            jerseyNumber: info['jerseyNumber'] as int?,
          );

          final rosterPlayer = _parsePlayerToRosterPlayer(
            playerResponse.data!,
            teamInfo,
          );
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
    debugPrint(
      'Loading players: Team ${team.name} (${teamIndex + 1}/${teams.length}), page $page',
    );

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
  @Deprecated(
    'Use getTeamPlayers() or getAllPlayersPage() instead for lazy loading',
  )
  Future<List<RosterPlayer>> getLigaMxRosterPlayers({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _playerDetailsCache.isNotEmpty) {
      final refreshedPlayers = _playerDetailsCache.values
          .map(_recalculateRosterPlayer)
          .toList();
      _playerDetailsCache
        ..clear()
        ..addEntries(
          refreshedPlayers.map((player) => MapEntry(player.id, player)),
        );
      return refreshedPlayers;
    }

    if (!forceRefresh) {
      final cachedPlayers = getCachedPlayers();
      if (cachedPlayers.isNotEmpty) {
        for (final player in cachedPlayers) {
          _playerDetailsCache[player.id] = player;
        }
        return cachedPlayers;
      }
    }

    return loadAllPlayersFromFirestore(forceRefresh: forceRefresh);
  }

  /// Load Liga MX team IDs from local CSV file
  /// Returns list of maps with 'id' and 'name' keys
  Future<List<Map<String, dynamic>>> _loadLigaMxTeamsFromCsv() async {
    try {
      final csvString = await rootBundle.loadString(
        'assets/Teams/LigaMXTeamIds.csv',
      );
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
            teams.add({'id': teamId, 'name': teamName});
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
      final normalizedPositionCode = _normalizePositionCode(positionCode);
      final seasonProjectedPoints = _calculateProjectedPoints(
        stats,
        positionCode,
      );
      final projectedPoints = _calculateNextMatchProjectedPoints(
        playerId: id,
        playerName: name,
        displayName:
            playerData['display_name']?.toString() ??
            playerData['common_name']?.toString() ??
            name,
        positionCode: normalizedPositionCode,
        seasonProjectedPoints: seasonProjectedPoints,
        seasonStats: stats,
        teamId: teamInfo.teamId,
      );
      final price = _calculatePrice(
        stats,
        positionCode,
        seasonProjectedPoints,
        playerName: name,
        displayName:
            playerData['display_name']?.toString() ??
            playerData['common_name']?.toString() ??
            name,
      );

      return RosterPlayer(
        id: id,
        name: name,
        displayName:
            playerData['display_name']?.toString() ??
            playerData['common_name']?.toString() ??
            name,
        imagePath: playerData['image_path']?.toString(),
        position: positionName,
        positionCode: normalizedPositionCode,
        teamId: teamInfo.teamId,
        teamName: teamInfo.teamName,
        teamLogo: teamInfo.teamLogo,
        jerseyNumber: teamInfo.jerseyNumber,
        price: price,
        projectedPoints: projectedPoints,
        seasonProjectedPointsPerMatch: seasonProjectedPoints,
        stats: stats,
      );
    } catch (e) {
      debugPrint('Error parsing player to roster player: $e');
      return null;
    }
  }

  /// Get players filtered by position
  Future<List<RosterPlayer>> getRosterPlayersByPosition(
    String positionCode,
  ) async {
    final allPlayers = await getLigaMxRosterPlayers();

    // Handle FWD which includes both attacker and forward
    if (positionCode.toUpperCase() == 'FWD') {
      return allPlayers.where((p) {
        final pos = p.positionCode.toUpperCase();
        return pos == 'FWD' || pos == 'ATT' || pos == 'ST' || pos == 'CF';
      }).toList();
    }

    return allPlayers
        .where(
          (p) => p.positionCode.toUpperCase() == positionCode.toUpperCase(),
        )
        .toList();
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
    if (value is Map<String, dynamic>) {
      final nestedValue = value['total'] ?? value['value'];
      if (nestedValue is double) return nestedValue;
      if (nestedValue is int) return nestedValue.toDouble();
      if (nestedValue is String) return double.tryParse(nestedValue);
      return null;
    }
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

      final latestStatsRaw = _selectPreferredStatisticsEntry(statisticsList);
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
          case 119: // Minutes played
            stats['minutes'] = value;
            break;
          case 84: // Yellow cards
            stats['yellowCards'] = value;
            break;
          case 83: // Red cards
          case 85: // Yellow-red cards
            stats['redCards'] = value;
            break;
          case 194:
          case 59: // Clean sheets
            stats['cleanSheets'] = value;
            break;
          case 209:
          case 101: // Saves
            stats['saves'] = value;
            break;
          case 321:
          case 42: // Appearances
            stats['appearances'] = value;
            break;
          case 322: // Lineups (starts)
            stats['lineups'] = value;
            break;
        }
      }

      final seasonRating = _parseDoubleValue(latestStats['rating']);
      if (seasonRating != null) {
        stats['rating'] = seasonRating;
      }

      stats['seasonId'] = _parseIntValue(latestStats['season_id']);
      stats['seasonName'] = latestStats['season']?['name']?.toString();

      return stats.isNotEmpty ? stats : null;
    } catch (e) {
      debugPrint('Error extracting player stats: $e');
      return null;
    }
  }

  /// Calculate projected fantasy points based on stats (per game average)
  double _calculateProjectedPoints(
    Map<String, dynamic>? stats,
    String positionCode,
  ) {
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
    final lineups = _parseDoubleValue(stats['lineups']) ?? 0;
    final minutes = _parseDoubleValue(stats['minutes']) ?? 0;
    final yellowCards = _parseDoubleValue(stats['yellowCards']) ?? 0;
    final redCards = _parseDoubleValue(stats['redCards']) ?? 0;
    final rating = _parseDoubleValue(stats['rating']) ?? 0;

    // Calculate games played (estimate if not available)
    final gamesPlayed = appearances > 0
        ? appearances
        : (lineups > 0 ? lineups : (minutes > 0 ? minutes / 70 : 0));
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
    } else {
      // FWD
      // FWD: Goals and assists are everything
      final goalsBonus = (goals / gamesPlayed) * 4.0;
      final assistsBonus = (assists / gamesPlayed) * 3.0;
      points = 2.0 + goalsBonus + assistsBonus;
    }

    // Deductions
    final cardsDeduction =
        ((yellowCards * 1.0) + (redCards * 3.0)) / gamesPlayed;
    points -= cardsDeduction;

    // Bonus for high rating (if available)
    if (rating > 0) {
      if (rating >= 7.5) points += 0.5;
      if (rating >= 8.0) points += 0.5;
    }

    // Clamp to reasonable per-match range.
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
  double _calculatePrice(
    Map<String, dynamic>? stats,
    String positionCode,
    double projectedPoints, {
    String? playerName,
    String? displayName,
  }) {
    final normalizedPos = _normalizePositionCode(positionCode);
    final normalizedPlayerName = _normalizePlayerPricingName(
      displayName ?? playerName,
    );
    final marketValue = normalizedPlayerName == null
        ? null
        : WorldCupMarketValues.lookupMarketValue(normalizedPlayerName);
    final marketTier = normalizedPlayerName == null
        ? null
        : WorldCupMarketTiers.byPlayerName[normalizedPlayerName];

    // Base prices by position (in millions USD)
    double basePrice;
    switch (normalizedPos) {
      case 'GK':
        basePrice = 3.5;
        break;
      case 'DEF':
        basePrice = 4.0;
        break;
      case 'MID':
        basePrice = 4.8;
        break;
      case 'FWD':
        basePrice = 5.2;
        break;
      default:
        basePrice = 4.5;
    }

    if (stats == null || stats.isEmpty) {
      final priceFromPoints = basePrice + (projectedPoints - 3.0) * 1.35;
      final adjusted = _applyMarketTierToPrice(
        basePricePrice: priceFromPoints,
        projectedPoints: projectedPoints,
        marketValue: marketValue,
        marketTier: marketTier,
      );
      return double.parse(adjusted.clamp(3.0, 20.0).toStringAsFixed(1));
    }

    final goals = _extractStatValue(stats['goals']);
    final assists = _extractStatValue(stats['assists']);
    final cleanSheets =
        _extractStatValue(stats['cleanSheets']) +
        _extractStatValue(stats['clean_sheets']);
    final saves = _extractStatValue(stats['saves']);
    final appearances = _extractStatValue(stats['appearances']);
    final rating = _extractStatValue(stats['rating']);
    final minutes = _extractStatValue(stats['minutes']);

    // Calculate games played (for per-game calculations)
    final gamesPlayed = appearances > 0
        ? appearances
        : (minutes > 0 ? minutes / 70 : 1);

    double price = basePrice;

    switch (normalizedPos) {
      case 'FWD':
        price += (goals / gamesPlayed) * 7.8;
        price += (assists / gamesPlayed) * 3.2;
        break;
      case 'MID':
        price += (goals / gamesPlayed) * 6.2;
        price += (assists / gamesPlayed) * 4.8;
        price += (cleanSheets / gamesPlayed) * 0.9;
        break;
      case 'DEF':
        price += (goals / gamesPlayed) * 7.0;
        price += (assists / gamesPlayed) * 3.2;
        price += (cleanSheets / gamesPlayed) * 4.8;
        break;
      case 'GK':
        price += (cleanSheets / gamesPlayed) * 5.0;
        price += (saves / gamesPlayed) * 0.55;
        break;
    }

    if (rating > 0) {
      price += ((rating - 6.6).clamp(0.0, 1.8)) * 1.15;
    }

    if (gamesPlayed >= 16) {
      price += 1.0;
    } else if (gamesPlayed >= 10) {
      price += 0.5;
    } else if (gamesPlayed < 10) {
      price *= 0.82;
    }

    final projectedPrice = basePrice + ((projectedPoints - 3.0) * 1.2);
    final blended = (price * 0.68) + (projectedPrice * 0.32);
    final adjusted = _applyMarketTierToPrice(
      basePricePrice: blended,
      projectedPoints: projectedPoints,
      marketValue: marketValue,
      marketTier: marketTier,
    );

    return double.parse(adjusted.clamp(3.0, 20.0).toStringAsFixed(1));
  }

  double _applyMarketTierToPrice({
    required double basePricePrice,
    required double projectedPoints,
    required double? marketValue,
    required MarketTier? marketTier,
  }) {
    var adjustedPrice = basePricePrice;

    if (marketValue != null && marketValue > 0) {
      final normalizedMarketSignal = _normalizeMarketValueToPrice(marketValue);
      final marketInfluence = _marketValueInfluenceWeight(marketValue);
      adjustedPrice =
          (adjustedPrice * (1 - marketInfluence)) +
          (normalizedMarketSignal * marketInfluence);
      adjustedPrice += _marketValueScarcityPremium(marketValue);
    }

    if (marketTier == null) {
      return adjustedPrice;
    }

    final premiumPrice =
        adjustedPrice + marketTier.projectionBonus + (projectedPoints * 0.16);
    return premiumPrice.clamp(marketTier.minPrice, marketTier.maxPrice);
  }

  double _normalizeMarketValueToPrice(double marketValueEurMillions) {
    final capped = marketValueEurMillions.clamp(0.75, 220.0);
    final normalized = (capped <= 0) ? 0.0 : (log(capped + 1) / log(221));

    // Keep affordable players close together, but expand the elite band so
    // global stars become materially harder to fit under the squad budget.
    final curved = normalized < 0.45
        ? normalized * 0.82
        : (0.369 + ((normalized - 0.45) / 0.55) * 0.631);
    final starWeighted = curved * curved;
    final price = 3.8 + (starWeighted * 16.7);
    return double.parse(price.toStringAsFixed(2));
  }

  double _marketValueInfluenceWeight(double marketValueEurMillions) {
    final capped = marketValueEurMillions.clamp(0.75, 220.0);
    final normalized = (capped <= 0) ? 0.0 : (log(capped + 1) / log(221));
    final weight = 0.18 + (normalized * normalized * 0.44);
    return weight.clamp(0.18, 0.62);
  }

  double _marketValueScarcityPremium(double marketValueEurMillions) {
    if (marketValueEurMillions >= 180) return 3.3;
    if (marketValueEurMillions >= 140) return 2.7;
    if (marketValueEurMillions >= 110) return 2.1;
    if (marketValueEurMillions >= 85) return 1.6;
    if (marketValueEurMillions >= 65) return 1.1;
    if (marketValueEurMillions >= 45) return 0.7;
    if (marketValueEurMillions >= 30) return 0.35;
    return 0.0;
  }

  String? _normalizePlayerPricingName(String? rawName) {
    return WorldCupMarketValues.normalizePlayerName(rawName);
  }

  // NOTE: Demo data generator removed - we now always use real API data
  // and throw errors if API fails (to help debug during development)

  /// Save roster to persistent cache
  Future<void> _saveRosterToCache(List<RosterPlayer> players) async {
    try {
      final cacheService = CacheService();
      final data = players.map((p) => p.toJson()).toList();
      await cacheService.set('liga_mx_roster', json.encode(data));
      await cacheService.set(
        'liga_mx_roster_time',
        DateTime.now().toIso8601String(),
      );
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
      debugPrint(
        'PlayersRepository: Found ${cachedPlayers.length} players for team $teamId in memory cache',
      );
      return cachedPlayers;
    }

    // Second, try Hive cache
    final hivePlayers = getCachedPlayers()
        .where((p) => p.teamId == teamId)
        .map((p) => p.id)
        .toSet();

    if (hivePlayers.isNotEmpty) {
      debugPrint(
        'PlayersRepository: Found ${hivePlayers.length} players for team $teamId in Hive cache',
      );
      return hivePlayers;
    }

    // Third, fetch from Firebase (which you've updated with teamId)
    try {
      debugPrint(
        'PlayersRepository: Fetching players for team $teamId from Firebase',
      );
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

      debugPrint(
        'PlayersRepository: Found ${playerIds.length} players for team $teamId in Firebase',
      );
      return playerIds;
    } catch (e) {
      debugPrint('PlayersRepository: Error fetching from Firebase: $e');
    }

    // Last resort: fetch from SportMonks API
    try {
      debugPrint(
        'PlayersRepository: Falling back to SportMonks API for team $teamId',
      );
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
    final cachedPlayer = cachedPlayers
        .where((p) => p.id == playerId)
        .firstOrNull;
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
      debugPrint(
        'PlayersRepository: Error fetching player $playerId from Firebase: $e',
      );
    }

    return null;
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}
