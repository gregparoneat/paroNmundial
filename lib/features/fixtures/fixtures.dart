import 'package:flutter/material.dart';

import '../../app_config/colors.dart';
import '../../generated/l10n.dart';
import '../components/custom_scaffold.dart';
import 'ui/past_fixtures_page.dart';
import 'ui/upcoming_fixtures_page.dart';
import 'ui/world_cup_predictor_page.dart';
import 'ui/world_cup_standings_page.dart';

class Fixtures extends StatelessWidget {
  const Fixtures({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);

    return CustomScaffold(
      isRoot: true,
      actions: [
        Icon(Icons.sports_soccer, color: iconColor),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: theme.scaffoldBackgroundColor,
                content: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(locale.noOtherSportsAvailableContactAdmin),
                  ],
                ),
              ),
            );
          },
          child: DropdownButton<String>(
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 20,
            iconEnabledColor: iconColor,
            iconDisabledColor: iconColor,
            hint: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
              child: Text(locale.football, style: theme.textTheme.bodyMedium),
            ),
            items: const [],
            underline: const SizedBox.shrink(),
            onChanged: (value) {},
          ),
        ),
        const SizedBox(width: 16),
      ],
      pageTitle: locale.fixtures,
      tabBarItems: [
        Tab(text: locale.upcoming),
        Tab(
          text: Localizations.localeOf(context).languageCode == 'es'
              ? 'Predictor'
              : 'Predictor',
        ),
        Tab(
          text: Localizations.localeOf(context).languageCode == 'es'
              ? 'Grupos'
              : 'Groups',
        ),
        Tab(text: locale.completed),
      ],
      tabBarChild: const SizedBox.shrink(),
      tabBarViewItems: [
        // Upcoming fixtures with predicted lineups
        const UpcomingFixturesPage(embedded: true),
        const WorldCupPredictorPage(embedded: true),
        const WorldCupStandingsPage(embedded: true),
        // Past/Completed fixtures with real results and lineups
        const PastFixturesPage(embedded: true),
      ],
      centerTitle: false,
      tabBarHeight: 92,
      tabBarColor: Colors.transparent,
    );
  }
}
