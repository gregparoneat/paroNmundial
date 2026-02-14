import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/api/firestore_service.dart';
import 'package:uuid/uuid.dart';

/// Repository for managing fantasy leagues
/// Uses Firestore for persistence and Hive for local caching
class LeagueRepository {
  static final LeagueRepository _instance = LeagueRepository._internal();
  factory LeagueRepository() => _instance;
  LeagueRepository._internal();

  static const String _leaguesBox = 'leagues_box';
  static const String _membersBox = 'league_members_box';
  static const String _teamsBox = 'fantasy_teams_box';
  static const String _currentUserKey = 'current_user';
  
  final _uuid = const Uuid();
  final _firestoreService = FirestoreService();
  
  Box<String>? _leaguesBoxInstance;
  Box<String>? _membersBoxInstance;
  Box<String>? _teamsBoxInstance;
  bool _initialized = false;
  bool _useFirestore = true; // Toggle Firestore sync

  /// Initialize the repository
  Future<void> init() async {
    if (_initialized) return;
    
    _leaguesBoxInstance = await Hive.openBox<String>(_leaguesBox);
    _membersBoxInstance = await Hive.openBox<String>(_membersBox);
    _teamsBoxInstance = await Hive.openBox<String>(_teamsBox);
    
    _initialized = true;
    debugPrint('LeagueRepository initialized');
    
    // Sync from Firestore or create demo data
    await _syncFromFirestoreOrCreateDemo();
  }
  
  /// Sync data from Firestore or create demo leagues if empty
  Future<void> _syncFromFirestoreOrCreateDemo() async {
    try {
      if (_useFirestore) {
        // Try to fetch leagues from Firestore
        final firestoreLeagues = await _firestoreService.getLeagues();
        
        if (firestoreLeagues.isNotEmpty) {
          debugPrint('Syncing ${firestoreLeagues.length} leagues from Firestore');
          
          // Cache leagues locally
          for (final leagueJson in firestoreLeagues) {
            final leagueId = leagueJson['id'] as String;
            await _leaguesBoxInstance!.put(leagueId, json.encode(leagueJson));
            
            // Also sync members and teams for this league
            final members = await _firestoreService.getLeagueMembers(leagueId);
            for (final memberJson in members) {
              final memberId = memberJson['id'] as String;
              await _membersBoxInstance!.put(memberId, json.encode(memberJson));
            }
            
            final teams = await _firestoreService.getLeagueTeams(leagueId);
            for (final teamJson in teams) {
              final teamId = teamJson['id'] as String;
              await _teamsBoxInstance!.put(teamId, json.encode(teamJson));
            }
          }
          
          debugPrint('Firestore sync complete');
          return;
        }
      }
    } catch (e) {
      debugPrint('Firestore sync failed, using local data: $e');
    }
    
    // Fall back to demo data if Firestore is empty or unavailable
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
    LeagueMode mode = LeagueMode.classic,
    DraftSettings? draftSettings,
    TradeSettings? tradeSettings,
    int rosterSize = 18,
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
      mode: mode,
      draftSettings: draftSettings,
      tradeSettings: tradeSettings,
      rosterSize: rosterSize,
    );
    
    // Save league (to Hive and Firestore)
    await _saveLeague(league);
    
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
    
    debugPrint('Created ${mode.name} league: ${league.name} (${league.id})');
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
    await _saveLeague(updatedLeague);
    
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
    if (_useFirestore) {
      try {
        await _firestoreService.deleteMember(member.id);
      } catch (e) {
        debugPrint('Failed to delete member from Firestore: $e');
      }
    }
    
    // Update league member count
    final league = await getLeague(leagueId);
    if (league != null) {
      final updatedLeague = league.copyWith(
        memberCount: (league.memberCount - 1).clamp(0, league.maxMembers),
        updatedAt: DateTime.now(),
      );
      await _saveLeague(updatedLeague);
    }
    
