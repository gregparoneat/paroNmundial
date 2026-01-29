import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing fantasy leagues
class LeagueRepository {
  static final LeagueRepository _instance = LeagueRepository._internal();
  factory LeagueRepository() => _instance;
  LeagueRepository._internal();

  static const String _leaguesBox = 'leagues_box';
  static const String _membersBox = 'league_members_box';
  static const String _teamsBox = 'fantasy_teams_box';
  static const String _currentUserKey = 'current_user';
  
  final _uuid = const Uuid();
  
  Box<String>? _leaguesBoxInstance;
  Box<String>? _membersBoxInstance;
  Box<String>? _teamsBoxInstance;
  bool _initialized = false;

  /// Initialize the repository
  Future<void> init() async {
    if (_initialized) return;
    
    _leaguesBoxInstance = await Hive.openBox<String>(_leaguesBox);
    _membersBoxInstance = await Hive.openBox<String>(_membersBox);
    _teamsBoxInstance = await Hive.openBox<String>(_teamsBox);
    
    _initialized = true;
    debugPrint('LeagueRepository initialized');
    
    // Create demo leagues if none exist
    await _createDemoLeaguesIfNeeded();
  }

  /// Ensure initialized
  Future<void> _ensureInitialized() async {
    if (!_initialized) await init();
  }

  // ==================== LEAGUE OPERATIONS ====================

  /// Create a new league
  Future<League> createLeague({
    required String name,
    String? description,
    required LeagueType type,
    int maxMembers = 20,
    double budget = 100.0,
    int? matchId,
    String? matchName,
    DateTime? matchDateTime,
    double? entryFee,
  }) async {
    await _ensureInitialized();
    
    final currentUser = await getCurrentUser();
    final leagueId = _uuid.v4();
    final inviteCode = type == LeagueType.private ? League.generateInviteCode() : null;
    
    final league = League(
      id: leagueId,
      name: name,
      description: description,
      type: type,
      inviteCode: inviteCode,
      maxMembers: maxMembers,
      budget: budget,
      matchId: matchId,
      matchName: matchName,
      matchDateTime: matchDateTime,
      createdBy: currentUser.oderId,
      createdAt: DateTime.now(),
      memberCount: 1, // Creator is automatically a member
      entryFee: entryFee,
      prizePool: entryFee != null ? entryFee * maxMembers * 0.9 : null,
    );
    
    // Save league
    await _leaguesBoxInstance!.put(leagueId, json.encode(league.toJson()));
    
    // Add creator as first member
    final member = LeagueMember(
      id: _uuid.v4(),
      leagueId: leagueId,
      oderId: currentUser.oderId,
      userName: currentUser.userName,
      userImageUrl: currentUser.userImageUrl,
      joinedAt: DateTime.now(),
      isCreator: true,
    );
    await _saveMember(member);
    
    debugPrint('Created league: ${league.name} (${league.id})');
    return league;
  }

