import 'package:fantacy11/api/sportmonks_client.dart';
import 'package:fantacy11/api/sportmonks_config.dart';

/// Model representing a stage/tournament within a season (e.g., Apertura, Clausura)
class StageInfo {
  final int id;
  final String name;
  final int seasonId;
  final bool isCurrent;
  final bool isFinished;
  final DateTime? startDate;
  final DateTime? endDate;

  const StageInfo({
    required this.id,
    required this.name,
    required this.seasonId,
    this.isCurrent = false,
    this.isFinished = false,
    this.startDate,
    this.endDate,
  });

  factory StageInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    return StageInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Unknown Stage',
      seasonId: json['season_id'] as int? ?? 0,
      isCurrent: json['is_current'] as bool? ?? false,
      isFinished: json['finished'] as bool? ?? false,
      startDate: parseDate(json['starting_at'] as String?),
      endDate: parseDate(json['ending_at'] as String?),
    );
  }

  /// Check if this stage is currently active
  bool get isActive {
    if (isFinished) return false;
    if (startDate == null) return isCurrent;
    
    final now = DateTime.now();
    if (now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    return true;
  }
}

/// Model representing a football season (full year, contains multiple stages)
class SeasonInfo {
  final int id;
  final String name;
  final int leagueId;
  final bool isCurrent;
  final bool isFinished;
  final DateTime? startDate;
  final DateTime? endDate;
  final StageInfo? currentStage;
  final List<StageInfo> stages;

  const SeasonInfo({
    required this.id,
    required this.name,
    required this.leagueId,
    this.isCurrent = false,
    this.isFinished = false,
    this.startDate,
    this.endDate,
    this.currentStage,
    this.stages = const [],
  });

  factory SeasonInfo.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return null;
      }
    }

    // Parse current stage
    StageInfo? currentStage;
    final currentStageJson = json['currentstage'] as Map<String, dynamic>?;
    if (currentStageJson != null) {
      currentStage = StageInfo.fromJson(currentStageJson);
    }

    // Parse all stages
    List<StageInfo> stages = [];
    final stagesJson = json['stages'] as List?;
    if (stagesJson != null) {
      stages = stagesJson
          .whereType<Map<String, dynamic>>()
          .map((s) => StageInfo.fromJson(s))
          .toList();
    }

    return SeasonInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Unknown Season',
      leagueId: json['league_id'] as int? ?? 0,
      isCurrent: json['is_current'] as bool? ?? false,
      isFinished: json['finished'] as bool? ?? false,
      startDate: parseDate(json['starting_at'] as String?),
      endDate: parseDate(json['ending_at'] as String?),
      currentStage: currentStage,
      stages: stages,
    );
  }

  /// Check if this season is currently active (started but not finished)
  bool get isActive {
    if (isFinished) return false;
    if (startDate == null) return isCurrent;
    
    final now = DateTime.now();
    if (now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    return true;
  }
}

/// Repository for managing season/tournament data
/// Handles Liga MX's Apertura/Clausura tournament structure
class SeasonsRepository {
  final SportMonksClient _client;
  
  // Cache for current season and stage
  static SeasonInfo? _currentSeason;
  static StageInfo? _currentStage;
  static DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(hours: 6);
  
  // Liga MX League ID in SportMonks
  static const int ligaMxLeagueId = 262;
  
  SeasonsRepository({SportMonksClient? client}) 
      : _client = client ?? SportMonksClient();

