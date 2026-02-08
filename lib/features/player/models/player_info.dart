// Pure Dart file - no Flutter imports
// Colors are stored as int values (ARGB format)

/// Position color constants as int values (ARGB format)
class PositionColors {
  static const int goalkeeper = 0xFFFF9800; // Colors.orange
  static const int defender = 0xFF2196F3;   // Colors.blue
  static const int midfielder = 0xFF4CAF50; // Colors.green
  static const int attacker = 0xFFF44336;   // Colors.red
  static const int unknown = 0xFF9E9E9E;    // Colors.grey
}

/// Nationality information
class NationalityInfo {
  final int id;
  final String name;
  final String? officialName;
  final String? fifaName;
  final String? imagePath;

  const NationalityInfo({
    required this.id,
    required this.name,
    this.officialName,
    this.fifaName,
    this.imagePath,
  });

  factory NationalityInfo.fromJson(Map<String, dynamic> json) {
    return NationalityInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Unknown',
      officialName: json['official_name'] as String?,
      fifaName: json['fifa_name'] as String?,
      imagePath: json['image_path'] as String?,
    );
  }
}

/// Position information
class PositionInfo {
  final int id;
  final String name;
  final String code;

  const PositionInfo({
    required this.id,
    required this.name,
    required this.code,
  });

  factory PositionInfo.fromJson(Map<String, dynamic> json) {
    return PositionInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Unknown',
      code: json['code'] ?? '',
    );
  }

  /// Get icon name for position (for use with Flutter Icons)
  /// Returns the icon identifier string (e.g., 'sports_handball')
  String get iconName {
    switch (code.toLowerCase()) {
      case 'goalkeeper':
        return 'sports_handball';
      case 'defender':
        return 'shield';
      case 'midfielder':
        return 'swap_horiz';
      case 'attacker':
        return 'sports_soccer';
      default:
        return 'person';
    }
  }

  /// Get color value for position as ARGB int
  int get colorValue {
    switch (code.toLowerCase()) {
      case 'goalkeeper':
        return PositionColors.goalkeeper;
      case 'defender':
        return PositionColors.defender;
      case 'midfielder':
        return PositionColors.midfielder;
      case 'attacker':
        return PositionColors.attacker;
      default:
        return PositionColors.unknown;
    }
  }
}

/// Team squad entry
class PlayerTeamInfo {
  final int teamId;
  final int? jerseyNumber;
  final bool isCaptain;
  final String? startDate;
  final String? endDate;
  
  // Team details (populated after fetching team info)
  String? teamName;
  String? teamLogo;
  String? teamShortCode;

  PlayerTeamInfo({
    required this.teamId,
    this.jerseyNumber,
    this.isCaptain = false,
    this.startDate,
    this.endDate,
    this.teamName,
    this.teamLogo,
    this.teamShortCode,
  });

  factory PlayerTeamInfo.fromJson(Map<String, dynamic> json) {
    // Check if team data is nested (from API includes)
    final teamData = json['team'] as Map<String, dynamic>?;
    
    // Debug: Print team data if available
    if (teamData != null) {
      print('Team data from API include: ${teamData['name']}');
    }
    
    return PlayerTeamInfo(
      teamId: json['team_id'] as int? ?? 0,
      jerseyNumber: json['jersey_number'] as int?,
      isCaptain: json['captain'] as bool? ?? false,
      startDate: json['start'] as String?,
      endDate: json['end'] as String?,
      teamName: teamData?['name'] as String?,
      teamLogo: teamData?['image_path'] as String?,
      teamShortCode: teamData?['short_code'] as String?,
    );
  }

  /// Display name with fallback to team ID
  String get teamDisplay => teamName ?? 'Team #$teamId';
}

/// Transfer record
class TransferInfo {
  final int id;
  final int? fromTeamId;
  final int? toTeamId;
  final String? date;
  final int? amount;
  final bool completed;
  
