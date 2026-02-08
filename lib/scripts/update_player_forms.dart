// scripts/update_player_forms.dart
// (This remains largely the same, but imports are now clean)

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/features/fantasy/fantasy_points_predictor.dart'; // Ensure pure Dart

// Configuration (unchanged)
const int _batchSize = 10;
const Duration _delayBetweenBatches = Duration(seconds: 2);
const Duration _delayBetweenPlayers = Duration(milliseconds: 500);

// Default values (unchanged)
const String _defaultApiToken = 'dummy_token_for_local_dev';
const int _defaultSeasonId = 25539;

Future<void> main(List<String> args) async {
  // Argument parsing (unchanged)
  String apiToken = Platform.environment['SPORTSMONKS_API_TOKEN'] ?? _defaultApiToken;
  int seasonId = int.tryParse(Platform.environment['SPORTSMONKS_SEASON_ID'] ?? '') ?? _defaultSeasonId;
  for (final arg in args) {
    if (arg.startsWith('--api-token=')) {
      apiToken = arg.substring('--api-token='.length);
    } else if (arg.startsWith('--season-id=')) {
      seasonId = int.tryParse(arg.substring('--season-id='.length)) ?? seasonId;
    }
  }

  // Final check for critical values (unchanged)
  if (apiToken == _defaultApiToken && apiToken == 'dummy_token_for_local_dev') {
    print('⚠️ WARNING: Using default/dummy API token. This is likely not intended for production.');
    print('Ensure SPORTSMONKS_API_TOKEN environment variable is set for Cloud Run deployment.');
  }
  if (seasonId == _defaultSeasonId && !Platform.environment.containsKey('SPORTSMONKS_SEASON_ID')) {
    print('⚠️ WARNING: Using default Season ID. Ensure SPORTSMONKS_SEASON_ID environment variable is set for Cloud Run deployment.');
  }

  print('🏃 Starting Player Forms Batch Job');
  print('📅 ${DateTime.now()}');
  print('🔑 API Token: ${apiToken.substring(0, 5)}...${apiToken.substring(apiToken.length - 5)}');
  print('🏆 Season ID: $seasonId');
  print('');

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    final fixturesRepository = FixturesRepository(
      apiToken: apiToken,
      seasonId: seasonId,
    );

    print('📥 Loading players from Firestore...');
    // Make sure your player documents in Firestore have the 'id' field as an int
    // and 'team.id' if denormalized, or the 'statistics' array if not.
    final playersSnapshot = await firestore.collection('players').get();
    final players = playersSnapshot.docs;
    print('📊 Found ${players.length} players');

    int processed = 0;
    int success = 0;
    int failed = 0;
    int skipped = 0;

    for (int i = 0; i < players.length; i += _batchSize) {
      final batchEnd = (i + _batchSize).clamp(0, players.length);
      final batch = players.sublist(i, batchEnd);

      print('\n📦 Processing batch ${(i ~/ _batchSize) + 1}/${(players.length / _batchSize).ceil()}');

      for (final playerDoc in batch) {
        processed++;

        try {
          final data = playerDoc.data();
          final playerId = data['id'] as int?;

          int? teamId;
          // Prioritize denormalized 'team.id' if available (more reliable)
          if (data.containsKey('team') && data['team'] is Map) {
            teamId = data['team']['id'] as int?;
          } else {
            // Fallback to finding from 'statistics' array if 'team' is not denormalized
            final statistics = data['statistics'] as List<dynamic>?;
            if (statistics != null && statistics.isNotEmpty) {
              statistics.sort((a, b) {
                final aSeasonId = a['season_id'] as int? ?? 0;
                final bSeasonId = b['season_id'] as int? ?? 0;
                return bSeasonId.compareTo(aSeasonId);
              });
              teamId = statistics.first['team_id'] as int?;
            }
          }

          if (playerId == null || teamId == null || teamId == 0) {
            print('  ⏭️  Skipping ${data['display_name'] ?? 'Unknown'} (ID: $playerId) - no valid team ID ($teamId)');
            skipped++;
            continue;
          }

          final playerName = data['display_name'] ?? 'Player $playerId';
          print('  🔄 Processing: $playerName (#$playerId) for team $teamId');

          final recentStats = await fixturesRepository.getPlayerRecentStats(
            playerId,
            teamId,
          );

          if (recentStats == null) {
            print('     ⚠️  No form data calculated for $playerName');
            skipped++;
            continue;
          }

          await _saveFormToFirestore(firestore, playerId, recentStats);

          print('     ✅ Saved: ${recentStats.matchesPlayed} matches, ${recentStats.goals}G ${recentStats.assists}A');
          success++;

          await Future.delayed(_delayBetweenPlayers);

        } catch (e, stack) {
          final playerName = (playerDoc.data() as Map<String, dynamic>)['display_name'] ?? 'Unknown Player';
          print('     ❌ Error processing $playerName: $e');
          print('     Stack: $stack');
          failed++;
        }
      }

      if (batchEnd < players.length) {
        print('\n⏳ Waiting before next batch...');
        await Future.delayed(_delayBetweenBatches);
      }
    }

    print('\n');
    print('═══════════════════════════════════════');
    print('📊 BATCH JOB COMPLETE');
    print('═══════════════════════════════════════');
    print('Total Players: $processed');
    print('✅ Success: $success');
    print('⏭️  Skipped: $skipped');
    print('❌ Failed: $failed');
    print('═══════════════════════════════════════');
    print('📅 Completed at: ${DateTime.now()}');

    fixturesRepository.dispose();
    exit(0);

  } catch (e, stack) {
    print('❌ Fatal error in main: $e');
    print(stack);
    exit(1);
  }
}

