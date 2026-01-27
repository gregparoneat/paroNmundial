import 'package:fantacy11/features/auth/login_navigator.dart';
import 'package:fantacy11/features/responsive_widget.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/services/cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app_config/styles.dart';
import 'features/language/language_cubit.dart';
import 'routes/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cache service (Hive)
  await CacheService().init();
  
  MobileAds.instance.initialize();

  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(
    Phoenix(
      child: BlocProvider(
        create: (context) => LanguageCubit()..getCurrentLanguage(),
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
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) =>
                const ResponsiveWidget(child: LoginNavigator()),
            '/app_navigation': (BuildContext context) =>
                const ResponsiveWidget(child: AppNavigator()),
          },
        );
      },
    );
  }
}
