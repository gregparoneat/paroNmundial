import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/line_container.dart';
import 'package:fantacy11/features/components/signle_team_container.dart';
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

class ChooseCaptain extends StatelessWidget {
  const ChooseCaptain({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    List<Defenders> defenders = [
      Defenders('assets/Players/player4.png', 'R Jackson', 'WLS', Colors.blue,
          'GK', '125', 'C'),
      Defenders('assets/Players/player2.png', 'J Caven', 'CBR',
          Colors.purpleAccent, 'DEF', '135', 'C'),
      Defenders('assets/Players/player11.png', 'P William', 'CBR',
          Colors.purpleAccent, 'DEF', '320', '2x'),
      Defenders('assets/Players/player5.png', 'B Cordero', 'WLS', Colors.blue,
          'DEF', '169', 'C'),
      Defenders('assets/Players/player6.png', 'J Donald', 'WLS', Colors.blue,
          'MID', '103', 'C'),
      Defenders('assets/Players/player7.png', 'R Simsons', 'WLS', Colors.blue,
          'MID', '265', 'C'),
      Defenders('assets/Players/player8.png', 'K Smith', 'CBR',
          Colors.purpleAccent, 'MID', '265', 'C'),
      Defenders('assets/Players/player9.png', 'R Jackson', 'WLS', Colors.blue,
          'MID', '265', 'C'),
      Defenders('assets/Players/player10.png', 'R Jackson', 'WLS', Colors.blue,
          'MID', '265', 'C'),
    ];
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(top: 40),
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 8,
                  ),
                  IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: iconColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                  const Spacer(),
                  Text(
                    '0h 9m left',
                    style: theme.textTheme.bodyLarge!.copyWith(
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
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
                          Navigator.pushNamed(context, PageRoutes.teamPreview);
                        }),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              SingleTeamContainer(
                text: '5  :  6',
                match: theme.textTheme.bodySmall!
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 5.0, left: 20, right: 20, top: 16),
                child: Text(
                  locale.chooseCaptain,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                locale.cWillGet,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: bgTextColor,
                  fontSize: 10,
                ),
              ),
              Container(
                color: bgColor,
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Spacer(
                      flex: 3,
                    ),
                    Text(locale.type.toUpperCase(),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: bgTextColor,
                          fontSize: 12,
                        )),
                    const Spacer(
                      flex: 3,
                    ),
                    Text(locale.point.toUpperCase(),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: bgTextColor,
                          fontSize: 12,
                        )),
                    const Spacer(),
                    Text(locale.cap.toUpperCase(),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: bgTextColor,
                          fontSize: 12,
                        )),
                    const Spacer(),
                    Text(locale.vcap.toUpperCase(),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: bgTextColor,
                          fontSize: 12,
                        )),
                    const Spacer(),
                  ],
                ),
              ),
              FadedSlideAnimation(
                beginOffset: const Offset(0, 2),
                endOffset: const Offset(0, 0),
                slideCurve: Curves.linearToEaseOut,
                child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: defenders.length,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ListTile(
                                  leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: Image.asset(
                                        defenders[index].image,
                                        scale: 1.5,
                                      )),
                                  title: Text(defenders[index].name,
                                      style:
                                          theme.textTheme.bodyMedium!.copyWith(
                                        fontSize: 12,
                                      )),
                                  subtitle: RichText(
                                    text: TextSpan(
                                        text: defenders[index].teamName,
                                        style: theme.textTheme.bodyMedium!
                                            .copyWith(
                                          fontSize: 10,
                                          color: defenders[index].color,
                                        ),
                                        children: [
                                          TextSpan(
                                              text:
                                                  ' | ${defenders[index].subtitle}',
                                              style: theme.textTheme.bodySmall!
                                                  .copyWith(
                                                color: bgTextColor,
                                                fontSize: 9,
                                              )),
                                        ]),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                ),
                              ),
                              const SizedBox(
                                width: 30,
                              ),
                              Text(defenders[index].points,
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(
                                width: 30,
                              ),
                              CircleAvatar(
                                backgroundColor: index == 2
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.2),
                                radius: 12,
                                child: Text(
                                  defenders[index].credits,
                                  style: index == 2
                                      ? theme.textTheme.bodyMedium!.copyWith(
                                          fontSize: 10, color: Colors.black)
                                      : theme.textTheme.bodyMedium!
                                          .copyWith(fontSize: 10),
                                ),
                              ),
                              const SizedBox(
                                width: 30,
                              ),
                              CircleAvatar(
                                backgroundColor: index == 3
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.2),
                                radius: 15,
                                child: Text(
                                  index == 3 ? '1.5x' : 'VC',
                                  style: index == 3
                                      ? theme.textTheme.bodyMedium!.copyWith(
                                          fontSize: 10, color: Colors.black)
                                      : theme.textTheme.bodyMedium!
                                          .copyWith(fontSize: 10),
                                ),
                              ),
                              const SizedBox(
                                width: 40,
                              ),
                            ],
                          ),
                          const LineContainer(4),
                        ],
                      );
                    }),
              ),
            ],
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 20,
            child: FadedScaleAnimation(
              child: CustomButton(
                text: locale.saveTeam.toUpperCase(),
                margin: const EdgeInsets.symmetric(horizontal: 70),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
