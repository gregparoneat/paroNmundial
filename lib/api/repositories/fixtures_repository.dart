import 'package:flutter/foundation.dart';
import 'package:fantacy11/api/sportmonks_client.dart';
import 'package:fantacy11/api/sportmonks_config.dart';
import 'package:fantacy11/api/repositories/seasons_repository.dart';
import 'package:fantacy11/features/fantasy/fantasy_points_predictor.dart';
import 'package:fantacy11/features/match/models/match_info.dart';

/// Repository for fetching fixture/match data
class FixturesRepository {
  static final Map<int, Future<List<MatchInfo>>> _upcomingFixturesInFlight = {};
  static final Map<int, _CachedUpcomingFixtures> _upcomingFixturesCache = {};
  static const Duration _upcomingFixturesTtl = Duration(minutes: 2);

  final SportMonksClient _client;
  final int? _seasonId;
  final SeasonsRepository _seasonsRepository;

  /// Create a FixturesRepository
  ///
  /// Optional parameters for batch jobs or scripts:
  /// - [apiToken]: Custom API token to use instead of SportMonksConfig
  /// - [seasonId]: Season ID to use for queries (Liga MX current season)
  /// - [client]: Custom SportMonksClient instance
  FixturesRepository({
    SportMonksClient? client,
    String? apiToken,
    int? seasonId,
  }) : _client = client ?? SportMonksClient(apiToken: apiToken),
       _seasonId = seasonId,
       _seasonsRepository = SeasonsRepository(
         client: client ?? SportMonksClient(apiToken: apiToken),
       );

  /// Get the season ID (from constructor or default)
  int? get seasonId => _seasonId;

  int get _configuredLeagueId => SportMonksConfig.competitionLeagueId;

  int get _fallbackSeasonId => _seasonId ?? SportMonksConfig.fallbackSeasonId;

