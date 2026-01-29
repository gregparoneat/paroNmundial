import 'package:flutter/material.dart';
import 'package:fantacy11/features/player/models/player_info.dart' show Player;

/// Player position enum for fantasy team building
enum PlayerPosition {
  goalkeeper,
  defender,
  midfielder,
  attacker,
  forward;

  String get name {
    switch (this) {
      case PlayerPosition.goalkeeper:
        return 'Goalkeeper';
      case PlayerPosition.defender:
        return 'Defender';
      case PlayerPosition.midfielder:
        return 'Midfielder';
      case PlayerPosition.attacker:
        return 'Attacker';
      case PlayerPosition.forward:
        return 'Forward';
    }
  }

  String get abbreviation {
    switch (this) {
      case PlayerPosition.goalkeeper:
        return 'GK';
      case PlayerPosition.defender:
        return 'DEF';
      case PlayerPosition.midfielder:
        return 'MID';
      case PlayerPosition.attacker:
        return 'FWD';
      case PlayerPosition.forward:
        return 'FWD';
    }
  }

  Color get color {
    switch (this) {
      case PlayerPosition.goalkeeper:
        return Colors.orange;
      case PlayerPosition.defender:
        return Colors.blue;
      case PlayerPosition.midfielder:
        return Colors.green;
      case PlayerPosition.attacker:
        return Colors.red;
      case PlayerPosition.forward:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case PlayerPosition.goalkeeper:
        return Icons.sports_handball;
      case PlayerPosition.defender:
        return Icons.shield;
      case PlayerPosition.midfielder:
        return Icons.swap_horiz;
      case PlayerPosition.attacker:
        return Icons.sports_soccer;
      case PlayerPosition.forward:
        return Icons.sports_soccer;
    }
  }
}

/// League visibility type
enum LeagueType {
  public,
  private;

  String get displayName {
    switch (this) {
      case LeagueType.public:
        return 'Public';
      case LeagueType.private:
        return 'Private';
    }
  }

  IconData get icon {
    switch (this) {
      case LeagueType.public:
        return Icons.public;
      case LeagueType.private:
        return Icons.lock;
    }
  }
}

/// League status
enum LeagueStatus {
  draft,      // League created but match not started
  active,     // Match is ongoing
  completed,  // Match finished, points calculated
  cancelled;  // League was cancelled

  String get displayName {
    switch (this) {
      case LeagueStatus.draft:
        return 'Upcoming';
      case LeagueStatus.active:
        return 'Live';
      case LeagueStatus.completed:
        return 'Completed';
      case LeagueStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case LeagueStatus.draft:
        return Colors.orange;
      case LeagueStatus.active:
        return Colors.green;
      case LeagueStatus.completed:
        return Colors.blue;
      case LeagueStatus.cancelled:
        return Colors.red;
    }
  }
}

/// Fantasy League model
class League {
  final String id;
  final String name;
  final String? description;
  final LeagueType type;
  final LeagueStatus status;
  final String? inviteCode;
  final int maxMembers;
  final double budget; // Total budget per team (in credits)
  final int? matchId; // Associated match ID from SportMonks
  final String? matchName; // e.g., "Team A vs Team B"
  final DateTime? matchDateTime;
  final String createdBy; // User ID of creator
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int memberCount;
  final double? entryFee;
  final double? prizePool;
  final String? leagueImageUrl;
  final bool isJoined; // Whether current user has joined this league

  League({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.status = LeagueStatus.draft,
    this.inviteCode,
    this.maxMembers = 20,
    this.budget = 100.0,
    this.matchId,
    this.matchName,
    this.matchDateTime,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.memberCount = 0,
    this.entryFee,
    this.prizePool,
    this.leagueImageUrl,
    this.isJoined = false,
  });

  bool get isPublic => type == LeagueType.public;
  bool get isPrivate => type == LeagueType.private;
  bool get isFull => memberCount >= maxMembers;
  bool get canJoin => !isFull && status == LeagueStatus.draft && !isJoined;

