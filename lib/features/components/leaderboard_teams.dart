import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

import 'line_container.dart';

class LeaderboardTeams {
  final String image;
  final String name;
  final String subtitle;
  final String points;
  final String rank;

  LeaderboardTeams(
      this.image, this.name, this.subtitle, this.points, this.rank);
}

class LeaderboardComponent extends StatelessWidget {
  final Function? onTap;
  final Text? subtitle;
  const LeaderboardComponent({super.key, this.onTap, this.subtitle});
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    List<LeaderboardTeams> leaderboardItems = [
      LeaderboardTeams('assets/Teams/accountTeam.png', 'Samanthateam123',
          '${locale.level} 89', '1952.5', '1'),
      LeaderboardTeams('assets/Teams/click to edit-1.png', 'Daniel007',
          '${locale.level} 99', '2530.5', '1'),
      LeaderboardTeams('assets/Teams/click to edit-2.png', 'EmiliiWilliamson',
          '${locale.level} 99', '2530.5', '2'),
      LeaderboardTeams('assets/Teams/click to edit-3.png', 'Tomboy',
          '${locale.level} 23', '2530.5', '3'),
      LeaderboardTeams('assets/Teams/click to edit-4.png', 'MummasBoy',
          '${locale.level} 76', '2530.5', '4'),
      LeaderboardTeams('assets/Teams/click to edit-5.png', 'Team4Win07',
          '${locale.level} 89', '2530.5', '5'),
      LeaderboardTeams('assets/Teams/click to edit-6.png', 'Harshuteam',
          '${locale.level} 65', '2530.5', '6'),
      LeaderboardTeams('assets/Teams/click to edit-7.png', 'RoseTeam',
          '${locale.level} 67', '2530.5', '7'),
      LeaderboardTeams('assets/Teams/click to edit-8.png', 'amanTeam',
          '${locale.level} 99', '2530.5', '8'),
      LeaderboardTeams('assets/Teams/click to edit-9.png', 'raunaqTeam',
          '${locale.level} 99', '2530.5', '9'),
    ];
    return FadedSlideAnimation(
      beginOffset: const Offset(0, 2),
      endOffset: const Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
              ),
              Text(
                ' ${locale.allTeams}${' (10,000)'.toUpperCase()}',
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
                '#${locale.rank.toUpperCase()}',
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
          const LineContainer(8),
          ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leaderboardItems.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            onTap: onTap as void Function()? ??
                                () {
                                  Navigator.pushNamed(
                                      context, PageRoutes.profile);
                                },
                            leading: FadedScaleAnimation(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: Image.asset(
                                  leaderboardItems[index].image,
                                  scale: 2.5,
                                ),
                              ),
                            ),
                            title: Text(
                              leaderboardItems[index].name,
                              style: theme.textTheme.titleLarge!.copyWith(
                                color: iconColor,
                                fontSize: 12,
                              ),
                            ),
                            subtitle: subtitle ??
                                Text(leaderboardItems[index].subtitle,
                                    style: theme.textTheme.titleLarge!.copyWith(
                                      fontSize: 10,
                                    )),
                          ),
                        ),
                        Text(
                          leaderboardItems[index].points,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(
                          width: 85,
                        ),
                        Text(
                          leaderboardItems[index].rank,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
                    const LineContainer(3),
                  ],
                );
              })
        ],
      ),
    );
  }
}
