import 'package:flutter/material.dart';
import 'dart:developer' as developer; // Alias to avoid conflict with 'log'

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
    this.team2Color,
  );

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
      participants.length > 0 ? participants[0] as Map<String, dynamic> : null;
      away ??=
      participants.length > 1 ? participants[1] as Map<String, dynamic> : null;

      if (home != null) {
        team1 = (home['id']?.toString() ?? '');
        team1Name = home['name'] ?? '';
        team1Logo = home['image_path'] ?? home['logo_path'] ?? '';
      }
      if (away != null) {
        team2 = (away['id']?.toString() ?? '');
        team2Name = away['name'] ?? '';
        team2Logo = away['image_path'] ?? away['logo_path'] ?? '';
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

    final leagueName = json['league_name'] ?? json['league'] ?? '';
    final matchTime = json['starting_at'] ?? json['match_time'] ??
        json['time'] ?? '';
    final leftText = json['leftText'] ?? '';
    final rightText = json['rightText'] ?? json['right_text'] ?? '';

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
