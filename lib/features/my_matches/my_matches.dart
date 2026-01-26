import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/custom_scaffold.dart';
import 'package:fantacy11/features/match/ui/match_list.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class MyMatches extends StatelessWidget {
  const MyMatches({super.key});

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
              child: Text(
                locale.football,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            items: const [],
            underline: const SizedBox.shrink(),
            onChanged: (value) {},
          ),
        ),
        const SizedBox(width: 16),
      ],
      pageTitle: locale.myMatches,
      tabBarItems: [
        Tab(text: locale.upcoming),
        Tab(text: locale.live),
        Tab(text: locale.completed),
      ],
      tabBarChild: const SizedBox.shrink(),
      tabBarViewItems: [
        MatchList.vertical(
          '0h 9m',
          'Lineup Announced',
          (matchInfo) => Navigator.pushNamed(
            context,
            PageRoutes.contests,
            arguments: matchInfo,
          ),
          itemCount: 3,
        ),
        MatchList.vertical(
          locale.live,
          '',
          (matchInfo) => Navigator.pushNamed(
            context,
            PageRoutes.matchLive,
            arguments: matchInfo,
          ),
          itemCount: 2,
        ),
        MatchList.vertical(
          locale.completed,
          'You\'ve earned \$50',
          (matchInfo) => Navigator.pushNamed(
            context,
            PageRoutes.matchCompleted,
            arguments: matchInfo,
          ),
          itemCount: 4,
        ),
      ],
      centerTitle: false,
      tabBarHeight: 92,
      tabBarColor: Colors.transparent,
    );
  }
}
