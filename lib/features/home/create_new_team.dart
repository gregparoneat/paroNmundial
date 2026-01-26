import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/custom_scaffold.dart';
import 'package:fantacy11/features/components/line_container.dart';
import 'package:fantacy11/features/components/players_for_team_preview.dart';
import 'package:fantacy11/features/components/team_match_container.dart';
import 'package:fantacy11/features/responsive_widget.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class MatchStatus {
  final Color color;
  final String date;
  final String teamName;
  final String sellBy;
  final String point;
  final String credit;

  MatchStatus(this.color, this.date, this.teamName, this.sellBy, this.point,
      this.credit);
}

class Defenders {
  final String image;
  final String name;
  final String teamName;
  final Color color;
  final String subtitle;
  final String points;
  final String credits;
  bool isAdded = false;

  Defenders(
    this.image,
    this.name,
    this.teamName,
    this.color,
    this.subtitle,
    this.points,
    this.credits,
  );
}

class CreateNewTeam extends StatefulWidget {
  const CreateNewTeam({super.key});

  @override
  CreateNewTeamState createState() => CreateNewTeamState();
}

class CreateNewTeamState extends State<CreateNewTeam> {
  bool playerAdded = false;
  bool showPlayerInfo = false;

  List<Defenders> defenders = [
    Defenders('assets/Players/player4.png', 'R Jackson', 'WLS', Colors.blue,
        'Sel by 19.20%', '265', '10.0'),
    Defenders('assets/Players/player2.png', 'J Caven', 'CBR',
        Colors.purpleAccent, 'Sel by 19.20%', '265', '12.0'),
    Defenders('assets/Players/player11.png', 'P William', 'CBR',
        Colors.purpleAccent, 'Sel by 19.20%', '265', '14.0'),
    Defenders('assets/Players/player5.png', 'B Cordero', 'WLS', Colors.blue,
        'Sel by 19.20%', '265', '10.0'),
    Defenders('assets/Players/player6.png', 'J Donald', 'WLS', Colors.blue,
        'Sel by 19.20%', '265', '10.0'),
    Defenders('assets/Players/player7.png', 'R Simsons', 'WLS', Colors.blue,
        'Sel by 19.20%', '265', '10.0'),
    Defenders('assets/Players/player8.png', 'K Smith', 'CBR',
        Colors.purpleAccent, 'Sel by 19.20%', '265', '13.0'),
    Defenders('assets/Players/player9.png', 'R Jackson', 'WLS', Colors.blue,
        'Sel by 19.20%', '265', '10.0'),
    Defenders('assets/Players/player10.png', 'R Jackson', 'WLS', Colors.blue,
        'Sel by 19.20%', '265', '10.0'),
  ];

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return CustomScaffold(
      pageTitle: '0h 9m left',
      actions: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          child: IconButton(
              icon: Icon(
                Icons.remove_red_eye_rounded,
                size: 16,
                color: iconColor,
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, PageRoutes.teamPreview);
              }),
        ),
        const SizedBox(width: 16),
      ],
      tabBarItems: const [
        Tab(text: "GK (1)"),
        Tab(text: "DEF (0)"),
        Tab(text: "MID (0)"),
        Tab(text: "ST (0)"),
      ],
      tabBarChild: const TeamMatchContainer(),
      tabBarViewItems: [
        buildListView(theme, locale),
        buildListView(theme, locale),
        buildListView(theme, locale),
        buildListView(theme, locale),
      ],
      tabBarHeight: MediaQuery.of(context).size.height * 0.25,
      secondPage: ResponsiveWidget.isLargeScreen(context)
          ? showPlayerInfo
              ? Stack(
                  children: [
                    PlayerInfo(theme: theme, playerPerformance: true),
                    PositionedDirectional(
                      top: 16,
                      end: 16,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            showPlayerInfo = !showPlayerInfo;
                          });
                        },
                      ),
                    ),
                  ],
                )
              : previewTeam()
          : null,
    );
  }

  Widget previewTeam() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/ground.png',
          fit: BoxFit.fill,
        ),
        const PositionedDirectional(
          top: 120,
          start: 0,
          end: 0,
          child: PlayerForTeamPreview(
              'assets/Players/player5.png', 'J Caven', Colors.blue),
        ),
        const PositionedDirectional(
          top: 220,
          start: 0,
          end: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayerForTeamPreview(
                  'assets/Players/player1.png', 'P William', Colors.deepPurple),
              SizedBox(
                width: 20,
              ),
              PlayerForTeamPreview(
                  'assets/Players/player2.png', 'B Carde', Colors.blue),
              SizedBox(
                width: 20,
              ),
              PlayerForTeamPreview(
                  'assets/Players/player4.png', 'C Damde', Colors.deepPurple),
            ],
          ),
        ),
        const PositionedDirectional(
          bottom: 190,
          start: 0,
          end: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayerForTeamPreview(
                  'assets/Players/player6.png', 'P William', Colors.deepPurple),
              SizedBox(
                width: 20,
              ),
              PlayerForTeamPreview(
                  'assets/Players/player7.png', 'B Carde', Colors.blue),
              SizedBox(
                width: 20,
              ),
              PlayerForTeamPreview(
                  'assets/Players/player8.png', 'C Damde', Colors.deepPurple),
              SizedBox(
                width: 20,
              ),
              PlayerForTeamPreview(
                  'assets/Players/player9.png', 'C Damde', Colors.blue),
            ],
          ),
        ),
        const PositionedDirectional(
          bottom: 76,
          start: 0,
          end: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PlayerForTeamPreview('assets/Players/player10.png', 'P William',
                  Colors.deepPurple),
              SizedBox(
                width: 20,
              ),
              PlayerForTeamPreview(
                  'assets/Players/player11.png', 'B Carde', Colors.blue),
              SizedBox(
                width: 20,
              ),
              PlayerForTeamPreview(
                  'assets/Players/player12.png', 'C Damde', Colors.deepPurple),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildListView(ThemeData theme, S locale) {
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            Container(
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                  ),
                  Text(
                    locale.select,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    locale.selBy.toUpperCase(),
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontSize: 10,
                      color: bgTextColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    locale.point.toUpperCase(),
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontSize: 10,
                      color: bgTextColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    locale.credit.toUpperCase(),
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontSize: 10,
                      color: bgTextColor,
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        size: 16,
                        color: iconColor,
                      ),
                      onPressed: () {}),
                  const SizedBox(
                    width: 20,
                  ),
                ],
              ),
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
                        decoration: BoxDecoration(
                            gradient: defenders[index].isAdded
                                ? LinearGradient(colors: [
                                    const Color(0xff154427).withValues(alpha: 0.4),
                                    const Color(0xff154427).withValues(alpha: 0.4),
                                    const Color(0xff154427),
                                  ])
                                : const LinearGradient(
                                    colors: [Colors.black, Colors.black])),
                        child: Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: FadedScaleAnimation(
                                      child: Image.asset(
                                        defenders[index].image,
                                        scale: 1.5,
                                      ),
                                    )),
                                title: Text(defenders[index].name,
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      fontSize: 12,
                                    )),
                                subtitle: RichText(
                                  text: TextSpan(
                                      text: defenders[index].teamName,
                                      style:
                                          theme.textTheme.bodyMedium!.copyWith(
                                        fontSize: 10,
                                        color: defenders[index].color,
                                      ),
                                      children: [
                                        TextSpan(
                                            text:
                                                '  ${defenders[index].subtitle}',
                                            style: theme.textTheme.bodySmall!
                                                .copyWith(
                                              color: bgTextColor,
                                              fontSize: 9,
                                            )),
                                      ]),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                onTap: () {
                                  if (ResponsiveWidget.isLargeScreen(context)) {
                                    setState(() {
                                      showPlayerInfo = !showPlayerInfo;
                                    });
                                  } else {
                                    showModalBottomSheet(
                                        backgroundColor: bgColor,
                                        shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(24),
                                                topLeft: Radius.circular(24))),
                                        context: context,
                                        builder: (context) {
                                          return PlayerInfo(
                                            theme: theme,
                                            playerPerformance: true,
                                          );
                                        });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 30,
                            ),
                            Text(
                              defenders[index].points,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: bgTextColor,
                              ),
                            ),
                            const SizedBox(
                              width: 30,
                            ),
                            Text(
                              defenders[index].credits,
                              style: theme.textTheme.bodyMedium!.copyWith(),
                            ),
                            const SizedBox(
                              width: 30,
                            ),
                            IconButton(
                                icon: Icon(
                                  defenders[index].isAdded
                                      ? Icons.remove_circle_outline
                                      : Icons.add_circle_outline,
                                  color: const Color(0xff2F5813),
                                ),
                                onPressed: () {
                                  if (defenders[index].isAdded) {
                                    setState(() {
                                      defenders[index].isAdded = false;
                                    });
                                  } else {
                                    setState(() {
                                      defenders[index].isAdded = true;
                                    });
                                  }
                                  if (defenders.any(
                                      (element) => element.isAdded = true)) {
                                    playerAdded = true;
                                  } else {
                                    playerAdded = false;
                                  }
                                }),
                            const SizedBox(
                              width: 20,
                            ),
                          ],
                        ),
                      ),
                      const LineContainer(0),
                    ],
                  );
                })
          ],
        ),
        if (playerAdded)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 20,
            child: CustomButton(
              text: locale.continueText,
              margin: const EdgeInsets.symmetric(horizontal: 50),
              onTap: () {
                Navigator.pushReplacementNamed(context, PageRoutes.teamPreview,
                    arguments: true);
              },
            ),
          )
      ],
    );
  }
}

