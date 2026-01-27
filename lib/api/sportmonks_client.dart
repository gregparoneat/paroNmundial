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
    
    debugPrint('SportMonks API Request: $uri');

    try {
      final response = await _httpClient.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

      debugPrint('SportMonks API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        // Parse the data
        final data = parser(jsonData['data']);
        
        return SportMonksResponse<T>(
          data: data,
          pagination: jsonData['pagination'] as Map<String, dynamic>?,
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

  /// Get team by ID
  Future<SportMonksResponse<Map<String, dynamic>>> getTeamById(
    int teamId, {
    List<String>? includes,
  }) async {
    final queryParams = <String, String>{};
    if (includes != null && includes.isNotEmpty) {
      queryParams['include'] = SportMonksConfig.buildIncludes(includes);
    }
    
    return get<Map<String, dynamic>>(
      '/teams/$teamId',
      queryParams: queryParams,
      parser: (data) => data as Map<String, dynamic>,
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

  /// Dispose the client
  void dispose() {
    _httpClient.close();
  }
}

