import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'sportmonks_config.dart';

/// Exception thrown when API request fails
class SportMonksException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic response;

  SportMonksException(this.message, {this.statusCode, this.response});

  @override
  String toString() => 'SportMonksException: $message (status: $statusCode)';
}

/// Response wrapper for SportMonks API
class SportMonksResponse<T> {
  final T data;
  final Map<String, dynamic>? pagination;
  final Map<String, dynamic>? rateLimit;
  final String? timezone;

  SportMonksResponse({
    required this.data,
    this.pagination,
    this.rateLimit,
    this.timezone,
  });

  bool get hasMore => pagination?['has_more'] == true;
  int? get currentPage => pagination?['current_page'];
  int? get nextPage => pagination?['next_page'];
  int? get totalCount => pagination?['count'];
}

/// HTTP Client for SportMonks API
class SportMonksClient {
  final http.Client _httpClient;
  
  SportMonksClient({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  /// Build the full URL with query parameters
  Uri _buildUrl(String endpoint, Map<String, String>? queryParams) {
    final params = <String, String>{
      'api_token': SportMonksConfig.apiToken,
      'timezone': SportMonksConfig.timezone,
      ...?queryParams,
    };
    
    final url = '${SportMonksConfig.baseUrl}$endpoint';
    return Uri.parse(url).replace(queryParameters: params);
  }

  /// Make a GET request to the API
  Future<SportMonksResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    required T Function(dynamic json) parser,
  }) async {
    if (!SportMonksConfig.isConfigured) {
      throw SportMonksException(
        'API not configured. Please set your API token in SportMonksConfig.',
      );
    }

    final uri = _buildUrl(endpoint, queryParams);
    
    //debugPrint('SportMonks API Request: $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

     // debugPrint('SportMonks API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Debug: Print raw pagination info
        final pagination = jsonData['pagination'] as Map<String, dynamic>?;
        if (pagination != null) {
          debugPrint('Pagination: total=${pagination['total']}, count=${pagination['count']}, '
              'per_page=${pagination['per_page']}, current_page=${pagination['current_page']}, '
              'total_pages=${pagination['total_pages']}, has_more=${pagination['has_more']}');
        }
        
        // Debug: Check for subscription info or messages
        final subscription = jsonData['subscription'];
        if (subscription != null) {
         // debugPrint('Subscription info: $subscription');
        }
        final message = jsonData['message'];
        if (message != null) {
         // debugPrint('API Message: $message');
        }
        
        // Parse the data
        final data = parser(jsonData['data']);
        
        return SportMonksResponse<T>(
          data: data,
          pagination: pagination,
          rateLimit: jsonData['rate_limit'] as Map<String, dynamic>?,
          timezone: jsonData['timezone'] as String?,
        );
      } else if (response.statusCode == 401) {
        throw SportMonksException(
          'Invalid API token. Please check your SportMonks API key.',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 429) {
        throw SportMonksException(
          'Rate limit exceeded. Please try again later.',
          statusCode: response.statusCode,
        );
      } else {
        final errorBody = json.decode(response.body);
        throw SportMonksException(
          errorBody['message'] ?? 'API request failed',
          statusCode: response.statusCode,
          response: errorBody,
        );
      }
    } on FormatException catch (e) {
      throw SportMonksException('Invalid JSON response: $e');
    } on http.ClientException catch (e) {
      throw SportMonksException('Network error: $e');
    }
  }

  /// Get fixtures for a specific date
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getFixturesByDate(
    DateTime date, {
    List<String>? includes,
  }) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<List<Map<String, dynamic>>>(
      '/fixtures/date/$dateStr',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get live fixtures
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getLiveFixtures({
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<List<Map<String, dynamic>>>(
      '/livescores/inplay',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get fixture by ID
  Future<SportMonksResponse<Map<String, dynamic>>> getFixtureById(
    int fixtureId, {
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<Map<String, dynamic>>(
      '/fixtures/$fixtureId',
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Search players by name
  Future<SportMonksResponse<List<Map<String, dynamic>>>> searchPlayers(
    String query, {
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<List<Map<String, dynamic>>>(
      '/players/search/$query',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get player by ID
  Future<SportMonksResponse<Map<String, dynamic>>> getPlayerById(
    int playerId, {
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<Map<String, dynamic>>(
      '/players/$playerId',
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get player by ID with their latest fixtures
  /// Uses include=latest to get the most recent fixtures the player participated in
  Future<SportMonksResponse<Map<String, dynamic>>> getPlayerWithLatestFixtures(
    int playerId, {
    int fixtureCount = 10,
  }) async {
    final queryParams = <String, String>{
      'include': 'latest',
    };
    
    debugPrint('SportMonks: Getting player $playerId with latest fixtures');
    
    return get<Map<String, dynamic>>(
      '/players/$playerId',
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>,
    );
  }

  /// Get fixture with detailed stats for player form calculation
  /// Includes events, statistics, timeline, and sidelined information
  Future<SportMonksResponse<Map<String, dynamic>?>> getFixtureWithDetailedStats(
    int fixtureId,
  ) async {
    final queryParams = <String, String>{
      // Combined includes:
      // - lineups;lineups.player;lineups.details.type = player advanced stats
      // - statistics;statistics.type = team stats
      // - events;events.player = goals, assists, cards
      // - participants;scores;state = match info needed for basic calculations
      'include': 'lineups;lineups.player;lineups.details.type;statistics;statistics.type;events;events.player;participants;scores;state',
    };
    
    debugPrint('SportMonks: Getting fixture $fixtureId with advanced player stats');
    
    return get<Map<String, dynamic>?>(
      '/fixtures/$fixtureId',
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>?,
    );
  }

  /// Get team by ID
  Future<SportMonksResponse<Map<String, dynamic>?>> getTeamById(
    int teamId, {
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<Map<String, dynamic>?>(
      '/teams/$teamId',
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>?,
    );
  }

  /// Get team squad (players)
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getTeamSquad(
    int teamId, {
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<List<Map<String, dynamic>>>(
      '/squads/teams/$teamId',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get leagues
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getLeagues({
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<List<Map<String, dynamic>>>(
      '/leagues',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get fixtures for a specific team within a date range
  /// Uses endpoint: /fixtures/between/{startDate}/{endDate}/{teamId}
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getFixturesByTeam(
    int teamId, {
    DateTime? startDate,
    DateTime? endDate,
    List<String>? includes,
  }) async {
    // Default to today and 7 days from now
    final start = startDate ?? DateTime.now();
    final end = endDate ?? DateTime.now().add(const Duration(days: 7));
    
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);
    
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<List<Map<String, dynamic>>>(
      '/fixtures/between/$startStr/$endStr/$teamId',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get recent past fixtures for a team (last N days)
  /// Used to calculate player's recent form from actual match data
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getRecentFixturesForTeam(
    int teamId, {
    int daysBack = 60,
    List<String>? includes,
  }) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: daysBack));
    
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);
    
    final queryParams = <String, String>{};
    // Include events for goals/assists/cards, lineups with details for minutes played
    // and statistics for player match stats
    final defaultIncludes = includes ?? [
      'participants',
      'events.player',
      'lineups.player',
      'lineups.details',    // Contains minutes played, rating, etc.
      'statistics.player',  // Contains detailed player statistics per match
      'scores',
      'state',
    ];
    queryParams['include'] = SportMonksConfig.buildIncludes(defaultIncludes);
    
    return get<List<Map<String, dynamic>>>(
      '/fixtures/between/$startStr/$endStr/$teamId',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get season info by ID
  /// Use includes like 'currentStage', 'stages', 'groups' for more details
  Future<SportMonksResponse<Map<String, dynamic>?>> getSeasonById(
    int seasonId, {
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<Map<String, dynamic>?>(
      '/seasons/$seasonId',
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>?,
    );
  }

  /// Get all seasons for a league
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getSeasonsByLeague(
    int leagueId, {
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{
      'filters': 'seasonLeagues:$leagueId',
    };
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<List<Map<String, dynamic>>>(
      '/seasons',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get all teams with their players (current roster)
  /// Since the API plan only covers Liga MX, this returns only Liga MX teams
  /// The players array contains basic player info including IDs
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getAllTeamsWithPlayers({
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'include': 'players',  // Simple include to get player list with basic info
    };
    
    debugPrint('Fetching teams with players - page: $page, perPage: $perPage');
    
    final response = await get<List<Map<String, dynamic>>>(
      '/teams',
      queryParams: queryParams,
      parser: (data) {
        if (data == null) return [];
        final teams = (data as List).cast<Map<String, dynamic>>();
        debugPrint('Raw teams response: ${teams.length} teams');
        for (final team in teams) {
          final name = team['name'];
          final id = team['id'];
          final players = team['players'];
          debugPrint('  Team: $name (ID: $id), players: ${players is List ? players.length : "none"}');
        }
        return teams;
      },
    );
    
    debugPrint('getAllTeamsWithPlayers - hasMore: ${response.hasMore}');
    return response;
  }

  /// Get all players with pagination
  /// Returns players with full details
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getAllPlayers({
    List<String>? includes,
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    
    final defaultIncludes = includes ?? [
      'nationality',
      'position',
      'detailedPosition',
      // Note: currentTeam is NOT available on /players endpoint
      'statistics.details',
    ];
    queryParams['include'] = SportMonksConfig.buildIncludes(defaultIncludes);
    
    return get<List<Map<String, dynamic>>>(
      '/players',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get teams by season ID with their current squad
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getTeamsBySeason(
    int seasonId, {
    List<String>? includes,
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
    };
    
    final defaultIncludes = includes ?? [
      'players.player.nationality',
      'players.player.position',
      'players.player.statistics.details',
    ];
    queryParams['include'] = SportMonksConfig.buildIncludes(defaultIncludes);
    
    return get<List<Map<String, dynamic>>>(
      '/teams/seasons/$seasonId',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get standings for a season (includes team IDs)
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getStandingsBySeason(
    int seasonId, {
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    
    final defaultIncludes = includes ?? [
      'participant',  // Team info
    ];
    queryParams['include'] = SportMonksConfig.buildIncludes(defaultIncludes);
    
    return get<List<Map<String, dynamic>>>(
      '/standings/seasons/$seasonId',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get multiple players by IDs in a single request
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getPlayersByIds(
    List<int> playerIds, {
    List<String>? includes,
  }) async {
    if (playerIds.isEmpty) {
      return SportMonksResponse(data: []);
    }
    
    final queryParams = <String, String>{};
    final defaultIncludes = includes ?? SportMonksConfig.playerIncludes;
    queryParams['include'] = SportMonksConfig.buildIncludes(defaultIncludes);
    
    // Join player IDs with comma
    final idsStr = playerIds.take(50).join(','); // API limit
    queryParams['filters'] = 'playerIds:$idsStr';
    
    return get<List<Map<String, dynamic>>>(
      '/players',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  // ========== ADVANCED STATISTICS METHODS ==========

  /// Get league with seasons to find current season
  /// Liga MX league ID is 743
  Future<SportMonksResponse<Map<String, dynamic>?>> getLeagueWithSeasons(
    int leagueId,
  ) async {
    final queryParams = <String, String>{
      'include': 'seasons',
    };
    
    debugPrint('SportMonks: Getting league $leagueId with seasons');
    
    return get<Map<String, dynamic>?>(
      '/leagues/$leagueId',
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>?,
    );
  }

  /// Get season with all fixtures
  /// Used to get fixture IDs for the season
  Future<SportMonksResponse<Map<String, dynamic>?>> getSeasonWithFixtures(
    int seasonId,
  ) async {
    final queryParams = <String, String>{
      'include': 'fixtures',
    };
    
    debugPrint('SportMonks: Getting season $seasonId with fixtures');
    
    return get<Map<String, dynamic>?>(
      '/seasons/$seasonId',
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>?,
    );
  }

  /// Get fixtures by season with advanced lineup statistics
  /// This is the key method for getting advanced player stats
  /// Uses filter=fixtureSeasons:{season_id} and includes lineups.details.type
  Future<SportMonksResponse<List<Map<String, dynamic>>>> getFixturesBySeasonWithAdvancedStats(
    int seasonId, {
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      'filters': 'fixtureSeasons:$seasonId',
      // Include lineups with player and details.type for advanced player stats
      'include': 'lineups;lineups.player;lineups.details.type;participants;scores;state',
    };
    
    debugPrint('SportMonks: Getting fixtures for season $seasonId with advanced stats (page $page)');
    
    return get<List<Map<String, dynamic>>>(
      '/fixtures',
      queryParams: queryParams,
      parser: (data) => data == null ? [] : (data as List).cast<Map<String, dynamic>>(),
    );
  }

  /// Get all fixtures for a season with pagination support
  /// Fetches all pages automatically
  Future<List<Map<String, dynamic>>> getAllFixturesForSeasonWithAdvancedStats(
    int seasonId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final allFixtures = <Map<String, dynamic>>[];
    int page = 1;
    bool hasMore = true;
    
    while (hasMore) {
      final response = await getFixturesBySeasonWithAdvancedStats(
        seasonId,
        page: page,
        perPage: 100, // Max per page
      );
      
      allFixtures.addAll(response.data);
      hasMore = response.hasMore;
      page++;
      
      // Safety limit to prevent infinite loops
      if (page > 20) {
        debugPrint('WARNING: Hit page limit of 20 when fetching fixtures');
        break;
      }
    }
    
    // Filter by date range if provided
    if (startDate != null || endDate != null) {
      return allFixtures.where((fixture) {
        final startingAt = fixture['starting_at'] as String?;
        if (startingAt == null) return false;
        
        final fixtureDate = DateTime.tryParse(startingAt);
        if (fixtureDate == null) return false;
        
        if (startDate != null && fixtureDate.isBefore(startDate)) return false;
        if (endDate != null && fixtureDate.isAfter(endDate)) return false;
        
        return true;
      }).toList();
    }
    
    return allFixtures;
  }

  /// Dispose the client
  void dispose() {
    _httpClient.close();
  }
}

