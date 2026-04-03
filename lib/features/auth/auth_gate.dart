import 'package:fantacy11/features/auth/auth_session_cubit.dart';
import 'package:fantacy11/features/auth/favorite_team/ui/favorite_team_selection_page.dart';
import 'package:fantacy11/features/auth/login_navigator.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthSessionCubit, AuthSessionState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthSessionStatus.loading:
            return const _BrandedSplashScreen();
          case AuthSessionStatus.unauthenticated:
          case AuthSessionStatus.otpRequested:
          case AuthSessionStatus.failure:
            return const LoginNavigator();
          case AuthSessionStatus.authenticatedNeedsOnboarding:
            return FavoriteTeamSelectionPage(
              onComplete: () =>
                  context.read<AuthSessionCubit>().completeOnboarding(),
            );
          case AuthSessionStatus.authenticatedReady:
            return const AppNavigator();
        }
      },
    );
  }
}

class _BrandedSplashScreen extends StatefulWidget {
  const _BrandedSplashScreen();

  @override
  State<_BrandedSplashScreen> createState() => _BrandedSplashScreenState();
}

class _BrandedSplashScreenState extends State<_BrandedSplashScreen>
    with SingleTickerProviderStateMixin {
  static const _backgroundColor = Color(0xFFF6F6F6);
  static const _nativeLogoWidth = 168.0;

  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _fadeAnimation;
  bool _showActivity = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _showActivity = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final yOffset = _showActivity ? _floatAnimation.value : 0.0;
            final opacity = _showActivity ? 0.88 + (_fadeAnimation.value * 0.12) : 1.0;
            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Opacity(opacity: opacity, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/paroNmundialTransparent.png',
                width: _nativeLogoWidth,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 28),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: _showActivity ? 1 : 0,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
