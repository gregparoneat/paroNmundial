import 'package:flutter/material.dart';

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

  /// Get icon for position
  IconData get icon {
    switch (code.toLowerCase()) {
      case 'goalkeeper':
        return Icons.sports_handball;
      case 'defender':
        return Icons.shield;
      case 'midfielder':
        return Icons.swap_horiz;
      case 'attacker':
        return Icons.sports_soccer;
      default:
        return Icons.person;
    }
  }

  /// Get color for position
  Color get color {
    switch (code.toLowerCase()) {
      case 'goalkeeper':
        return Colors.orange;
      case 'defender':
        return Colors.blue;
      case 'midfielder':
        return Colors.green;
      case 'attacker':
        return Colors.red;
      default:
        return Colors.grey;
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

  const PlayerTeamInfo({
    required this.teamId,
    this.jerseyNumber,
    this.isCaptain = false,
    this.startDate,
    this.endDate,
  });

  factory PlayerTeamInfo.fromJson(Map<String, dynamic> json) {
    return PlayerTeamInfo(
      teamId: json['team_id'] as int? ?? 0,
      jerseyNumber: json['jersey_number'] as int?,
      isCaptain: json['captain'] as bool? ?? false,
      startDate: json['start'] as String?,
      endDate: json['end'] as String?,
    );
  }
}

/// Transfer record
class TransferInfo {
  final int id;
  final int? fromTeamId;
  final int? toTeamId;
  final String? date;
  final int? amount;
  final bool completed;

  const TransferInfo({
    required this.id,
    this.fromTeamId,
    this.toTeamId,
    this.date,
    this.amount,
    this.completed = false,
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

  /// Parse a list of players from JSON
  static List<Player> fromJsonList(List list) {
    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => Player.fromJson(json))
        .toList();
  }
}