  /// Generate a short invite code
  static String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) {
      final randomIndex = DateTime.now().microsecondsSinceEpoch % chars.length;
      return chars[(randomIndex + index * 7) % chars.length];
    }).join();
  }

  /// Create invite link
  String get inviteLink => 'fantasy11://league/join/$inviteCode';

  /// Create share text
  String get shareText {
    return '''
🏆 Join my Fantasy League!

League: $name
${description != null ? 'Description: $description\n' : ''}Match: ${matchName ?? 'TBD'}
Budget: $budget credits
Entry: ${entryFee != null ? '\$${entryFee!.toStringAsFixed(2)}' : 'Free'}

Join with code: $inviteCode
Or click: $inviteLink
''';
  }

  League copyWith({
    String? id,
    String? name,
    String? description,
    LeagueType? type,
    LeagueStatus? status,
    String? inviteCode,
    int? maxMembers,
    double? budget,
    int? matchId,
    String? matchName,
    DateTime? matchDateTime,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? memberCount,
    double? entryFee,
    double? prizePool,
    String? leagueImageUrl,
    bool? isJoined,
  }) {
    return League(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      inviteCode: inviteCode ?? this.inviteCode,
      maxMembers: maxMembers ?? this.maxMembers,
      budget: budget ?? this.budget,
      matchId: matchId ?? this.matchId,
      matchName: matchName ?? this.matchName,
      matchDateTime: matchDateTime ?? this.matchDateTime,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      memberCount: memberCount ?? this.memberCount,
      entryFee: entryFee ?? this.entryFee,
      prizePool: prizePool ?? this.prizePool,
      leagueImageUrl: leagueImageUrl ?? this.leagueImageUrl,
      isJoined: isJoined ?? this.isJoined,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'status': status.name,
      'inviteCode': inviteCode,
      'maxMembers': maxMembers,
      'budget': budget,
      'matchId': matchId,
      'matchName': matchName,
      'matchDateTime': matchDateTime?.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'memberCount': memberCount,
      'entryFee': entryFee,
      'prizePool': prizePool,
      'leagueImageUrl': leagueImageUrl,
    };
  }

  factory League.fromJson(Map<String, dynamic> json) {
    return League(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: LeagueType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => LeagueType.public,
      ),
      status: LeagueStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LeagueStatus.draft,
      ),
      inviteCode: json['inviteCode'] as String?,
      maxMembers: json['maxMembers'] as int? ?? 20,
      budget: (json['budget'] as num?)?.toDouble() ?? 100.0,
      matchId: json['matchId'] as int?,
      matchName: json['matchName'] as String?,
      matchDateTime: json['matchDateTime'] != null
          ? DateTime.parse(json['matchDateTime'] as String)
          : null,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      memberCount: json['memberCount'] as int? ?? 0,
      entryFee: (json['entryFee'] as num?)?.toDouble(),
      prizePool: (json['prizePool'] as num?)?.toDouble(),
      leagueImageUrl: json['leagueImageUrl'] as String?,
    );
  }
}

/// Member of a league
class LeagueMember {
  final String id;
  final String leagueId;
  final String oderId;
  final String userName;
  final String? userImageUrl;
  final DateTime joinedAt;
  final String? fantasyTeamId;
  final int rank;
  final double totalPoints;
  final bool isCreator;

  LeagueMember({
    required this.id,
    required this.leagueId,
    required this.oderId,
    required this.userName,
    this.userImageUrl,
    required this.joinedAt,
    this.fantasyTeamId,
    this.rank = 0,
    this.totalPoints = 0,
    this.isCreator = false,
  });

  bool get hasTeam => fantasyTeamId != null;

  LeagueMember copyWith({
    String? id,
    String? leagueId,
    String? oderId,
    String? userName,
    String? userImageUrl,
    DateTime? joinedAt,
    String? fantasyTeamId,
    int? rank,
    double? totalPoints,
    bool? isCreator,
  }) {
    return LeagueMember(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      oderId: oderId ?? this.oderId,
      userName: userName ?? this.userName,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      fantasyTeamId: fantasyTeamId ?? this.fantasyTeamId,
      rank: rank ?? this.rank,
      totalPoints: totalPoints ?? this.totalPoints,
      isCreator: isCreator ?? this.isCreator,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leagueId': leagueId,
      'oderId': oderId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'joinedAt': joinedAt.toIso8601String(),
      'fantasyTeamId': fantasyTeamId,
      'rank': rank,
      'totalPoints': totalPoints,
      'isCreator': isCreator,
    };
  }

  factory LeagueMember.fromJson(Map<String, dynamic> json) {
    return LeagueMember(
      id: json['id'] as String,
      leagueId: json['leagueId'] as String,
      oderId: json['oderId'] as String,
      userName: json['userName'] as String,
      userImageUrl: json['userImageUrl'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      fantasyTeamId: json['fantasyTeamId'] as String?,
      rank: json['rank'] as int? ?? 0,
      totalPoints: (json['totalPoints'] as num?)?.toDouble() ?? 0,
      isCreator: json['isCreator'] as bool? ?? false,
    );
  }
}

/// Player selection for a fantasy team
class FantasyTeamPlayer {
  final int playerId;
  final String playerName;
  final String? playerImageUrl;
  final PlayerPosition position;
  final String? teamName;
  final double credits; // Cost in credits
  final double points; // Points earned (calculated after match)
  final bool isCaptain;
  final bool isViceCaptain;