  // Team names (populated after fetching team details)
  String? fromTeamName;
  String? toTeamName;
  String? fromTeamLogo;
  String? toTeamLogo;

  TransferInfo({
    required this.id,
    this.fromTeamId,
    this.toTeamId,
    this.date,
    this.amount,
    this.completed = false,
    this.fromTeamName,
    this.toTeamName,
    this.fromTeamLogo,
    this.toTeamLogo,
  });

  factory TransferInfo.fromJson(Map<String, dynamic> json) {
    return TransferInfo(
      id: json['id'] as int? ?? 0,
      fromTeamId: json['from_team_id'] as int?,
      toTeamId: json['to_team_id'] as int?,
      date: json['date'] as String?,
      amount: json['amount'] as int?,
      completed: json['completed'] as bool? ?? false,
    );
  }

  /// Get display name for from team
  String get fromTeamDisplay => fromTeamName ?? (fromTeamId != null ? 'Team $fromTeamId' : '?');
  
  /// Get display name for to team
  String get toTeamDisplay => toTeamName ?? (toTeamId != null ? 'Team $toTeamId' : '?');

  /// Format transfer amount
  String get formattedAmount {
    if (amount == null) return 'Free';
    if (amount! >= 1000000) {
      return '€${(amount! / 1000000).toStringAsFixed(1)}M';
    } else if (amount! >= 1000) {
      return '€${(amount! / 1000).toStringAsFixed(0)}K';
    }
    return '€$amount';
  }
}

/// Trophy/Award record
class TrophyInfo {
  final int id;
  final int? teamId;
  final int? leagueId;
  final int? seasonId;

  const TrophyInfo({
    required this.id,
    this.teamId,
    this.leagueId,
    this.seasonId,
  });

  factory TrophyInfo.fromJson(Map<String, dynamic> json) {
    return TrophyInfo(
      id: json['id'] as int? ?? 0,
      teamId: json['team_id'] as int?,
      leagueId: json['league_id'] as int?,
      seasonId: json['season_id'] as int?,
    );
  }
}

/// Player statistics for a season
class PlayerStatistics {
  final int id;
  final int? seasonId;
  final int? playerId;
  final int? teamId;
  final int? appearances;
  final int? lineups;
  final int? minutesPlayed;
  final int? goals;
  final int? assists;
  final int? yellowCards;
  final int? yellowRedCards;
  final int? redCards;
  final int? cleanSheets;
  final int? saves;
  final int? penaltiesScored;
  final int? penaltiesMissed;
  final int? penaltiesSaved;
  final double? rating;
  final String? seasonName;

