import 'package:fantacy11/features/auth/login/ui/login_page.dart';
import 'package:fantacy11/features/auth/register/ui/register_page.dart';
import 'package:fantacy11/features/auth/verification/ui/verification_page.dart';
import 'package:flutter/material.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class LoginRoutes {
  static const String loginRoot = 'login/';
  static const String registration = 'login/registration';
  static const String verification = 'login/verification';
}

class LoginNavigator extends StatelessWidget {
  const LoginNavigator({super.key});

  void checkCanPop(BuildContext context) {
    var canPop = navigatorKey.currentState!.canPop();
    if (canPop) {
      navigatorKey.currentState!.pop();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPopWithResult: (result) => checkCanPop(context),
      child: Navigator(
        key: navigatorKey,
        initialRoute: LoginRoutes.loginRoot,
        onGenerateRoute: (RouteSettings settings) {
          late Widget Function(BuildContext, Animation, Animation) builder;
          switch (settings.name) {
            case LoginRoutes.loginRoot:
              builder = (_, _, _) => const LoginPage();
              break;
            case LoginRoutes.registration:
              builder = (_, _, _) => const RegisterPage();
              break;
            case LoginRoutes.verification:
              builder = (_, _, _) => VerificationPage(
                    "",
                    () => Navigator.pushReplacementNamed(
                        context, "/app_navigation"),
                  );
              break;
          }
          return PageRouteBuilder(pageBuilder: builder, settings: settings);
        },
        onDidRemovePage: (page) {
        },
      ),
    );
  }
}