  FantasyTeamPlayer({
    required this.playerId,
    required this.playerName,
    this.playerImageUrl,
    required this.position,
    this.teamName,
    required this.credits,
    this.points = 0,
    this.isCaptain = false,
    this.isViceCaptain = false,
  });

  /// Captain gets 2x points, Vice-captain gets 1.5x
  double get effectivePoints {
    if (isCaptain) return points * 2;
    if (isViceCaptain) return points * 1.5;
    return points;
  }

  FantasyTeamPlayer copyWith({
    int? playerId,
    String? playerName,
    String? playerImageUrl,
    PlayerPosition? position,
    String? teamName,
    double? credits,
    double? points,
    bool? isCaptain,
    bool? isViceCaptain,
  }) {
    return FantasyTeamPlayer(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerImageUrl: playerImageUrl ?? this.playerImageUrl,
      position: position ?? this.position,
      teamName: teamName ?? this.teamName,
      credits: credits ?? this.credits,
      points: points ?? this.points,
      isCaptain: isCaptain ?? this.isCaptain,
      isViceCaptain: isViceCaptain ?? this.isViceCaptain,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'playerImageUrl': playerImageUrl,
      'position': position.name,
      'teamName': teamName,
      'credits': credits,
      'points': points,
      'isCaptain': isCaptain,
      'isViceCaptain': isViceCaptain,
    };
  }

  factory FantasyTeamPlayer.fromJson(Map<String, dynamic> json) {
    return FantasyTeamPlayer(
      playerId: json['playerId'] as int,
      playerName: json['playerName'] as String,
      playerImageUrl: json['playerImageUrl'] as String?,
      position: PlayerPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => PlayerPosition.midfielder,
      ),
      teamName: json['teamName'] as String?,
      credits: (json['credits'] as num).toDouble(),
      points: (json['points'] as num?)?.toDouble() ?? 0,
      isCaptain: json['isCaptain'] as bool? ?? false,
      isViceCaptain: json['isViceCaptain'] as bool? ?? false,
    );
  }

  /// Create from a Player model
  factory FantasyTeamPlayer.fromPlayer(Player player, double credits) {
    // Convert PositionInfo to PlayerPosition
    PlayerPosition position = PlayerPosition.midfielder;
    if (player.position != null) {
      final posCode = player.position!.code.toLowerCase();
      switch (posCode) {
        case 'goalkeeper':
          position = PlayerPosition.goalkeeper;
          break;
        case 'defender':
          position = PlayerPosition.defender;
          break;
        case 'midfielder':
          position = PlayerPosition.midfielder;
          break;
        case 'attacker':
          position = PlayerPosition.attacker;
          break;
        case 'forward':
          position = PlayerPosition.forward;
          break;
      }
    }
    
    return FantasyTeamPlayer(
      playerId: player.id,
      playerName: player.displayName,
      playerImageUrl: player.imagePath,
      position: position,
      teamName: player.currentTeam?.teamName,
      credits: credits,
    );
  }
}

/// User's fantasy team for a league
class FantasyTeam {
  final String id;
  final String leagueId;
  final String userId;
  final String userName;
  final List<FantasyTeamPlayer> players;
  final double totalCredits;
  final double budgetRemaining;
  final double totalPoints;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isLocked; // Locked when match starts

  FantasyTeam({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.userName,
    required this.players,
    required this.totalCredits,
    required this.budgetRemaining,
    this.totalPoints = 0,
    required this.createdAt,
    this.updatedAt,
    this.isLocked = false,
  });

  /// Get captain
  FantasyTeamPlayer? get captain => 
      players.where((p) => p.isCaptain).firstOrNull;

  /// Get vice-captain
  FantasyTeamPlayer? get viceCaptain => 
      players.where((p) => p.isViceCaptain).firstOrNull;

  /// Get players by position
  List<FantasyTeamPlayer> getPlayersByPosition(PlayerPosition position) {
    return players.where((p) => p.position == position).toList();
  }

  /// Count players by position
  int countByPosition(PlayerPosition position) {
    return players.where((p) => p.position == position).length;
  }

