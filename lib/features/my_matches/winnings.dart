import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/contest_container.dart';
import 'package:fantacy11/features/components/custom_scaffold.dart';
import 'package:fantacy11/features/components/line_container.dart';
import 'package:fantacy11/features/components/winnings.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class TeamsRank {
  final String image;
  final String teamName;
  final String rank;

  TeamsRank(this.image, this.teamName, this.rank);
}

class Winnings extends StatelessWidget {
  final List<TeamsRank> leaderboard = [
    TeamsRank('assets/Teams/click to edit-1.png', 'Samanthateam123', '11'),
    TeamsRank('assets/Teams/click to edit-2.png', 'Daniel007', '23'),
    TeamsRank('assets/Teams/click to edit-3.png', 'Emmiliteam', '51'),
    TeamsRank('assets/Teams/click to edit-4.png', 'Tomboy123', '1'),
    TeamsRank('assets/Teams/click to edit-5.png', 'Plaboy789', '31'),
    TeamsRank('assets/Teams/click to edit-6.png', 'harshuTeam', '1'),
    TeamsRank('assets/Teams/click to edit-7.png', 'raunaqTeam', '11'),
    TeamsRank('assets/Teams/click to edit-8.png', 'Jaggu123', '12'),
    TeamsRank('assets/Teams/click to edit-9.png', 'Samanthateam123', '21'),
  ];

  Winnings({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return CustomScaffold(
      pageTitle: '0h 9m left',
      tabBarHeight: MediaQuery.of(context).size.height * 0.24,
      tabBarItems: [
        Tab(text: locale.winnings.toUpperCase()),
        Tab(text: locale.leaderboard.toUpperCase()),
      ],
      tabBarChild: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.only(bottom: 8, left: 16, right: 16, top: 8),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                  topRight: Radius.circular(18), topLeft: Radius.circular(18)),
              gradient: LinearGradient(
                colors: [
                  Colors.blue,
                  Colors.black,
                  Colors.deepPurple,
                ],
              ),
            ),
            child: Row(
              children: [
                Text(
                  'WOLVES UNITED',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  'VS',
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontSize: 10,
                    color: bgTextColor,
                  ),
                ),
                const Spacer(),
                Text(
                  'COBRA GUARDIANS',
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          ContestContainer(
            ContestModel(
              radius: BorderRadius.zero,
              margin: EdgeInsets.zero,
              entryType: locale.multipleEntries,
              amount: '\$5,00,000',
              winner: '60% Winners | 1st \$50,000',
              entryTicket: '\$20',
              color1: Colors.green,
              color2: Colors.red,
              color3: bgTextColor,
              color4: bgTextColor,
              spotsFilled: '10,000',
              spotsLeft: '5,670',
            ),
          )
        ],
      ),
      tabBarViewItems: [
        const RanksAndWinnings(),
        FadedSlideAnimation(
          beginOffset: const Offset(0, 2),
          endOffset: const Offset(0, 0),
          slideCurve: Curves.linearToEaseOut,
          child: ListView.builder(
              shrinkWrap: true,
              itemCount: leaderboard.length,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    index == 0
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16),
                            child: Text(
                              '${locale.allTeams.toUpperCase()} (6,125)',
                              style: theme.textTheme.bodySmall!.copyWith(
                                fontSize: 10,
                                color: bgTextColor,
                              ),
                            ),
                          )
                        : ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                leaderboard[index].image,
                                scale: 3,
                              ),
                            ),
                            title: RichText(
                              text: TextSpan(
                                  text: leaderboard[index].teamName,
                                  style: theme.textTheme.bodyMedium!.copyWith(
                                    fontSize: 10,
                                  ),
                                  children: [
                                    TextSpan(
                                        text: ' (${leaderboard[index].rank})',
                                        style:
                                            theme.textTheme.bodySmall!.copyWith(
                                          color: bgTextColor,
                                          fontSize: 10,
                                        ))
                                  ]),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 0, horizontal: 8),
                          ),
                    const LineContainer(
                      2,
                      height: 0.2,
                    ),
                  ],
                );
              }),
        ),
      ],
    );
  }
}