    // Delete user's fantasy team if exists
    final team = await getFantasyTeam(leagueId, currentUser.oderId);
    if (team != null) {
      await _teamsBoxInstance!.delete(team.id);
      if (_useFirestore) {
        try {
          await _firestoreService.deleteFantasyTeam(team.id);
        } catch (e) {
          debugPrint('Failed to delete team from Firestore: $e');
        }
      }
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
          debugPrint('(1) Error parsing team $key: $e');
        }
      }
    }
    
    // Delete league
    await _leaguesBoxInstance!.delete(leagueId);
    
    // Delete from Firestore (this also deletes members and teams)
    if (_useFirestore) {
      try {
        await _firestoreService.deleteLeague(leagueId);
      } catch (e) {
        debugPrint('Failed to delete league from Firestore: $e');
      }
    }
    
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

  /// Save a member (to Hive and Firestore)
  Future<void> _saveMember(LeagueMember member) async {
    final memberJson = member.toJson();
    await _membersBoxInstance!.put(member.id, json.encode(memberJson));
    
    // Sync to Firestore
    if (_useFirestore) {
      try {
        await _firestoreService.saveMember(memberJson);
      } catch (e) {
        debugPrint('Failed to sync member to Firestore: $e');
      }
    }
  }
  
  /// Save a league (to Hive and Firestore)
  Future<void> _saveLeague(League league) async {
    final leagueJson = league.toJson();
    await _leaguesBoxInstance!.put(league.id, json.encode(leagueJson));
    
    // Sync to Firestore
    if (_useFirestore) {
      try {
        await _firestoreService.saveLeague(leagueJson);
      } catch (e) {
        debugPrint('Failed to sync league to Firestore: $e');
      }
    }
  }

  // ==================== FANTASY TEAM OPERATIONS ====================

  /// Create or update a fantasy team
  Future<FantasyTeam> saveFantasyTeam(FantasyTeam team) async {
    await _ensureInitialized();
    
    final teamToSave = team.copyWith(updatedAt: DateTime.now());
    final teamJson = teamToSave.toJson();
    await _teamsBoxInstance!.put(team.id, json.encode(teamJson));
    
    // Sync to Firestore
    if (_useFirestore) {
      try {
        await _firestoreService.saveFantasyTeam(teamJson);
      } catch (e) {
        debugPrint('Failed to sync fantasy team to Firestore: $e');
      }
    }
    
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
          debugPrint('(2) Error parsing team $key: $e');
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
          debugPrint('(3) Error parsing team $key: $e');
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
    String? teamName,
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
      teamName: teamName ?? '${currentUser.userName}\'s Team',
      budget: budget,
    );
    
    return await saveFantasyTeam(team);
  }
  
  /// Update a fantasy team's name
  Future<FantasyTeam?> updateTeamName(String leagueId, String newTeamName) async {
    await _ensureInitialized();
    
    final currentUser = await getCurrentUser();
    final team = await getFantasyTeam(leagueId, currentUser.oderId);
    
    if (team == null) return null;
    
    final updatedTeam = team.copyWith(teamName: newTeamName);
    return await saveFantasyTeam(updatedTeam);
  }
  
  /// Get the next matchup for the current user in a league
  /// Returns the opponent's fantasy team, or null if no matchup
  Future<FantasyTeam?> getNextMatchup(String leagueId) async {
    await _ensureInitialized();
    
    final currentUser = await getCurrentUser();
    final teams = await getLeagueTeams(leagueId);
    
    if (teams.length < 2) return null;
    
    // Find user's team index
    final userTeamIndex = teams.indexWhere((t) => t.userId == currentUser.oderId);
    if (userTeamIndex == -1) return null;
    
    // Simple round-robin matchup: pair teams sequentially
    // In a real implementation, you'd have a proper fixture/schedule system
    final totalTeams = teams.length;
    int opponentIndex;
    
    if (userTeamIndex % 2 == 0) {
      // Even index: opponent is next team
      opponentIndex = (userTeamIndex + 1) % totalTeams;
    } else {
      // Odd index: opponent is previous team
      opponentIndex = (userTeamIndex - 1 + totalTeams) % totalTeams;
    }
    
    // Make sure we don't match against ourselves
    if (opponentIndex == userTeamIndex) {
      opponentIndex = (userTeamIndex + 1) % totalTeams;
    }
    
    return teams[opponentIndex];
  }
  
  /// Get all matchups for a league (pairing teams)
  Future<List<(FantasyTeam, FantasyTeam)>> getLeagueMatchups(String leagueId) async {
    await _ensureInitialized();
    
    final teams = await getLeagueTeams(leagueId);
    final matchups = <(FantasyTeam, FantasyTeam)>[];
    
    // Pair teams: 0 vs 1, 2 vs 3, etc.
    for (int i = 0; i < teams.length - 1; i += 2) {
      matchups.add((teams[i], teams[i + 1]));
    }
    
    return matchups;
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
    final existingLeagues = await getPublicLeagues();
    if (existingLeagues.length >= 5) return; // Already have seed data
    
    debugPrint('Creating comprehensive seed data for leagues...');
    
    final currentUser = await getCurrentUser();

    // ==================== 1. ACTIVE LEAGUE (Match in progress) ====================
    final activeLeagueId = _uuid.v4();
    final activeLeague = League(
      id: activeLeagueId,
      name: '🔴 LIVE: Clásico Nacional',
      description: 'América vs Guadalajara - Match is currently in progress!',
      type: LeagueType.public,
      status: LeagueStatus.active,
      maxMembers: 50,
      budget: 100.0,
      matchName: 'América vs Guadalajara',
      matchDateTime: DateTime.now().subtract(const Duration(hours: 1)), // Started 1 hour ago
      createdBy: 'system',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      memberCount: 12,
    );
    await _leaguesBoxInstance!.put(activeLeagueId, json.encode(activeLeague.toJson()));
    
    // Add current user as member of active league
    final activeUserMember = LeagueMember(
      id: _uuid.v4(),
      leagueId: activeLeagueId,
      oderId: currentUser.oderId,
      userName: currentUser.userName,
      joinedAt: DateTime.now().subtract(const Duration(days: 2)),
      rank: 3,
      totalPoints: 47.5,
    );
    await _saveMember(activeUserMember);
    
    // Create user's team for active league with players and points
    final activeUserTeam = FantasyTeam(
      id: _uuid.v4(),
      leagueId: activeLeagueId,
      userId: currentUser.oderId,
      userName: currentUser.userName,
      teamName: currentUser.userName,
      players: _createDemoPlayers(withPoints: true),
      totalCredits: 100.0,
      budgetRemaining: 2.5,
      totalPoints: 47.5,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isLocked: true,
    );
    await _teamsBoxInstance!.put(activeUserTeam.id, json.encode(activeUserTeam.toJson()));
    
    // Add AI opponents with their teams
    await _addAiMembersWithTeams(activeLeagueId, [
      ('Carlos García', 1, 62.0),
      ('María López', 2, 55.5),
      ('Juan Hernández', 4, 42.0),
      ('Ana Martínez', 5, 38.5),
      ('Pedro Sánchez', 6, 35.0),
    ]);
    
    // ==================== 2. COMPLETED LEAGUE (Final standings) ====================
    final completedLeagueId = _uuid.v4();
    final completedLeague = League(
      id: completedLeagueId,
      name: '✅ Jornada 3 - Cruz Azul vs Pumas',
      description: 'Match completed! Final standings available.',
      type: LeagueType.public,
      status: LeagueStatus.completed,
      maxMembers: 30,
      budget: 100.0,
      matchName: 'Cruz Azul 2-1 Pumas',
      matchDateTime: DateTime.now().subtract(const Duration(days: 2)),
      createdBy: 'system',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      memberCount: 8,
      entryFee: 5.0,
      prizePool: 36.0,
    );
    await _leaguesBoxInstance!.put(completedLeagueId, json.encode(completedLeague.toJson()));
    
    // Add current user - won this league!
    final completedUserMember = LeagueMember(
      id: _uuid.v4(),
      leagueId: completedLeagueId,
      oderId: currentUser.oderId,
      userName: currentUser.userName,
      joinedAt: DateTime.now().subtract(const Duration(days: 4)),
      rank: 1,
      totalPoints: 78.5,
    );
    await _saveMember(completedUserMember);
    
    // Create user's winning team
    final completedUserTeam = FantasyTeam(
      id: _uuid.v4(),
      leagueId: completedLeagueId,
      userId: currentUser.oderId,
      userName: currentUser.userName,
      teamName: currentUser.userName,
      players: _createDemoPlayers(withPoints: true, highScoring: true),
      totalCredits: 100.0,
      budgetRemaining: 5.0,
      totalPoints: 78.5,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      isLocked: true,
    );
    await _teamsBoxInstance!.put(completedUserTeam.id, json.encode(completedUserTeam.toJson()));
    
    await _addAiMembersWithTeams(completedLeagueId, [
      ('Roberto Díaz', 2, 72.0),
      ('Laura Vega', 3, 65.5),
      ('Miguel Torres', 4, 58.0),
    ]);
    
    // ==================== 3. FULL LEAGUE (20 members, all with teams) ====================
    final fullLeagueId = _uuid.v4();
    final fullLeague = League(
      id: fullLeagueId,
      name: '🏆 Full League: Jornada 5 Classic',
      description: 'All spots filled! Check standings and prepare for matchday.',
      type: LeagueType.public,
      status: LeagueStatus.draft,
      maxMembers: 20,
      budget: 100.0,
      matchName: 'Tigres vs Monterrey',
      matchDateTime: DateTime.now().add(const Duration(days: 1)),
      createdBy: 'system',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      memberCount: 20,
    );
    await _leaguesBoxInstance!.put(fullLeagueId, json.encode(fullLeague.toJson()));
    
    // Add current user to full league
    final fullLeagueUserMember = LeagueMember(
      id: _uuid.v4(),
      leagueId: fullLeagueId,
      oderId: currentUser.oderId,
      userName: currentUser.userName,
      joinedAt: DateTime.now().subtract(const Duration(days: 4)),
      rank: 5,
    );
    await _saveMember(fullLeagueUserMember);
    
    // Create user's team with predicted points
    final fullLeagueUserTeam = FantasyTeam(
      id: _uuid.v4(),
      leagueId: fullLeagueId,
      userId: currentUser.oderId,
      userName: currentUser.userName,
      teamName: 'random ass name${_uuid.v4()}',
      players: _createDemoPlayers(withPoints: false, seed: 0),
      totalCredits: 100.0,
      budgetRemaining: 3.5,
      totalPoints: 0,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );
    await _teamsBoxInstance!.put(fullLeagueUserTeam.id, json.encode(fullLeagueUserTeam.toJson()));
    
    // Add 19 more AI members with built teams (total 20)
    final fullLeagueMembers = [
      ('Carlos García', 1), ('María López', 2), ('Juan Hernández', 3),
      ('Ana Martínez', 4), ('Pedro Sánchez', 6), ('Laura Vega', 7),
      ('Roberto Díaz', 8), ('Sofia Castro', 9), ('Miguel Torres', 10),
      ('Andrés Moreno', 11), ('Carmen Flores', 12), ('Diego Ramírez', 13),
      ('Patricia Gómez', 14), ('Fernando Silva', 15), ('Lucía Ruiz', 16),
      ('Jorge Medina', 17), ('Isabel Navarro', 18), ('Ricardo Ortiz', 19),
      ('Elena Vargas', 20),
    ];
    await _addAiMembersWithTeamsAndPredictions(fullLeagueId, fullLeagueMembers);
    
    // ==================== 4. UPCOMING LEAGUES (Draft status - joinable) ====================
    
    // 4a. Free league - user already joined
    await createLeague(
      name: 'Liga MX Jornada 6 - Free Entry',
      description: 'Compete for glory in the upcoming matchday!',
      type: LeagueType.public,
      maxMembers: 100,
      budget: 100.0,
      matchName: 'León vs Santos',
      matchDateTime: DateTime.now().add(const Duration(days: 3)),
    );
    
    // 4b. Small league with spots available
    final smallLeagueId = _uuid.v4();
    final smallLeague = League(
      id: smallLeagueId,
      name: '⚔️ Head-to-Head Challenge',
      description: 'Small league, big competition!',
      type: LeagueType.public,
      status: LeagueStatus.draft,
      maxMembers: 10,
      budget: 100.0,
      matchName: 'Toluca vs Pachuca',
      matchDateTime: DateTime.now().add(const Duration(hours: 18)),
      createdBy: 'system',
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      memberCount: 6,
    );
    await _leaguesBoxInstance!.put(smallLeagueId, json.encode(smallLeague.toJson()));
    
    // ==================== 4. PRIVATE LEAGUE (with invite code) ====================
    final privateLeagueId = _uuid.v4();
    final privateLeague = League(
      id: privateLeagueId,
      name: '🔒 Amigos del Fantasy',
      description: 'Private league for friends only. Share the code to invite!',
      type: LeagueType.private,
      status: LeagueStatus.draft,
      inviteCode: 'AMIGOS',
      maxMembers: 12,
      budget: 100.0,
      matchName: 'Atlas vs Necaxa',
      matchDateTime: DateTime.now().add(const Duration(days: 4)),
      createdBy: currentUser.oderId,
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      memberCount: 4,
    );
    await _leaguesBoxInstance!.put(privateLeagueId, json.encode(privateLeague.toJson()));
    
    // Add current user as creator
    final privateUserMember = LeagueMember(
      id: _uuid.v4(),
      leagueId: privateLeagueId,
      oderId: currentUser.oderId,
      userName: currentUser.userName,
      joinedAt: DateTime.now().subtract(const Duration(hours: 6)),
      isCreator: true,
    );
    await _saveMember(privateUserMember);
    
    // Add some friends
    await _addAiMembersWithTeams(privateLeagueId, [
      ('Diego Ramírez', 0, 0.0),
      ('Sofia Castro', 0, 0.0),
      ('Andrés Moreno', 0, 0.0),
    ], withTeams: false);
    
    // ==================== 5. USER'S TEAM IN PROGRESS (draft league) ====================
    final inProgressLeagueId = _uuid.v4();
    final inProgressLeague = League(
      id: inProgressLeagueId,
      name: '⚽ Jornada 6 Challenge',
      description: 'Build your team before the deadline!',
      type: LeagueType.public,
      status: LeagueStatus.draft,
      maxMembers: 50,
      budget: 100.0,
      matchName: 'Mazatlán vs Querétaro',
      matchDateTime: DateTime.now().add(const Duration(days: 5)),
      createdBy: 'system',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      memberCount: 15,
    );
    await _leaguesBoxInstance!.put(inProgressLeagueId, json.encode(inProgressLeague.toJson()));
    
    // Add user with partial team
    final inProgressUserMember = LeagueMember(
      id: _uuid.v4(),
      leagueId: inProgressLeagueId,
      oderId: currentUser.oderId,
      userName: currentUser.userName,
      joinedAt: DateTime.now().subtract(const Duration(hours: 3)),
    );
    await _saveMember(inProgressUserMember);
    
    // Create user's partial team (only 7 players)
    final partialTeam = FantasyTeam(
      id: _uuid.v4(),
      leagueId: inProgressLeagueId,
      userId: currentUser.oderId,
      userName: currentUser.userName,
      teamName: currentUser.userName,
      players: _createDemoPlayers(withPoints: false, count: 7),
      totalCredits: 100.0,
      budgetRemaining: 35.0,
      totalPoints: 0,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );
    await _teamsBoxInstance!.put(partialTeam.id, json.encode(partialTeam.toJson()));
    
    debugPrint('Comprehensive seed data created: 5+ leagues with various scenarios');
  }
  
  /// Create demo players for a fantasy team with predicted points
  List<FantasyTeamPlayer> _createDemoPlayers({
    bool withPoints = false,
    bool highScoring = false,
    int count = 11,
    int seed = 0, // Seed for variation
  }) {
    // Player data: (id, name, pos, team, credits, basePoints, predictedPoints)
    final demoPlayerData = [
      // Goalkeepers
      (37547842, 'Guillermo Ochoa', 'GK', 'América', 9.0, 6.0, 4.5),
      (260742, 'Gabriel Fernández', 'GK', 'Cruz Azul', 8.5, 4.0, 5.0),
      (1234520, 'Rodolfo Cota', 'GK', 'León', 7.5, 5.0, 4.0),
      (1234521, 'Nahuel Guzmán', 'GK', 'Tigres', 8.0, 4.5, 3.5),
      // Defenders
      (1234501, 'Néstor Araujo', 'DEF', 'América', 7.5, 5.5, 5.0),
      (1234502, 'Luis Fuentes', 'DEF', 'Cruz Azul', 6.5, 4.0, 4.5),
      (1234503, 'Israel Reyes', 'DEF', 'América', 6.0, 6.0, 5.5),
      (1234504, 'Julio González', 'DEF', 'Pumas', 5.5, 3.5, 3.0),
      (1234522, 'Hugo Nervo', 'DEF', 'Atlas', 6.0, 4.0, 4.0),
      (1234523, 'Jesús Angulo', 'DEF', 'Tigres', 7.0, 5.0, 5.0),
      (1234524, 'Érick Aguirre', 'DEF', 'Monterrey', 6.5, 4.5, 4.0),
      (1234525, 'Jorge Sánchez', 'DEF', 'América', 6.5, 5.0, 4.5),
      // Midfielders
      (159455, 'Paulinho', 'MID', 'Toluca', 10.0, 12.0, 8.5),
      (1234506, 'Álvaro Fidalgo', 'MID', 'América', 9.5, 8.5, 7.5),
      (1234507, 'Carlos Rodríguez', 'MID', 'Cruz Azul', 8.0, 7.0, 6.5),
      (1234508, 'Luis Romo', 'MID', 'Monterrey', 7.5, 5.0, 5.5),
      (1234509, 'Erick Sánchez', 'MID', 'Pachuca', 7.0, 6.5, 6.0),
      (1234526, 'Sebastián Córdova', 'MID', 'Tigres', 8.5, 6.0, 6.5),
      (1234527, 'Orbelín Pineda', 'MID', 'Monterrey', 8.0, 5.5, 6.0),
      (1234528, 'Diego Valdés', 'MID', 'América', 9.0, 7.0, 7.0),
      // Forwards
      (1234510, 'Henry Martín', 'FWD', 'América', 10.5, 10.0, 9.0),
      (1234511, 'André-Pierre Gignac', 'FWD', 'Tigres', 11.0, 9.0, 8.5),
      (1234512, 'Germán Berterame', 'FWD', 'Monterrey', 9.5, 11.5, 9.5),
      (1234513, 'Ángel Sepúlveda', 'FWD', 'Toluca', 8.0, 7.5, 7.0),
      (1234529, 'Uriel Antuna', 'FWD', 'Cruz Azul', 8.5, 6.0, 6.5),
      (1234530, 'Julián Quiñones', 'FWD', 'Atlas', 9.0, 7.5, 7.5),
    ];
    
    final players = <FantasyTeamPlayer>[];
    final usedIndices = <int>{};
    
    // Shuffle based on seed for variation
    final shuffledData = List.from(demoPlayerData);
    if (seed > 0) {
      for (int i = 0; i < seed; i++) {
        final temp = shuffledData.removeAt(0);
        shuffledData.add(temp);
      }
    }
    
    // Ensure we have proper formation: 1 GK, 4 DEF, 4 MID, 2 FWD
    final formation = {
      'GK': 1,
      'DEF': count >= 11 ? 4 : (count >= 7 ? 3 : 2),
      'MID': count >= 11 ? 4 : (count >= 7 ? 2 : 2),
      'FWD': count >= 11 ? 2 : (count >= 7 ? 2 : 1),
    };
    
    for (final entry in formation.entries) {
      final posCode = entry.key;
      final needed = entry.value;
      final posPlayers = shuffledData
          .asMap()
          .entries
          .where((e) => e.value.$3 == posCode && !usedIndices.contains(e.key))
          .take(needed);
      
      for (final p in posPlayers) {
        usedIndices.add(p.key);
        final data = p.value;
        final basePoints = highScoring ? data.$6 * 1.5 : data.$6;
        final points = withPoints ? basePoints + (p.key % 5) : 0.0;
        // Add some variation to predicted points
        final predictedPoints = data.$7 + (seed % 3) * 0.5 - 0.5;
        
        players.add(FantasyTeamPlayer(
          playerId: data.$1,
          playerName: data.$2,
          position: _stringToPosition(data.$3),
          teamName: data.$4,
          price: data.$5,
          points: points,
          predictedPoints: predictedPoints > 0 ? predictedPoints : 0.0,
        ));
      }
    }
    
    // Set captain/VC properly
    if (players.length >= 2) {
      // Find best forward for captain
      final forwards = players.where((p) => p.position == PlayerPosition.forward || p.position == PlayerPosition.attacker).toList();
      final mids = players.where((p) => p.position == PlayerPosition.midfielder).toList();
      
      int captainIdx = -1;
      int vcIdx = -1;
      
      if (forwards.isNotEmpty) {
        captainIdx = players.indexOf(forwards.first);
      } else if (mids.isNotEmpty) {
        captainIdx = players.indexOf(mids.first);
      }
      
      if (mids.isNotEmpty && players.indexOf(mids.first) != captainIdx) {
        vcIdx = players.indexOf(mids.first);
      } else if (forwards.length > 1) {
        vcIdx = players.indexOf(forwards[1]);
      }
      
      if (captainIdx >= 0) {
        players[captainIdx] = players[captainIdx].copyWith(isCaptain: true, isViceCaptain: false);
      }
      if (vcIdx >= 0 && vcIdx != captainIdx) {
        players[vcIdx] = players[vcIdx].copyWith(isViceCaptain: true, isCaptain: false);
      }
    }
    
    return players.take(count).toList();
  }
  
  PlayerPosition _stringToPosition(String code) {
    switch (code) {
      case 'GK':
        return PlayerPosition.goalkeeper;
      case 'DEF':
        return PlayerPosition.defender;
      case 'MID':
        return PlayerPosition.midfielder;
      case 'FWD':
        return PlayerPosition.forward;
      default:
        return PlayerPosition.midfielder;
    }
  }
  
  /// Add AI members with optional teams
  Future<void> _addAiMembersWithTeams(
    String leagueId,
    List<(String name, int rank, double points)> members, {
    bool withTeams = true,
  }) async {
    final teamNames = _getFantasyTeamNames();
    
    for (int i = 0; i < members.length; i++) {
      final m = members[i];
      final oderId = _uuid.v4();
      final member = LeagueMember(
        id: _uuid.v4(),
        leagueId: leagueId,
        oderId: oderId,
        userName: m.$1,
        joinedAt: DateTime.now().subtract(Duration(days: m.$2 + 1)),
        rank: m.$2,
        totalPoints: m.$3,
      );
      await _saveMember(member);
      
      if (withTeams && m.$3 > 0) {
        final team = FantasyTeam(
          id: _uuid.v4(),
          leagueId: leagueId,
          userId: oderId,
          userName: m.$1,
          teamName: teamNames[i % teamNames.length],
          players: _createDemoPlayers(withPoints: true, seed: m.$2),
          totalCredits: 100.0,
          budgetRemaining: 3.0 + (m.$2 * 0.5),
          totalPoints: m.$3,
          createdAt: DateTime.now().subtract(Duration(days: m.$2 + 2)),
          isLocked: true,
        );
        await _teamsBoxInstance!.put(team.id, json.encode(team.toJson()));
      }
    }
  }
  
  /// Add AI members with teams that have predicted points (for upcoming leagues)
  Future<void> _addAiMembersWithTeamsAndPredictions(
    String leagueId,
    List<(String name, int rank)> members,
  ) async {
    final teamNames = _getFantasyTeamNames();
    
    for (int i = 0; i < members.length; i++) {
      final m = members[i];
      final oderId = _uuid.v4();
      final member = LeagueMember(
        id: _uuid.v4(),
        leagueId: leagueId,
        oderId: oderId,
        userName: m.$1,
        joinedAt: DateTime.now().subtract(Duration(days: m.$2 + 1)),
        rank: m.$2,
        totalPoints: 0, // No points yet - league hasn't started
      );
      await _saveMember(member);
      
      // Create team with predicted points (different seed for each player)
      final team = FantasyTeam(
        id: _uuid.v4(),
        leagueId: leagueId,
        userId: oderId,
        userName: m.$1,
        teamName: teamNames[i % teamNames.length],
        players: _createDemoPlayers(withPoints: false, seed: i + 1),
        totalCredits: 100.0,
        budgetRemaining: 2.0 + (i % 5) * 0.5,
        totalPoints: 0,
        createdAt: DateTime.now().subtract(Duration(days: m.$2 + 2)),
      );
      await _teamsBoxInstance!.put(team.id, json.encode(team.toJson()));
    }
  }
  
  /// Get a list of creative fantasy team names
  List<String> _getFantasyTeamNames() {
    return [
      'Los Galácticos FC',
      'Dream Team XI',
      'Águilas Doradas',
      'Los Invencibles',
      'Máquina Azul',
      'Tigres del Norte',
      'Rayados United',
      'Pumas Power',
      'Diablos Rojos',
      'Santos Warriors',
      'Atlas Legends',
      'Pachuca Tuzos',
      'León Esmeralda',
      'Necaxa Thunder',
      'Querétaro FC',
      'Mazatlán Crew',
      'Juárez Bravos',
      'Puebla Franja',
      'Toluca Devils',
      'Chivas Pride',
    ];
  }
  
  /// Force recreate all seed data (for testing)
  Future<void> resetSeedData() async {
    await _ensureInitialized();
    await clearAllData();
    await _createDemoLeaguesIfNeeded();
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

