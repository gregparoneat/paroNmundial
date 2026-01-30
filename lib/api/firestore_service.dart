import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for fetching Liga MX teams and players from Firestore
/// Also handles fantasy league data storage
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names for Liga MX data
  static const String teamsCollection = 'teams';
  static const String playersCollection = 'players';
  
  // Collection names for fantasy league data
  static const String leaguesCollection = 'fantasy_leagues';
  static const String membersCollection = 'league_members';
  static const String fantasyTeamsCollection = 'fantasy_teams';
  static const String usersCollection = 'users';

  /// Get all Liga MX teams from Firestore
  Future<List<Map<String, dynamic>>> getTeams() async {
    try {
      debugPrint('FirestoreService: Fetching teams from Firestore...');
      
      final snapshot = await _firestore
          .collection(teamsCollection)
          .get();
      
      final teams = snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure we have the document ID as the team ID if not in data
        if (!data.containsKey('id')) {
          data['id'] = int.tryParse(doc.id) ?? doc.id;
        }
        return data;
      }).toList();
      
      debugPrint('FirestoreService: Loaded ${teams.length} teams from Firestore');
      return teams;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching teams: $e');
      rethrow;
    }
  }

  /// Get all players from Firestore
  Future<List<Map<String, dynamic>>> getPlayers() async {
    try {
      debugPrint('FirestoreService: Fetching players from Firestore...');
      
      final snapshot = await _firestore
          .collection(playersCollection)
          .get();
      
      final players = snapshot.docs.map((doc) {
        final data = doc.data();
        // Ensure we have the document ID as the player ID if not in data
        if (!data.containsKey('id')) {
          data['id'] = int.tryParse(doc.id) ?? doc.id;
        }
        return data;
      }).toList();
      
      debugPrint('FirestoreService: Loaded ${players.length} players from Firestore');
      return players;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching players: $e');
      rethrow;
    }
  }

  /// Get players for a specific team
  Future<List<Map<String, dynamic>>> getPlayersByTeam(int teamId) async {
    try {
      debugPrint('FirestoreService: Fetching players for team $teamId...');
      
      final snapshot = await _firestore
          .collection(playersCollection)
          .where('teamId', isEqualTo: teamId)
          .get();
      
      final players = snapshot.docs.map((doc) {
        final data = doc.data();
        if (!data.containsKey('id')) {
          data['id'] = int.tryParse(doc.id) ?? doc.id;
        }
        return data;
      }).toList();
      
      debugPrint('FirestoreService: Loaded ${players.length} players for team $teamId');
      return players;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching players for team $teamId: $e');
      rethrow;
    }
  }

  /// Get a single team by ID
  Future<Map<String, dynamic>?> getTeamById(int teamId) async {
    try {
      final doc = await _firestore
          .collection(teamsCollection)
          .doc(teamId.toString())
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        if (!data.containsKey('id')) {
          data['id'] = teamId;
        }
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching team $teamId: $e');
      rethrow;
    }
  }

  /// Get a single player by ID
  Future<Map<String, dynamic>?> getPlayerById(int playerId) async {
    try {
      final doc = await _firestore
          .collection(playersCollection)
          .doc(playerId.toString())
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        if (!data.containsKey('id')) {
          data['id'] = playerId;
        }
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching player $playerId: $e');
      rethrow;
    }
  }

  /// Search players by name
  Future<List<Map<String, dynamic>>> searchPlayers(String query) async {
    try {
      debugPrint('FirestoreService: Searching players with query: $query');
      
      // Firestore doesn't support full-text search, so we'll fetch all and filter locally
      // For better performance, consider using Algolia or similar
      final allPlayers = await getPlayers();
      
      final queryLower = query.toLowerCase();
      final results = allPlayers.where((player) {
        final name = (player['name'] as String? ?? '').toLowerCase();
        final displayName = (player['displayName'] as String? ?? '').toLowerCase();
        final commonName = (player['commonName'] as String? ?? '').toLowerCase();
        
        return name.contains(queryLower) || 
               displayName.contains(queryLower) ||
               commonName.contains(queryLower);
      }).toList();
      
      debugPrint('FirestoreService: Found ${results.length} players matching "$query"');
      return results;
    } catch (e) {
      debugPrint('FirestoreService: Error searching players: $e');
      rethrow;
    }
  }

  /// Check if Firestore has data (to know if we should use it or fall back to API)
  Future<bool> hasData() async {
    try {
      final teamsSnapshot = await _firestore
          .collection(teamsCollection)
          .limit(1)
          .get();
      
      return teamsSnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('FirestoreService: Error checking data: $e');
      return false;
    }
  }

  // ==================== FANTASY LEAGUE OPERATIONS ====================

  /// Save a fantasy league
  Future<void> saveLeague(Map<String, dynamic> league) async {
    try {
      final leagueId = league['id'] as String;
      await _firestore
          .collection(leaguesCollection)
          .doc(leagueId)
          .set(league, SetOptions(merge: true));
      debugPrint('FirestoreService: Saved league $leagueId');
    } catch (e) {
      debugPrint('FirestoreService: Error saving league: $e');
      rethrow;
    }
  }

  /// Get all leagues
  Future<List<Map<String, dynamic>>> getLeagues() async {
    try {
      final snapshot = await _firestore
          .collection(leaguesCollection)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('FirestoreService: Error fetching leagues: $e');
      return [];
    }
  }

  /// Get public leagues
  Future<List<Map<String, dynamic>>> getPublicLeagues() async {
    try {
      final snapshot = await _firestore
          .collection(leaguesCollection)
          .where('type', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('FirestoreService: Error fetching public leagues: $e');
      return [];
    }
  }

  /// Get a league by ID
  Future<Map<String, dynamic>?> getLeague(String leagueId) async {
    try {
      final doc = await _firestore
          .collection(leaguesCollection)
          .doc(leagueId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching league $leagueId: $e');
      return null;
    }
  }

  /// Get league by invite code
  Future<Map<String, dynamic>?> getLeagueByInviteCode(String inviteCode) async {
    try {
      final snapshot = await _firestore
          .collection(leaguesCollection)
          .where('inviteCode', isEqualTo: inviteCode)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching league by invite code: $e');
      return null;
    }
  }

  /// Delete a league
  Future<void> deleteLeague(String leagueId) async {
    try {
      // Delete the league document
      await _firestore
          .collection(leaguesCollection)
          .doc(leagueId)
          .delete();
      
      // Delete all members of this league
      final membersSnapshot = await _firestore
          .collection(membersCollection)
          .where('leagueId', isEqualTo: leagueId)
          .get();
      
      for (final doc in membersSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete all teams of this league
      final teamsSnapshot = await _firestore
          .collection(fantasyTeamsCollection)
          .where('leagueId', isEqualTo: leagueId)
          .get();
      
      for (final doc in teamsSnapshot.docs) {
        await doc.reference.delete();
      }
      
      debugPrint('FirestoreService: Deleted league $leagueId and all related data');
    } catch (e) {
      debugPrint('FirestoreService: Error deleting league: $e');
      rethrow;
    }
  }

  // ==================== LEAGUE MEMBER OPERATIONS ====================

  /// Save a league member
  Future<void> saveMember(Map<String, dynamic> member) async {
    try {
      final memberId = member['id'] as String;
      await _firestore
          .collection(membersCollection)
          .doc(memberId)
          .set(member, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: Error saving member: $e');
      rethrow;
    }
  }

  /// Get members of a league
  Future<List<Map<String, dynamic>>> getLeagueMembers(String leagueId) async {
    try {
      final snapshot = await _firestore
          .collection(membersCollection)
          .where('leagueId', isEqualTo: leagueId)
          .orderBy('joinedAt')
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('FirestoreService: Error fetching members for league $leagueId: $e');
      return [];
    }
  }

  /// Get leagues that a user is a member of
  Future<List<String>> getUserLeagueIds(String oderId) async {
    try {
      final snapshot = await _firestore
          .collection(membersCollection)
          .where('oderId', isEqualTo: oderId)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.data()['leagueId'] as String)
          .toList();
    } catch (e) {
      debugPrint('FirestoreService: Error fetching user leagues: $e');
      return [];
    }
  }

  /// Check if user is member of a league
  Future<bool> isUserMemberOfLeague(String leagueId, String oderId) async {
    try {
      final snapshot = await _firestore
          .collection(membersCollection)
          .where('leagueId', isEqualTo: leagueId)
          .where('oderId', isEqualTo: oderId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('FirestoreService: Error checking membership: $e');
      return false;
    }
  }

  /// Delete a member from a league
  Future<void> deleteMember(String memberId) async {
    try {
      await _firestore
          .collection(membersCollection)
          .doc(memberId)
          .delete();
    } catch (e) {
      debugPrint('FirestoreService: Error deleting member: $e');
      rethrow;
    }
  }

  // ==================== FANTASY TEAM OPERATIONS ====================

  /// Save a fantasy team
  Future<void> saveFantasyTeam(Map<String, dynamic> team) async {
    try {
      final teamId = team['id'] as String;
      await _firestore
          .collection(fantasyTeamsCollection)
          .doc(teamId)
          .set(team, SetOptions(merge: true));
      debugPrint('FirestoreService: Saved fantasy team $teamId');
    } catch (e) {
      debugPrint('FirestoreService: Error saving fantasy team: $e');
      rethrow;
    }
  }

  /// Get a fantasy team by league and user
  Future<Map<String, dynamic>?> getFantasyTeam(String leagueId, String oderId) async {
    try {
      final snapshot = await _firestore
          .collection(fantasyTeamsCollection)
          .where('leagueId', isEqualTo: leagueId)
          .where('userId', isEqualTo: oderId)
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty ? snapshot.docs.first.data() : null;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching fantasy team: $e');
      return null;
    }
  }

  /// Get all fantasy teams for a league
  Future<List<Map<String, dynamic>>> getLeagueTeams(String leagueId) async {
    try {
      final snapshot = await _firestore
          .collection(fantasyTeamsCollection)
          .where('leagueId', isEqualTo: leagueId)
          .orderBy('totalPoints', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('FirestoreService: Error fetching league teams: $e');
      return [];
    }
  }

  /// Delete a fantasy team
  Future<void> deleteFantasyTeam(String teamId) async {
    try {
      await _firestore
          .collection(fantasyTeamsCollection)
          .doc(teamId)
          .delete();
    } catch (e) {
      debugPrint('FirestoreService: Error deleting fantasy team: $e');
      rethrow;
    }
  }

  // ==================== USER OPERATIONS ====================

  /// Save user data
  Future<void> saveUser(Map<String, dynamic> user) async {
    try {
      final oderId = user['oderId'] as String;
      await _firestore
          .collection(usersCollection)
          .doc(oderId)
          .set(user, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreService: Error saving user: $e');
      rethrow;
    }
  }

  /// Get user by ID
  Future<Map<String, dynamic>?> getUser(String oderId) async {
    try {
      final doc = await _firestore
          .collection(usersCollection)
          .doc(oderId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('FirestoreService: Error fetching user: $e');
      return null;
    }
  }

  /// Listen to league updates (for real-time updates)
  Stream<Map<String, dynamic>?> leagueStream(String leagueId) {
    return _firestore
        .collection(leaguesCollection)
        .doc(leagueId)
        .snapshots()
        .map((doc) => doc.exists ? doc.data() : null);
  }

  /// Listen to league members updates
  Stream<List<Map<String, dynamic>>> leagueMembersStream(String leagueId) {
    return _firestore
        .collection(membersCollection)
        .where('leagueId', isEqualTo: leagueId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Listen to league teams updates
  Stream<List<Map<String, dynamic>>> leagueTeamsStream(String leagueId) {
    return _firestore
        .collection(fantasyTeamsCollection)
        .where('leagueId', isEqualTo: leagueId)
        .orderBy('totalPoints', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}

