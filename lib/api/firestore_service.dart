import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for fetching Liga MX teams and players from Firestore
/// This replaces SportMonks API calls for base player/team data
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names - adjust these to match your Firestore structure
  static const String teamsCollection = 'teams';
  static const String playersCollection = 'players';

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
}