  const PlayerStatistics({
    required this.id,
    this.seasonId,
    this.playerId,
    this.teamId,
    this.appearances,
    this.lineups,
    this.minutesPlayed,
    this.goals,
    this.assists,
    this.yellowCards,
    this.yellowRedCards,
    this.redCards,
    this.cleanSheets,
    this.saves,
    this.penaltiesScored,
    this.penaltiesMissed,
    this.penaltiesSaved,
    this.rating,
    this.seasonName,
  });

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) {
    // Handle nested details structure from SportMonks API
    final details = json['details'] as List<dynamic>? ?? [];
    
    // Build a map of type_id -> value for easier lookup
    final statsMap = <int, dynamic>{};
    for (var detail in details) {
      if (detail is Map && detail['type_id'] != null) {
        final value = detail['value'];
        // Handle different value formats
        if (value is Map) {
          statsMap[detail['type_id'] as int] = value['total'] ?? value['all'] ?? value['home'] ?? value['away'];
        } else {
          statsMap[detail['type_id'] as int] = value;
        }
      }
    }
    
    // Helper to safely get int value
    int? getInt(int typeId) {
      final value = statsMap[typeId];
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      return int.tryParse(value.toString());
    }

    // SportMonks type IDs (from actual API response):
    // 52 = Goals
    // 79 = Assists
    // 84 = Yellow Cards
    // 83 = Red Cards
    // 119 = Minutes Played
    // 194 = Clean Sheets
    // 321 = Appearances
    // 322 = Lineups
    // 214 = Penalties (taken/scored)
    
    return PlayerStatistics(
      id: json['id'] as int? ?? 0,
      seasonId: json['season_id'] as int?,
      playerId: json['player_id'] as int?,
      teamId: json['team_id'] as int?,
      appearances: getInt(321),
      lineups: getInt(322),
      minutesPlayed: getInt(119),
      goals: getInt(52),
      assists: getInt(79),
      yellowCards: getInt(84),
      yellowRedCards: getInt(85),
      redCards: getInt(83),
      cleanSheets: getInt(194),
      saves: getInt(209) ?? getInt(58),
      penaltiesScored: getInt(214),
      penaltiesMissed: getInt(215),
      penaltiesSaved: getInt(59),
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : null,
      seasonName: json['season']?['name'] as String?,
    );
  }

  /// Check if this stats object has meaningful data
  bool get hasData {
    return appearances != null ||
        goals != null ||
        assists != null ||
        minutesPlayed != null;
  }

  /// Get formatted minutes played (e.g., "1,234 min")
  String get formattedMinutes {
    if (minutesPlayed == null) return '-';
    if (minutesPlayed! >= 1000) {
      return '${(minutesPlayed! / 1000).toStringAsFixed(1)}k min';
    }
    return '$minutesPlayed min';
  }

  /// Get goal contributions (goals + assists)
  int get goalContributions => (goals ?? 0) + (assists ?? 0);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'season_id': seasonId,
      'player_id': playerId,
      'team_id': teamId,
      'details': [
        // Use correct SportMonks type IDs that match fromJson
        if (appearances != null) {'type_id': 321, 'value': {'total': appearances}},
        if (lineups != null) {'type_id': 322, 'value': {'total': lineups}},
        if (minutesPlayed != null) {'type_id': 119, 'value': {'total': minutesPlayed}},
        if (goals != null) {'type_id': 52, 'value': {'total': goals}},
        if (assists != null) {'type_id': 79, 'value': {'total': assists}},
        if (yellowCards != null) {'type_id': 84, 'value': {'total': yellowCards}},
        if (yellowRedCards != null) {'type_id': 85, 'value': {'total': yellowRedCards}},
        if (redCards != null) {'type_id': 83, 'value': {'total': redCards}},
        if (cleanSheets != null) {'type_id': 194, 'value': {'total': cleanSheets}},
        if (saves != null) {'type_id': 209, 'value': {'total': saves}},
        if (penaltiesScored != null) {'type_id': 214, 'value': {'total': penaltiesScored}},
        if (penaltiesSaved != null) {'type_id': 59, 'value': {'total': penaltiesSaved}},
      ],
      'rating': rating?.toString(),
      'season': seasonName != null ? {'name': seasonName} : null,
    };
  }
}

/// Main Player information class
class Player {
  final int id;
  final String name;
  final String displayName;
  final String commonName;
  final String? firstName;
  final String? lastName;
  final String? imagePath;
  final int? height; // in cm
  final int? weight; // in kg
  final String? dateOfBirth;
  final String? gender;
  final NationalityInfo? nationality;
  final PositionInfo? position;
  final PositionInfo? detailedPosition;
  final List<PlayerTeamInfo> teams;
  final List<TransferInfo> transfers;
  final List<TrophyInfo> trophies;
  final List<PlayerStatistics> statistics;