Future<void> _saveFormToFirestore(
    FirebaseFirestore firestore,
    int playerId,
    RecentMatchStats form,
    ) async {
  final formData = <String, dynamic>{
    'matchesPlayed': form.matchesPlayed,
    'goals': form.goals,
    'assists': form.assists,
    'yellowCards': form.yellowCards,
    'redCards': form.redCards,
    'minutesPlayed': form.minutesPlayed,
    'cleanSheets': form.cleanSheets,
    'saves': form.saves,
    'averageRating': form.averageRating,
    'fixturesAnalyzed': form.fixturesAnalyzed,
  };

  if (form.advancedStats != null) {
    formData['advancedStats'] = {
      'accuratePasses': form.advancedStats!.accuratePasses,
      'keyPasses': form.advancedStats!.keyPasses,
      'tackles': form.advancedStats!.tackles,
      'interceptions': form.advancedStats!.interceptions,
      'clearances': form.advancedStats!.clearances,
      'blocks': form.advancedStats!.blocks,
      'duelsWon': form.advancedStats!.duelsWon,
      'totalDuels': form.advancedStats!.totalDuels,
      'aerialsWon': form.advancedStats!.aerialsWon,
      'fouls': form.advancedStats!.fouls,
      'foulsDrawn': form.advancedStats!.foulsDrawn,
      'shotsTotal': form.advancedStats!.shotsTotal,
      'shotsOnTarget': form.advancedStats!.shotsOnTarget,
      'bigChancesCreated': form.advancedStats!.bigChancesCreated,
      'bigChancesMissed': form.advancedStats!.bigChancesMissed,
      'dribbledPast': form.advancedStats!.dribbledPast,
      'dispossessed': form.advancedStats!.dispossessed,
      'saves': form.advancedStats!.saves,
      'savesInsideBox': form.advancedStats!.savesInsideBox,
      'longBalls': form.advancedStats!.longBalls,
      'longBallsWon': form.advancedStats!.longBallsWon,
      'throughBalls': form.advancedStats!.throughBalls,
      'throughBallsWon': form.advancedStats!.throughBallsWon,
      'accurateCrosses': form.advancedStats!.accurateCrosses,
      'totalCrosses': form.advancedStats!.totalCrosses,
      'hitWoodwork': form.advancedStats!.hitWoodwork,
      'offsides': form.advancedStats!.offsides,
      'goalsConceeded': form.advancedStats!.goalsConceeded,
      'ratings': form.advancedStats!.ratings,
    };
  }

  await firestore.collection('player_forms').doc(playerId.toString()).set({
    'playerId': playerId,
    'formData': formData,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