class PlayerHistory {
  final String events;
  final String actual;
  final String credit;

  PlayerHistory(this.events, this.actual, this.credit);
}

class PlayerInfo extends StatefulWidget {
  final bool playerPerformance;

  const PlayerInfo({
    super.key,
    required this.theme,
    this.playerPerformance = false,
  });

  final ThemeData theme;

  @override
  PlayerInfoState createState() => PlayerInfoState();
}

class PlayerInfoState extends State<PlayerInfo> {
  bool playerHistory = false;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    List<MatchStatus> matchStatus = [
      MatchStatus(
          Colors.orange, 'JUL 05, 2021', 'MXT', '20.50%', '325', '10.0'),
      MatchStatus(Colors.red, 'JUL 05, 2021', 'BLB', '30.50%', '325', '10.0'),
      MatchStatus(Colors.blue, 'JUL 05, 2021', 'HJI', '20.45%', '325', '10.0'),
      MatchStatus(Colors.green, 'JUL 05, 2021', 'KKK', '20.60%', '325', '10.0'),
      MatchStatus(
          Colors.yellow, 'JUL 05, 2021', 'SDF', '24.50%', '325', '10.0'),
      MatchStatus(
          Colors.purpleAccent, 'JUL 05, 2021', 'MXT', '30.50%', '325', '10.0'),
      MatchStatus(Colors.pink, 'JUL 05, 2021', 'MXT', '20.50%', '325', '10.0'),
      MatchStatus(
          Colors.blueGrey, 'JUL a05, 2021', 'MXT', '20.50%', '325', '10.0'),
    ];
    List<PlayerHistory> playerHistoryy = [
      PlayerHistory(locale.inPlayingEleven, '1', '4.0'),
      PlayerHistory(locale.substitute, '0', '3.0'),
      PlayerHistory(locale.goals, '1', '4.0'),
      PlayerHistory(locale.assists, '0', '4.0'),
      PlayerHistory(locale.shotsOnTarget, '1', '5.0'),
      PlayerHistory(locale.passesCompleted, '0', '4.0'),
      PlayerHistory(locale.tackleWon, '1', '4.0'),
      PlayerHistory(locale.interceptionsWon, '1', '6.0'),
      PlayerHistory(locale.blockedShots, '1', '4.0'),
      PlayerHistory(locale.clearance, '1', '4.0'),
      PlayerHistory(locale.passesCompleted, '0', '4.0'),
      PlayerHistory(locale.tackleWon, '1', '4.0'),
      PlayerHistory(locale.interceptionsWon, '1', '6.0'),
      PlayerHistory(locale.blockedShots, '1', '4.0'),
      PlayerHistory(locale.clearance, '1', '4.0'),
    ];
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        FadedSlideAnimation(
          beginOffset: const Offset(0, 2),
          endOffset: const Offset(0, 0),
          slideCurve: Curves.linearToEaseOut,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24), topLeft: Radius.circular(24)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(
                  width: 16,
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: Image.asset(
                    'assets/Players/player7.png',
                    scale: 1.5,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'J Caven',
                      style: widget.theme.textTheme.bodyMedium,
                    ),
                    RichText(
                      text: TextSpan(
                          text: 'CBR | ',
                          style: widget.theme.textTheme.bodySmall!.copyWith(
                            color: Colors.purpleAccent,
                            fontSize: 10,
                          ),
                          children: [
                            TextSpan(
                                text: '${locale.defenders}\n',
                                style:
                                    widget.theme.textTheme.bodySmall!.copyWith(
                                  color: bgTextColor,
                                  fontSize: 10,
                                )),
                          ]),
                    ),
                    Text(
                      '${locale.point.toUpperCase()}     ${locale.credit.toUpperCase()}',
                      style: widget.theme.textTheme.bodySmall!.copyWith(
                        color: bgTextColor,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '265     9.5',
                      style: widget.theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.playerPerformance)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: bgTextColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      locale.add,
                      style: widget.theme.textTheme.headlineSmall!.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                const SizedBox(
                  width: 16,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: widget.theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.recentMatchStatus,
                style: widget.theme.textTheme.bodyMedium,
              ),
              const SizedBox(
                height: 10,
              ),
              ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: playerHistory == true ? 1 : matchStatus.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          playerHistory = !playerHistory;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: playerHistory == true
                            ? const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0)
                            : const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: playerHistory == true
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12))
                              : BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              matchStatus[index].color,
                              bgColor,
                              bgColor,
                              bgColor,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              matchStatus[index].date,
                              style: widget.theme.textTheme.bodySmall!
                                  .copyWith(color: bgTextColor, fontSize: 10),
                            ),
                            Row(
                              children: [
                                Text(
                                  'VS.',
                                  style: widget.theme.textTheme.bodySmall!
                                      .copyWith(
                                          color: bgTextColor, fontSize: 8),
                                ),
                                const Spacer(
                                  flex: 2,
                                ),
                                Text(
                                  locale.selBy.toUpperCase(),
                                  style: widget.theme.textTheme.bodySmall!
                                      .copyWith(
                                          color: bgTextColor, fontSize: 10),
                                ),
                                const Spacer(),
                                Text(
                                  locale.point.toUpperCase(),
                                  style: widget.theme.textTheme.bodySmall!
                                      .copyWith(
                                          color: bgTextColor, fontSize: 10),
                                ),
                                const Spacer(),
                                Text(
                                  locale.credit.toUpperCase(),
                                  style: widget.theme.textTheme.bodySmall!
                                      .copyWith(
                                          color: bgTextColor, fontSize: 10),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  matchStatus[index].teamName,
                                  style: widget.theme.textTheme.bodySmall!
                                      .copyWith(
                                          color: matchStatus[index].color,
                                          fontSize: 10),
                                ),
                                const Spacer(
                                  flex: 2,
                                ),
                                Text(
                                  matchStatus[index].sellBy,
                                  style: widget.theme.textTheme.bodySmall!
                                      .copyWith(fontSize: 10),
                                ),
                                const Spacer(),
                                Text(
                                  matchStatus[index].point,
                                  style: widget.theme.textTheme.bodySmall!
                                      .copyWith(fontSize: 10),
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                                const Spacer(),
                                Text(
                                  matchStatus[index].credit,
                                  style: widget.theme.textTheme.bodySmall!
                                      .copyWith(fontSize: 10),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              playerHistory == true
                  ? FadedSlideAnimation(
                      beginOffset: const Offset(0, 2),
                      endOffset: const Offset(0, 0),
                      slideCurve: Curves.linearToEaseOut,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 0),
                            color: Colors.black,
                            child: Row(
                              children: [
                                Text(
                                  locale.events.toUpperCase(),
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    fontSize: 10,
                                    color: bgTextColor,
                                  ),
                                ),
                                const Spacer(
                                  flex: 4,
                                ),
                                Text(
                                  locale.actual.toUpperCase(),
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    fontSize: 10,
                                    color: bgTextColor,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  locale.points.toUpperCase(),
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    fontSize: 10,
                                    color: bgTextColor,
                                  ),
                                )
                              ],
                            ),
                          ),
                          ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: playerHistoryy.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  color: bgColor,
                                  child: Row(
                                    children: [
                                      Text(
                                        playerHistoryy[index].events,
                                        style:
                                            theme.textTheme.bodySmall!.copyWith(
                                          fontSize: 10,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        playerHistoryy[index].actual,
                                        style:
                                            theme.textTheme.bodySmall!.copyWith(
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 70,
                                      ),
                                      Text(
                                        playerHistoryy[index].credit,
                                        style:
                                            theme.textTheme.bodySmall!.copyWith(
                                          fontSize: 10,
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              })
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        )
      ],
    );
  }
}
