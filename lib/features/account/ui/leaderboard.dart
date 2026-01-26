import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/leaderboard_teams.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: iconColor,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context)),
        title: Text(
          locale.leaderboard,
          style: theme.textTheme.bodySmall!.copyWith(
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Container(
            color: bgColor,
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                ),
                Text(
                  locale.leaderboard,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  margin:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                      color: bgTextColor,
                      borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    children: [
                      Text(
                        locale.allSeries,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 24,
                        color: iconColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          const Expanded(child: LeaderboardComponent()),
        ],
      ),
    );
  }
}
