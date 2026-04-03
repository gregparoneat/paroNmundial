import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/features/auth/auth_gate.dart';
import 'package:fantacy11/features/auth/auth_repository.dart';
import 'package:fantacy11/features/auth/auth_session_cubit.dart';
import 'package:fantacy11/features/responsive_widget.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/services/cache_service.dart';
import 'package:fantacy11/services/player_form_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_config/styles.dart';
import 'features/language/language_cubit.dart';
import 'firebase_options.dart';
import 'routes/routes.dart';

const _splashBackground = Color(0xFFF6F6F6);

/// Pre-load players from Firestore into Hive cache
/// This runs in the background to speed up subsequent player loads
Future<void> _preloadPlayersFromFirestore() async {
  try {
    debugPrint('Pre-loading players from Firestore...');
    final repository = PlayersRepository();
    final players = await repository.loadAllPlayersFromFirestore();
    debugPrint('Pre-loaded ${players.length} players from Firestore');
  } catch (e) {
    debugPrint('Failed to pre-load players from Firestore: $e');
  }
}

Future<void> _syncPlayerFormsFromFirestore() async {
  try {
    debugPrint('Syncing player forms from Firestore...');
    final formService = PlayerFormService();
    await formService.syncFormsFromFirestore();
    debugPrint('Player forms synced successfully');
  } catch (e) {
    debugPrint('Failed to sync player forms from Firestore: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize cache service (Hive)
  await CacheService().init();
  
  // Pre-load players from Firestore in background (don't await to not block startup)
  _preloadPlayersFromFirestore();
  
  // Sync pre-calculated player forms from Firestore in background
  // Form data is updated by batch jobs running Mon/Fri
  _syncPlayerFormsFromFirestore();
  
  MobileAds.instance.initialize();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(
    Phoenix(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => LanguageCubit()..getCurrentLanguage(),
          ),
          BlocProvider(
            create: (context) => AuthSessionCubit(
              authRepository: AuthRepository(),
              cacheService: CacheService(),
            )..initialize(),
          ),
        ],
        child: const Fantasy11(),
      ),
    ),
  );
}

class Fantasy11 extends StatelessWidget {
  const Fantasy11({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, Locale>(
      builder: (_, locale) {
        return MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.delegate.supportedLocales,
          locale: locale,
          theme: appTheme,
          initialRoute: "/",
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            return ColoredBox(
              color: _splashBackground,
              child: child ?? const SizedBox.shrink(),
            );
          },
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) =>
                const ResponsiveWidget(child: AuthGate()),
            '/app_navigation': (BuildContext context) =>
                const ResponsiveWidget(child: AppNavigator()),
          },
        );
      },
    );
  }
}
