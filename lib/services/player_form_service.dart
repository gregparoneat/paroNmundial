import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/features/player/models/player_form.dart';
import 'package:fantacy11/services/cache_service.dart';
// Using print instead of print for logging

/// Service for managing player form data
/// Form data is pre-calculated by batch jobs and stored in Firestore
/// This eliminates the need to calculate form on-the-fly when viewing player profiles
class PlayerFormService {
  final FirebaseFirestore _firestore;
  final CacheService _cacheService;
  final FixturesRepository _fixturesRepository;
  
  // Firestore collection for player form data
  static const String _formCollection = 'player_forms';
  
  // Cache validity: 3 days (batch runs Mon/Fri, so data is valid for ~3-4 days)
  static const Duration _cacheValidity = Duration(days: 3);
  
  /// Create a PlayerFormService
  /// 
  /// Optional parameters for batch jobs or scripts:
  /// - [apiToken]: Custom API token to use instead of SportMonksConfig
  /// - [seasonId]: Season ID to use for queries
  PlayerFormService({
    String? apiToken,
    int? seasonId,
    FirebaseFirestore? firestore,
    CacheService? cacheService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _cacheService = cacheService ?? CacheService(),
       _fixturesRepository = FixturesRepository(
         apiToken: apiToken,
         seasonId: seasonId,
       );
  
  /// Get player form data - checks Hive cache first, then Firestore
  /// Returns null if no data available (triggers on-demand calculation)
  Future<RecentMatchStats?> getPlayerForm(int playerId) async {
    try {
      // Step 1: Check Hive cache
      final cachedForm = _cacheService.getPlayerFormStats(playerId);
      if (cachedForm != null) {
        final cachedAt = cachedForm['cachedAt'] as int?;
        if (cachedAt != null) {
          final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedAt);
          if (DateTime.now().difference(cacheTime) < _cacheValidity) {
            print('PlayerFormService: Using Hive cache for player $playerId');
            return _parseFormFromCache(cachedForm);
          }
        }
      }
      
      // Step 2: Check Firestore
      final firestoreForm = await _getFormFromFirestore(playerId);
      if (firestoreForm != null) {
        // Cache in Hive for faster subsequent access
        await _cacheFormToHive(playerId, firestoreForm);
        return firestoreForm;
      }
      
      // Step 3: No pre-calculated data available
      print('PlayerFormService: No pre-calculated form for player $playerId');
      return null;
      
    } catch (e) {
      print('PlayerFormService: Error getting form for player $playerId: $e');
      return null;
    }
  }
  
  /// Check if we have fresh form data (either in cache or Firestore)
  Future<bool> hasValidFormData(int playerId) async {
    // Check Hive first
    final cachedForm = _cacheService.getPlayerFormStats(playerId);
    if (cachedForm != null) {
      final cachedAt = cachedForm['cachedAt'] as int?;
      if (cachedAt != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(cachedAt);
        if (DateTime.now().difference(cacheTime) < _cacheValidity) {
          return true;
        }
      }
    }
    
    // Check Firestore
    try {
      final doc = await _firestore.collection(_formCollection).doc(playerId.toString()).get();
      if (doc.exists) {
        final data = doc.data();
        final updatedAt = data?['updatedAt'] as Timestamp?;
        if (updatedAt != null) {
          final updateTime = updatedAt.toDate();
          return DateTime.now().difference(updateTime) < _cacheValidity;
        }
      }
    } catch (e) {
      print('PlayerFormService: Error checking Firestore: $e');
    }
    
    return false;
  }
  
  /// Get form data from Firestore
  Future<RecentMatchStats?> _getFormFromFirestore(int playerId) async {
    try {
      final doc = await _firestore.collection(_formCollection).doc(playerId.toString()).get();
      
      if (!doc.exists) {
        print('PlayerFormService: No Firestore document for player $playerId');
        return null;
      }
      
      final data = doc.data()!;
      
      // Check if data is still valid
      final updatedAt = data['updatedAt'] as Timestamp?;
      if (updatedAt != null) {
        final updateTime = updatedAt.toDate();
        if (DateTime.now().difference(updateTime) > _cacheValidity) {
          print('PlayerFormService: Firestore data for player $playerId is stale');
          return null;
        }
      }
      
      print('PlayerFormService: Using Firestore form data for player $playerId');
      return _parseFormFromFirestore(data);
      
    } catch (e) {
      print('PlayerFormService: Error fetching from Firestore: $e');
      return null;
    }
  }
  
  /// Parse form data from Firestore document
  RecentMatchStats? _parseFormFromFirestore(Map<String, dynamic> data) {
    try {
      final formData = data['formData'] as Map<String, dynamic>?;
      if (formData == null) return null;
      
      // Parse advanced stats if present
      AdvancedStats? advancedStats;
      final advancedData = formData['advancedStats'] as Map<String, dynamic>?;
      if (advancedData != null) {
        advancedStats = AdvancedStats(
          accuratePasses: advancedData['accuratePasses'] as int? ?? 0,
          keyPasses: advancedData['keyPasses'] as int? ?? 0,
          tackles: advancedData['tackles'] as int? ?? 0,
          interceptions: advancedData['interceptions'] as int? ?? 0,
          clearances: advancedData['clearances'] as int? ?? 0,
          blocks: advancedData['blocks'] as int? ?? 0,
          duelsWon: advancedData['duelsWon'] as int? ?? 0,
          totalDuels: advancedData['totalDuels'] as int? ?? 0,
          aerialsWon: advancedData['aerialsWon'] as int? ?? 0,
          fouls: advancedData['fouls'] as int? ?? 0,
          foulsDrawn: advancedData['foulsDrawn'] as int? ?? 0,
          shotsTotal: advancedData['shotsTotal'] as int? ?? 0,
          shotsOnTarget: advancedData['shotsOnTarget'] as int? ?? 0,
          bigChancesCreated: advancedData['bigChancesCreated'] as int? ?? 0,
          bigChancesMissed: advancedData['bigChancesMissed'] as int? ?? 0,
          dribbledPast: advancedData['dribbledPast'] as int? ?? 0,
          dispossessed: advancedData['dispossessed'] as int? ?? 0,
          saves: advancedData['saves'] as int? ?? 0,
          savesInsideBox: advancedData['savesInsideBox'] as int? ?? 0,
          longBalls: advancedData['longBalls'] as int? ?? 0,
          longBallsWon: advancedData['longBallsWon'] as int? ?? 0,
          throughBalls: advancedData['throughBalls'] as int? ?? 0,
          throughBallsWon: advancedData['throughBallsWon'] as int? ?? 0,
          accurateCrosses: advancedData['accurateCrosses'] as int? ?? 0,
          totalCrosses: advancedData['totalCrosses'] as int? ?? 0,
          hitWoodwork: advancedData['hitWoodwork'] as int? ?? 0,
          offsides: advancedData['offsides'] as int? ?? 0,
          goalsConceeded: advancedData['goalsConceeded'] as int? ?? 0,
          ratings: (advancedData['ratings'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ?? [],
        );
      }
      
      return RecentMatchStats(
        matchesPlayed: formData['matchesPlayed'] as int? ?? 0,
        goals: formData['goals'] as int? ?? 0,
        assists: formData['assists'] as int? ?? 0,
        yellowCards: formData['yellowCards'] as int? ?? 0,
        redCards: formData['redCards'] as int? ?? 0,
        minutesPlayed: formData['minutesPlayed'] as int? ?? 0,
        cleanSheets: formData['cleanSheets'] as int? ?? 0,
        saves: formData['saves'] as int? ?? 0,
        averageRating: (formData['averageRating'] as num?)?.toDouble(),
        fixturesAnalyzed: formData['fixturesAnalyzed'] as int?,
        advancedStats: advancedStats,
      );
    } catch (e) {
      print('PlayerFormService: Error parsing Firestore form: $e');
      return null;
    }
  }
  
  /// Parse form data from Hive cache
  RecentMatchStats? _parseFormFromCache(Map<String, dynamic> data) {
    try {
      // Parse advanced stats if present
      AdvancedStats? advancedStats;
      final advancedData = data['advancedStats'] as Map<String, dynamic>?;
      if (advancedData != null) {
        advancedStats = AdvancedStats(
          accuratePasses: advancedData['accuratePasses'] as int? ?? 0,
          keyPasses: advancedData['keyPasses'] as int? ?? 0,
          tackles: advancedData['tackles'] as int? ?? 0,
          interceptions: advancedData['interceptions'] as int? ?? 0,
          clearances: advancedData['clearances'] as int? ?? 0,
          blocks: advancedData['blocks'] as int? ?? 0,
          duelsWon: advancedData['duelsWon'] as int? ?? 0,
          totalDuels: advancedData['totalDuels'] as int? ?? 0,
          aerialsWon: advancedData['aerialsWon'] as int? ?? 0,
          fouls: advancedData['fouls'] as int? ?? 0,
          foulsDrawn: advancedData['foulsDrawn'] as int? ?? 0,
          shotsTotal: advancedData['shotsTotal'] as int? ?? 0,
          shotsOnTarget: advancedData['shotsOnTarget'] as int? ?? 0,
          bigChancesCreated: advancedData['bigChancesCreated'] as int? ?? 0,
          bigChancesMissed: advancedData['bigChancesMissed'] as int? ?? 0,
          dribbledPast: advancedData['dribbledPast'] as int? ?? 0,
          dispossessed: advancedData['dispossessed'] as int? ?? 0,
          saves: advancedData['saves'] as int? ?? 0,
          savesInsideBox: advancedData['savesInsideBox'] as int? ?? 0,
          longBalls: advancedData['longBalls'] as int? ?? 0,
          longBallsWon: advancedData['longBallsWon'] as int? ?? 0,
          throughBalls: advancedData['throughBalls'] as int? ?? 0,
          throughBallsWon: advancedData['throughBallsWon'] as int? ?? 0,
          accurateCrosses: advancedData['accurateCrosses'] as int? ?? 0,
          totalCrosses: advancedData['totalCrosses'] as int? ?? 0,
          hitWoodwork: advancedData['hitWoodwork'] as int? ?? 0,
          offsides: advancedData['offsides'] as int? ?? 0,
          goalsConceeded: advancedData['goalsConceeded'] as int? ?? 0,
          ratings: (advancedData['ratings'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ?? [],
        );
      }
      
      return RecentMatchStats(
        matchesPlayed: data['matchesPlayed'] as int? ?? 0,
        goals: data['goals'] as int? ?? 0,
        assists: data['assists'] as int? ?? 0,
        yellowCards: data['yellowCards'] as int? ?? 0,
        redCards: data['redCards'] as int? ?? 0,
        minutesPlayed: data['minutesPlayed'] as int? ?? 0,
        cleanSheets: data['cleanSheets'] as int? ?? 0,
        saves: data['saves'] as int? ?? 0,
        averageRating: (data['averageRating'] as num?)?.toDouble(),
        fixturesAnalyzed: data['fixturesAnalyzed'] as int?,
        advancedStats: advancedStats,
      );
    } catch (e) {
      print('PlayerFormService: Error parsing cache form: $e');
      return null;
    }
  }
  
  /// Cache form data to Hive
  Future<void> _cacheFormToHive(int playerId, RecentMatchStats form) async {
    final cacheData = <String, dynamic>{
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
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
    };
    
    if (form.advancedStats != null) {
      cacheData['advancedStats'] = {
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
    
    _cacheService.savePlayerFormStats(playerId, cacheData);
  }
  
  /// Sync all player forms from Firestore to Hive cache
  /// Call this on app startup to pre-load form data
  Future<void> syncFormsFromFirestore() async {
    try {
      print('PlayerFormService: Syncing player forms from Firestore...');
      
      final snapshot = await _firestore.collection(_formCollection).get();
      
      int synced = 0;
      for (final doc in snapshot.docs) {
        final playerId = int.tryParse(doc.id);
        if (playerId == null) continue;
        
        final form = _parseFormFromFirestore(doc.data());
        if (form != null) {
          await _cacheFormToHive(playerId, form);
          synced++;
        }
      }
      
      print('PlayerFormService: Synced $synced player forms to Hive cache');
    } catch (e) {
      print('PlayerFormService: Error syncing forms: $e');
    }
  }
  
  // ============================================================
  // BATCH JOB METHODS - For running form calculation batch jobs
  // These can be called from a Cloud Function or standalone script
  // ============================================================
  
  /// Calculate and save form for a single player
  /// Used by batch jobs to update Firestore
  Future<bool> calculateAndSavePlayerForm(int playerId, int teamId) async {
    try {
      print('BatchJob: Calculating form for player $playerId');
      
      final recentStats = await _fixturesRepository.getPlayerRecentStats(
        playerId,
        teamId,
      );
      
      if (recentStats == null) {
        print('BatchJob: No form data calculated for player $playerId');
        return false;
      }
      
      // Save to Firestore
      await _saveFormToFirestore(playerId, recentStats);
      
      print('BatchJob: Saved form for player $playerId - ${recentStats.matchesPlayed} matches');
      return true;
      
    } catch (e) {
      print('BatchJob: Error calculating form for player $playerId: $e');
      return false;
    }
  }
  
  /// Save form data to Firestore
  Future<void> _saveFormToFirestore(int playerId, RecentMatchStats form) async {
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
    
    await _firestore.collection(_formCollection).doc(playerId.toString()).set({
      'playerId': playerId,
      'formData': formData,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
  
  void dispose() {
    _fixturesRepository.dispose();
  }
}