  int? _extractLeagueId(Map<String, dynamic> fixture) {
    final direct = fixture['league_id'];
    if (direct is int) return direct;
    if (fixture['league'] is Map<String, dynamic>) {
      final league = fixture['league'] as Map<String, dynamic>;
      final id = league['id'];
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? '');
    }
    return int.tryParse(direct?.toString() ?? '');
  }

  int? _extractSeasonId(Map<String, dynamic> fixture) {
    final direct = fixture['season_id'];
    if (direct is int) return direct;
    if (fixture['season'] is Map<String, dynamic>) {
      final season = fixture['season'] as Map<String, dynamic>;
      final id = season['id'];
      if (id is int) return id;
      return int.tryParse(id?.toString() ?? '');
    }
    return int.tryParse(direct?.toString() ?? '');
  }

  bool _matchesConfiguredCompetition(Map<String, dynamic> fixture) {
    final leagueId = _extractLeagueId(fixture);
    if (leagueId != null && leagueId == _configuredLeagueId) return true;

    final fixtureSeasonId = _extractSeasonId(fixture);
    return fixtureSeasonId != null && fixtureSeasonId == _fallbackSeasonId;
  }

  List<Map<String, dynamic>> _filterFixturesToConfiguredCompetition(
    List<Map<String, dynamic>> fixtures,
  ) {
    return fixtures.where(_matchesConfiguredCompetition).toList();
  }

  bool _matchesLeagueOrSeasonWhitelist(
    Map<String, dynamic> fixture, {
    List<int>? leagueIds,
    List<int>? seasonIds,
  }) {
    final allowedLeagueIds = leagueIds ?? const <int>[];
    final allowedSeasonIds = seasonIds ?? const <int>[];

    if (allowedLeagueIds.isEmpty && allowedSeasonIds.isEmpty) {
      return true;
    }

    final fixtureLeagueId = _extractLeagueId(fixture);
    if (fixtureLeagueId != null && allowedLeagueIds.contains(fixtureLeagueId)) {
      return true;
    }

    final fixtureSeasonId = _extractSeasonId(fixture);
    if (fixtureSeasonId != null && allowedSeasonIds.contains(fixtureSeasonId)) {
      return true;
    }

    return false;
  }

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

      final fixtures = _filterFixturesToConfiguredCompetition(response.data);
      print(
        'SportMonks API returned ${response.data.length} fixtures, ${fixtures.length} matched ${SportMonksConfig.competitionName}',
      );
      return fixtures.map((json) => MatchInfo.fromJson(json)).toList();
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

      final fixtures = _filterFixturesToConfiguredCompetition(response.data);
      return fixtures.map((json) => MatchInfo.fromJson(json)).toList();
    } on SportMonksException catch (e) {
      print('SportMonks API Error: $e');
      return _loadMockFixtures();
    }
  }

  Future<List<Map<String, dynamic>>> getWorldCupStandings() async {
    if (!SportMonksConfig.isConfigured) {
      return [];
    }

    final seasonId = await getCurrentSeasonId();
    if (seasonId == null) {
      return [];
    }

    try {
      final response = await _client.getStandingsBySeason(
        seasonId,
        includes: ['participant', 'group', 'stage', 'details.type'],
      );

      final standings = response.data.where((standing) {
        final participant = standing['participant'];
        return participant is Map<String, dynamic> &&
            _matchesConfiguredCompetition({
              'league_id': standing['league_id'],
              'season_id': standing['season_id'],
            });
      }).toList();

      standings.sort((a, b) {
        final groupA =
            (a['group'] as Map<String, dynamic>?)?['name']?.toString() ??
            a['group_id']?.toString() ??
            '';
        final groupB =
            (b['group'] as Map<String, dynamic>?)?['name']?.toString() ??
            b['group_id']?.toString() ??
            '';
        final groupCompare = groupA.compareTo(groupB);
        if (groupCompare != 0) return groupCompare;

        final positionA = a['position'] as int? ?? 999;
        final positionB = b['position'] as int? ?? 999;
        return positionA.compareTo(positionB);
      });

      print(
        'Loaded ${standings.length} ${SportMonksConfig.competitionName} standings rows from season $seasonId',
      );

      return standings;
    } on SportMonksException catch (e) {
      print('SportMonks standings error: $e');
      return [];
    } catch (e) {
      print('Unexpected standings error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getWorldCupScheduleRaw() async {
    if (!SportMonksConfig.isConfigured) {
      return [];
    }

    final seasonId = await getCurrentSeasonId();
    if (seasonId == null) {
      return [];
    }

    try {
      final allFixtures = <Map<String, dynamic>>[];
      var page = 1;
      var hasMore = true;

      while (hasMore) {
        final response = await _client.getFixturesBySeason(
          seasonId,
          includes: [
            'participants',
            'venue',
            'state',
            'league',
            'group',
            'round',
            'stage',
            'scores',
          ],
          page: page,
          perPage: 100,
        );

        allFixtures.addAll(_filterFixturesToConfiguredCompetition(response.data));
        hasMore = response.hasMore;
        page++;

        if (page > 20) {
          break;
        }
      }

      allFixtures.sort((a, b) {
        final aTs = a['starting_at_timestamp'] as int? ?? 0;
        final bTs = b['starting_at_timestamp'] as int? ?? 0;
        return aTs.compareTo(bTs);
      });

      return allFixtures;
    } on SportMonksException catch (e) {
      print('SportMonks schedule error: $e');
      return [];
    } catch (e) {
      print('Unexpected schedule error: $e');
      return [];
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

  /// Get upcoming fixtures for the configured competition.
  ///
  /// For long-format tournaments like the World Cup, this loads the full season
  /// schedule and filters it down to matches that have not started yet, instead
  /// of only checking the next few calendar days.
  Future<List<MatchInfo>> getUpcomingFixtures({int days = 7}) async {
    final cached = _upcomingFixturesCache[days];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _upcomingFixturesTtl) {
      return cached.fixtures;
    }

    final inFlight = _upcomingFixturesInFlight[days];
    if (inFlight != null) return inFlight;

    final future = _fetchUpcomingFixtures(days: days);
    _upcomingFixturesInFlight[days] = future;

    try {
      final fixtures = await future;
      _upcomingFixturesCache[days] = _CachedUpcomingFixtures(
        fixtures: fixtures,
        fetchedAt: DateTime.now(),
      );
      return fixtures;
    } finally {
      _upcomingFixturesInFlight.remove(days);
    }
  }

  Future<List<MatchInfo>> _fetchUpcomingFixtures({required int days}) async {
    if (!SportMonksConfig.isConfigured) {
      return _loadMockFixtures();
    }

    final seasonId = await getCurrentSeasonId();
    if (seasonId != null) {
      try {
        final fixtures = await _fetchUpcomingFixturesForSeason(seasonId);
        if (fixtures.isNotEmpty) {
          return fixtures;
        }
      } catch (e) {
        print(
          'Error fetching season schedule for ${SportMonksConfig.competitionName}: $e',
        );
      }
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
      if (a.startingAtTimestamp == null && b.startingAtTimestamp == null)
        return 0;
      if (a.startingAtTimestamp == null) return 1;
      if (b.startingAtTimestamp == null) return -1;
      return a.startingAtTimestamp!.compareTo(b.startingAtTimestamp!);
    });

    return allFixtures;
  }

  Future<List<MatchInfo>> _fetchUpcomingFixturesForSeason(int seasonId) async {
    final allFixtures = <Map<String, dynamic>>[];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      final response = await _client.getFixturesBySeason(
        seasonId,
        includes: SportMonksConfig.fixtureIncludes,
        page: page,
        perPage: 100,
      );

      final fixtures = _filterFixturesToConfiguredCompetition(response.data);
      allFixtures.addAll(fixtures);
      hasMore = response.hasMore;
      page++;

      if (page > 20) {
        print(
          'Reached pagination safety limit while loading ${SportMonksConfig.competitionName} fixtures',
        );
        break;
      }
    }

    final now = DateTime.now();
    final upcomingFixtures = allFixtures.where((fixture) {
      final timestamp = fixture['starting_at_timestamp'] as int?;
      if (timestamp == null) return false;
      final matchTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return !matchTime.isBefore(now);
    }).toList();

    upcomingFixtures.sort((a, b) {
      final aTimestamp = a['starting_at_timestamp'] as int?;
      final bTimestamp = b['starting_at_timestamp'] as int?;
      if (aTimestamp == null && bTimestamp == null) return 0;
      if (aTimestamp == null) return 1;
      if (bTimestamp == null) return -1;
      return aTimestamp.compareTo(bTimestamp);
    });

    print(
      'Loaded ${upcomingFixtures.length} upcoming ${SportMonksConfig.competitionName} fixtures from season $seasonId',
    );

    return upcomingFixtures.map((json) => MatchInfo.fromJson(json)).toList();
  }

  /// Get next upcoming match for a specific team
  /// Uses the /fixtures/between/{startDate}/{endDate}/{teamId} endpoint
  Future<MatchInfo?> getNextMatchForTeam(
    int teamId, {
    bool allowDemoFallback = true,
  }) async {
    if (!SportMonksConfig.isConfigured || teamId <= 0) {
      print(
        'API not configured or invalid team ID ($teamId), '
        '${allowDemoFallback ? "returning demo fixture" : "returning null"}',
      );
      return allowDemoFallback ? _createDemoNextMatch() : null;
    }

    try {
      final scheduledWorldCupMatch = await _findUpcomingSeasonMatchForTeam(
        teamId,
      );
      if (scheduledWorldCupMatch != null) {
        print(
          'Found next ${SportMonksConfig.competitionName} match for team $teamId: '
          '${scheduledWorldCupMatch.team1Name} vs ${scheduledWorldCupMatch.team2Name} '
          'at ${scheduledWorldCupMatch.startDateTime}',
        );
        return scheduledWorldCupMatch;
      }

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
        print(
          'No fixtures returned from API for team $teamId, '
          '${allowDemoFallback ? "using demo" : "returning null"}',
        );
        return allowDemoFallback ? _createDemoNextMatch() : null;
      }

      print('API returned ${response.data.length} fixtures for team $teamId');

      // Parse all fixtures
      final now = DateTime.now();
      final allFixtures = response.data
          .map((json) => MatchInfo.fromJson(json))
          .toList();

      // Filter to only upcoming fixtures (starting after now)
      final upcomingFixtures = allFixtures.where((match) {
        if (match.startingAtTimestamp == null)
          return true; // Include if no timestamp (will sort to end)
        final matchTime = DateTime.fromMillisecondsSinceEpoch(
          match.startingAtTimestamp! * 1000,
        );
        return matchTime.isAfter(now);
      }).toList();

      if (upcomingFixtures.isEmpty) {
        print(
          'No upcoming fixtures for team $teamId '
          '(all ${allFixtures.length} are in the past), '
          '${allowDemoFallback ? "using demo" : "returning null"}',
        );
        return allowDemoFallback ? _createDemoNextMatch() : null;
      }

      // Sort by time - closest match first
      upcomingFixtures.sort((a, b) {
        if (a.startingAtTimestamp == null && b.startingAtTimestamp == null)
          return 0;
        if (a.startingAtTimestamp == null) return 1;
        if (b.startingAtTimestamp == null) return -1;
        return a.startingAtTimestamp!.compareTo(b.startingAtTimestamp!);
      });

      final nextMatch = upcomingFixtures.first;
      print(
        'Found next match: ${nextMatch.team1Name} vs ${nextMatch.team2Name} at ${nextMatch.startDateTime}',
      );
      return nextMatch;
    } on SportMonksException catch (e) {
      print('SportMonks API Error: $e');
      return allowDemoFallback ? _createDemoNextMatch() : null;
    } catch (e) {
      print('Unexpected error fetching team fixtures: $e');
      return allowDemoFallback ? _createDemoNextMatch() : null;
    }
  }

  Future<MatchInfo?> _findUpcomingSeasonMatchForTeam(int teamId) async {
    final fixtures = await getUpcomingFixtures();
    for (final fixture in fixtures) {
      if (fixture.homeTeam?.id == teamId || fixture.awayTeam?.id == teamId) {
        return fixture;
      }
    }
    return null;
  }

  /// Create a demo next match for testing/demo purposes
  MatchInfo _createDemoNextMatch() {
    // Create a fixture 2 days from now at 19:00
    final matchTime = DateTime.now()
        .add(const Duration(days: 2))
        .copyWith(hour: 19, minute: 0, second: 0, millisecond: 0);
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
      MatchColors.gold, // 0xFFFFD700
      MatchColors.crimson, // 0xFFCD2027
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

  /// Load mock fixtures - returns empty list in pure Dart context
  /// For Flutter apps, use the FixturesRepositoryFlutter extension
  Future<List<MatchInfo>> _loadMockFixtures() async {
    // Mock data loading requires Flutter's rootBundle, which is not available in pure Dart
    // Return empty list - batch jobs shouldn't need mock data anyway
    print('Note: Mock fixtures not available in pure Dart context');
    return [];
  }

  /// Get recent match statistics for a specific player using accurate algorithm
  ///
  /// Algorithm:
  /// 1. Get player's latest fixtures (using include=latest)
  /// 2. For each fixture, get detailed stats (events, statistics, timeline, sidelined)
  /// 3. Skip international/invalid fixtures (null response)
  /// 4. Only consider fixtures within the last 6 weeks
  /// 5. Use timeline to verify player involvement
  /// 6. Repeat until we have 5 fixtures worth of data
  /// 7. Track actual fixtures used for form calculation
  ///
  /// If 0 fixtures in last 6 weeks = player is likely injured or bench warmer
  Future<RecentMatchStats?> getPlayerRecentStats(
    int playerId,
    int teamId, {
    int matchCount = 5,
  }) async {
    if (!SportMonksConfig.isConfigured || playerId <= 0) {
      print(
        'Cannot fetch recent stats: API not configured or invalid player ID ($playerId)',
      );
      return null;
    }

    try {
      print('=== ACCURATE FORM CALCULATION for player $playerId ===');

      // Step 1: Get player with their latest fixtures
      final playerResponse = await _client.getPlayerWithLatestFixtures(
        playerId,
      );
      final playerData = playerResponse.data;

      final latestFixtures = playerData['latest'] as List?;
      if (latestFixtures == null || latestFixtures.isEmpty) {
        print('No latest fixtures found for player $playerId');
        print('Player data keys: ${playerData.keys.toList()}');
        return _createZeroFormStats();
      }

      print(
        'Found ${latestFixtures.length} fixture references for player $playerId',
      );

      // Debug: Log structure of first fixture reference
      if (latestFixtures.isNotEmpty) {
        final firstRef = latestFixtures.first;
        print('First fixture reference type: ${firstRef.runtimeType}');
        if (firstRef is Map) {
          print('First fixture reference keys: ${firstRef.keys.toList()}');
          print('First fixture ID: ${firstRef['id']}');
        } else if (firstRef is int) {
          print('Fixture references are direct IDs');
        }
      }

      // 6 weeks cutoff
      final sixWeeksAgo = DateTime.now().subtract(const Duration(days: 42));

      // Stats accumulators
      int matchesAnalyzed = 0;
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

      // Advanced stats accumulator
      AdvancedStats aggregatedAdvanced = const AdvancedStats();

      // Step 2: Process each fixture until we have enough data
      // Fixtures come in order - first one is the most recent
      for (final fixtureRef in latestFixtures) {
        if (matchesAnalyzed >= matchCount) break;

        // Handle different possible structures of fixture reference
        // The 'latest' array contains lineup entries, NOT fixtures directly
        // Each entry has 'fixture_id' (the actual fixture) and 'id' (the lineup entry ID)
        int? fixtureId;
        if (fixtureRef is int) {
          fixtureId = fixtureRef;
        } else if (fixtureRef is Map) {
          // Use 'fixture_id' NOT 'id' - 'id' is the lineup entry ID
          fixtureId = fixtureRef['fixture_id'] as int?;
        }

        if (fixtureId == null) {
          print('Could not extract fixture_id from latest entry: $fixtureRef');
          continue;
        }

        print(
          'Processing fixture $fixtureId - calling fixtures endpoint for detailed stats...',
        );

        // Step 3: Get detailed fixture data by calling the fixtures endpoint
        // API call: /fixtures/{fixtureId}?include=events;statistics;timeline;sidelined;lineups;participants;scores;state
        try {
          final fixtureResponse = await _client.getFixtureWithDetailedStats(
            fixtureId,
          );
          final fixture = fixtureResponse.data;

          // Null response likely means international game or fixture not in our league coverage - skip it
          if (fixture == null) {
            print(
              'Fixture $fixtureId returned null (likely international/not covered) - skipping',
            );
            continue;
          }

          print(
            'Fixture $fixtureId loaded - has timeline: ${fixture['timeline'] != null}, statistics: ${fixture['statistics'] != null}, events: ${fixture['events'] != null}',
          );

          // Step 4: Check fixture date (must be within 6 weeks)
          final fixtureTimestamp = fixture['starting_at_timestamp'] as int?;
          if (fixtureTimestamp != null) {
            final fixtureDate = DateTime.fromMillisecondsSinceEpoch(
              fixtureTimestamp * 1000,
            );
            if (fixtureDate.isBefore(sixWeeksAgo)) {
              print(
                'Fixture $fixtureId is older than 6 weeks (${fixtureDate.toIso8601String()}) - stopping',
              );
              break; // Since fixtures are sorted newest first, stop here
            }
          }

          // Check fixture is completed
          final state = fixture['state'] as Map<String, dynamic>?;
          final stateId = state?['id'] as int?;
          if (stateId != 5 && stateId != 3 && stateId != 11) {
            print(
              'Fixture $fixtureId not completed (state: $stateId) - skipping',
            );
            continue;
          }

          // Step 5 & 6: Extract player stats using timeline, statistics, and sidelined
          final playerStats = _extractPlayerStatsFromDetailedFixture(
            fixture,
            playerId,
            teamId,
          );

          matchesAnalyzed++;

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

            // Extract advanced stats from lineup details
            final advancedFromFixture = _extractAdvancedStatsFromLineup(
              fixture,
              playerId,
            );
            if (advancedFromFixture != null) {
              aggregatedAdvanced = aggregatedAdvanced.mergeWith(
                advancedFromFixture,
              );
              print('Fixture $fixtureId: Extracted advanced stats for player');
            }

            print(
              'Fixture $fixtureId: Player played ${playerStats['minutes']} mins, ${playerStats['goals']} goals, ${playerStats['assists']} assists',
            );
          } else {
            print(
              'Fixture $fixtureId: Player did not participate (sidelined/bench)',
            );
          }
        } on SportMonksException catch (e) {
          print('Error fetching fixture $fixtureId: $e - skipping');
          continue;
        }
      }

      print(
        '=== Form calculation complete: $matchesPlayed matches played out of $matchesAnalyzed analyzed ===',
      );

      // Step 7: Handle case where player hasn't played in 6 weeks
      if (matchesPlayed == 0) {
        print(
          'Player $playerId has not played in the last 6 weeks - likely injured or bench warmer',
        );
        return _createZeroFormStats();
      }

      print(
        'Player $playerId form stats: $goals goals, $assists assists, $minutesPlayed mins in $matchesPlayed matches',
      );
      print(
        'Player $playerId advanced stats: ${aggregatedAdvanced.keyPasses} key passes, ${aggregatedAdvanced.tackles} tackles, ${aggregatedAdvanced.shotsTotal} shots',
      );

      // Check if we actually got any advanced stats (at least some non-zero values)
      final hasRealAdvancedStats =
          aggregatedAdvanced.keyPasses > 0 ||
          aggregatedAdvanced.tackles > 0 ||
          aggregatedAdvanced.shotsTotal > 0 ||
          aggregatedAdvanced.totalPasses > 0 ||
          aggregatedAdvanced.duelsWon > 0;

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
        fixturesAnalyzed: matchesAnalyzed,
        advancedStats: hasRealAdvancedStats ? aggregatedAdvanced : null,
      );
    } on SportMonksException catch (e) {
      print('SportMonks API Error fetching recent stats: $e');
      return null;
    } catch (e, stackTrace) {
      print('Error fetching recent stats for player $playerId: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Extract advanced stats from lineup details for a specific player
  ///
  /// The lineup details contain per-player stats like key passes, tackles, etc.
  /// Format: lineups[].details[].type.developer_name -> stat type, details[].data.value -> stat value
  AdvancedStats? _extractAdvancedStatsFromLineup(
    Map<String, dynamic> fixture,
    int playerId,
  ) {
    // Debug: Show what keys are in the fixture
    print(
      'DEBUG _extractAdvancedStats: Fixture keys: ${fixture.keys.toList()}',
    );

    final lineups = fixture['lineups'] as List?;
    print(
      'DEBUG _extractAdvancedStats: lineups is ${lineups == null ? "NULL" : "List with ${lineups.length} entries"}',
    );

    if (lineups == null || lineups.isEmpty) {
      print(
        'DEBUG _extractAdvancedStats: No lineups array in fixture or it is empty',
      );
      return null;
    }

    print(
      'DEBUG: Fixture has ${lineups.length} lineup entries, looking for player $playerId',
    );

    // Find the lineup entry for this player
    for (final lineup in lineups) {
      if (lineup is! Map<String, dynamic>) {
        print('DEBUG: Lineup entry is not a Map: ${lineup.runtimeType}');
        continue;
      }

      final lineupPlayerId = lineup['player_id'] as int?;
      if (lineupPlayerId != playerId) continue;

      print('DEBUG: Found player $playerId in lineup!');
      print('DEBUG: Lineup keys: ${lineup.keys.toList()}');

      // Found player's lineup entry - extract details
      final details = lineup['details'] as List?;
      if (details == null || details.isEmpty) {
        print(
          'DEBUG: Player $playerId found in lineup but no details array (details: ${lineup['details']})',
        );
        return null;
      }

      print(
        'DEBUG: Extracting advanced stats from ${details.length} detail entries for player $playerId',
      );

      // Debug first detail entry structure
      if (details.isNotEmpty) {
        final firstDetail = details.first;
        print('DEBUG: First detail structure: ${firstDetail.runtimeType}');
        if (firstDetail is Map) {
          print('DEBUG: First detail keys: ${firstDetail.keys.toList()}');
          print('DEBUG: First detail type: ${firstDetail['type']}');
          print('DEBUG: First detail type_id: ${firstDetail['type_id']}');
          print('DEBUG: First detail value: ${firstDetail['value']}');
        }
      }

      // Use the AdvancedStats factory to parse the details
      final stats = AdvancedStats.fromLineupDetails(details);
      print(
        'DEBUG: Parsed advanced stats - keyPasses: ${stats.keyPasses}, tackles: ${stats.tackles}, shots: ${stats.shotsTotal}',
      );
      return stats;
    }

    print('DEBUG: Player $playerId NOT found in any lineup entry');
    return null;
  }

  /// Create zero form stats for players with no recent activity
  RecentMatchStats _createZeroFormStats() {
    return RecentMatchStats(
      matchesPlayed: 0,
      goals: 0,
      assists: 0,
      minutesPlayed: 0,
      cleanSheets: 0,
      yellowCards: 0,
      redCards: 0,
      saves: 0,
      averageRating: null,
      fixturesAnalyzed: 0,
    );
  }

  /// Extract player stats from a detailed fixture (with events, lineups, sidelined)
  ///
  /// Data sources:
  /// - events: goals (type_id 14/16), assists (related_player_id on goals),
  ///           cards (type_id 19/20/21), substitutions (type_id 18)
  /// - lineups: starter (type_id 11) vs bench (type_id 12)
  /// - sidelined: injured/suspended players
  ///
  /// Note: statistics in fixture response are TEAM-level, not player-level!
  ///
  /// Substitution event format:
  /// - player_id = player coming ON (substitute entering)
  /// - related_player_id = player going OFF (being replaced)
  Map<String, dynamic>? _extractPlayerStatsFromDetailedFixture(
    Map<String, dynamic> fixture,
    int playerId,
    int teamId,
  ) {
    bool played = false;
    bool wasStarter = false;
    bool isSidelined = false;
    bool isOnBench = false;
    int goals = 0;
    int assists = 0;
    int minutes = 0;
    int yellowCards = 0;
    int redCards = 0;
    int saves = 0;
    bool cleanSheet = false;
    double? rating;
    int? subInMinute; // Minute player came ON
    int? subOutMinute; // Minute player went OFF

    final fixtureId = fixture['id'];

    // Step 1: Check if player is sidelined (injured/suspended)
    final sidelined = fixture['sidelined'] as List?;
    if (sidelined != null) {
      for (final entry in sidelined) {
        if (entry is! Map<String, dynamic>) continue;
        final sidelinedPlayerId = entry['player_id'] as int?;
        if (sidelinedPlayerId == playerId) {
          isSidelined = true;
          print(
            'Fixture $fixtureId: Player $playerId is sidelined (injured/suspended)',
          );
          return {'played': false, 'sidelined': true};
        }
      }
    }

    // Step 2: Check lineups to determine if player was starter or bench
    // Also extract saves and rating from lineup details
    final lineups = fixture['lineups'] as List?;
    if (lineups != null) {
      for (final lineup in lineups) {
        if (lineup is! Map<String, dynamic>) continue;
        final lineupPlayerId = lineup['player_id'] as int?;
        if (lineupPlayerId == playerId) {
          // type_id 11 = starting lineup, type_id 12 = substitute (on bench)
          final lineupTypeId = lineup['type_id'] as int?;
          wasStarter = lineupTypeId == 11;
          isOnBench = lineupTypeId == 12;

          if (wasStarter) {
            played = true;
            print('Fixture $fixtureId: Player $playerId was a STARTER');
          } else if (isOnBench) {
            print('Fixture $fixtureId: Player $playerId was on BENCH');
          }

          // Extract saves, rating, and minutes from lineup details
          final details = lineup['details'] as List?;
          if (details != null) {
            for (final detail in details) {
              if (detail is! Map<String, dynamic>) continue;
              final type = detail['type'] as Map<String, dynamic>?;
              final devName = type?['developer_name']?.toString() ?? '';
              final data = detail['data'] as Map<String, dynamic>?;
              final value = data?['value'];

              switch (devName) {
                case 'SAVES':
                  saves = _parseIntSafe(value) ?? 0;
                  print('Fixture $fixtureId: Player $playerId SAVES=$saves');
                  break;
                case 'RATING':
                  rating = _parseDoubleSafe(value);
                  print('Fixture $fixtureId: Player $playerId RATING=$rating');
                  break;
                case 'MINUTES_PLAYED':
                  final detailMinutes = _parseIntSafe(value) ?? 0;
                  if (detailMinutes > 0) {
                    minutes = detailMinutes;
                    played = true;
                  }
                  break;
              }
            }
          }
          break;
        }
      }
    }

    // Step 3: Check events for goals, assists, cards, and substitutions
    final events = fixture['events'] as List?;
    if (events != null) {
      for (final event in events) {
        if (event is! Map<String, dynamic>) continue;
        final eventPlayerId = event['player_id'] as int?;
        final relatedPlayerId = event['related_player_id'] as int?;
        final typeId = event['type_id'] as int?;
        final minute = event['minute'] as int? ?? 0;

        // Goal (type_id 14) or Penalty Goal (type_id 16)
        if (eventPlayerId == playerId && (typeId == 14 || typeId == 16)) {
          goals++;
          played = true;
          print(
            'Fixture $fixtureId: Player $playerId scored at minute $minute',
          );
        }

        // Assist - related_player_id on goal event (player who assisted)
        if (relatedPlayerId == playerId && (typeId == 14 || typeId == 16)) {
          assists++;
          played = true;
          print(
            'Fixture $fixtureId: Player $playerId assisted at minute $minute',
          );
        }

        // Yellow card (type_id 19)
        if (eventPlayerId == playerId && typeId == 19) {
          yellowCards++;
          played = true;
        }

        // Red card (type_id 20) or second yellow (type_id 21)
        if (eventPlayerId == playerId && (typeId == 20 || typeId == 21)) {
          redCards++;
          played = true;
        }

        // Substitution (type_id 18)
        // IMPORTANT: player_id = player coming ON, related_player_id = player going OFF
        if (typeId == 18) {
          // Player came ON as substitute
          if (eventPlayerId == playerId) {
            subInMinute = minute;
            played = true;
            print(
              'Fixture $fixtureId: Player $playerId came ON at minute $minute',
            );
          }
          // Player went OFF (was subbed out)
          if (relatedPlayerId == playerId) {
            subOutMinute = minute;
            print(
              'Fixture $fixtureId: Player $playerId went OFF at minute $minute',
            );
          }
        }
      }
    }

    // If player was on bench but never came on, they didn't play
    if (isOnBench && subInMinute == null) {
      print(
        'Fixture $fixtureId: Player $playerId stayed on bench (did not play)',
      );
      return {'played': false, 'onBench': true};
    }

    // If player not found in lineups at all
    if (!wasStarter && !isOnBench && !played) {
      print('Fixture $fixtureId: Player $playerId not in lineup');
      return null;
    }

    if (!played) {
      return {'played': false};
    }

    // Step 4: Calculate minutes played
    if (wasStarter) {
      // Starter: played from 0 until subbed out (or full 90)
      minutes = subOutMinute ?? 90;
    } else if (subInMinute != null) {
      // Substitute: played from subIn until subOut (or end of game)
      if (subOutMinute != null && subOutMinute > subInMinute) {
        minutes = subOutMinute - subInMinute;
      } else {
        minutes = 90 - subInMinute;
      }
    }

    print(
      'Fixture $fixtureId: Player $playerId - starter=$wasStarter, subIn=$subInMinute, subOut=$subOutMinute, TOTAL MINUTES=$minutes',
    );

    // Step 5: Check for clean sheet (opponent scored 0 goals)
    // Use the 'scores' array which is more reliable than participants.meta
    // Default to false (not a clean sheet) if we can't determine
    cleanSheet = false;

    final scores = fixture['scores'] as List?;
    if (scores != null && scores.isNotEmpty) {
      for (final score in scores) {
        if (score is! Map<String, dynamic>) continue;

        // Look for the opponent's score (description usually "CURRENT" for final score)
        final description =
            score['description']?.toString().toUpperCase() ?? '';
        final scoreParticipantId = score['participant_id'] as int?;

        // We want the opponent's goals (not our team)
        if (scoreParticipantId != null && scoreParticipantId != teamId) {
          // Check for final/current score
          if (description == 'CURRENT' ||
              description == '2ND_HALF' ||
              description.contains('FINAL')) {
            final scoreData = score['score'] as Map<String, dynamic>?;
            final opponentGoals =
                scoreData?['goals'] as int? ??
                _parseIntSafe(score['goals']) ??
                _parseIntSafe(scoreData?['participant']) ??
                -1;

            if (opponentGoals >= 0) {
              cleanSheet = opponentGoals == 0;
              print(
                'Fixture $fixtureId: Opponent goals = $opponentGoals, cleanSheet = $cleanSheet',
              );
            }
            break;
          }
        }
      }
    }

    // Fallback: check participants meta if scores didn't work
    if (!cleanSheet) {
      final participants = fixture['participants'] as List?;
      if (participants != null) {
        for (final participant in participants) {
          if (participant is! Map<String, dynamic>) continue;
          final participantId = participant['id'] as int?;
          if (participantId != null && participantId != teamId) {
            final meta = participant['meta'] as Map<String, dynamic>?;
            if (meta != null) {
              final opponentGoals = _parseIntSafe(meta['goals']);
              if (opponentGoals != null) {
                cleanSheet = opponentGoals == 0;
                print(
                  'Fixture $fixtureId: (from meta) Opponent goals = $opponentGoals, cleanSheet = $cleanSheet',
                );
              }
            }
            break;
          }
        }
      }
    }

    return {
      'played': played,
      'wasStarter': wasStarter,
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

  /// Get player's stats for a specific tournament/stage using date range
  /// This is the most accurate way to get tournament-specific stats since
  /// SportMonks aggregates stats per-season (full year) not per-stage
  ///
  /// Uses detailed fixture data (events, statistics, timeline, sidelined) for accuracy
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
      print(
        'Fetching tournament stats for player $playerId (team $teamId) from ${startDate.toIso8601String().split('T')[0]} to ${end.toIso8601String().split('T')[0]}',
      );

      // Get all fixtures for the team within the tournament date range
      final response = await _client.getFixturesByTeam(
        teamId,
        startDate: startDate,
        endDate: end,
        includes: ['participants', 'scores', 'state'],
      );

      if (response.data.isEmpty) {
        print('No fixtures found for team $teamId in tournament date range');
        return null;
      }

      print('Found ${response.data.length} fixtures in tournament date range');

      // Filter to completed matches only and sort by date (newest first)
      final completedFixtures = response.data.where((fixture) {
        final state = fixture['state'] as Map<String, dynamic>?;
        final stateId = state?['id'] as int?;
        return stateId == 5 || stateId == 3 || stateId == 11;
      }).toList();

      completedFixtures.sort((a, b) {
        final aTimestamp = a['starting_at_timestamp'] as int? ?? 0;
        final bTimestamp = b['starting_at_timestamp'] as int? ?? 0;
        return bTimestamp.compareTo(aTimestamp); // Newest first
      });

      if (completedFixtures.isEmpty) {
        print('No completed matches found in tournament date range');
        return null;
      }

      print(
        'Analyzing ${completedFixtures.length} completed tournament matches',
      );

      // Aggregate player stats from all tournament matches
      int matchesAnalyzed = 0;
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
        final fixtureId = fixture['id'] as int?;
        if (fixtureId == null) continue;

        // Get detailed fixture data for accurate stats
        try {
          final detailedResponse = await _client.getFixtureWithDetailedStats(
            fixtureId,
          );
          final detailedFixture = detailedResponse.data;

          if (detailedFixture == null) {
            print(
              'Fixture $fixtureId returned null (likely international) - skipping',
            );
            continue;
          }

          matchesAnalyzed++;

          final playerStats = _extractPlayerStatsFromDetailedFixture(
            detailedFixture,
            playerId,
            teamId,
          );

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

            print(
              'Tournament fixture $fixtureId: Player played ${playerStats['minutes']} mins',
            );
          }
        } on SportMonksException catch (e) {
          print('Error fetching fixture $fixtureId details: $e - skipping');
          continue;
        }
      }

      if (matchesPlayed == 0) {
        print(
          'Player $playerId did not play in any tournament matches ($matchesAnalyzed analyzed)',
        );
        return RecentMatchStats(
          matchesPlayed: 0,
          fixturesAnalyzed: matchesAnalyzed,
        );
      }

      print(
        'Tournament stats for player $playerId: $matchesPlayed matches played, $goals goals, $assists assists, $minutesPlayed mins',
      );

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
        fixturesAnalyzed: matchesAnalyzed,
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
    bool wasStarter = false;
    int goals = 0;
    int assists = 0;
    int minutes = 0;
    int yellowCards = 0;
    int redCards = 0;
    int saves = 0;
    bool cleanSheet = false;
    double? rating;
    int? subInMinute;
    int? subOutMinute;

    final fixtureId = fixture['id'];

    // First check fixture statistics (most accurate source)
    final statistics = fixture['statistics'] as List?;
    if (statistics != null) {
      for (final stat in statistics) {
        if (stat is! Map<String, dynamic>) continue;
        final statPlayerId = stat['player_id'] as int?;
        if (statPlayerId == playerId) {
          played = true;
          final data = stat['data'] as Map<String, dynamic>?;
          if (data != null) {
            minutes = _parseIntSafe(data['minutes']) ?? minutes;
            goals = _parseIntSafe(data['goals']) ?? goals;
            assists = _parseIntSafe(data['assists']) ?? assists;
            yellowCards = _parseIntSafe(data['yellowcards']) ?? yellowCards;
            redCards = _parseIntSafe(data['redcards']) ?? redCards;
            saves = _parseIntSafe(data['saves']) ?? saves;
            rating = _parseDoubleSafe(data['rating']) ?? rating;
          }
          break;
        }
      }
    }

    // Check lineups for player participation
    final lineups = fixture['lineups'] as List?;
    if (lineups != null) {
      for (final lineup in lineups) {
        if (lineup is! Map<String, dynamic>) continue;

        final lineupPlayerId = lineup['player_id'] as int?;
        if (lineupPlayerId == playerId) {
          played = true;

          // type_id 11 = starting lineup, type_id 12 = substitute
          final lineupTypeId = lineup['type_id'] as int?;
          wasStarter = lineupTypeId == 11;

          // Get stats from lineup details if not found in statistics
          final details = lineup['details'] as List?;
          if (details != null && minutes == 0) {
            for (final detail in details) {
              if (detail is! Map<String, dynamic>) continue;
              final typeId = detail['type_id'] as int?;
              final value = detail['value'];

              if (typeId == 119 && minutes == 0) {
                minutes = _parseIntSafe(value) ?? 0;
              }
              if (typeId == 79 && rating == null) {
                rating = _parseDoubleSafe(value);
              }
              if ((typeId == 209 || typeId == 57) && saves == 0) {
                saves = _parseIntSafe(value) ?? 0;
              }
            }
          }
          break;
        }
      }
    }

    if (!played) {
      return null;
    }

    // Check events for goals, assists, cards, and substitutions
    final events = fixture['events'] as List?;
    if (events != null) {
      for (final event in events) {
        if (event is! Map<String, dynamic>) continue;

        final eventPlayerId = event['player_id'] as int?;
        final relatedPlayerId = event['related_player_id'] as int?;
        final typeId = event['type_id'] as int?;
        final minute = event['minute'] as int? ?? 0;

        // Goal (type_id 14) or Penalty Goal (type_id 16)
        if (eventPlayerId == playerId && (typeId == 14 || typeId == 16)) {
          goals++;
        }

        // Assist (related_player_id on goal event)
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

        // Substitution (type_id 18)
        // player_id = player going OFF, related_player_id = player coming ON
        if (typeId == 18) {
          if (eventPlayerId == playerId) {
            subOutMinute = minute;
          }
          if (relatedPlayerId == playerId) {
            subInMinute = minute;
          }
        }
      }
    }

    // Calculate minutes if not found from statistics/lineup details
    if (minutes == 0) {
      if (wasStarter) {
        minutes = subOutMinute ?? 90;
      } else if (subInMinute != null) {
        if (subOutMinute != null && subOutMinute > subInMinute) {
          minutes = subOutMinute - subInMinute;
        } else {
          minutes = 90 - subInMinute;
        }
      }
    }

    print(
      'Fixture $fixtureId - Player $playerId: starter=$wasStarter, subIn=$subInMinute, subOut=$subOutMinute, minutes=$minutes, goals=$goals',
    );

    // Check for clean sheet
    final scores = fixture['scores'] as List?;
    if (scores != null) {
      for (final score in scores) {
        if (score is! Map<String, dynamic>) continue;
        final scoreParticipant = score['participant_id'] as int?;
        if (scoreParticipant != teamId) {
          final scoreData = score['score'] as Map<String, dynamic>?;
          final goalsAgainst = scoreData?['goals'] as int? ?? 0;
          cleanSheet = goalsAgainst == 0;
          break;
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

  int? _parseIntSafe(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _parseDoubleSafe(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // ========== ADVANCED STATISTICS METHODS ==========

  /// Cache for current season ID
  int? _currentSeasonId;

  /// Cache for fixtures with advanced stats (player_id -> list of fixture stats)
  final Map<int, List<Map<String, dynamic>>> _playerFixtureStatsCache = {};

  /// Get the current season ID for the configured competition.
  Future<int?> getCurrentSeasonId() async {
    if (_currentSeasonId != null) return _currentSeasonId;

    try {
      _currentSeasonId =
          _seasonId ??
          await _seasonsRepository.getCurrentSeasonId() ??
          SportMonksConfig.fallbackSeasonId;
      print(
        'Using ${SportMonksConfig.competitionName} season: $_currentSeasonId',
      );
      return _currentSeasonId;
    } catch (e) {
      print('Error getting current season: $e');
      _currentSeasonId = _fallbackSeasonId;
      return _currentSeasonId;
    }
  }

  /// Get player advanced stats from the last 6 weeks of fixtures
  /// This uses the new advanced statistics from lineup details
  Future<RecentMatchStats> getPlayerAdvancedStats(
    int playerId,
    int teamId,
  ) async {
    // Check cache first
    if (_playerFixtureStatsCache.containsKey(playerId)) {
      return _aggregatePlayerStats(
        playerId,
        _playerFixtureStatsCache[playerId]!,
      );
    }

    try {
      // Get current season
      final seasonId = await getCurrentSeasonId();
      if (seasonId == null) {
        print('Could not get current season ID');
        return const RecentMatchStats(matchesPlayed: 0);
      }

      // Calculate date range (last 6 weeks)
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 42)); // 6 weeks

      // Fetch all fixtures for the season
      final fixtures = await _client.getAllFixturesForSeasonWithAdvancedStats(
        seasonId,
        startDate: startDate,
        endDate: endDate,
      );

      print('Fetched ${fixtures.length} fixtures from last 6 weeks');

      // Process fixtures to extract player stats
      final playerStats = <Map<String, dynamic>>[];

      for (final fixture in fixtures) {
        final fixtureId = fixture['id'] as int?;
        final lineups = fixture['lineups'] as List?;

        if (lineups == null || fixtureId == null) continue;

        // Find player in lineups
        for (final lineup in lineups) {
          if (lineup is! Map<String, dynamic>) continue;

          final lineupPlayerId = lineup['player_id'] as int?;
          if (lineupPlayerId != playerId) continue;

          // Found player in this fixture
          final details = lineup['details'] as List?;
          if (details == null || details.isEmpty) continue;

          // Parse advanced stats from details
          final advancedStats = AdvancedStats.fromLineupDetails(details);

          // Extract basic stats from the fixture/lineup
          final fixtureStats = _extractBasicStatsFromLineup(
            fixture,
            lineup,
            details,
          );
          fixtureStats['advancedStats'] = advancedStats;
          fixtureStats['fixtureId'] = fixtureId;

          playerStats.add(fixtureStats);
          break; // Player found, move to next fixture
        }
      }

      // Cache the results
      _playerFixtureStatsCache[playerId] = playerStats;

      return _aggregatePlayerStats(playerId, playerStats);
    } catch (e) {
      print('Error fetching advanced stats for player $playerId: $e');
      return const RecentMatchStats(matchesPlayed: 0);
    }
  }

  /// Extract basic stats from lineup data
  Map<String, dynamic> _extractBasicStatsFromLineup(
    Map<String, dynamic> fixture,
    Map<String, dynamic> lineup,
    List<dynamic> details,
  ) {
    int goals = 0, assists = 0, minutes = 0, saves = 0;
    int yellowCards = 0, redCards = 0;
    bool cleanSheet = false;
    double? rating;

    // Extract from details
    for (final detail in details) {
      if (detail is! Map<String, dynamic>) continue;

      final type = detail['type'] as Map<String, dynamic>?;
      final code = type?['code']?.toString().toUpperCase() ?? '';
      final value = detail['value'];

      switch (code) {
        case 'GOALS':
          goals = _parseIntSafe(value) ?? 0;
          break;
        case 'ASSISTS':
          assists = _parseIntSafe(value) ?? 0;
          break;
        case 'MINUTES':
        case 'MINUTES_PLAYED':
          minutes = _parseIntSafe(value) ?? 0;
          break;
        case 'SAVES':
          saves = _parseIntSafe(value) ?? 0;
          break;
        case 'YELLOWCARDS':
        case 'YELLOW_CARDS':
          yellowCards = _parseIntSafe(value) ?? 0;
          break;
        case 'REDCARDS':
        case 'RED_CARDS':
          redCards = _parseIntSafe(value) ?? 0;
          break;
        case 'RATING':
          rating = _parseDoubleSafe(value);
          break;
      }
    }

    // If minutes not found in details, estimate from type_id
    if (minutes == 0) {
      final typeId = lineup['type_id'] as int?;
      // type_id 11 = starter, type_id 12 = substitute
      if (typeId == 11) {
        minutes = 90; // Assume full match for starters
      }
    }

    // Check for clean sheet from fixture scores
    final participantId = lineup['team_id'] as int?;
    final scores = fixture['scores'] as List?;
    if (scores != null && participantId != null) {
      for (final score in scores) {
        if (score is! Map<String, dynamic>) continue;
        final scoreParticipant = score['participant_id'] as int?;
        if (scoreParticipant != participantId) {
          final scoreData = score['score'] as Map<String, dynamic>?;
          final goalsAgainst = scoreData?['goals'] as int? ?? 0;
          cleanSheet = goalsAgainst == 0;
          break;
        }
      }
    }

    return {
      'goals': goals,
      'assists': assists,
      'minutes': minutes,
      'saves': saves,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'cleanSheet': cleanSheet,
      'rating': rating,
    };
  }

  /// Aggregate player stats from multiple fixtures into RecentMatchStats
  RecentMatchStats _aggregatePlayerStats(
    int playerId,
    List<Map<String, dynamic>> fixtureStats,
  ) {
    if (fixtureStats.isEmpty) {
      return const RecentMatchStats(matchesPlayed: 0);
    }

    int totalGoals = 0, totalAssists = 0, totalMinutes = 0;
    int totalSaves = 0, totalYellowCards = 0, totalRedCards = 0;
    int cleanSheets = 0;
    final ratings = <double>[];
    AdvancedStats aggregatedAdvanced = const AdvancedStats();

    for (final stats in fixtureStats) {
      totalGoals += stats['goals'] as int? ?? 0;
      totalAssists += stats['assists'] as int? ?? 0;
      totalMinutes += stats['minutes'] as int? ?? 0;
      totalSaves += stats['saves'] as int? ?? 0;
      totalYellowCards += stats['yellowCards'] as int? ?? 0;
      totalRedCards += stats['redCards'] as int? ?? 0;
      if (stats['cleanSheet'] == true) cleanSheets++;

      final rating = stats['rating'] as double?;
      if (rating != null && rating > 0) ratings.add(rating);

      final advanced = stats['advancedStats'] as AdvancedStats?;
      if (advanced != null) {
        aggregatedAdvanced = aggregatedAdvanced.mergeWith(advanced);
      }
    }

    // Calculate average rating
    double? avgRating;
    if (ratings.isNotEmpty) {
      avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
    }

    print(
      'Player $playerId advanced stats: ${fixtureStats.length} matches, '
      '$totalGoals goals, $totalAssists assists, $totalMinutes mins, '
      'rating: ${avgRating?.toStringAsFixed(2)}',
    );

    return RecentMatchStats(
      matchesPlayed: fixtureStats.length,
      goals: totalGoals,
      assists: totalAssists,
      minutesPlayed: totalMinutes,
      cleanSheets: cleanSheets,
      yellowCards: totalYellowCards,
      redCards: totalRedCards,
      saves: totalSaves,
      averageRating: avgRating,
      fixturesAnalyzed: fixtureStats.length,
      advancedStats: aggregatedAdvanced,
    );
  }

  /// Clear advanced stats cache (call when refreshing data)
  void clearAdvancedStatsCache() {
    _playerFixtureStatsCache.clear();
    _currentSeasonId = null;
  }

  // ========== PAST FIXTURES METHODS ==========

  /// Get past/completed fixtures for the configured competition.
  /// Returns fixtures from the last [daysBack] days
  /// Uses /fixtures/between endpoint for efficient date range fetching
  Future<List<Map<String, dynamic>>> getPastFixtures({
    int daysBack = 30,
    int? teamId,
    bool restrictToConfiguredCompetition = true,
    List<int>? allowedLeagueIds,
    List<int>? allowedSeasonIds,
  }) async {
    debugPrint('>>> getPastFixtures called with daysBack=$daysBack <<<');

    if (!SportMonksConfig.isConfigured) {
      return [];
    }

    try {
      final end = DateTime.now();
      final start = end.subtract(Duration(days: daysBack));
      debugPrint(
        '>>> Calling /fixtures/between/${_formatDate(start)}/${_formatDate(end)} <<<',
      );

      List<Map<String, dynamic>> fixtures;

      // Detailed includes for rich fixture data
      const detailedIncludes = [
        'participants',
        'scores',
        'state',
        'league',
        'venue',
        'lineups',
        'lineups.player',
        'lineups.details.type',
        'statistics',
        'statistics.type',
        'coaches',
        'timeline',
        'sidelined',
        'sidelined.sideline',
        'weatherReport',
        'formations', // Team formations for proper lineup display
      ];

      if (teamId != null && teamId > 0) {
        final response = await _client.getFixturesByTeam(
          teamId,
          startDate: start,
          endDate: end,
          includes: detailedIncludes,
        );
        final rawFixtures = restrictToConfiguredCompetition
            ? _filterFixturesToConfiguredCompetition(response.data)
            : response.data;
        fixtures = rawFixtures.where((fixture) {
          return _matchesLeagueOrSeasonWhitelist(
            fixture,
            leagueIds: allowedLeagueIds,
            seasonIds: allowedSeasonIds,
          );
        }).toList();
      } else {
        final seasonId = await getCurrentSeasonId();
        if (seasonId != null) {
          final response = await _client.getFixturesBySeason(
            seasonId,
            includes: detailedIncludes,
            perPage: 200,
          );
          fixtures = response.data.where((fixture) {
            if (!_matchesConfiguredCompetition(fixture)) return false;
            final timestamp = fixture['starting_at_timestamp'] as int?;
            if (timestamp == null) return false;
            final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            return !date.isBefore(start) && !date.isAfter(end);
          }).toList();
        } else {
          final response = await _client.getFixturesBetweenDates(
            start,
            end,
            includes: detailedIncludes,
          );
          fixtures = _filterFixturesToConfiguredCompetition(response.data);
        }
        debugPrint('>>> API returned ${fixtures.length} fixtures <<<');
      }

      // Log all fixture states for debugging
      for (final f in fixtures) {
        final state = f['state'] as Map<String, dynamic>?;
        final participants = f['participants'] as List?;
        final homeTeam = participants?.firstWhere(
          (p) => p['meta']?['location'] == 'home',
          orElse: () => null,
        );
        final awayTeam = participants?.firstWhere(
          (p) => p['meta']?['location'] == 'away',
          orElse: () => null,
        );
        debugPrint(
          '>>> Fixture: ${homeTeam?['name']} vs ${awayTeam?['name']}, state_id=${state?['id']}, state=${state?['name'] ?? state?['short_name']} <<<',
        );
      }

      // Filter to only completed matches
      // State IDs: 5 = FT (Full Time), 3 = FT_PEN, 10 = AET, 11 = AWARDED
      final completedFixtures = fixtures.where((f) {
        final state = f['state'] as Map<String, dynamic>?;
        if (state == null) return false;

        final stateId = state['id'] as int?;
        final stateName = (state['name'] ?? state['short_name'] ?? '')
            .toString()
            .toUpperCase();

        final isCompletedById =
            stateId == 5 || stateId == 3 || stateId == 10 || stateId == 11;
        final isCompletedByName =
            stateName.contains('FT') ||
            stateName.contains('FINISHED') ||
            stateName.contains('ENDED') ||
            stateName.contains('AET');

        return isCompletedById || isCompletedByName;
      }).toList();

      debugPrint(
        '>>> After filtering: ${completedFixtures.length} completed fixtures <<<',
      );

      // Sort by date (newest first)
      completedFixtures.sort((a, b) {
        final aTimestamp = a['starting_at_timestamp'] as int? ?? 0;
        final bTimestamp = b['starting_at_timestamp'] as int? ?? 0;
        return bTimestamp.compareTo(aTimestamp);
      });

      return completedFixtures;
    } on SportMonksException {
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get detailed fixture data with lineups for a completed match
  /// This fetches all the data needed for the match details page
  Future<Map<String, dynamic>?> getCompletedMatchDetails(int fixtureId) async {
    if (!SportMonksConfig.isConfigured) {
      print('API not configured for match details');
      return null;
    }

    try {
      print('Fetching completed match details for fixture $fixtureId');

      final response = await _client.getFixtureWithDetailedStats(fixtureId);
      final fixture = response.data;

      if (fixture == null) {
        print('Fixture $fixtureId not found');
        return null;
      }

      // Verify it's a completed match
      final state = fixture['state'] as Map<String, dynamic>?;
      final stateId = state?['id'] as int?;

      if (stateId != 5 && stateId != 3 && stateId != 11) {
        print('Fixture $fixtureId is not completed (state: $stateId)');
        // Still return it, but caller can check state
      }

      print(
        'Loaded fixture $fixtureId with lineups: ${fixture['lineups'] != null}',
      );
      return fixture;
    } on SportMonksException catch (e) {
      print('SportMonks API Error fetching match details: $e');
      return null;
    } catch (e) {
      print('Error fetching match details: $e');
      return null;
    }
  }

  /// Helper to format date
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get sidelined (injured/suspended) players for a team
  ///
  /// Uses: GET /football/teams/{TEAM_ID}?include=sidelined.player
  ///
  /// Returns a list of sidelined player entries normalized for SidelinedPlayer.fromJson.
  ///
  /// [teamId] - The team ID to get sidelined players for
  /// [matchDate] - Optional match date to check if player will be back by then
  Future<List<Map<String, dynamic>>> getSidelinedPlayers(
    int teamId, {
    DateTime? matchDate,
  }) async {
    if (!SportMonksConfig.isConfigured) {
      print('Cannot fetch sidelined players: API not configured');
      return [];
    }

    try {
      print('Fetching sidelined players for team $teamId...');
      final response = await _client.getTeamWithSidelined(teamId);

      final teamData = response.data;
      if (teamData == null) {
        print('Team $teamId not found');
        return [];
      }

      // Extract sidelined array from team response
      final sidelinedList = teamData['sidelined'] as List?;
      if (sidelinedList == null || sidelinedList.isEmpty) {
        print('No sidelined players found for team $teamId');
        return [];
      }

      print('Found ${sidelinedList.length} sidelined entries for team $teamId');

      // Filter to only currently sidelined players (not completed)
      final now = DateTime.now();
      final currentlySidelined = <Map<String, dynamic>>[];

      for (final entry in sidelinedList) {
        if (entry is! Map<String, dynamic>) continue;

        // Check the 'completed' field first
        final completed = entry['completed'] as bool? ?? false;
        if (completed) {
          continue; // Player has returned
        }

        // Check dates
        final endDateStr = entry['end_date'] as String?;
        if (endDateStr != null && endDateStr.isNotEmpty) {
          final endDate = DateTime.tryParse(endDateStr);
          if (endDate != null && endDate.isBefore(now)) {
            continue; // Sideline period has ended
          }
        }

        final startDateStr = entry['start_date'] as String?;
        if (startDateStr != null && startDateStr.isNotEmpty) {
          final startDate = DateTime.tryParse(startDateStr);
          if (startDate != null && startDate.isAfter(now)) {
            continue; // Sideline hasn't started yet
          }
        }

        // Extract player info - could be nested under 'player' key
        final playerInfo = entry['player'] as Map<String, dynamic>?;
        final playerId =
            entry['player_id'] as int? ?? playerInfo?['id'] as int? ?? 0;

        if (playerId == 0) {
          print('  - Skipping sidelined entry with no player_id');
          continue;
        }

        // Normalize the entry for SidelinedPlayer.fromJson
        // Format expected by SidelinedPlayer.fromJson:
        // {
        //   'player_id': int,
        //   'sideline': { 'category', 'start_date', 'end_date', 'description' },
        //   'player': { 'display_name', 'common_name', 'image_path' }
        // }
        final normalizedEntry = <String, dynamic>{
          'player_id': playerId,
          'sideline': {
            'category': entry['category'], // "injury" or "suspended"
            'start_date': entry['start_date'],
            'end_date': entry['end_date'],
            'completed': entry['completed'],
            'description': entry['description'] ?? entry['reason'],
          },
          'player': playerInfo,
        };

        currentlySidelined.add(normalizedEntry);

        // Log details
        final category = entry['category'] ?? 'unknown';
        final playerName =
            playerInfo?['display_name'] ??
            playerInfo?['common_name'] ??
            'Player $playerId';
        print(
          '  - $playerName ($playerId): $category (end: ${endDateStr ?? "unknown"})',
        );
      }

      print('${currentlySidelined.length} players currently sidelined');
      return currentlySidelined;
    } on SportMonksException catch (e) {
      print('SportMonks API Error fetching sidelined players: $e');
      return [];
    } catch (e) {
      print('Error fetching sidelined players: $e');
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}

class _CachedUpcomingFixtures {
  final List<MatchInfo> fixtures;
  final DateTime fetchedAt;

  const _CachedUpcomingFixtures({
    required this.fixtures,
    required this.fetchedAt,
  });
}
