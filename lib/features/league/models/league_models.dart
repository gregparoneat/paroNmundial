// Pure Dart file - no Flutter imports
// Colors are stored as int values (ARGB format), icons as string names
import 'package:fantacy11/features/league/models/draft_models.dart';
import 'package:fantacy11/features/player/models/player_info.dart'
    show Player, PositionColors;

export 'draft_models.dart';

/// League color constants as int values (ARGB format)
class LeagueColors {
  static const int orange = 0xFFFF9800;
  static const int green = 0xFF4CAF50;
  static const int blue = 0xFF2196F3;
  static const int red = 0xFFF44336;
}

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

  /// Get color value as ARGB int
  int get colorValue {
    switch (this) {
      case PlayerPosition.goalkeeper:
        return PositionColors.goalkeeper;
      case PlayerPosition.defender:
        return PositionColors.defender;
      case PlayerPosition.midfielder:
        return PositionColors.midfielder;
      case PlayerPosition.attacker:
        return PositionColors.attacker;
      case PlayerPosition.forward:
        return PositionColors.attacker;
    }
  }

  /// Get icon name for Flutter Icons
  String get iconName {
    switch (this) {
      case PlayerPosition.goalkeeper:
        return 'sports_handball';
      case PlayerPosition.defender:
        return 'shield';
      case PlayerPosition.midfielder:
        return 'swap_horiz';
      case PlayerPosition.attacker:
        return 'sports_soccer';
      case PlayerPosition.forward:
        return 'sports_soccer';
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

  /// Get icon name for Flutter Icons
  String get iconName {
    switch (this) {
      case LeagueType.public:
        return 'public';
      case LeagueType.private:
        return 'lock';
    }
  }
}

/// League status
enum LeagueStatus {
  draft, // League created but match not started
  active, // Match is ongoing
  completed, // Match finished, points calculated
  cancelled; // League was cancelled

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

  /// Get color value as ARGB int
  int get colorValue {
    switch (this) {
      case LeagueStatus.draft:
        return LeagueColors.orange;
      case LeagueStatus.active:
        return LeagueColors.green;
      case LeagueStatus.completed:
        return LeagueColors.blue;
      case LeagueStatus.cancelled:
        return LeagueColors.red;
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
  final double
  budget; // Total budget per team (in millions of USD, e.g., 150.0 = $150M)
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

  // Draft mode fields
  final LeagueMode mode; // Classic (budget) or Draft
  final DraftSettings? draftSettings; // Settings for draft mode
  final TradeSettings? tradeSettings; // Trade rules for draft mode
  final int rosterSize; // Total roster size (default 18)

  League({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.status = LeagueStatus.draft,
    this.inviteCode,
    this.maxMembers = 20,
    this.budget = 150.0,
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
    this.mode = LeagueMode.classic,
    this.draftSettings,
    this.tradeSettings,
    this.rosterSize = 18,
  });

  bool get isPublic => type == LeagueType.public;
  bool get isPrivate => type == LeagueType.private;
  bool get isFull => memberCount >= maxMembers;
  bool get canJoin => !isFull && status == LeagueStatus.draft && !isJoined;

  // Draft mode helpers
  bool get isClassicMode => mode == LeagueMode.classic;
  bool get isDraftMode => mode == LeagueMode.draft;

  /// Check if draft is scheduled and upcoming
  bool get hasDraftScheduled =>
      isDraftMode && draftSettings?.draftDateTime != null;

  /// Check if draft time has passed
  bool get isDraftTimePassed {
    if (!hasDraftScheduled) return false;
    return DateTime.now().isAfter(draftSettings!.draftDateTime!);
  }

  /// Generate a short invite code
  static String generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) {
      final randomIndex = DateTime.now().microsecondsSinceEpoch % chars.length;
      return chars[(randomIndex + index * 7) % chars.length];
    }).join();
  }

  /// Create invite link
  String get inviteLink => 'paronfantasymx://league/join/$inviteCode';

  /// Create share text
  String get shareText {
    return '''
🏆 Join my paroNfantasyMx League!

League: $name
${description != null ? 'Description: $description\n' : ''}Match: ${matchName ?? 'TBD'}
Budget: \$${budget.toInt()}M
FREE to play!

Join with code: $inviteCode
Or click: $inviteLink
''';
  }

  /// Get formatted budget string (e.g., "$100M")
  String get formattedBudget => '\$${budget.toInt()}M';

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
    LeagueMode? mode,
    DraftSettings? draftSettings,
    TradeSettings? tradeSettings,
    int? rosterSize,
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
      mode: mode ?? this.mode,
      draftSettings: draftSettings ?? this.draftSettings,
      tradeSettings: tradeSettings ?? this.tradeSettings,
      rosterSize: rosterSize ?? this.rosterSize,
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
      'mode': mode.name,
      'draftSettings': draftSettings?.toJson(),
      'tradeSettings': tradeSettings?.toJson(),
      'rosterSize': rosterSize,
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
      budget: (json['budget'] as num?)?.toDouble() ?? 150.0,
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
      mode: LeagueMode.classic,
      draftSettings: null,
      tradeSettings: null,
      rosterSize: json['rosterSize'] as int? ?? 18,
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
  final String? teamName;
  final PlayerPosition position;
  final double price; // Cost in millions of USD (e.g., 8.5 = $8.5M)
  final double points; // Points earned (calculated after match)
  final double predictedPoints; // Predicted points for next fixture
  final bool isCaptain;
  final bool isViceCaptain;

  /// Backwards compatibility - returns price (previously called credits)
  double get credits => price;

  /// Get formatted price string (e.g., "$8.5M")
  String get formattedPrice => '\$${price.toStringAsFixed(1)}M';

  FantasyTeamPlayer({
    required this.playerId,
    required this.playerName,
    this.playerImageUrl,
    this.teamName,
    required this.position,
    required this.price,
    this.points = 0,
    this.predictedPoints = 0,
    this.isCaptain = false,
    this.isViceCaptain = false,
  });

  /// Captain gets 2x points, Vice-captain gets 1.5x
  double get effectivePoints {
    if (isCaptain) return points * 2;
    if (isViceCaptain) return points * 1.5;
    return points;
  }

  /// Predicted points with captain/VC multipliers
  double get effectivePredictedPoints {
    if (isCaptain) return predictedPoints * 2;
    if (isViceCaptain) return predictedPoints * 1.5;
    return predictedPoints;
  }

  FantasyTeamPlayer copyWith({
    int? playerId,
    String? playerName,
    String? playerImageUrl,
    PlayerPosition? position,
    String? teamName,
    double? price,
    double? points,
    double? predictedPoints,
    bool? isCaptain,
    bool? isViceCaptain,
  }) {
    return FantasyTeamPlayer(
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerImageUrl: playerImageUrl ?? this.playerImageUrl,
      position: position ?? this.position,
      price: price ?? this.price,
      points: points ?? this.points,
      predictedPoints: predictedPoints ?? this.predictedPoints,
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
      'price': price,
      'credits': price, // Backwards compatibility
      'points': points,
      'predictedPoints': predictedPoints,
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
      price:
          (json['price'] as num?)?.toDouble() ??
          (json['credits'] as num?)?.toDouble() ??
          5.0, // Support both
      points: (json['points'] as num?)?.toDouble() ?? 0,
      predictedPoints: (json['predictedPoints'] as num?)?.toDouble() ?? 0,
      isCaptain: json['isCaptain'] as bool? ?? false,
      isViceCaptain: json['isViceCaptain'] as bool? ?? false,
    );
  }

  /// Create from a Player model
  factory FantasyTeamPlayer.fromPlayer(Player player, double price) {
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
      price: price,
    );
  }
}

