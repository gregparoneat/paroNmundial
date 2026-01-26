import 'package:fantacy11/features/account/ui/about_us.dart';
import 'package:fantacy11/features/account/ui/faqs.dart';
import 'package:fantacy11/features/account/ui/leaderboard.dart';
import 'package:fantacy11/features/account/ui/level.dart';
import 'package:fantacy11/features/account/ui/privacy_policy.dart';
import 'package:fantacy11/features/account/ui/profile.dart';
import 'package:fantacy11/features/account/ui/support.dart';
import 'package:fantacy11/features/app_navigation/app_navigation.dart';
import 'package:fantacy11/features/home/choose_captain_and_vice_captain.dart';
import 'package:fantacy11/features/home/contests.dart';
import 'package:fantacy11/features/home/create_new_team.dart';
import 'package:fantacy11/features/home/team_preview.dart';
import 'package:fantacy11/features/language/language_ui.dart';
import 'package:fantacy11/features/my_matches/match_completed.dart';
import 'package:fantacy11/features/my_matches/match_live.dart';
import 'package:fantacy11/features/my_matches/winnings.dart';
import 'package:fantacy11/features/wallet/wallet.dart';
import 'package:flutter/material.dart';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class PageRoutes {
  static const String appNavigation = "appNavigation";
  static const String aboutUs = "aboutUs";
  static const String faqs = "faqs";
  static const String leaderboard = "leaderboard";
  static const String level = "level";
  static const String privacyPolicy = "privacyPolicy";
  static const String profile = "profile";
  static const String changeLanguage = "changeLanguage";
  static const String contests = "contests";
  static const String createNewTeam = "createNewTeam";
  static const String teamPreview = "teamPreview";
  static const String chooseCaptain = "chooseCaptain";
  static const String winnings = "winnings";
  static const String matchLive = "matchLive";
  static const String matchCompleted = "matchCompleted";
  static const String support = "support";
  static const String wallet = "wallet";
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  void checkCanPop(BuildContext context) {
    var canPop = appNavigatorKey.currentState!.canPop();
    if (canPop) {
      appNavigatorKey.currentState!.pop();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigatorPopHandler(
      onPopWithResult: (result) => checkCanPop(context),
      child: Navigator(
        key: appNavigatorKey,
        initialRoute: PageRoutes.appNavigation,
        onGenerateRoute: (RouteSettings settings) {
          late Widget Function(BuildContext, Animation, Animation) builder;
          switch (settings.name) {
            case PageRoutes.appNavigation:
              builder = (_, _, _) => const AppNavigation();
              break;
            case PageRoutes.aboutUs:
              builder = (_, _, _) => const AboutUs();
              break;
            case PageRoutes.faqs:
              builder = (_, _, _) => const Faqs();
              break;
            case PageRoutes.leaderboard:
              builder = (_, _, _) => const Leaderboard();
              break;
            case PageRoutes.level:
              builder = (_, _, _) => const Level();
              break;
            case PageRoutes.privacyPolicy:
              builder = (_, _, _) => const PrivacyPolicy();
              break;
            case PageRoutes.profile:
              builder = (_, _, _) => const Profile();
              break;
            case PageRoutes.changeLanguage:
              builder = (_, _, _) => const LanguageUI();
              break;
            case PageRoutes.contests:
              builder = (_, _, _) => const Contests();
              break;
            case PageRoutes.createNewTeam:
              builder = (_, _, _) => const CreateNewTeam();
              break;
            case PageRoutes.teamPreview:
              builder = (_, _, _) => const TeamPreview();
              break;
            case PageRoutes.chooseCaptain:
              builder = (_, _, _) => const ChooseCaptain();
              break;
            case PageRoutes.winnings:
              builder = (_, _, _) => Winnings();
              break;
            case PageRoutes.matchLive:
              builder = (_, _, _) => const MatchLive();
              break;
            case PageRoutes.matchCompleted:
              builder = (_, _, _) => MatchCompleted();
              break;
            case PageRoutes.support:
              builder = (_, _, _) => const Support();
              break;
            case PageRoutes.wallet:
              builder = (_, _, _) => const Wallet();
              break;
          }
          return PageRouteBuilder(pageBuilder: builder, settings: settings);
        },
        onDidRemovePage: (page) {},
      ),
    );
  }
}
