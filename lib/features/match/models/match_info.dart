import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Venue information for a match
class VenueInfo {
  final String name;
  final String? address;
  final String? cityName;
  final int? capacity;
  final String? imagePath;
  final String? surface;

  const VenueInfo({
    required this.name,
    this.address,
    this.cityName,
    this.capacity,
    this.imagePath,
    this.surface,
  });

  factory VenueInfo.fromJson(Map<String, dynamic> json) {
    return VenueInfo(
      name: json['name'] ?? 'Unknown Venue',
      address: json['address'] as String?,
      cityName: json['city_name'] as String?,
      capacity: json['capacity'] as int?,
      imagePath: json['image_path'] as String?,
      surface: json['surface'] as String?,
    );
  }
}

/// Coach information
class CoachInfo {
  final int id;
  final String name;
  final String displayName;
  final String? imagePath;
  final String? dateOfBirth;
  final int? teamId; // participant_id to match with team

  const CoachInfo({
    required this.id,
    required this.name,
    required this.displayName,
    this.imagePath,
    this.dateOfBirth,
    this.teamId,
  });

  factory CoachInfo.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>?;
    return CoachInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? json['common_name'] ?? 'Unknown',
      displayName: json['display_name'] ?? json['common_name'] ?? 'Unknown',
      imagePath: json['image_path'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      teamId: meta?['participant_id'] as int?,
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
}

/// Team participant info
class TeamParticipant {
  final int id;
  final String name;
  final String shortCode;
  final String? imagePath;
  final int? founded;
  final int? leaguePosition;
  final bool isHome;

  const TeamParticipant({
    required this.id,
    required this.name,
    required this.shortCode,
    this.imagePath,
    this.founded,
    this.leaguePosition,
    required this.isHome,
  });

  factory TeamParticipant.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>?;
    return TeamParticipant(
      id: json['id'] as int? ?? 0,
      name: json['name'] ?? 'Unknown',
      shortCode: json['short_code'] ?? '',
      imagePath: json['image_path'] as String?,
      founded: json['founded'] as int?,
      leaguePosition: meta?['position'] as int?,
      isHome: meta?['location'] == 'home',
    );
  }
}

class MatchInfo {
  final String team1;
  final String team2;
  final String team1Name;
  final String team2Name;
  final String leagueName;
  final String matchTime;
  final String leftText;
  final String rightText;
  final String team1Logo;
  final String team2Logo;
  final Color team1Color;
  final Color team2Color;
  final int? startingAtTimestamp;
  
  // New fields for fixture details
  final VenueInfo? venue;
  final List<CoachInfo> coaches;
  final TeamParticipant? homeTeam;
  final TeamParticipant? awayTeam;

  MatchInfo(
    this.team1,
    this.team2,
    this.team1Name,
    this.team2Name,
    this.leagueName,
    this.matchTime,
    this.leftText,
    this.rightText,
    this.team1Logo,
    this.team2Logo,
    this.team1Color,
    this.team2Color, {
    this.startingAtTimestamp,
    this.venue,
    this.coaches = const [],
    this.homeTeam,
    this.awayTeam,
  });

  /// Get the coach for the home team
  CoachInfo? get homeCoach {
    if (homeTeam == null) return null;
    try {
      return coaches.firstWhere((c) => c.teamId == homeTeam!.id);
    } catch (e) {
      return coaches.isNotEmpty ? coaches.first : null;
    }
  }

  /// Get the coach for the away team
  CoachInfo? get awayCoach {
    if (awayTeam == null) return null;
    try {
      return coaches.firstWhere((c) => c.teamId == awayTeam!.id);
    } catch (e) {
      return coaches.length > 1 ? coaches[1] : null;
    }
  }

  /// Get formatted match date and time
  String get formattedDateTime {
    if (startingAtTimestamp == null) return matchTime;
    final dt = DateTime.fromMillisecondsSinceEpoch(startingAtTimestamp! * 1000);
    return DateFormat('EEE, MMM d • HH:mm').format(dt);
  }