/// User's fantasy team for a league
class FantasyTeam {
  final String id;
  final String leagueId;
  final String userId;
  final String userName;
  final String teamName;
  final List<FantasyTeamPlayer> players;
  final double
  totalCredits; // Total budget in millions USD (e.g., 100.0 = $100M)
  final double budgetRemaining; // Remaining budget in millions USD
  final double totalPoints;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isLocked; // Locked when match starts
  final String? formation; // Formation code like "4-3-3", "4-4-2", etc.

  FantasyTeam({
    required this.id,
    required this.leagueId,
    required this.userId,
    required this.userName,
    required this.teamName,
    required this.players,
    required this.totalCredits,
    required this.budgetRemaining,
    this.totalPoints = 0,
    required this.createdAt,
    this.updatedAt,
    this.isLocked = false,
    this.formation,
  });

  /// Get captain
  FantasyTeamPlayer? get captain =>
      players.where((p) => p.isCaptain).firstOrNull;

  /// Get vice-captain
  FantasyTeamPlayer? get viceCaptain =>
      players.where((p) => p.isViceCaptain).firstOrNull;

  /// Get total predicted points for all players (with captain/VC multipliers)
  double get totalPredictedPoints {
    return players.fold(0.0, (sum, p) => sum + p.effectivePredictedPoints);
  }

  /// Get players by position
  List<FantasyTeamPlayer> getPlayersByPosition(PlayerPosition position) {
    return players.where((p) => p.position == position).toList();
  }

  /// Count players by position
  int countByPosition(PlayerPosition position) {
    return players.where((p) => p.position == position).length;
  }

  /// Check if team is valid for the requested roster size.
  bool isValidForRosterSize(int rosterSize) {
    // Check total player count matches roster size
    if (players.length != rosterSize) return false;
    if (captain == null || viceCaptain == null) return false;

    // Check position constraints - flexible for different formations
    final gk = countByPosition(PlayerPosition.goalkeeper);
    final def = countByPosition(PlayerPosition.defender);
    final mid = countByPosition(PlayerPosition.midfielder);
    final fwd =
        countByPosition(PlayerPosition.attacker) +
        countByPosition(PlayerPosition.forward);

    // Minimum constraints vary by roster size
    if (rosterSize == 18) {
      // 18-player roster: 2 GK, 5-6 DEF, 5-6 MID, 3-4 FWD
      if (gk < 2) return false;
      if (def < 5 || def > 6) return false;
      if (mid < 5 || mid > 6) return false;
      if (fwd < 3 || fwd > 4) return false;
      if (gk + def + mid + fwd != 18) return false;
    } else {
      // 15-player roster (default): 2 GK, 3-6 DEF, 3-6 MID, 1-4 FWD
      if (gk < 2) return false;
      if (def < 3 || def > 6) return false;
      if (mid < 3 || mid > 6) return false;
      if (fwd < 1 || fwd > 4) return false;
      if (gk + def + mid + fwd != 15) return false;
    }

    return true;
  }

