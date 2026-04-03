import 'dart:convert';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  static const String _draftTestLeagueName = 'TEST: Draft Today';
  static const String _draftQuickTestLeagueName = 'TEST: Draft Today (6 Teams)';
  static const String _tradeFlowTestLeagueName =
      'TEST: Trades Sandbox (Draft Complete)';

  final _uuid = const Uuid();
  final _firestoreService = FirestoreService();

  Box<String>? _leaguesBoxInstance;
  Box<String>? _membersBoxInstance;
  Box<String>? _teamsBoxInstance;
  bool _initialized = false;
  bool _useFirestore = true; // Toggle Firestore sync
  Future<void>? _initFuture;

  bool _isReservedLeagueBoxKey(dynamic key) => key == _currentUserKey;

  void _handleFirestoreSyncError(Object error, String operation) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      if (_useFirestore) {
        debugPrint(
          'Firestore permission denied during $operation. Switching to local-only mode.',
        );
      }
      _useFirestore = false;
      return;
    }
    debugPrint('Failed Firestore operation ($operation): $error');
  }

  /// Initialize the repository
  Future<void> init() async {
    if (_initFuture != null) {
      return _initFuture!;
    }

    _initFuture = _initializeOnce();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _initializeOnce() async {
    if (_initialized) {
      await _migrateClassicLeagueBudgets();
      return;
    }

    _leaguesBoxInstance = await Hive.openBox<String>(_leaguesBox);
    _membersBoxInstance = await Hive.openBox<String>(_membersBox);
    _teamsBoxInstance = await Hive.openBox<String>(_teamsBox);

    _initialized = true;
    debugPrint('LeagueRepository initialized');

    // Sync from Firestore or create demo data
    await _syncFromFirestoreOrCreateDemo();
    await _cleanupLegacyDemoLeagues();
    await _cleanupLegacyDraftTestLeagues();
    await _migrateClassicLeagueBudgets();
  }

  static const Set<String> _legacyDemoLeagueNames = {
    '🔴 LIVE: Clásico Nacional',
    '✅ Jornada 3 - Cruz Azul vs Pumas',
    '🏆 Full League: Jornada 5 Classic',
    'Liga MX Jornada 6 - Free Entry',
    '⚔️ Head-to-Head Challenge',
    '🔒 Amigos del Fantasy',
    '⚽ Jornada 6 Challenge',
  };

  bool _isLegacyDemoLeague(League league) {
    final normalizedName = league.name.trim();
    final normalizedMatchName = league.matchName?.trim() ?? '';
    final description = (league.description ?? '').toLowerCase();

    if (_legacyDemoLeagueNames.contains(normalizedName)) return true;
    if (league.createdBy == 'system') return true;
    if (normalizedName.contains('Liga MX')) return true;
    if (normalizedMatchName.contains('América') ||
        normalizedMatchName.contains('Guadalajara') ||
        normalizedMatchName.contains('Cruz Azul') ||
        normalizedMatchName.contains('Pumas') ||
        normalizedMatchName.contains('Tigres') ||
        normalizedMatchName.contains('Monterrey') ||
        normalizedMatchName.contains('Toluca') ||
        normalizedMatchName.contains('Pachuca') ||
        normalizedMatchName.contains('Atlas') ||
        normalizedMatchName.contains('Necaxa') ||
        normalizedMatchName.contains('Mazatlán') ||
        normalizedMatchName.contains('Querétaro') ||
        normalizedMatchName.contains('León') ||
        normalizedMatchName.contains('Santos')) {
      return true;
    }

    return description.contains('private league for friends only') ||
        description.contains('small league, big competition') ||
        description.contains('compete for glory in the upcoming matchday');
  }

  Future<void> _cleanupLegacyDemoLeagues() async {
    await _ensureInitialized();

    final leaguesToDelete = <String>[];
    for (final key in _leaguesBoxInstance!.keys) {
      if (_isReservedLeagueBoxKey(key)) continue;
      final data = _leaguesBoxInstance!.get(key);
      if (data == null) continue;

      try {
        final league = League.fromJson(
          json.decode(data) as Map<String, dynamic>,
        );
        if (_isLegacyDemoLeague(league)) {
          leaguesToDelete.add(league.id);
        }
      } catch (e) {
        debugPrint('Error parsing potential legacy demo league $key: $e');
      }
    }

    if (leaguesToDelete.isEmpty) return;

    for (final leagueId in leaguesToDelete) {
      await _removeLocalLeagueData(leagueId);
      if (_useFirestore) {
        try {
          await _firestoreService.deleteLeague(leagueId);
        } catch (e) {
          _handleFirestoreSyncError(e, 'deleteLegacyDemoLeague');
        }
      }
    }

    debugPrint(
      'Removed ${leaguesToDelete.length} legacy demo league(s) from World Cup mode',
    );
  }

  bool _isLegacyDraftTestLeague(League league) {
    final normalizedName = league.name.trim();
    return normalizedName == 'TEST: Draft Today' ||
        normalizedName == 'TEST: Draft Today (6 Teams)' ||
        normalizedName == 'TEST: Trades Sandbox (Draft Complete)' ||
        (league.mode == LeagueMode.draft && normalizedName.startsWith('TEST:'));
  }

  Future<void> _cleanupLegacyDraftTestLeagues() async {
    await _ensureInitialized();

    final leaguesToDelete = <String>[];
    for (final key in _leaguesBoxInstance!.keys) {
      if (_isReservedLeagueBoxKey(key)) continue;
      final data = _leaguesBoxInstance!.get(key);
      if (data == null) continue;

      try {
        final league = League.fromJson(
          json.decode(data) as Map<String, dynamic>,
        );
        if (_isLegacyDraftTestLeague(league)) {
          leaguesToDelete.add(league.id);
        }
      } catch (e) {
        debugPrint('Error parsing potential legacy draft test league $key: $e');
      }
    }

    if (leaguesToDelete.isEmpty) return;

    for (final leagueId in leaguesToDelete) {
      await _removeLocalLeagueData(leagueId);
      if (_useFirestore) {
        try {
          await _firestoreService.deleteLeague(leagueId);
        } catch (e) {
          _handleFirestoreSyncError(e, 'deleteLegacyDraftTestLeague');
        }
      }
    }

    debugPrint(
      'Removed ${leaguesToDelete.length} legacy draft test league(s) from classic-only mode',
    );
  }

  Future<void> _migrateClassicLeagueBudgets() async {
    await _ensureInitialized();

    const targetBudget = 150.0;
    final migratedLeagueIds = <String>[];

    for (final key in _leaguesBoxInstance!.keys) {
      if (_isReservedLeagueBoxKey(key)) continue;
      final data = _leaguesBoxInstance!.get(key);
      if (data == null) continue;

      try {
        final league = League.fromJson(
          json.decode(data) as Map<String, dynamic>,
        );
        final shouldMigrate =
            league.isClassicMode && (league.budget - 100.0).abs() < 0.001;
        if (!shouldMigrate) continue;

        final updatedLeague = league.copyWith(
          budget: targetBudget,
          updatedAt: DateTime.now(),
        );
        await _saveLeague(updatedLeague);
        migratedLeagueIds.add(league.id);
      } catch (e) {
        debugPrint('Classic budget migration parse error for league $key: $e');
      }
    }

    if (migratedLeagueIds.isEmpty) return;

    for (final leagueId in migratedLeagueIds) {
      final teams = await getLeagueTeams(leagueId);
      for (final team in teams) {
        final delta = targetBudget - team.totalCredits;
        if (delta.abs() < 0.001) continue;

        final updatedTeam = team.copyWith(
          totalCredits: targetBudget,
          budgetRemaining: (team.budgetRemaining + delta).clamp(
            0.0,
            targetBudget,
          ),
          updatedAt: DateTime.now(),
        );
        await saveFantasyTeam(updatedTeam);
      }
    }

    debugPrint(
      'Classic budget migration complete for ${migratedLeagueIds.length} leagues',
    );
  }

  /// Sync data from Firestore or create demo leagues if empty
  Future<void> _syncFromFirestoreOrCreateDemo() async {
    try {
      if (_useFirestore) {
        // Try to fetch leagues from Firestore
        final firestoreLeagues = await _firestoreService.getLeagues();

        if (firestoreLeagues.isNotEmpty) {
          debugPrint(
            'Syncing ${firestoreLeagues.length} leagues from Firestore',
          );

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
    double budget = 150.0,
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
    final inviteCode = type == LeagueType.private
        ? League.generateInviteCode()
        : null;

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
      mode: LeagueMode.classic,
      draftSettings: null,
      tradeSettings: null,
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

    debugPrint('Created classic league: ${league.name} (${league.id})');
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
          final member = LeagueMember.fromJson(
            json.decode(data) as Map<String, dynamic>,
          );
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
      if (_isReservedLeagueBoxKey(key)) continue;
      final data = _leaguesBoxInstance!.get(key);
      if (data != null) {
        try {
          final league = League.fromJson(
            json.decode(data) as Map<String, dynamic>,
          );
          if (league.isPublic && league.status == LeagueStatus.draft) {
            // Mark as joined if user is a member
            leagues.add(
              league.copyWith(isJoined: myLeagueIds.contains(league.id)),
            );
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
          final member = LeagueMember.fromJson(
            json.decode(data) as Map<String, dynamic>,
          );
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
      if (_isReservedLeagueBoxKey(key)) continue;
      final data = _leaguesBoxInstance!.get(key);
      if (data != null) {
        try {
          final league = League.fromJson(
            json.decode(data) as Map<String, dynamic>,
          );
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
      debugPrint(
        'Cannot join league: ${league.id} (full or not in draft status)',
      );
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

    final members = await getLeagueMembers(leagueId);
    if (members.length > 1) {
      debugPrint('League can only be deleted when it has one member');
      return false;
    }

    // Delete all members
    for (final member in members) {
      await _membersBoxInstance!.delete(member.id);
    }

    // Delete all fantasy teams
    for (final key in _teamsBoxInstance!.keys) {
      final data = _teamsBoxInstance!.get(key);
      if (data != null) {
        try {
          final team = FantasyTeam.fromJson(
            json.decode(data) as Map<String, dynamic>,
          );
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
          final member = LeagueMember.fromJson(
            json.decode(data) as Map<String, dynamic>,
          );
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
          final member = LeagueMember.fromJson(
            json.decode(data) as Map<String, dynamic>,
          );
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
        _handleFirestoreSyncError(e, 'saveMember');
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
        _handleFirestoreSyncError(e, 'saveLeague');
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
        _handleFirestoreSyncError(e, 'saveFantasyTeam');
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
          final team = FantasyTeam.fromJson(
            json.decode(data) as Map<String, dynamic>,
          );
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
          final team = FantasyTeam.fromJson(
            json.decode(data) as Map<String, dynamic>,
          );
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
  Future<FantasyTeam?> updateTeamName(
    String leagueId,
    String newTeamName,
  ) async {
    await _ensureInitialized();

    final currentUser = await getCurrentUser();
    final team = await getFantasyTeam(leagueId, currentUser.oderId);

    if (team == null) return null;

    final updatedTeam = team.copyWith(teamName: newTeamName);
    return await saveFantasyTeam(updatedTeam);
  }

  Future<void> finalizeDraftResults({
    required League league,
    required List<DraftPick> picks,
    required List<RosterPlayer> rosterPlayers,
  }) async {
    await _ensureInitialized();

    final members = await getLeagueMembers(league.id);
    final playersById = <int, RosterPlayer>{
      for (final player in rosterPlayers) player.id: player,
    };
    final picksByUser = <String, List<DraftPick>>{};

    for (final pick in picks) {
      picksByUser.putIfAbsent(pick.userId, () => []).add(pick);
    }

    for (final member in members) {
      final memberPicks = picksByUser[member.oderId] ?? const <DraftPick>[];
      if (memberPicks.isEmpty) continue;

      final existingTeam = await getFantasyTeam(league.id, member.oderId);
      final draftedPlayers = <FantasyTeamPlayer>[];
      double spentBudget = 0;

      for (int i = 0; i < memberPicks.length; i++) {
        final pick = memberPicks[i];
        final rosterPlayer = playersById[pick.playerId];
        final price = rosterPlayer?.price ?? 5.0;
        final projectedPoints = rosterPlayer?.projectedPoints ?? 0.0;
        spentBudget += price;

        draftedPlayers.add(
          FantasyTeamPlayer(
            playerId: pick.playerId,
            playerName: pick.playerName,
            playerImageUrl: pick.playerImageUrl,
            teamName: pick.teamName,
            position: pick.position,
            price: price,
            predictedPoints: projectedPoints,
            isCaptain: i == 0,
            isViceCaptain: i == 1,
          ),
        );
      }

      final team =
          (existingTeam ??
                  FantasyTeam.empty(
                    id: existingTeam?.id ?? _uuid.v4(),
                    leagueId: league.id,
                    userId: member.oderId,
                    userName: member.userName,
                    teamName: existingTeam?.teamName ?? member.userName,
                    budget: league.budget,
                  ))
              .copyWith(
                players: draftedPlayers,
                totalCredits: league.budget,
                budgetRemaining: (league.budget - spentBudget).clamp(
                  0.0,
                  league.budget,
                ),
                formation: draftedPlayers.length >= 11 ? '4-3-3' : null,
                isLocked: false,
              );

      await saveFantasyTeam(team);
    }

    final updatedLeague = league.copyWith(
      status: LeagueStatus.active,
      updatedAt: DateTime.now(),
    );
    await _saveLeague(updatedLeague);
  }

  /// Get the next matchup for the current user in a league
  /// Returns the opponent's fantasy team, or null if no matchup
  Future<FantasyTeam?> getNextMatchup(String leagueId) async {
    await _ensureInitialized();

    final currentUser = await getCurrentUser();
    final teams = await getLeagueTeams(leagueId);

    if (teams.length < 2) return null;

    // Find user's team index
    final userTeamIndex = teams.indexWhere(
      (t) => t.userId == currentUser.oderId,
    );
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
  Future<List<(FantasyTeam, FantasyTeam)>> getLeagueMatchups(
    String leagueId,
  ) async {
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

    // Prefer authenticated Firebase user when available.
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser != null) {
      final uid = authUser.uid;
      Map<String, dynamic>? profile;
      if (_useFirestore) {
        try {
          profile = await _firestoreService.getUser(uid);
        } catch (e) {
          _handleFirestoreSyncError(e, 'getUser');
        }
      }

      final userName =
          (profile?['userName'] as String?)?.trim().isNotEmpty == true
          ? (profile!['userName'] as String).trim()
          : (profile?['name'] as String?)?.trim().isNotEmpty == true
          ? (profile!['name'] as String).trim()
          : authUser.displayName?.trim().isNotEmpty == true
          ? authUser.displayName!.trim()
          : 'User ${uid.substring(0, 6)}';

      final userImageUrl =
          profile?['userImageUrl'] as String? ??
          profile?['photoUrl'] as String? ??
          authUser.photoURL;

      final userPayload = {
        'id': uid,
        'oderId': uid,
        'userName': userName,
        'name': userName,
        'phoneNumber': authUser.phoneNumber,
        'userImageUrl': userImageUrl,
      };
      await _leaguesBoxInstance!.put(_currentUserKey, json.encode(userPayload));

      if (_useFirestore) {
        try {
          await _firestoreService.saveUser(userPayload);
        } catch (e) {
          _handleFirestoreSyncError(e, 'saveUser (authenticated)');
        }
      }

      return LeagueMember(
        id: uid,
        leagueId: '',
        oderId: uid,
        userName: userName,
        userImageUrl: userImageUrl,
        joinedAt: DateTime.now(),
      );
    }

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

    if (_useFirestore) {
      try {
        await _firestoreService.saveUser(user);
      } catch (e) {
        _handleFirestoreSyncError(e, 'saveUser (updateCurrentUser)');
      }
    }
  }

  // ==================== DEMO DATA ====================

  /// Create demo leagues if none exist
  Future<void> _createDemoLeaguesIfNeeded() async {
    debugPrint(
      'Skipping legacy demo league creation for World Cup classic-only mode',
    );
  }

  Future<void> _ensureDraftTodayTestLeagues() async {
    await _ensureDraftTodayTestLeague(
      leagueName: _draftTestLeagueName,
      description:
          'Quick local draft test. Draft is live today, you pick your team and AI members auto-pick when their timers expire.',
      aiMembers: const [
        'Carlos García',
        'María López',
        'Juan Hernández',
        'Ana Martínez',
        'Pedro Sánchez',
        'Laura Vega',
        'Roberto Díaz',
        'Sofía Castro',
        'Miguel Torres',
        'Andrés Moreno',
        'Carmen Flores',
        'Diego Ramírez',
        'Patricia Gómez',
        'Fernando Silva',
        'Lucía Ruiz',
        'Jorge Medina',
        'Isabel Navarro',
      ],
    );

    await _ensureDraftTodayTestLeague(
      leagueName: _draftQuickTestLeagueName,
      description:
          'Fast local draft test with 6 managers total. Draft is live today so you can validate the full flow quickly.',
      aiMembers: const [
        'Carlos García',
        'María López',
        'Juan Hernández',
        'Ana Martínez',
        'Pedro Sánchez',
      ],
    );
  }

  Future<void> _ensureTradeFlowTestLeague() async {
    final currentUser = await getCurrentUser();
    final now = DateTime.now();

    String? existingLeagueId;
    for (final key in _leaguesBoxInstance!.keys) {
      if (_isReservedLeagueBoxKey(key)) continue;
      final data = _leaguesBoxInstance!.get(key);
      if (data == null) continue;

      try {
        final league = League.fromJson(
          json.decode(data) as Map<String, dynamic>,
        );
        if (league.name == _tradeFlowTestLeagueName) {
          existingLeagueId = league.id;
          break;
        }
      } catch (e) {
        debugPrint('Error parsing trade flow test league seed: $e');
      }
    }

    if (existingLeagueId != null) {
      const rosterSize = 18;
      final existingLeague = await getLeague(existingLeagueId);
      if (existingLeague != null) {
        final updatedLeague = existingLeague.copyWith(
          status: LeagueStatus.active,
          mode: LeagueMode.draft,
          draftSettings: DraftSettings(
            orderType: DraftOrderType.snake,
            pickTimerSeconds: 15,
            draftDateTime: now.subtract(const Duration(days: 1)),
            autoPick: true,
            rosterSize: rosterSize,
          ),
          tradeSettings: TradeSettings(
            approvalType: TradeApproval.none,
            tradeDeadline: now.add(const Duration(days: 14)),
            allowMultiPlayerTrades: true,
          ),
          rosterSize: rosterSize,
          updatedAt: now,
          isJoined: true,
        );
        await _saveLeague(updatedLeague);
      }

      final existingMember = await getMember(
        existingLeagueId,
        currentUser.oderId,
      );
      if (existingMember == null) {
        await _saveMember(
          LeagueMember(
            id: _uuid.v4(),
            leagueId: existingLeagueId,
            oderId: currentUser.oderId,
            userName: currentUser.userName,
            userImageUrl: currentUser.userImageUrl,
            joinedAt: now.subtract(const Duration(days: 2)),
            isCreator: true,
            rank: 2,
            totalPoints: 0,
          ),
        );
      }

      final existingTeam = await getFantasyTeam(
        existingLeagueId,
        currentUser.oderId,
      );
      if (existingTeam == null) {
        await saveFantasyTeam(
          FantasyTeam(
            id: _uuid.v4(),
            leagueId: existingLeagueId,
            userId: currentUser.oderId,
            userName: currentUser.userName,
            teamName: '${currentUser.userName} XI',
            players: _createDemoPlayers(
              withPoints: false,
              count: rosterSize,
              seed: 2,
            ),
            totalCredits: 150.0,
            budgetRemaining: 6.0,
            totalPoints: 0.0,
            createdAt: now.subtract(const Duration(days: 1)),
            updatedAt: now.subtract(const Duration(hours: 12)),
            isLocked: false,
            formation: '4-4-2',
          ),
        );
      }

      debugPrint(
        'Ensured local trade flow test league: $_tradeFlowTestLeagueName',
      );
      return;
    }

    final leagueId = _uuid.v4();
    const rosterSize = 18;

    final league = League(
      id: leagueId,
      name: _tradeFlowTestLeagueName,
      description:
          'Draft already completed. Open Trades to accept/reject incoming offers and test post-draft flow.',
      type: LeagueType.public,
      status: LeagueStatus.active,
      maxMembers: 6,
      budget: 100.0,
      matchName: 'Monterrey vs Tigres',
      matchDateTime: now.add(const Duration(days: 1)),
      createdBy: currentUser.oderId,
      createdAt: now.subtract(const Duration(days: 2)),
      memberCount: 6,
      mode: LeagueMode.draft,
      draftSettings: DraftSettings(
        orderType: DraftOrderType.snake,
        pickTimerSeconds: 15,
        draftDateTime: now.subtract(const Duration(days: 1)),
        autoPick: true,
        rosterSize: rosterSize,
      ),
      tradeSettings: TradeSettings(
        approvalType: TradeApproval.none,
        tradeDeadline: now.add(const Duration(days: 14)),
        allowMultiPlayerTrades: true,
      ),
      rosterSize: rosterSize,
    );
    await _leaguesBoxInstance!.put(leagueId, json.encode(league.toJson()));

    final userMember = LeagueMember(
      id: _uuid.v4(),
      leagueId: leagueId,
      oderId: currentUser.oderId,
      userName: currentUser.userName,
      userImageUrl: currentUser.userImageUrl,
      joinedAt: now.subtract(const Duration(days: 2)),
      isCreator: true,
      rank: 2,
      totalPoints: 0,
    );
    await _membersBoxInstance!.put(
      userMember.id,
      json.encode(userMember.toJson()),
    );

    final userTeam = FantasyTeam(
      id: _uuid.v4(),
      leagueId: leagueId,
      userId: currentUser.oderId,
      userName: currentUser.userName,
      teamName: '${currentUser.userName} XI',
      players: _createDemoPlayers(
        withPoints: false,
        count: rosterSize,
        seed: 2,
      ),
      totalCredits: 100.0,
      budgetRemaining: 6.0,
      totalPoints: 0.0,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(hours: 12)),
      isLocked: false,
      formation: '4-4-2',
    );
    await _teamsBoxInstance!.put(userTeam.id, json.encode(userTeam.toJson()));

    await _addAiMembersWithTeamsAndPredictions(leagueId, const [
      ('Carlos García', 1),
      ('María López', 3),
      ('Juan Hernández', 4),
      ('Ana Martínez', 5),
      ('Pedro Sánchez', 6),
    ]);

    debugPrint(
      'Ensured local trade flow test league: $_tradeFlowTestLeagueName',
    );
  }

  Future<void> _ensureDraftTodayTestLeague({
    required String leagueName,
    required String description,
    required List<String> aiMembers,
  }) async {
    final currentUser = await getCurrentUser();
    final now = DateTime.now();

    final existingLeagueIds = <String>[];
    for (final key in _leaguesBoxInstance!.keys) {
      if (_isReservedLeagueBoxKey(key)) continue;
      final data = _leaguesBoxInstance!.get(key);
      if (data == null) continue;

      try {
        final league = League.fromJson(
          json.decode(data) as Map<String, dynamic>,
        );
        if (league.name == leagueName) {
          existingLeagueIds.add(league.id);
        }
      } catch (e) {
        debugPrint('Error parsing draft test league seed: $e');
      }
    }

    final leagueId = existingLeagueIds.isNotEmpty
        ? existingLeagueIds.first
        : _uuid.v4();

    if (existingLeagueIds.length > 1) {
      for (final duplicateLeagueId in existingLeagueIds.skip(1)) {
        await _removeLocalLeagueData(duplicateLeagueId);
      }
    }

    if (existingLeagueIds.isNotEmpty) {
      await _removeLocalLeagueData(leagueId, deleteLeagueRecord: false);
    }

    final draftOrder = <String>[currentUser.oderId];
    final joinedAtBase = now.subtract(const Duration(days: 1));

    final league = League(
      id: leagueId,
      name: leagueName,
      description: description,
      type: LeagueType.public,
      status: LeagueStatus.draft,
      maxMembers: aiMembers.length + 1,
      budget: 100.0,
      matchName: 'Test Draft Lobby',
      matchDateTime: now.add(const Duration(days: 2)),
      createdBy: currentUser.oderId,
      createdAt: joinedAtBase,
      memberCount: aiMembers.length + 1,
      mode: LeagueMode.draft,
      draftSettings: DraftSettings(
        orderType: DraftOrderType.snake,
        pickTimerSeconds: 8,
        draftDateTime: now.subtract(const Duration(minutes: 5)),
        autoPick: true,
        rosterSize: 18,
      ),
      tradeSettings: const TradeSettings(
        approvalType: TradeApproval.none,
        allowMultiPlayerTrades: true,
      ),
      rosterSize: 18,
    );
    await _saveLeague(league);

    final currentUserMember = LeagueMember(
      id: _uuid.v4(),
      leagueId: leagueId,
      oderId: currentUser.oderId,
      userName: currentUser.userName,
      userImageUrl: currentUser.userImageUrl,
      joinedAt: joinedAtBase,
      isCreator: true,
    );
    await _saveMember(currentUserMember);

    for (int i = 0; i < aiMembers.length; i++) {
      final aiUserId = _uuid.v4();
      draftOrder.add(aiUserId);

      final member = LeagueMember(
        id: _uuid.v4(),
        leagueId: leagueId,
        oderId: aiUserId,
        userName: aiMembers[i],
        joinedAt: joinedAtBase.add(Duration(minutes: i + 1)),
      );
      await _saveMember(member);
    }

    final seededLeague = league.copyWith(
      draftSettings: league.draftSettings?.copyWith(draftOrder: draftOrder),
    );
    await _saveLeague(seededLeague);

    debugPrint('Ensured local draft test league for today: $leagueName');
  }

  Future<void> _removeLocalLeagueData(
    String leagueId, {
    bool deleteLeagueRecord = true,
  }) async {
    if (deleteLeagueRecord) {
      await _leaguesBoxInstance!.delete(leagueId);
    }

    final memberKeysToDelete = <dynamic>[];
    for (final key in _membersBoxInstance!.keys) {
      final data = _membersBoxInstance!.get(key);
      if (data == null) continue;

      try {
        final member = LeagueMember.fromJson(
          json.decode(data) as Map<String, dynamic>,
        );
        if (member.leagueId == leagueId) {
          memberKeysToDelete.add(key);
        }
      } catch (e) {
        debugPrint('Error cleaning test league members: $e');
      }
    }
    for (final key in memberKeysToDelete) {
      await _membersBoxInstance!.delete(key);
    }

    final teamKeysToDelete = <dynamic>[];
    for (final key in _teamsBoxInstance!.keys) {
      final data = _teamsBoxInstance!.get(key);
      if (data == null) continue;

      try {
        final team = FantasyTeam.fromJson(
          json.decode(data) as Map<String, dynamic>,
        );
        if (team.leagueId == leagueId) {
          teamKeysToDelete.add(key);
        }
      } catch (e) {
        debugPrint('Error cleaning test league teams: $e');
      }
    }
    for (final key in teamKeysToDelete) {
      await _teamsBoxInstance!.delete(key);
    }
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

        players.add(
          FantasyTeamPlayer(
            playerId: data.$1,
            playerName: data.$2,
            playerImageUrl: _demoAvatarUrl(data.$2),
            position: _stringToPosition(data.$3),
            teamName: data.$4,
            price: data.$5,
            points: points,
            predictedPoints: predictedPoints > 0 ? predictedPoints : 0.0,
          ),
        );
      }
    }

    // Fill remaining bench slots (for draft rosters larger than XI)
    if (count > players.length) {
      final remaining = count - players.length;
      final benchPlayers = shuffledData
          .asMap()
          .entries
          .where((e) => !usedIndices.contains(e.key))
          .take(remaining);

      for (final p in benchPlayers) {
        usedIndices.add(p.key);
        final data = p.value;
        final basePoints = highScoring ? data.$6 * 1.5 : data.$6;
        final points = withPoints ? basePoints + (p.key % 5) : 0.0;
        final predictedPoints = data.$7 + (seed % 3) * 0.5 - 0.5;

        players.add(
          FantasyTeamPlayer(
            playerId: data.$1,
            playerName: data.$2,
            playerImageUrl: _demoAvatarUrl(data.$2),
            position: _stringToPosition(data.$3),
            teamName: data.$4,
            price: data.$5,
            points: points,
            predictedPoints: predictedPoints > 0 ? predictedPoints : 0.0,
          ),
        );
      }
    }

    // Set captain/VC properly
    if (players.length >= 2) {
      // Find best forward for captain
      final forwards = players
          .where(
            (p) =>
                p.position == PlayerPosition.forward ||
                p.position == PlayerPosition.attacker,
          )
          .toList();
      final mids = players
          .where((p) => p.position == PlayerPosition.midfielder)
          .toList();

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
        players[captainIdx] = players[captainIdx].copyWith(
          isCaptain: true,
          isViceCaptain: false,
        );
      }
      if (vcIdx >= 0 && vcIdx != captainIdx) {
        players[vcIdx] = players[vcIdx].copyWith(
          isViceCaptain: true,
          isCaptain: false,
        );
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

  String _demoAvatarUrl(String name) {
    final encoded = Uri.encodeComponent(name);
    return 'https://ui-avatars.com/api/?name=$encoded&size=256&background=0F141A&color=FFFFFF&format=png';
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
