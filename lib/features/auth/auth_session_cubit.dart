import 'dart:async';

import 'package:fantacy11/features/auth/auth_repository.dart';
import 'package:fantacy11/services/cache_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthSessionStatus {
  loading,
  unauthenticated,
  otpRequested,
  authenticatedNeedsOnboarding,
  authenticatedReady,
  failure,
}

class AuthSessionState {
  const AuthSessionState({
    required this.status,
    this.phoneNumber,
    this.verificationId,
    this.errorMessage,
  });

  final AuthSessionStatus status;
  final String? phoneNumber;
  final String? verificationId;
  final String? errorMessage;

  AuthSessionState copyWith({
    AuthSessionStatus? status,
    String? phoneNumber,
    String? verificationId,
    String? errorMessage,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      errorMessage: errorMessage,
    );
  }

  static const initial = AuthSessionState(status: AuthSessionStatus.loading);
}

class AuthSessionCubit extends Cubit<AuthSessionState> {
  AuthSessionCubit({
    required AuthRepository authRepository,
    required CacheService cacheService,
  }) : _authRepository = authRepository,
       _cacheService = cacheService,
       super(AuthSessionState.initial) {
    _authSub = _authRepository.authStateChanges().listen((_) {
      _refreshFromAuth();
    });
  }

  final AuthRepository _authRepository;
  final CacheService _cacheService;
  StreamSubscription? _authSub;

  String? _pendingName;
  String? _pendingEmail;

  Future<void> initialize() async {
    emit(const AuthSessionState(status: AuthSessionStatus.loading));
    await _refreshFromAuth();
  }