  /// Default validation uses the current 18-player squad standard.
  bool get isValid => isValidForRosterSize(18);

  /// Check if team has minimum required players to be saved (can be incomplete)
  bool get hasMinimumPlayers {
    return players.length >= 11 && captain != null && viceCaptain != null;
  }

  /// Get starting XI (first 11 players)
  List<FantasyTeamPlayer> get startingXI => players.take(11).toList();

  /// Get bench players (players after first 11)
  List<FantasyTeamPlayer> get benchPlayers => players.skip(11).toList();

  /// Get validation errors for a given roster size.
  List<String> validationErrorsForRosterSize(int rosterSize) {
    final errors = <String>[];

    if (players.length != rosterSize) {
      errors.add(
        'Team must have exactly $rosterSize players (currently ${players.length})',
      );
    }

    if (captain == null) errors.add('Select a captain');
    if (viceCaptain == null) errors.add('Select a vice-captain');

    final gk = countByPosition(PlayerPosition.goalkeeper);
    final def = countByPosition(PlayerPosition.defender);
    final mid = countByPosition(PlayerPosition.midfielder);
    final fwd =
        countByPosition(PlayerPosition.attacker) +
        countByPosition(PlayerPosition.forward);

    if (gk < 2) errors.add('Need at least 2 goalkeepers (currently $gk)');
    if (def < 3) errors.add('Need at least 3 defenders (currently $def)');
    if (mid < 3) errors.add('Need at least 3 midfielders (currently $mid)');
    if (fwd < 1) errors.add('Need at least 1 forward (currently $fwd)');

    if (budgetRemaining < 0) {
      errors.add('Over budget by \$${(-budgetRemaining).toStringAsFixed(1)}M');
    }

    return errors;
  }

  /// Default validation errors use the current 18-player squad standard.
  List<String> get validationErrors => validationErrorsForRosterSize(18);

  FantasyTeam copyWith({
    String? id,
    String? leagueId,
    String? userId,
    String? userName,
    String? teamName,
    List<FantasyTeamPlayer>? players,
    double? totalCredits,
    double? budgetRemaining,
    double? totalPoints,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isLocked,
    String? formation,
  }) {
    return FantasyTeam(
      id: id ?? this.id,
      leagueId: leagueId ?? this.leagueId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      teamName: teamName ?? this.teamName,
      players: players ?? this.players,
      totalCredits: totalCredits ?? this.totalCredits,
      budgetRemaining: budgetRemaining ?? this.budgetRemaining,
      totalPoints: totalPoints ?? this.totalPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isLocked: isLocked ?? this.isLocked,
      formation: formation ?? this.formation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leagueId': leagueId,
      'userId': userId,
      'userName': userName,
      'teamName': teamName,
      'players': players.map((p) => p.toJson()).toList(),
      'totalCredits': totalCredits,
      'budgetRemaining': budgetRemaining,
      'totalPoints': totalPoints,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isLocked': isLocked,
      'formation': formation,
    };
  }

  factory FantasyTeam.fromJson(Map<String, dynamic> json) {
    return FantasyTeam(
      id: json['id'] as String,
      leagueId: json['leagueId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      teamName: json['teamName'] as String? ?? json['userName'] as String,
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
      formation: json['formation'] as String?,
    );
  }

  /// Create a new empty team
  factory FantasyTeam.empty({
    required String id,
    required String leagueId,
    required String userId,
    required String userName,
    required String teamName,
    required double budget,
  }) {
    return FantasyTeam(
      id: id,
      leagueId: leagueId,
      userId: userId,
      userName: userName,
      teamName: teamName,
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
  final double price; // Price in millions USD (e.g., 8.5 = $8.5M)
  final double
  selectedByPercent; // Percentage of users who selected this player
  final double averagePoints; // Average fantasy points per match
  final bool isSelected; // Is this player in the user's current team?
  final PlayerPosition? position; // Override position for demo players

  /// Backwards compatibility - returns price (previously called credits)
  double get credits => price;

  /// Get formatted price string (e.g., "$8.5M")
  String get formattedPrice => '\$${price.toStringAsFixed(1)}M';

  AvailablePlayer({
    required this.player,
    required this.price,
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
    double? price,
    double? selectedByPercent,
    double? averagePoints,
    bool? isSelected,
    PlayerPosition? position,
  }) {
    return AvailablePlayer(
      player: player ?? this.player,
      price: price ?? this.price,
      selectedByPercent: selectedByPercent ?? this.selectedByPercent,
      averagePoints: averagePoints ?? this.averagePoints,
      isSelected: isSelected ?? this.isSelected,
      position: position ?? this.position,
    );
  }
}