  /// Check if team is valid (11 players, valid formation, captain/VC selected)
  bool get isValid {
    if (players.length != 11) return false;
    if (captain == null || viceCaptain == null) return false;
    
    // Check formation constraints
    final gk = countByPosition(PlayerPosition.goalkeeper);
    final def = countByPosition(PlayerPosition.defender);
    final mid = countByPosition(PlayerPosition.midfielder);
    final fwd = countByPosition(PlayerPosition.attacker) + 
                countByPosition(PlayerPosition.forward);
    
    if (gk != 1) return false;
    if (def < 3 || def > 5) return false;
    if (mid < 3 || mid > 5) return false;
    if (fwd < 1 || fwd > 3) return false;
    
    return true;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (players.length != 11) {
      errors.add('Team must have exactly 11 players (currently ${players.length})');
    }
    
    if (captain == null) errors.add('Select a captain');
    if (viceCaptain == null) errors.add('Select a vice-captain');
    
    final gk = countByPosition(PlayerPosition.goalkeeper);
    final def = countByPosition(PlayerPosition.defender);
    final mid = countByPosition(PlayerPosition.midfielder);
    final fwd = countByPosition(PlayerPosition.attacker) + 
                countByPosition(PlayerPosition.forward);
    
    if (gk != 1) errors.add('Must have exactly 1 goalkeeper (currently $gk)');
    if (def < 3) errors.add('Must have at least 3 defenders (currently $def)');
    if (def > 5) errors.add('Cannot have more than 5 defenders (currently $def)');
    if (mid < 3) errors.add('Must have at least 3 midfielders (currently $mid)');
    if (mid > 5) errors.add('Cannot have more than 5 midfielders (currently $mid)');
    if (fwd < 1) errors.add('Must have at least 1 forward (currently $fwd)');
    if (fwd > 3) errors.add('Cannot have more than 3 forwards (currently $fwd)');
    
    if (budgetRemaining < 0) {
      errors.add('Over budget by ${(-budgetRemaining).toStringAsFixed(1)} credits');
    }
    
    return errors;
  }

  FantasyTeam copyWith({
    String? id,
    String? leagueId,
    String? userId,
    String? userName,
    List<FantasyTeamPlayer>? players,
    double? totalCredits,
    double? budgetRemaining,
    double? totalPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocked,
  }) {
    return FantasyTeam(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      players: players ?? this.players,
      totalCredits: totalCredits ?? this.totalCredits,
      budgetRemaining: budgetRemaining ?? this.budgetRemaining,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leagueId': leagueId,
      'userId': userId,
      'userName': userName,
      'players': players.map((p) => p.toJson()).toList(),
      'totalCredits': totalCredits,
      'budgetRemaining': budgetRemaining,
      'totalPoints': totalPoints,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isLocked': isLocked,
    };
  }

  factory FantasyTeam.fromJson(Map<String, dynamic> json) {
    return FantasyTeam(
      id: json['id'] as String,
      leagueId: json['leagueId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      players: (json['players'] as List<dynamic>)
          .map((p) => FantasyTeamPlayer.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalCredits: (json['totalCredits'] as num).toDouble(),
      budgetRemaining: (json['budgetRemaining'] as num).toDouble(),
      totalPoints: (json['totalPoints'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  /// Create a new empty team
  factory FantasyTeam.empty({
    required String id,
    required String leagueId,
    required String userId,
    required String userName,
    required double budget,
  }) {
    return FantasyTeam(
      id: id,
      leagueId: leagueId,
      userId: userId,
      userName: userName,
      players: [],
      totalCredits: budget,
      budgetRemaining: budget,
      createdAt: DateTime.now(),
    );
  }
}

/// Available player for selection in team builder
class AvailablePlayer {
  final Player player;
  final double credits;
  final double selectedByPercent; // Percentage of users who selected this player
  final double averagePoints; // Average fantasy points per match
  final bool isSelected; // Is this player in the user's current team?
  final PlayerPosition? position; // Override position for demo players

  AvailablePlayer({
    required this.player,
    required this.credits,
    this.selectedByPercent = 0,
    this.averagePoints = 0,
    this.isSelected = false,
    this.position,
  });

  /// Get the effective position (override or from player)
  PlayerPosition get effectivePosition {
    if (position != null) return position!;
    
    // Convert from player's PositionInfo to PlayerPosition
    final posCode = player.position?.code.toLowerCase() ?? 'midfielder';
    switch (posCode) {
      case 'goalkeeper':
        return PlayerPosition.goalkeeper;
      case 'defender':
        return PlayerPosition.defender;
      case 'midfielder':
        return PlayerPosition.midfielder;
      case 'attacker':
        return PlayerPosition.attacker;
      case 'forward':
        return PlayerPosition.forward;
      default:
        return PlayerPosition.midfielder;
    }
  }

  AvailablePlayer copyWith({
    Player? player,
    double? credits,
    double? selectedByPercent,
    double? averagePoints,
    bool? isSelected,
    PlayerPosition? position,
  }) {
    return AvailablePlayer(
      player: player ?? this.player,
      credits: credits ?? this.credits,
      selectedByPercent: selectedByPercent ?? this.selectedByPercent,
      averagePoints: averagePoints ?? this.averagePoints,
      isSelected: isSelected ?? this.isSelected,
      position: position ?? this.position,
    );
  }
}