  /// Returns the formatted time remaining until match starts
  /// e.g., "2h 30m", "45m", "5d 3h", "LIVE", "COMPLETED"
  String getTimeRemaining() {
    if (startingAtTimestamp == null) {
      return matchTime; // Fallback to the string matchTime
    }

    final now = DateTime.now();
    final matchStart = DateTime.fromMillisecondsSinceEpoch(
      startingAtTimestamp! * 1000,
    );
    final difference = matchStart.difference(now);

    if (difference.isNegative) {
      // Match has started or completed
      if (difference.inHours.abs() < 2) {
        return 'LIVE';
      }
      return 'COMPLETED';
    }

    if (difference.inDays > 0) {
      final hours = difference.inHours % 24;
      return '${difference.inDays}d ${hours}h';
    } else if (difference.inHours > 0) {
      final minutes = difference.inMinutes % 60;
      return '${difference.inHours}h ${minutes}m';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Starting soon';
    }
  }

  /// Returns the DateTime of when the match starts
  DateTime? get startDateTime {
    if (startingAtTimestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(startingAtTimestamp! * 1000);
  }

  /// Returns true if the match is upcoming (hasn't started yet)
  bool get isUpcoming {
    if (startingAtTimestamp == null) return false;
    final matchStart = DateTime.fromMillisecondsSinceEpoch(
      startingAtTimestamp! * 1000,
    );
    return matchStart.isAfter(DateTime.now());
  }

  static final List<MatchInfo> matches = [
    MatchInfo(
      'BLAZER BULLS',
      'POWER PANDAS',
      'BLB',
      'PPD',
      'Premier League',
      'LIVE',
      '2 Team   3 Contests',
      ' ',
      'assets/TeamLogo/Vector Smart Object-2.png',
      'assets/TeamLogo/Layer 3093.png',
      Colors.red,
      Colors.green,
    ),
    MatchInfo(
      'WOLVES UNITED',
      'COBRA GUARDIANS',
      'WLS',
      'CBR',
      'Premier League',
      '0h 9m',
      'Max \$10 Million',
      'Lineup Announced',
      'assets/TeamLogo/Vector Smart Object-6.png',
      'assets/TeamLogo/Vector Smart Object-5.png',
      Colors.blue,
      Colors.deepPurple,
    ),
    MatchInfo(
        'MEXICAN TIGERS',
        'SHARK CHAMPIONS',
        'MXT',
        'SKC',
        'Mexican League',
        '3h 29m',
        'Max \$5 Million',
        ' ',
        'assets/TeamLogo/Vector Smart Object-4.png',
        'assets/TeamLogo/Vector Smart Object-3.png',
        const Color(0xff875E12),
        Colors.blue),
    MatchInfo(
        'BLAZER BULLS',
        'POWER PANDAS',
        'BLB',
        'PPD',
        'Premier League',
        'LIVE',
        '2 Team   3 Contests',
        ' ',
        'assets/TeamLogo/Vector Smart Object-2.png',
        'assets/TeamLogo/Layer 3093.png',
        Colors.red,
        Colors.blue),
    MatchInfo(
      'WOLVES UNITED',
      'GREAT GORILLAS',
      'WLS',
      'GGS',
      'Mexican League',
      '3h 29m',
      '2 Team   3 Contests',
      ' ',
      'assets/TeamLogo/Vector Smart Object-1.png',
      'assets/TeamLogo/Vector Smart Object.png',
      const Color(0xff847313),
      Colors.purpleAccent,
    ),
  ];

  factory MatchInfo.fromJson(Map<String, dynamic> json) {
    debugPrint('in fromJson method');
    String team1 = '';
    String team2 = '';
    String team1Name = '';
    String team2Name = '';
    String team1Logo = '';
    String team2Logo = '';
    TeamParticipant? homeTeam;
    TeamParticipant? awayTeam;
    
    final participants = json['participants'] as List<dynamic>?;
    if (participants != null && participants.isNotEmpty) {
      Map<String, dynamic>? home;
      Map<String, dynamic>? away;
      for (var p in participants) {
        if (p is! Map<String, dynamic>) continue;
        final location = p['meta'] is Map
            ? p['meta']['location'] as String?
            : null;
        if (location == 'home') home = p;
        if (location == 'away') away = p;
      }
      home ??=
      participants.isNotEmpty ? participants[0] as Map<String, dynamic> : null;
      away ??=
      participants.length > 1 ? participants[1] as Map<String, dynamic> : null;

      if (home != null) {
        team1 = (home['short_code']?.toString() ?? '');
        team1Name = home['name'] ?? '';
        team1Logo = home['image_path'] ?? home['logo_path'] ?? '';
        homeTeam = TeamParticipant.fromJson(home);
      }
      if (away != null) {
        team2 = (away['short_code']?.toString() ?? '');
        team2Name = away['name'] ?? '';
        team2Logo = away['image_path'] ?? away['logo_path'] ?? '';
        awayTeam = TeamParticipant.fromJson(away);
      }
    } else {
      // fallback: handle localTeam/visitorTeam or other shapes
      final local = json['localTeam'] is Map ? (json['localTeam']['data'] ??
          json['localTeam']) as Map<String, dynamic>? : null;
      final visitor = json['visitorTeam'] is Map
          ? (json['visitorTeam']['data'] ?? json['visitorTeam']) as Map<
          String,
          dynamic>?
          : null;

      if (local != null) {
        team1 = (local['id']?.toString() ?? '');
        team1Name = local['name'] ?? '';
        team1Logo = local['logo_path'] ?? local['image_path'] ?? '';
      }
      if (visitor != null) {
        team2 = (visitor['id']?.toString() ?? '');
        team2Name = visitor['name'] ?? '';
        team2Logo = visitor['logo_path'] ?? visitor['image_path'] ?? '';
      }
    }

    // Parse league name - could be a string or an object
    String leagueName = '';
    if (json['league_name'] is String) {
      leagueName = json['league_name'];
    } else if (json['league'] is Map) {
      leagueName = json['league']['name'] ?? '';
    } else if (json['league'] is String) {
      leagueName = json['league'];
    }
    
    // Parse match time - starting_at could be a string datetime
    String matchTime = '';
    if (json['starting_at'] is String) {
      matchTime = json['starting_at'];
    } else if (json['match_time'] is String) {
      matchTime = json['match_time'];
    } else if (json['time'] is String) {
      matchTime = json['time'];
    }
    final leftText = json['leftText'] ?? '';
    final rightText = json['rightText'] ?? json['right_text'] ?? '';

    // Parse the starting timestamp
    final startingAtTimestamp = json['starting_at_timestamp'] as int?;

    // Parse venue
    VenueInfo? venue;
    if (json['venue'] is Map<String, dynamic>) {
      venue = VenueInfo.fromJson(json['venue'] as Map<String, dynamic>);
    }

    // Parse coaches
    List<CoachInfo> coaches = [];
    if (json['coaches'] is List) {
      coaches = (json['coaches'] as List)
          .whereType<Map<String, dynamic>>()
          .map((c) => CoachInfo.fromJson(c))
          .toList();
    }

    final team1Color = colorFromHex(
        json['team1Color'] ?? json['team1_color'], fallback: Colors.blue);
    final team2Color = colorFromHex(
        json['team2Color'] ?? json['team2_color'], fallback: Colors.red);

    return MatchInfo(
      team1,
      team2,
      team1Name,
      team2Name,
      leagueName,
      matchTime,
      leftText,
      rightText,
      team1Logo,
      team2Logo,
      team1Color,
      team2Color,
      startingAtTimestamp: startingAtTimestamp,
      venue: venue,
      coaches: coaches,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
    );
  }

  static Color colorFromHex(String? hex, {Color fallback = Colors.grey}) {
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return fallback;
    try {
      return Color(int.parse(h, radix: 16));
    } catch (err) {
      return fallback;
    }
  }

  static List<MatchInfo> fromJsonList(List list) {
    debugPrint('in fromJsonList');
    // synchronous parsing wrapped in Future; or remove async and return Future.value(...)
    final parsed = list
        .map((e) => MatchInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    debugPrint('after parsing json list');
    debugPrint(parsed.first.team1Logo);
    return parsed;
  }

}