  const Player({
    required this.id,
    required this.name,
    required this.displayName,
    required this.commonName,
    this.firstName,
    this.lastName,
    this.imagePath,
    this.height,
    this.weight,
    this.dateOfBirth,
    this.gender,
    this.nationality,
    this.position,
    this.detailedPosition,
    this.teams = const [],
    this.transfers = const [],
    this.trophies = const [],
    this.statistics = const [],
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    // Parse nationality
    NationalityInfo? nationality;
    if (json['nationality'] is Map<String, dynamic>) {
      nationality = NationalityInfo.fromJson(json['nationality']);
    }

    // Parse position
    PositionInfo? position;
    if (json['position'] is Map<String, dynamic>) {
      position = PositionInfo.fromJson(json['position']);
    }

    // Parse detailed position
    PositionInfo? detailedPosition;
    if (json['detailedposition'] is Map<String, dynamic>) {
      detailedPosition = PositionInfo.fromJson(json['detailedposition']);
    }

    // Parse teams
    List<PlayerTeamInfo> teams = [];
    if (json['teams'] is List) {
      teams = (json['teams'] as List)
          .whereType<Map<String, dynamic>>()
          .map((t) => PlayerTeamInfo.fromJson(t))
          .toList();
    }

    // Parse transfers
    List<TransferInfo> transfers = [];
    if (json['transfers'] is List) {
      transfers = (json['transfers'] as List)
          .whereType<Map<String, dynamic>>()
          .map((t) => TransferInfo.fromJson(t))
          .toList();
    }

    // Parse trophies
    List<TrophyInfo> trophies = [];
    if (json['trophies'] is List) {
      trophies = (json['trophies'] as List)
          .whereType<Map<String, dynamic>>()
          .map((t) => TrophyInfo.fromJson(t))
          .toList();
    }

    // Parse statistics
    List<PlayerStatistics> statistics = [];
    if (json['statistics'] is List) {
      statistics = (json['statistics'] as List)
          .whereType<Map<String, dynamic>>()
          .map((s) => PlayerStatistics.fromJson(s))
          .toList();
    }

    return Player(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Unknown Player',
      displayName: json['display_name'] ?? json['name'] ?? 'Unknown',
      commonName: json['common_name'] ?? '',
      firstName: json['firstname'] as String?,
      lastName: json['lastname'] as String?,
      imagePath: json['image_path'] as String?,
      height: json['height'] as int?,
      weight: json['weight'] as int?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      nationality: nationality,
      position: position,
      detailedPosition: detailedPosition,
      teams: teams,
      transfers: transfers,
      trophies: trophies,
      statistics: statistics,
    );
  }

  /// Calculate age from date of birth
  int? get age {
    if (dateOfBirth == null) return null;
    try {
      final dob = DateTime.parse(dateOfBirth!);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  /// Get current jersey number
  int? get jerseyNumber {
    if (teams.isEmpty) return null;
    return teams.first.jerseyNumber;
  }

  /// Get current team ID
  int? get currentTeamId {
    if (teams.isEmpty) return null;
    return teams.first.teamId;
  }

  /// Get current team info
  PlayerTeamInfo? get currentTeam {
    if (teams.isEmpty) return null;
    return teams.first;
  }

  /// Get current team name
  String? get currentTeamName {
    return currentTeam?.teamName;
  }

  /// Get current team logo
  String? get currentTeamLogo {
    return currentTeam?.teamLogo;
  }

  /// Check if player is captain
  bool get isCaptain {
    if (teams.isEmpty) return false;
    return teams.first.isCaptain;
  }

  /// Get formatted height
  String get formattedHeight {
    if (height == null) return '-';
    return '$height cm';
  }

  /// Get formatted weight
  String get formattedWeight {
    if (weight == null) return '-';
    return '$weight kg';
  }

  /// Check if player has a real image (not placeholder)
  bool get hasRealImage {
    return imagePath != null &&
        imagePath!.isNotEmpty &&
        !imagePath!.contains('placeholder');
  }

  /// Check if player is a goalkeeper
  bool get isGoalkeeper {
    if (position == null) return false;
    final posName = position!.name.toLowerCase();
    final posCode = position!.code?.toLowerCase() ?? '';
    return posCode == 'g' || 
           posName.contains('goalkeeper') || 
           posName.contains('portero') ||
           posName == 'gk';
  }

  /// Get the most recent statistics (first in list, usually most recent season)
  PlayerStatistics? get latestStats {
    if (statistics.isEmpty) return null;
    // Return first stats that has meaningful data
    for (var stat in statistics) {
      if (stat.hasData) return stat;
    }
    return statistics.first;
  }

  /// Get statistics for a specific season by ID
  PlayerStatistics? getStatsForSeason(int seasonId) {
    if (statistics.isEmpty) return null;
    
    // Debug: print available season IDs
    print('Looking for season ID: $seasonId');
    print('Available stats: ${statistics.map((s) => "ID:${s.seasonId} Name:${s.seasonName} Goals:${s.goals}").join(", ")}');
    
    try {
      return statistics.firstWhere(
        (stat) => stat.seasonId == seasonId && stat.hasData,
      );
    } catch (e) {
      // No matching season found
      print('No stats found for season $seasonId');
      return null;
    }
  }

  /// Get statistics for the current season, with fallback to latest stats
  /// [currentSeasonId] - The ID of the current tournament (e.g., Clausura 2026)
  PlayerStatistics? getStatsForCurrentSeason(int? currentSeasonId) {
    if (statistics.isEmpty) {
      return null;
    }
    
    // If we have a current season ID, try to find stats for that season
    if (currentSeasonId != null) {
      final seasonStats = getStatsForSeason(currentSeasonId);
      if (seasonStats != null) {
        return seasonStats;
      }
    }
    
    // Fallback to latest stats
    return latestStats;
  }

  /// Get all available season IDs from statistics
  List<int> get availableSeasonIds {
    return statistics
        .where((stat) => stat.seasonId != null && stat.hasData)
        .map((stat) => stat.seasonId!)
        .toSet()
        .toList();
  }

  /// Get total career goals from all statistics
  int get careerGoals {
    return statistics.fold(0, (sum, stat) => sum + (stat.goals ?? 0));
  }

  /// Get total career assists from all statistics
  int get careerAssists {
    return statistics.fold(0, (sum, stat) => sum + (stat.assists ?? 0));
  }

  /// Get total career appearances from all statistics
  int get careerAppearances {
    return statistics.fold(0, (sum, stat) => sum + (stat.appearances ?? 0));
  }

  /// Parse a list of players from JSON
  static List<Player> fromJsonList(List list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => Player.fromJson(json))
        .toList();
  }

  /// Convert player to JSON for caching
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'common_name': commonName,
      'firstname': firstName,
      'lastname': lastName,
      'image_path': imagePath,
      'height': height,
      'weight': weight,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'nationality': nationality != null
          ? {
              'id': nationality!.id,
              'name': nationality!.name,
              'official_name': nationality!.officialName,
              'fifa_name': nationality!.fifaName,
              'image_path': nationality!.imagePath,
            }
          : null,
      'position': position != null
          ? {
              'id': position!.id,
              'name': position!.name,
              'code': position!.code,
            }
          : null,
      'detailedposition': detailedPosition != null
          ? {
              'id': detailedPosition!.id,
              'name': detailedPosition!.name,
              'code': detailedPosition!.code,
            }
          : null,
      'teams': teams
          .map((t) => {
                'team_id': t.teamId,
                'jersey_number': t.jerseyNumber,
                'captain': t.isCaptain,
                'start': t.startDate,
                'end': t.endDate,
                'team': t.teamName != null
                    ? {
                        'name': t.teamName,
                        'image_path': t.teamLogo,
                        'short_code': t.teamShortCode,
                      }
                    : null,
              })
          .toList(),
      'transfers': transfers
          .map((t) => {
                'id': t.id,
                'from_team_id': t.fromTeamId,
                'to_team_id': t.toTeamId,
                'date': t.date,
                'amount': t.amount,
                'completed': t.completed,
              })
          .toList(),
      'trophies': trophies
          .map((t) => {
                'id': t.id,
                'team_id': t.teamId,
                'league_id': t.leagueId,
                'season_id': t.seasonId,
              })
          .toList(),
      'statistics': statistics.map((s) => s.toJson()).toList(),
    };
  }
}

