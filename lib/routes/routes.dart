import 'package:fantacy11/features/account/ui/about_us.dart';
import 'package:fantacy11/features/account/ui/faqs.dart';
import 'package:fantacy11/features/account/ui/leaderboard.dart';
import 'package:fantacy11/features/account/ui/level.dart';
import 'package:fantacy11/features/account/ui/privacy_policy.dart';
import 'package:fantacy11/features/account/ui/profile.dart';
import 'package:fantacy11/features/account/ui/support.dart';
import 'package:fantacy11/features/app_navigation/app_navigation.dart';
import 'package:fantacy11/features/fixtures/ui/match_details_page.dart';
import 'package:fantacy11/features/fixtures/ui/past_fixtures_page.dart';
import 'package:fantacy11/features/home/choose_captain_and_vice_captain.dart';
import 'package:fantacy11/features/home/contests.dart';
import 'package:fantacy11/features/home/create_new_team.dart';
import 'package:fantacy11/features/home/team_preview.dart';
import 'package:fantacy11/features/language/language_ui.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:fantacy11/features/my_matches/match_completed.dart';
import 'package:fantacy11/features/my_matches/match_live.dart';
import 'package:fantacy11/features/my_matches/winnings.dart';
import 'package:fantacy11/features/player/models/player_info.dart' show Player;
import 'package:fantacy11/features/player/ui/player_details_page.dart';
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
  static const String playerDetails = "playerDetails";
  static const String pastFixtures = "pastFixtures";
  static const String matchDetails = "matchDetails";
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
              builder = (c, a1, a2) => const AppNavigation();
              break;
            case PageRoutes.aboutUs:
              builder = (c, a1, a2) => const AboutUs();
              break;
            case PageRoutes.faqs:
              builder = (c, a1, a2) => const Faqs();
              break;
            case PageRoutes.leaderboard:
              builder = (c, a1, a2) => const Leaderboard();
              break;
            case PageRoutes.level:
              builder = (c, a1, a2) => const Level();
              break;
            case PageRoutes.privacyPolicy:
              builder = (c, a1, a2) => const PrivacyPolicy();
              break;
            case PageRoutes.profile:
              builder = (c, a1, a2) => const Profile();
              break;
            case PageRoutes.changeLanguage:
              builder = (c, a1, a2) => const LanguageUI();
              break;
            case PageRoutes.contests:
              builder = (c, a1, a2) {
                final matchInfo = settings.arguments as MatchInfo?;
                return Contests(matchInfo: matchInfo);
              };
              break;
            case PageRoutes.createNewTeam:
              builder = (c, a1, a2) => const CreateNewTeam();
              break;
            case PageRoutes.teamPreview:
              builder = (c, a1, a2) => const TeamPreview();
              break;
            case PageRoutes.chooseCaptain:
              builder = (c, a1, a2) => const ChooseCaptain();
              break;
            case PageRoutes.winnings:
              builder = (c, a1, a2) => Winnings();
              break;
            case PageRoutes.matchLive:
              builder = (c, a1, a2) => const MatchLive();
              break;
            case PageRoutes.matchCompleted:
              builder = (c, a1, a2) => MatchCompleted();
              break;
            case PageRoutes.support:
              builder = (c, a1, a2) => const Support();
              break;
            case PageRoutes.wallet:
              builder = (c, a1, a2) => const Wallet();
              break;
            case PageRoutes.playerDetails:
              builder = (c, a1, a2) {
                final player = settings.arguments as Player?;
                return PlayerDetailsPage(player: player);
              };
              break;
            case PageRoutes.pastFixtures:
              builder = (c, a1, a2) => const PastFixturesPage();
              break;
            case PageRoutes.matchDetails:
              builder = (c, a1, a2) {
                final fixtureId = settings.arguments as int;
                return MatchDetailsPage(fixtureId: fixtureId);
              };
              break;
          }
          return PageRouteBuilder(pageBuilder: builder, settings: settings);
        },
        onDidRemovePage: (page) {},
      ),
    );
  }
}
