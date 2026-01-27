import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:fantacy11/api/sportmonks_client.dart';
import 'package:fantacy11/api/sportmonks_config.dart';
import 'package:fantacy11/features/fantasy/fantasy_points_predictor.dart';
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

  /// Get next upcoming match for a specific team
  /// Uses the /fixtures/between/{startDate}/{endDate}/{teamId} endpoint
  Future<MatchInfo?> getNextMatchForTeam(int teamId) async {
    if (!SportMonksConfig.isConfigured || teamId <= 0) {
      // Return a demo fixture for mock mode or invalid team ID
      print('API not configured or invalid team ID ($teamId), returning demo fixture');
      return _createDemoNextMatch();
    }

    try {
      // Query fixtures from today to 7 days from now
      final today = DateTime.now();
      final nextWeek = today.add(const Duration(days: 7));
      
      print('Fetching fixtures for team $teamId between $today and $nextWeek');
      
      final response = await _client.getFixturesByTeam(
        teamId,
        startDate: today,
        endDate: nextWeek,
        includes: SportMonksConfig.fixtureIncludes,
      );
      
      if (response.data.isEmpty) {
        print('No fixtures returned from API for team $teamId, using demo');
        return _createDemoNextMatch();
      }
      
      print('API returned ${response.data.length} fixtures for team $teamId');
      
      // Parse all fixtures
      final now = DateTime.now();
      final allFixtures = response.data
          .map((json) => MatchInfo.fromJson(json))
          .toList();
      
      // Filter to only upcoming fixtures (starting after now)
      final upcomingFixtures = allFixtures.where((match) {
        if (match.startingAtTimestamp == null) return true; // Include if no timestamp (will sort to end)
        final matchTime = DateTime.fromMillisecondsSinceEpoch(
          match.startingAtTimestamp! * 1000,
        );
        return matchTime.isAfter(now);
      }).toList();
      
      if (upcomingFixtures.isEmpty) {
        print('No upcoming fixtures for team $teamId (all ${allFixtures.length} are in the past), using demo');
        return _createDemoNextMatch();
      }
      
      // Sort by time - closest match first
      upcomingFixtures.sort((a, b) {
        if (a.startingAtTimestamp == null && b.startingAtTimestamp == null) return 0;
        if (a.startingAtTimestamp == null) return 1;
        if (b.startingAtTimestamp == null) return -1;
        return a.startingAtTimestamp!.compareTo(b.startingAtTimestamp!);
      });
      
      final nextMatch = upcomingFixtures.first;
      print('Found next match: ${nextMatch.team1Name} vs ${nextMatch.team2Name} at ${nextMatch.startDateTime}');
      return nextMatch;
    } on SportMonksException catch (e) {
      print('SportMonks API Error: $e');
      // Fall back to demo fixture
      return _createDemoNextMatch();
    } catch (e) {
      print('Unexpected error fetching team fixtures: $e');
      // Fall back to demo fixture
      return _createDemoNextMatch();
    }
  }

  /// Create a demo next match for testing/demo purposes
  MatchInfo _createDemoNextMatch() {
    // Create a fixture 2 days from now at 19:00
    final matchTime = DateTime.now().add(const Duration(days: 2)).copyWith(
      hour: 19,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    final timestamp = matchTime.millisecondsSinceEpoch ~/ 1000;

    return MatchInfo(
      'AME',
      'GDL',
      'Club América',
      'Guadalajara',
      'Liga MX',
      matchTime.toIso8601String(),
      'Jornada 15',
      '',
      'assets/TeamLogo/Vector Smart Object-2.png',
      'assets/TeamLogo/Vector Smart Object-5.png',
      const Color(0xFFFFD700),
      const Color(0xFFCD2027),
      startingAtTimestamp: timestamp,
      venue: const VenueInfo(
        name: 'Estadio Azteca',
        cityName: 'Mexico City',
        capacity: 87523,
      ),
      homeTeam: const TeamParticipant(
        id: 1,
        name: 'Club América',
        shortCode: 'AME',
        imagePath: 'assets/TeamLogo/Vector Smart Object-2.png',
        leaguePosition: 2,
        isHome: true,
      ),
      awayTeam: const TeamParticipant(
        id: 2,
        name: 'Guadalajara',
        shortCode: 'GDL',
        imagePath: 'assets/TeamLogo/Vector Smart Object-5.png',
        leaguePosition: 5,
        isHome: false,
      ),
    );
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

  /// Get recent match statistics for a specific player
  /// Fetches the last [matchCount] completed matches and extracts player's actual stats
  Future<RecentMatchStats?> getPlayerRecentStats(int playerId, int teamId, {int matchCount = 5}) async {
    if (!SportMonksConfig.isConfigured || teamId <= 0 || playerId <= 0) {
      print('Cannot fetch recent stats: API not configured or invalid IDs (player: $playerId, team: $teamId)');
      return null;
    }

    try {
      print('Fetching recent fixtures for team $teamId to get player $playerId stats');
      
      // Get fixtures from last 60 days (should cover 5+ matches)
      final response = await _client.getRecentFixturesForTeam(teamId, daysBack: 60);
      
      if (response.data.isEmpty) {
        print('No recent fixtures found for team $teamId');
        return null;
      }
      
      print('Found ${response.data.length} recent fixtures for team $teamId');
      
      // Filter to completed matches only and sort by date (newest first)
      final completedFixtures = response.data.where((fixture) {
        final state = fixture['state'] as Map<String, dynamic>?;
        final stateId = state?['id'] as int?;
        // State ID 5 = finished, 3 = finished after extra time, etc.
        return stateId == 5 || stateId == 3 || stateId == 11;
      }).toList();
      
      completedFixtures.sort((a, b) {
        final aTimestamp = a['starting_at_timestamp'] as int? ?? 0;
        final bTimestamp = b['starting_at_timestamp'] as int? ?? 0;
        return bTimestamp.compareTo(aTimestamp); // Newest first
      });
      
      // Take only the last N matches
      final recentMatches = completedFixtures.take(matchCount).toList();
      
      if (recentMatches.isEmpty) {
        print('No completed matches found for team $teamId');
        return null;
      }
      
      print('Analyzing ${recentMatches.length} recent completed matches');
      
      // Extract player stats from each match
      int matchesPlayed = 0;
      int goals = 0;
      int assists = 0;
      int minutesPlayed = 0;
      int cleanSheets = 0;
      int yellowCards = 0;
      int redCards = 0;
      int saves = 0;
      double totalRating = 0;
      int ratingCount = 0;
      
      for (final fixture in recentMatches) {
        final playerStats = _extractPlayerStatsFromFixture(fixture, playerId, teamId);
        
        if (playerStats != null && playerStats['played'] == true) {
          matchesPlayed++;
          goals += playerStats['goals'] as int? ?? 0;
          assists += playerStats['assists'] as int? ?? 0;
          minutesPlayed += playerStats['minutes'] as int? ?? 0;
          yellowCards += playerStats['yellowCards'] as int? ?? 0;
          redCards += playerStats['redCards'] as int? ?? 0;
          saves += playerStats['saves'] as int? ?? 0;
          
          if (playerStats['cleanSheet'] == true) {
            cleanSheets++;
          }
          
          if (playerStats['rating'] != null) {
            totalRating += playerStats['rating'] as double;
            ratingCount++;
          }
        }
      }
      
      if (matchesPlayed == 0) {
        print('Player $playerId did not play in any of the last $matchCount matches');
        return null;
      }
      
      print('Player $playerId stats from last $matchesPlayed matches: $goals goals, $assists assists, $minutesPlayed mins');
      
      return RecentMatchStats(
        matchesPlayed: matchesPlayed,
        goals: goals,
        assists: assists,
        minutesPlayed: minutesPlayed,
        cleanSheets: cleanSheets,
        yellowCards: yellowCards,
        redCards: redCards,
        saves: saves,
        averageRating: ratingCount > 0 ? totalRating / ratingCount : null,
      );
    } on SportMonksException catch (e) {
      print('SportMonks API Error fetching recent stats: $e');
      return null;
    } catch (e) {
      print('Error fetching recent stats for player $playerId: $e');
      return null;
    }
  }

  /// Get player's stats for a specific tournament/stage using date range
  /// This is the most accurate way to get tournament-specific stats since
  /// SportMonks aggregates stats per-season (full year) not per-stage
  Future<RecentMatchStats?> getPlayerTournamentStats(
    int playerId, 
    int teamId, {
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    if (!SportMonksConfig.isConfigured || teamId <= 0 || playerId <= 0) {
      print('Cannot fetch tournament stats: API not configured or invalid IDs');
      return null;
    }

    try {
      final end = endDate ?? DateTime.now();
      print('Fetching tournament stats for player $playerId (team $teamId) from ${startDate.toIso8601String().split('T')[0]} to ${end.toIso8601String().split('T')[0]}');
      
      // Get all fixtures for the team within the tournament date range
      final response = await _client.getFixturesByTeam(
        teamId,
        startDate: startDate,
        endDate: end,
        includes: [
          'participants',
          'events.player',
          'lineups.player',
          'lineups.details',
          'scores',
          'state',
        ],
      );
      
      if (response.data.isEmpty) {
        print('No fixtures found for team $teamId in tournament date range');
        return null;
      }
      
      print('Found ${response.data.length} fixtures in tournament date range');
      
      // Filter to completed matches only
      final completedFixtures = response.data.where((fixture) {
        final state = fixture['state'] as Map<String, dynamic>?;
        final stateId = state?['id'] as int?;
        // State ID 5 = finished, 3 = finished after extra time, 11 = finished after penalties
        return stateId == 5 || stateId == 3 || stateId == 11;
      }).toList();
      
      // Sort by date (oldest first for chronological order)
      completedFixtures.sort((a, b) {
        final aTimestamp = a['starting_at_timestamp'] as int? ?? 0;
        final bTimestamp = b['starting_at_timestamp'] as int? ?? 0;
        return aTimestamp.compareTo(bTimestamp);
      });
      
      if (completedFixtures.isEmpty) {
        print('No completed matches found in tournament date range');
        return null;
      }
      
      print('Analyzing ${completedFixtures.length} completed tournament matches');
      
      // Aggregate player stats from all tournament matches
      int matchesPlayed = 0;
      int goals = 0;
      int assists = 0;
      int minutesPlayed = 0;
      int cleanSheets = 0;
      int yellowCards = 0;
      int redCards = 0;
      int saves = 0;
      double totalRating = 0;
      int ratingCount = 0;
      
      for (final fixture in completedFixtures) {
        final playerStats = _extractPlayerStatsFromFixture(fixture, playerId, teamId);
        
        if (playerStats != null && playerStats['played'] == true) {
          matchesPlayed++;
          goals += playerStats['goals'] as int? ?? 0;
          assists += playerStats['assists'] as int? ?? 0;
          minutesPlayed += playerStats['minutes'] as int? ?? 0;
          yellowCards += playerStats['yellowCards'] as int? ?? 0;
          redCards += playerStats['redCards'] as int? ?? 0;
          saves += playerStats['saves'] as int? ?? 0;
          
          if (playerStats['cleanSheet'] == true) {
            cleanSheets++;
          }
          
          if (playerStats['rating'] != null) {
            totalRating += playerStats['rating'] as double;
            ratingCount++;
          }
        }
      }
      
      if (matchesPlayed == 0) {
        print('Player $playerId did not play in any tournament matches');
        return null;
      }
      
      print('Tournament stats for player $playerId: $matchesPlayed matches, $goals goals, $assists assists');
      
      return RecentMatchStats(
        matchesPlayed: matchesPlayed,
        goals: goals,
        assists: assists,
        minutesPlayed: minutesPlayed,
        cleanSheets: cleanSheets,
        yellowCards: yellowCards,
        redCards: redCards,
        saves: saves,
        averageRating: ratingCount > 0 ? totalRating / ratingCount : null,
      );
    } on SportMonksException catch (e) {
      print('SportMonks API Error fetching tournament stats: $e');
      return null;
    } catch (e) {
      print('Error fetching tournament stats for player $playerId: $e');
      return null;
    }
  }

  /// Extract a player's statistics from a single fixture
  /// Returns a map with goals, assists, minutes, cards, etc.
  Map<String, dynamic>? _extractPlayerStatsFromFixture(
    Map<String, dynamic> fixture,
    int playerId,
    int teamId,
  ) {
    bool played = false;
    int goals = 0;
    int assists = 0;
    int minutes = 0;
    int yellowCards = 0;
    int redCards = 0;
    int saves = 0;
    bool cleanSheet = false;
    double? rating;
    
    // Check lineups for player participation and minutes
    final lineups = fixture['lineups'] as List?;
    if (lineups != null) {
      for (final lineup in lineups) {
        if (lineup is! Map<String, dynamic>) continue;
        
        final lineupPlayerId = lineup['player_id'] as int?;
        if (lineupPlayerId == playerId) {
          played = true;
          
          // Get minutes from lineup meta or details
          final details = lineup['details'] as List?;
          if (details != null) {
            for (final detail in details) {
              if (detail is! Map<String, dynamic>) continue;
              final typeId = detail['type_id'] as int?;
              final value = detail['value'] as dynamic;
              
              // Type IDs vary, but common ones:
              // Minutes played is often in the lineup data directly
              if (typeId == 119) { // Minutes played
                minutes = (value is int) ? value : int.tryParse(value.toString()) ?? 0;
              }
              if (typeId == 79) { // Rating
                rating = (value is double) ? value : double.tryParse(value.toString());
              }
              if (typeId == 57) { // Saves
                saves = (value is int) ? value : int.tryParse(value.toString()) ?? 0;
              }
            }
          }
          
          // If minutes not found in details, estimate from position
          if (minutes == 0) {
            final position = lineup['position'] as String?;
            if (position != null && position.isNotEmpty) {
              // Started the match
              minutes = 90; // Default to full match, will be adjusted by events
            }
          }
          
          break;
        }
      }
    }
    
    if (!played) {
      return null;
    }
    
    // Check events for goals, assists, cards, substitutions
    final events = fixture['events'] as List?;
    if (events != null) {
      for (final event in events) {
        if (event is! Map<String, dynamic>) continue;
        
        final eventPlayerId = event['player_id'] as int?;
        final relatedPlayerId = event['related_player_id'] as int?;
        final typeId = event['type_id'] as int?;
        final minute = event['minute'] as int?;
        
        // Goal scored (type_id 14 = Goal, 16 = Penalty Goal)
        if (eventPlayerId == playerId && (typeId == 14 || typeId == 16)) {
          goals++;
        }
        
        // Assist (the related_player_id on a goal event is often the assister)
        // Or check for type_id that indicates assist
        if (relatedPlayerId == playerId && (typeId == 14 || typeId == 16)) {
          assists++;
        }
        
        // Yellow card (type_id 19)
        if (eventPlayerId == playerId && typeId == 19) {
          yellowCards++;
        }
        
        // Red card (type_id 20) or second yellow (type_id 21)
        if (eventPlayerId == playerId && (typeId == 20 || typeId == 21)) {
          redCards++;
        }
        
        // Substitution out (type_id 18) - adjust minutes
        if (eventPlayerId == playerId && typeId == 18 && minute != null) {
          minutes = minute;
        }
        
        // Substitution in (type_id 18 with related_player_id being the one coming on)
        if (relatedPlayerId == playerId && typeId == 18 && minute != null) {
          minutes = 90 - minute;
        }
      }
    }
    
    // Check for clean sheet (team didn't concede)
    final scores = fixture['scores'] as List?;
    if (scores != null) {
      final participants = fixture['participants'] as List?;
      if (participants != null) {
        // Find which team the player is on and check if they conceded
        for (final participant in participants) {
          if (participant is! Map<String, dynamic>) continue;
          final participantId = participant['id'] as int?;
          if (participantId == teamId) {
            final meta = participant['meta'] as Map<String, dynamic>?;
            final location = meta?['location'] as String?;
            
            // Find the opponent's score
            for (final score in scores) {
              if (score is! Map<String, dynamic>) continue;
              final scoreParticipant = score['participant_id'] as int?;
              if (scoreParticipant != teamId) {
                final goalsAgainst = score['score']?['goals'] as int? ?? 0;
                cleanSheet = goalsAgainst == 0;
                break;
              }
            }
            break;
          }
        }
      }
    }
    
    return {
      'played': played,
      'goals': goals,
      'assists': assists,
      'minutes': minutes,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'saves': saves,
      'cleanSheet': cleanSheet,
      'rating': rating,
    };
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}