  /// Get a league by ID
  Future<League?> getLeague(String leagueId) async {
    await _ensureInitialized();
    
    final data = _leaguesBoxInstance!.get(leagueId);
    if (data == null) return null;
    
    try {
      return League.fromJson(json.decode(data) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error parsing league: $e');
      return null;
    }
  }

  /// Get all public leagues (marks isJoined for leagues user has already joined)
  Future<List<League>> getPublicLeagues() async {
    await _ensureInitialized();
    
    // First get the list of leagues the user has joined
    final currentUser = await getCurrentUser();
    final myLeagueIds = <String>{};
    
    for (final key in _membersBoxInstance!.keys) {
      final data = _membersBoxInstance!.get(key);
      if (data != null) {
        try {
          final member = LeagueMember.fromJson(json.decode(data) as Map<String, dynamic>);
          if (member.oderId == currentUser.oderId) {
            myLeagueIds.add(member.leagueId);
          }
        } catch (e) {
          debugPrint('Error parsing member for isJoined check: $e');
        }
      }
    }
    
    final leagues = <League>[];
    for (final key in _leaguesBoxInstance!.keys) {
      final data = _leaguesBoxInstance!.get(key);
      if (data != null) {
        try {
          final league = League.fromJson(json.decode(data) as Map<String, dynamic>);
          if (league.isPublic && league.status == LeagueStatus.draft) {
            // Mark as joined if user is a member
            leagues.add(league.copyWith(isJoined: myLeagueIds.contains(league.id)));
          }
        } catch (e) {
          debugPrint('Error parsing league $key: $e');
        }
      }
    }
    
    // Sort by created date (newest first)
    leagues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return leagues;
  }

  /// Get leagues the current user is a member of
  Future<List<League>> getMyLeagues() async {
    await _ensureInitialized();
    
    final currentUser = await getCurrentUser();
    final myLeagueIds = <String>[];
    
    // Find all leagues where user is a member
    for (final key in _membersBoxInstance!.keys) {
      final data = _membersBoxInstance!.get(key);
      if (data != null) {
        try {
          final member = LeagueMember.fromJson(json.decode(data) as Map<String, dynamic>);
          if (member.oderId == currentUser.oderId) {
            myLeagueIds.add(member.leagueId);
          }
        } catch (e) {
          debugPrint('Error parsing member $key: $e');
        }
      }
    }
    
    // Get league details and mark all as joined (since these are "My Leagues")
    final leagues = <League>[];
    for (final leagueId in myLeagueIds) {
      final league = await getLeague(leagueId);
      if (league != null) {
        leagues.add(league.copyWith(isJoined: true));
      }
    }
    
    // Sort by created date (newest first)
    leagues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return leagues;
  }

  /// Get league by invite code
  Future<League?> getLeagueByInviteCode(String code) async {
    await _ensureInitialized();
    
    for (final key in _leaguesBoxInstance!.keys) {
      final data = _leaguesBoxInstance!.get(key);
      if (data != null) {
        try {
          final league = League.fromJson(json.decode(data) as Map<String, dynamic>);
          if (league.inviteCode?.toUpperCase() == code.toUpperCase()) {
            return league;
          }
        } catch (e) {
          debugPrint('Error parsing league $key: $e');
        }
      }
    }
    return null;
  }

  /// Join a league
  Future<LeagueMember?> joinLeague(String leagueId) async {
    await _ensureInitialized();
    
    final league = await getLeague(leagueId);
    if (league == null) {
      debugPrint('League not found: $leagueId');
      return null;
    }
    
    if (!league.canJoin) {
      debugPrint('Cannot join league: ${league.id} (full or not in draft status)');
      return null;
    }
    
    final currentUser = await getCurrentUser();
    
    // Check if already a member
    final existingMember = await getMember(leagueId, currentUser.oderId);
    if (existingMember != null) {
      debugPrint('User already a member of league: $leagueId');
      return existingMember;
    }
    
    // Create member
    final member = LeagueMember(
      id: _uuid.v4(),
      leagueId: leagueId,
      oderId: currentUser.oderId,
      userName: currentUser.userName,
      userImageUrl: currentUser.userImageUrl,
      joinedAt: DateTime.now(),
    );
    await _saveMember(member);
    
    // Update league member count
    final updatedLeague = league.copyWith(
      memberCount: league.memberCount + 1,
      updatedAt: DateTime.now(),
    );
    await _leaguesBoxInstance!.put(leagueId, json.encode(updatedLeague.toJson()));
    
    debugPrint('Joined league: ${league.name}');
    return member;
  }

  /// Leave a league
  Future<bool> leaveLeague(String leagueId) async {
    await _ensureInitialized();
    
    final currentUser = await getCurrentUser();
    final member = await getMember(leagueId, currentUser.oderId);
    
    if (member == null) {
      debugPrint('User is not a member of league: $leagueId');
      return false;
    }
    
    if (member.isCreator) {
      debugPrint('Creator cannot leave league. Delete the league instead.');
      return false;
    }
    
    // Remove member
    await _membersBoxInstance!.delete(member.id);
    
    // Update league member count
    final league = await getLeague(leagueId);
    if (league != null) {
      final updatedLeague = league.copyWith(
        memberCount: (league.memberCount - 1).clamp(0, league.maxMembers),
        updatedAt: DateTime.now(),
      );
      await _leaguesBoxInstance!.put(leagueId, json.encode(updatedLeague.toJson()));
    }
    
    // Delete user's fantasy team if exists
    final team = await getFantasyTeam(leagueId, currentUser.oderId);
    if (team != null) {
      await _teamsBoxInstance!.delete(team.id);
    }
    
    debugPrint('Left league: $leagueId');
    return true;
  }

  /// Delete a league (only creator can delete)
  Future<bool> deleteLeague(String leagueId) async {
    await _ensureInitialized();
    
    final currentUser = await getCurrentUser();
    final league = await getLeague(leagueId);
    
    if (league == null) return false;
    if (league.createdBy != currentUser.oderId) {
      debugPrint('Only creator can delete the league');
      return false;
    }
    
    // Delete all members
    final members = await getLeagueMembers(leagueId);
    for (final member in members) {
      await _membersBoxInstance!.delete(member.id);
    }
    
    // Delete all fantasy teams
    for (final key in _teamsBoxInstance!.keys) {
      final data = _teamsBoxInstance!.get(key);
      if (data != null) {
        try {
          final team = FantasyTeam.fromJson(json.decode(data) as Map<String, dynamic>);
          if (team.leagueId == leagueId) {
            await _teamsBoxInstance!.delete(key);
          }
        } catch (e) {
          debugPrint('Error parsing team $key: $e');
        }
      }
    }
    
    // Delete league
    await _leaguesBoxInstance!.delete(leagueId);
    
    debugPrint('Deleted league: $leagueId');
    return true;
  }

  // ==================== MEMBER OPERATIONS ====================

  /// Get all members of a league
  Future<List<LeagueMember>> getLeagueMembers(String leagueId) async {
    await _ensureInitialized();
    
    final members = <LeagueMember>[];
    for (final key in _membersBoxInstance!.keys) {
      final data = _membersBoxInstance!.get(key);
      if (data != null) {
        try {
          final member = LeagueMember.fromJson(json.decode(data) as Map<String, dynamic>);
          if (member.leagueId == leagueId) {
            members.add(member);
          }
        } catch (e) {
          debugPrint('Error parsing member $key: $e');
        }
      }
    }
    
    // Sort by rank (if set) or join date
    members.sort((a, b) {
      if (a.rank != b.rank) return a.rank.compareTo(b.rank);
      return a.joinedAt.compareTo(b.joinedAt);
    });
    
    return members;
  }

  /// Get a specific member
  Future<LeagueMember?> getMember(String leagueId, String userId) async {
    await _ensureInitialized();
    
    for (final key in _membersBoxInstance!.keys) {
      final data = _membersBoxInstance!.get(key);
      if (data != null) {
        try {
          final member = LeagueMember.fromJson(json.decode(data) as Map<String, dynamic>);
          if (member.leagueId == leagueId && member.oderId == userId) {
            return member;
          }
        } catch (e) {
          debugPrint('Error parsing member $key: $e');
        }
      }
    }
    return null;
  }

  /// Save a member
  Future<void> _saveMember(LeagueMember member) async {
    await _membersBoxInstance!.put(member.id, json.encode(member.toJson()));
  }

  // ==================== FANTASY TEAM OPERATIONS ====================

  /// Create or update a fantasy team
  Future<FantasyTeam> saveFantasyTeam(FantasyTeam team) async {
    await _ensureInitialized();
    
    final teamToSave = team.copyWith(updatedAt: DateTime.now());
    await _teamsBoxInstance!.put(team.id, json.encode(teamToSave.toJson()));
    
    // Update member with team ID
    final member = await getMember(team.leagueId, team.userId);
    if (member != null && member.fantasyTeamId == null) {
      final updatedMember = member.copyWith(fantasyTeamId: team.id);
      await _saveMember(updatedMember);
    }
    
    debugPrint('Saved fantasy team: ${team.id}');
    return teamToSave;
  }

  /// Get a fantasy team
  Future<FantasyTeam?> getFantasyTeam(String leagueId, String userId) async {
    await _ensureInitialized();
    
    for (final key in _teamsBoxInstance!.keys) {
      final data = _teamsBoxInstance!.get(key);
      if (data != null) {
        try {
          final team = FantasyTeam.fromJson(json.decode(data) as Map<String, dynamic>);
          if (team.leagueId == leagueId && team.userId == userId) {
            return team;
          }
        } catch (e) {
          debugPrint('Error parsing team $key: $e');
        }
      }
    }
    return null;
  }

  /// Get all teams in a league (for standings)
  Future<List<FantasyTeam>> getLeagueTeams(String leagueId) async {
    await _ensureInitialized();
    
    final teams = <FantasyTeam>[];
    for (final key in _teamsBoxInstance!.keys) {
      final data = _teamsBoxInstance!.get(key);
      if (data != null) {
        try {
          final team = FantasyTeam.fromJson(json.decode(data) as Map<String, dynamic>);
          if (team.leagueId == leagueId) {
            teams.add(team);
          }
        } catch (e) {
          debugPrint('Error parsing team $key: $e');
        }
      }
    }
    
    // Sort by total points (descending)
    teams.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return teams;
  }

  /// Create a new empty fantasy team
  Future<FantasyTeam> createEmptyTeam({
    required String leagueId,
    required double budget,
  }) async {
    await _ensureInitialized();
    
    final currentUser = await getCurrentUser();
    
    // Check if team already exists
    final existingTeam = await getFantasyTeam(leagueId, currentUser.oderId);
    if (existingTeam != null) {
      return existingTeam;
    }
    
    final team = FantasyTeam.empty(
      id: _uuid.v4(),
      leagueId: leagueId,
      userId: currentUser.oderId,
      userName: currentUser.userName,
      budget: budget,
    );
    
    return await saveFantasyTeam(team);
  }

  // ==================== USER OPERATIONS ====================

  /// Get current user (mock implementation - replace with real auth)
  Future<LeagueMember> getCurrentUser() async {
    await _ensureInitialized();
    
    // Check if we have a stored user
    final userData = _leaguesBoxInstance!.get(_currentUserKey);
    if (userData != null) {
      try {
        final userJson = json.decode(userData) as Map<String, dynamic>;
        return LeagueMember(
          id: userJson['id'] as String,
          leagueId: '',
          oderId: userJson['oderId'] as String,
          userName: userJson['userName'] as String,
          userImageUrl: userJson['userImageUrl'] as String?,
          joinedAt: DateTime.now(),
        );
      } catch (e) {
        debugPrint('Error parsing user: $e');
      }
    }
    
    // Create a default demo user
    final userId = _uuid.v4();
    final user = {
      'id': userId,
      'oderId': userId,
      'userName': 'Demo User',
      'userImageUrl': null,
    };
    await _leaguesBoxInstance!.put(_currentUserKey, json.encode(user));
    
    return LeagueMember(
      id: userId,
      leagueId: '',
      oderId: userId,
      userName: 'Demo User',
      joinedAt: DateTime.now(),
    );
  }

  /// Update current user
  Future<void> updateCurrentUser({
    required String userName,
    String? userImageUrl,
  }) async {
    await _ensureInitialized();
    
    final currentUser = await getCurrentUser();
    final user = {
      'id': currentUser.id,
      'oderId': currentUser.oderId,
      'userName': userName,
      'userImageUrl': userImageUrl,
    };
    await _leaguesBoxInstance!.put(_currentUserKey, json.encode(user));
  }

  // ==================== DEMO DATA ====================

  /// Create demo leagues if none exist
  Future<void> _createDemoLeaguesIfNeeded() async {
    final leagues = await getPublicLeagues();
    if (leagues.isNotEmpty) return;
    
    debugPrint('Creating demo leagues...');
    
    // Create some demo public leagues
    await createLeague(
      name: 'Liga MX Weekly Challenge',
      description: 'Compete with others in Liga MX matches every week!',
      type: LeagueType.public,
      maxMembers: 50,
      budget: 100.0,
      matchName: 'América vs Guadalajara',
      matchDateTime: DateTime.now().add(const Duration(days: 2)),
    );
    
    await createLeague(
      name: 'Free Fantasy League',
      description: 'No entry fee, just for fun!',
      type: LeagueType.public,
      maxMembers: 100,
      budget: 100.0,
      matchName: 'Cruz Azul vs Pumas',
      matchDateTime: DateTime.now().add(const Duration(days: 3)),
    );
    
    await createLeague(
      name: 'Premium Contest - \$10 Entry',
      description: 'Higher stakes, bigger rewards!',
      type: LeagueType.public,
      maxMembers: 20,
      budget: 100.0,
      entryFee: 10.0,
      matchName: 'Tigres vs Monterrey',
      matchDateTime: DateTime.now().add(const Duration(days: 1)),
    );
    
    debugPrint('Demo leagues created');
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _leaguesBoxInstance!.clear();
    await _membersBoxInstance!.clear();
    await _teamsBoxInstance!.clear();
    debugPrint('All league data cleared');
  }

  /// Generate new ID
  String generateId() => _uuid.v4();
}

