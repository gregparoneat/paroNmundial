import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/leaderboard_teams.dart';
import 'package:fantacy11/features/components/line_container.dart';
import 'package:fantacy11/features/components/signle_team_container.dart';
import 'package:fantacy11/features/components/winnings.dart';
import 'package:fantacy11/features/home/create_new_team.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class Defenders {
  final String image;
  final String name;
  final String teamName;
  final Color color;
  final String subtitle;
  final String points;
  final String credits;

  Defenders(this.image, this.name, this.teamName, this.color, this.subtitle,
      this.points, this.credits);
}

class MatchCompleted extends StatelessWidget {
  final List<Defenders> defenders = [
    Defenders('assets/Players/player4.png', 'R Jackson', 'WLS', Colors.blue,
        'GK', '125', '55.9%'),
    Defenders('assets/Players/player2.png', 'J Caven', 'CBR',
        Colors.purpleAccent, 'DEF', '135', '41.0%'),
    Defenders('assets/Players/player11.png', 'P William', 'CBR',
        Colors.purpleAccent, 'DEF', '320', '23.5%'),
    Defenders('assets/Players/player5.png', 'B Cordero', 'WLS', Colors.blue,
        'DEF', '169', '11.2%'),
    Defenders('assets/Players/player6.png', 'J Donald', 'WLS', Colors.blue,
        'MID', '103', '0.5%'),
    Defenders('assets/Players/player7.png', 'R Simsons', 'WLS', Colors.blue,
        'MID', '265', '90.1%'),
    Defenders('assets/Players/player8.png', 'K Smith', 'CBR',
        Colors.purpleAccent, 'MID', '265', '50.0%'),
    Defenders('assets/Players/player9.png', 'R Jackson', 'WLS', Colors.blue,
        'MID', '265', '23.3%'),
    Defenders('assets/Players/player10.png', 'R Jackson', 'WLS', Colors.blue,
        'MID', '265', '10.5%'),
  ];

  MatchCompleted({super.key});
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset('assets/img_header.png'),
                PositionedDirectional(
                  top: 40,
                  start: 10,
                  end: 10,
                  child: Row(
                    children: [
                      IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: iconColor,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          }),
                      const Spacer(
                        flex: 2,
                      ),
                      Text(
                        locale.matchCompleted,
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(
                        flex: 3,
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  top: 100,
                  start: 0,
                  end: 0,
                  child: SingleTeamContainer(
                    text: '90 mins',
                    match: theme.textTheme.bodySmall!.copyWith(
                      color: iconColor,
                      fontSize: 10,
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: -20,
                  start: 96,
                  end: 96,
                  child: Row(
                    children: [
                      Text(
                        '1',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: iconColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '3',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: -80,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: bgColor,
                    child: TabBar(
                      indicatorColor: Colors.transparent,
                      tabs: [
                        Container(
                          decoration: BoxDecoration(
                              color: iconColor,
                              borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 16),
                          child: Text(
                            locale.winnings.toUpperCase(),
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: Colors.black,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          locale.leaderboard.toUpperCase(),
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          locale.stats.toUpperCase(),
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 60,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const RanksAndWinnings(),
                  LeaderboardComponent(
                    onTap: () {
                      Navigator.pushNamed(context, PageRoutes.appNavigation);
                    },
                    subtitle: Text(
                      'Won \$25',
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontSize: 10,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  FadedSlideAnimation(
                    beginOffset: const Offset(0, 2),
                    endOffset: const Offset(0, 0),
                    slideCurve: Curves.linearToEaseOut,
                    child: ListView(
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 20,
                            ),
                            Text(
                              locale.players.toUpperCase(),
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: bgTextColor,
                                fontSize: 10,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              locale.points.toUpperCase(),
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: bgTextColor,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(
                              width: 50,
                            ),
                            Text(
                              locale.selBy.toUpperCase(),
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: bgTextColor,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                          ],
                        ),
                        ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: defenders.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  Container(
                                    margin: EdgeInsets.zero,
                                    decoration: BoxDecoration(
                                        gradient: index == 0 ||
                                                index == 2 ||
                                                index == 3 ||
                                                index == 6 ||
                                                index == 8
                                            ? LinearGradient(colors: [
                                                const Color(0xff154427)
                                                    .withValues(alpha: 0.4),
                                                const Color(0xff154427)
                                                    .withValues(alpha: 0.4),
                                                const Color(0xff154427),
                                              ])
                                            : const LinearGradient(colors: [
                                                Colors.black,
                                                Colors.black
                                              ])),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ListTile(
                                            onTap: () {
                                              showModalBottomSheet(
                                                  backgroundColor: bgColor,
                                                  shape: const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topRight: Radius
                                                                  .circular(24),
                                                              topLeft: Radius
                                                                  .circular(
                                                                      24))),
                                                  context: context,
                                                  builder: (context) {
                                                    return PlayerInfo(
                                                      theme: theme,
                                                    );
                                                  });
                                            },
                                            leading: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                                child: Image.asset(
                                                  defenders[index].image,
                                                  scale: 1.5,
                                                )),
                                            title: Text(defenders[index].name,
                                                style: theme
                                                    .textTheme.bodyMedium!
                                                    .copyWith(
                                                  fontSize: 12,
                                                )),
                                            subtitle: RichText(
                                              text: TextSpan(
                                                  text:
                                                      defenders[index].teamName,
                                                  style: theme
                                                      .textTheme.bodyMedium!
                                                      .copyWith(
                                                    fontSize: 10,
                                                    color:
                                                        defenders[index].color,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                        text:
                                                            ' | ${defenders[index].subtitle}',
                                                        style: theme.textTheme
                                                            .bodySmall!
                                                            .copyWith(
                                                          color: bgTextColor,
                                                          fontSize: 10,
                                                        )),
                                                  ]),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 30,
                                        ),
                                        Text(defenders[index].points,
                                            style: theme.textTheme.bodyMedium!
                                                .copyWith(
                                              fontSize: 12,
                                            )),
                                        const SizedBox(
                                          width: 60,
                                        ),
                                        Text(defenders[index].credits,
                                            style: theme.textTheme.bodyMedium!
                                                .copyWith(
                                              fontSize: 12,
                                            )),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const LineContainer(0),
                                ],
                              );
                            }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
