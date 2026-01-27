import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fantacy11/api/sportmonks_client.dart';
import 'package:fantacy11/api/sportmonks_config.dart';
import 'package:fantacy11/features/match/models/match_info.dart';

/// Repository for fetching fixture/match data
class FixturesRepository {
  final SportMonksClient _client;
  
  FixturesRepository({SportMonksClient? client}) 
      : _client = client ?? SportMonksClient();

  /// Get fixtures for today, or upcoming if none today
  Future<List<MatchInfo>> getTodayFixtures() async {
    final today = await getFixturesByDate(DateTime.now());
    
    // If no fixtures today, try to get upcoming fixtures
    if (today.isEmpty) {
      print('No fixtures today, fetching upcoming fixtures...');
      return getUpcomingFixtures(days: 3);
    }
    
    return today;
  }

  /// Get fixtures for a specific date
  Future<List<MatchInfo>> getFixturesByDate(DateTime date) async {
    // If API is not configured, fall back to mock data
    print('SportMonks isConfigured: ${SportMonksConfig.isConfigured}');
    if (!SportMonksConfig.isConfigured) {
      print('API not configured, using mock data');
      return _loadMockFixtures();
    }

    print('Calling SportMonks API for date: $date');
    try {
      final response = await _client.getFixturesByDate(
        date,
        includes: SportMonksConfig.fixtureIncludes,
      );
      
      print('SportMonks API returned ${response.data.length} fixtures');
      return response.data
          .map((json) => MatchInfo.fromJson(json))
          .toList();
    } on SportMonksException catch (e) {
      // Log error and fall back to mock data in development
      print('SportMonks API Error: $e');
      return _loadMockFixtures();
    } catch (e) {
      // Catch any other errors
      print('Unexpected error calling SportMonks API: $e');
      return _loadMockFixtures();
    }
  }

  /// Get live fixtures
  Future<List<MatchInfo>> getLiveFixtures() async {
    if (!SportMonksConfig.isConfigured) {
      return _loadMockFixtures();
    }

    try {
      final response = await _client.getLiveFixtures(
        includes: SportMonksConfig.fixtureIncludes,
      );
      
      return response.data
          .map((json) => MatchInfo.fromJson(json))
          .toList();
    } on SportMonksException catch (e) {
      print('SportMonks API Error: $e');
      return _loadMockFixtures();
    }
  }

  /// Get a single fixture by ID
  Future<MatchInfo?> getFixtureById(int fixtureId) async {
    if (!SportMonksConfig.isConfigured) {
      final mockFixtures = await _loadMockFixtures();
      return mockFixtures.isNotEmpty ? mockFixtures.first : null;
    }

    try {
      final response = await _client.getFixtureById(
        fixtureId,
        includes: SportMonksConfig.fixtureIncludes,
      );
      
      return MatchInfo.fromJson(response.data);
    } on SportMonksException catch (e) {
      print('SportMonks API Error: $e');
      return null;
    }
  }

  /// Get upcoming fixtures (next 7 days)
  Future<List<MatchInfo>> getUpcomingFixtures({int days = 7}) async {
    if (!SportMonksConfig.isConfigured) {
      return _loadMockFixtures();
    }

    final allFixtures = <MatchInfo>[];
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = now.add(Duration(days: i));
      try {
        final fixtures = await getFixturesByDate(date);
        allFixtures.addAll(fixtures);
      } catch (e) {
        print('Error fetching fixtures for $date: $e');
      }
    }
    
    // Sort by starting time
    allFixtures.sort((a, b) {
      if (a.startingAtTimestamp == null && b.startingAtTimestamp == null) return 0;
      if (a.startingAtTimestamp == null) return 1;
      if (b.startingAtTimestamp == null) return -1;
      return a.startingAtTimestamp!.compareTo(b.startingAtTimestamp!);
    });
    
    return allFixtures;
  }

  /// Load mock fixtures from assets (fallback)
  Future<List<MatchInfo>> _loadMockFixtures() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/MockResponses/dayFixtures.json',
      );
      final jsonData = json.decode(jsonString);
      final data = jsonData['data'] as List?;
      
      if (data != null) {
        return data
            .map((json) => MatchInfo.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading mock fixtures: $e');
    }
    
    return [];
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}

