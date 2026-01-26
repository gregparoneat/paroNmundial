import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/custom_scaffold.dart';
import 'package:fantacy11/features/components/leaderboard_teams.dart';
import 'package:fantacy11/features/components/signle_team_container.dart';
import 'package:fantacy11/features/components/winnings.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class MatchLive extends StatelessWidget {
  const MatchLive({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return CustomScaffold(
      pageTitle: locale.matchLive,
      tabBarItems: [
        Tab(text: locale.winnings.toUpperCase()),
        Tab(text: locale.leaderboard.toUpperCase()),
      ],
      tabBarChild: SingleTeamContainer(
        text: '10:37 mins',
        match: theme.textTheme.bodySmall!.copyWith(
          color: iconColor,
          fontSize: 10,
        ),
        showScore: true,
      ),
      tabBarViewItems: [
        const RanksAndWinnings(),
        LeaderboardComponent(
          onTap: () {
            Navigator.pushNamed(context, PageRoutes.matchCompleted);
          },
        ),
      ],
    );
  }
}
