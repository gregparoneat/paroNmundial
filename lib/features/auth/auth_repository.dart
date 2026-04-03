import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final Map<String, ConfirmationResult> _webOtpSessions = {};
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<String> sendPhoneOtp(String phoneNumber) async {
    if (kIsWeb) {
      final confirmation = await _auth.signInWithPhoneNumber(phoneNumber);
      final sessionId = 'web_${DateTime.now().microsecondsSinceEpoch}';
      _webOtpSessions[sessionId] = confirmation;
      return sessionId;
    }

    final completer = Completer<String>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth.signInWithCredential(credential);
        } catch (e) {
          debugPrint('AuthRepository: Auto-verification sign-in failed: $e');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );

    return completer.future;
  }

  Future<UserCredential> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    if (kIsWeb) {
      final confirmation = _webOtpSessions.remove(verificationId);
      if (confirmation == null) {
        throw StateError('Verification session expired. Please request OTP again.');
      }
      return confirmation.confirm(otpCode);
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return _auth.signInWithPopup(provider);
    }

    await _googleSignIn.initialize();
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    if (googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
      throw StateError('Google sign-in did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> saveUserProfile({
    required String uid,
    required String phoneNumber,
    String? name,
    String? email,
    bool? onboardingCompleted,
    int? favoriteTeamId,
    String? favoriteTeamName,
    String? favoriteTeamLogo,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'phoneNumber': phoneNumber,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      if (onboardingCompleted != null)
        'onboardingCompleted': onboardingCompleted,
      if (favoriteTeamId != null) 'favoriteTeamId': favoriteTeamId,
      if (favoriteTeamName != null && favoriteTeamName.trim().isNotEmpty)
        'favoriteTeamName': favoriteTeamName.trim(),
      if (favoriteTeamLogo != null && favoriteTeamLogo.trim().isNotEmpty)
        'favoriteTeamLogo': favoriteTeamLogo.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> signOut() async {
    _webOtpSessions.clear();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