  /// Get the current active Liga MX season with stage info
  Future<SeasonInfo?> getCurrentLigaMxSeason({bool forceRefresh = false}) async {
    // Return cached if still valid
    if (!forceRefresh && 
        _currentSeason != null && 
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      print('Returning cached current season: ${_currentSeason!.name}');
      if (_currentSeason!.currentStage != null) {
        print('Current stage: ${_currentSeason!.currentStage!.name} (ID: ${_currentSeason!.currentStage!.id})');
      }
      return _currentSeason;
    }

    if (!SportMonksConfig.isConfigured) {
      print('API not configured, using fallback season');
      return _getFallbackSeason();
    }

    try {
      print('Fetching Liga MX seasons from API...');
      
      // Get all seasons for Liga MX with stages included
      final response = await _client.getSeasonsByLeague(
        ligaMxLeagueId,
        includes: ['currentStage', 'stages'],
      );

      if (response.data.isEmpty) {
        print('No seasons found for Liga MX');
        return _getFallbackSeason();
      }

      // Parse seasons and find the current one
      final seasons = response.data
          .map((json) => SeasonInfo.fromJson(json))
          .toList();

      // Sort by start date descending (newest first)
      seasons.sort((a, b) {
        if (a.startDate == null && b.startDate == null) return 0;
        if (a.startDate == null) return 1;
        if (b.startDate == null) return -1;
        return b.startDate!.compareTo(a.startDate!);
      });

      // Find the current active season
      SeasonInfo? currentSeason;
      
      // First, check for explicitly marked current season
      currentSeason = seasons.where((s) => s.isCurrent).firstOrNull;
      
      // If not found, find the most recent active (started but not finished) season
      currentSeason ??= seasons.where((s) => s.isActive).firstOrNull;
      
      // If still not found, take the most recent one that isn't finished
      currentSeason ??= seasons.where((s) => !s.isFinished).firstOrNull;
      
      // Last resort: take the most recent season
      currentSeason ??= seasons.firstOrNull;

      if (currentSeason != null) {
        print('Found current season: ${currentSeason.name} (ID: ${currentSeason.id})');
        if (currentSeason.currentStage != null) {
          print('Current stage: ${currentSeason.currentStage!.name} (ID: ${currentSeason.currentStage!.id})');
          _currentStage = currentSeason.currentStage;
        }
        print('Available stages: ${currentSeason.stages.map((s) => "${s.name}(${s.id})").join(", ")}');
        _currentSeason = currentSeason;
        _lastFetchTime = DateTime.now();
        return currentSeason;
      }

      return _getFallbackSeason();
    } on SportMonksException catch (e) {
      print('SportMonks API Error fetching seasons: $e');
      return _getFallbackSeason();
    } catch (e) {
      print('Error fetching current season: $e');
      return _getFallbackSeason();
    }
  }

  /// Get the current stage/tournament (e.g., Clausura 2026)
  Future<StageInfo?> getCurrentStage() async {
    final season = await getCurrentLigaMxSeason();
    return season?.currentStage ?? _currentStage;
  }

  /// Get the current stage ID
  Future<int?> getCurrentStageId() async {
    final stage = await getCurrentStage();
    return stage?.id;
  }

  /// Get the current stage name (e.g., "Clausura")
  Future<String?> getCurrentStageName() async {
    final stage = await getCurrentStage();
    return stage?.name;
  }

  /// Get a specific season by ID
  Future<SeasonInfo?> getSeasonById(int seasonId) async {
    if (!SportMonksConfig.isConfigured) {
      return null;
    }

    try {
      final response = await _client.getSeasonById(
        seasonId,
        includes: ['currentStage', 'stages'],
      );

      if (response.data == null) return null;
      return SeasonInfo.fromJson(response.data!);
    } on SportMonksException catch (e) {
      print('SportMonks API Error: $e');
      return null;
    }
  }

  /// Get the current season ID (cached for quick access)
  Future<int?> getCurrentSeasonId() async {
    final season = await getCurrentLigaMxSeason();
    return season?.id;
  }

  /// Fallback season when API is unavailable
  SeasonInfo _getFallbackSeason() {
    print('WARNING: Using fallback season data');
    return SeasonInfo(
      id: 23744, // Liga MX 2025/2026 season ID (update as needed)
      name: '2025/2026',
      leagueId: ligaMxLeagueId,
      isCurrent: true,
      currentStage: const StageInfo(
        id: 77471483, // Clausura 2026 stage ID (update as needed)
        name: 'Clausura',
        seasonId: 23744,
        isCurrent: true,
      ),
    );
  }

  /// Clear cached season data
  void clearCache() {
    _currentSeason = null;
    _currentStage = null;
    _lastFetchTime = null;
  }

  void dispose() {
    _client.dispose();
  }
}