  Future<void> _refreshFromAuth() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      emit(const AuthSessionState(status: AuthSessionStatus.unauthenticated));
      return;
    }

    Map<String, dynamic>? profile;
    try {
      profile = await _authRepository.getUserProfile(user.uid);
    } catch (e) {
      // A temporary Firestore profile read issue should not force logout.
      debugPrint('AuthSessionCubit: Failed to load profile for ${user.uid}: $e');
      profile = null;
    }

    final profileOnboarding = profile?['onboardingCompleted'] == true;
    final localOnboarding = _cacheService.isOnboardingCompleted();
    final onboardingCompleted = profileOnboarding || localOnboarding;

    // Pull favorite team from server profile into local cache when available.
    final profileFavTeamId = profile?['favoriteTeamId'];
    final profileFavTeamName = profile?['favoriteTeamName']?.toString();
    if (profileFavTeamId is num &&
        profileFavTeamName != null &&
        profileFavTeamName.isNotEmpty &&
        _cacheService.getFavoriteTeam() == null) {
      try {
        await _cacheService.saveFavoriteTeam(
          FavoriteTeam(
            id: profileFavTeamId.toInt(),
            name: profileFavTeamName,
            logo: profile?['favoriteTeamLogo']?.toString(),
          ),
        );
      } catch (e) {
        debugPrint('AuthSessionCubit: Failed to sync favorite team cache: $e');
      }
    }

    if (onboardingCompleted && !localOnboarding) {
      try {
        await _cacheService.setOnboardingCompleted(true);
      } catch (e) {
        debugPrint('AuthSessionCubit: Failed to sync onboarding cache: $e');
      }
    }

    emit(
      AuthSessionState(
        status: onboardingCompleted
            ? AuthSessionStatus.authenticatedReady
            : AuthSessionStatus.authenticatedNeedsOnboarding,
      ),
    );
  }

  Future<bool> requestOtp({
    required String phoneNumber,
    String? name,
    String? email,
  }) async {
    try {
      _pendingName = name;
      _pendingEmail = email;
      emit(const AuthSessionState(status: AuthSessionStatus.loading));

      final verificationId = await _authRepository.sendPhoneOtp(phoneNumber);
      emit(
        AuthSessionState(
          status: AuthSessionStatus.otpRequested,
          phoneNumber: phoneNumber,
          verificationId: verificationId,
        ),
      );
      return true;
    } catch (e) {
      emit(
        AuthSessionState(
          status: AuthSessionStatus.failure,
          errorMessage: _authErrorMessage(e, fallback: 'Failed to request OTP'),
        ),
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String otpCode) async {
    final verificationId = state.verificationId;
    final phoneNumber = state.phoneNumber;
    if (verificationId == null || phoneNumber == null) {
      emit(
        const AuthSessionState(
          status: AuthSessionStatus.failure,
          errorMessage: 'Verification session expired. Please request OTP again.',
        ),
      );
      return false;
    }

    try {
      emit(state.copyWith(status: AuthSessionStatus.loading));
      final userCredential = await _authRepository.verifyOtp(
        verificationId: verificationId,
        otpCode: otpCode,
      );
      final uid = userCredential.user?.uid;
      if (uid == null) {
        throw StateError('Missing user id after verification.');
      }

      try {
        await _authRepository.saveUserProfile(
          uid: uid,
          phoneNumber: phoneNumber,
          name: _pendingName,
          email: _pendingEmail,
        );
      } catch (e) {
        debugPrint('AuthSessionCubit: OTP profile save failed (non-fatal): $e');
      }

      await _refreshFromAuth();
      return true;
    } catch (e) {
      emit(
        AuthSessionState(
          status: AuthSessionStatus.failure,
          errorMessage: _authErrorMessage(e, fallback: 'Failed to verify code'),
          phoneNumber: phoneNumber,
          verificationId: verificationId,
        ),
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      emit(const AuthSessionState(status: AuthSessionStatus.loading));
      final userCredential = await _authRepository.signInWithGoogle();
      final user = userCredential.user;
      final uid = user?.uid;
      if (uid == null) {
        throw StateError('Missing user id after Google sign-in.');
      }

      try {
        await _authRepository.saveUserProfile(
          uid: uid,
          phoneNumber: user?.phoneNumber ?? '',
          name: user?.displayName,
          email: user?.email,
        );
      } catch (e) {
        debugPrint(
          'AuthSessionCubit: Google profile save failed (non-fatal): $e',
        );
      }

      await _refreshFromAuth();
      return true;
    } catch (e) {
      emit(
        AuthSessionState(
          status: AuthSessionStatus.failure,
          errorMessage: _authErrorMessage(
            e,
            fallback: 'Failed to sign in with Google',
          ),
        ),
      );
      return false;
    }
  }

  Future<void> completeOnboarding() async {
    final user = _authRepository.currentUser;
    if (user == null) return;

    try {
      await _cacheService.setOnboardingCompleted(true);
    } catch (e) {
      debugPrint(
        'AuthSessionCubit: Failed to persist local onboarding flag: $e',
      );
    }

    final favoriteTeam = _cacheService.getFavoriteTeam();
    try {
      await _authRepository.saveUserProfile(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        onboardingCompleted: true,
        favoriteTeamId: favoriteTeam?.id,
        favoriteTeamName: favoriteTeam?.name,
        favoriteTeamLogo: favoriteTeam?.logo,
      );
    } catch (e) {
      // Firestore rules may block writes in some environments.
      // Do not crash or block app access when auth already succeeded.
      debugPrint('AuthSessionCubit: Onboarding profile sync failed: $e');
    }

    emit(const AuthSessionState(status: AuthSessionStatus.authenticatedReady));
  }

  Future<void> resetToUnauthenticated() async {
    await _authRepository.signOut();
    _pendingName = null;
    _pendingEmail = null;
    emit(const AuthSessionState(status: AuthSessionStatus.unauthenticated));
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    return super.close();
  }

  String _authErrorMessage(Object error, {required String fallback}) {
    if (error is FirebaseAuthException) {
      return error.message ?? fallback;
    }
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.replaceFirst('Exception: ', '');
    }
    if (message.startsWith('StateError: ')) {
      return message.replaceFirst('StateError: ', '');
    }
    return '$fallback: $message';
  }
}
