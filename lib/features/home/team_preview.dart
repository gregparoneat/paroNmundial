import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/players_for_team_preview.dart';
import 'package:fantacy11/features/components/team_match_container.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class TeamPreview extends StatelessWidget {
  const TeamPreview({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    bool edit = ModalRoute.of(context)!.settings.arguments as bool? ?? false;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/ground.png',
                  fit: BoxFit.fill,
                ),
                PositionedDirectional(
                  top: 30,
                  start: 10,
                  end: 10,
                  child: Row(
                    children: [
                      IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: iconColor,
                            size: 20,
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
                      edit == false
                          ? CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: iconColor,
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                        context, PageRoutes.chooseCaptain);
                                  }),
                            )
                          : CircleAvatar(
                              radius: 16,
                              backgroundColor: theme.primaryColor,
                              child: IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: iconColor,
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                        context, PageRoutes.chooseCaptain);
                                  }),
                            ),
                      const SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                ),
                const PositionedDirectional(
                  top: 150,
                  start: 0,
                  end: 0,
                  child: PlayerForTeamPreview(
                      'assets/Players/player5.png', 'J Caven', Colors.blue),
                ),
                const PositionedDirectional(
                  top: 260,
                  start: 0,
                  end: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PlayerForTeamPreview('assets/Players/player1.png',
                          'P William', Colors.deepPurple),
                      SizedBox(
                        width: 20,
                      ),
                      PlayerForTeamPreview(
                          'assets/Players/player2.png', 'B Carde', Colors.blue),
                      SizedBox(
                        width: 20,
                      ),
                      PlayerForTeamPreview('assets/Players/player4.png',
                          'C Damde', Colors.deepPurple),
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
                      PlayerForTeamPreview('assets/Players/player6.png',
                          'P William', Colors.deepPurple),
                      SizedBox(
                        width: 20,
                      ),
                      PlayerForTeamPreview(
                          'assets/Players/player7.png', 'B Carde', Colors.blue),
                      SizedBox(
                        width: 20,
                      ),
                      PlayerForTeamPreview('assets/Players/player8.png',
                          'C Damde', Colors.deepPurple),
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
                      PlayerForTeamPreview('assets/Players/player10.png',
                          'P William', Colors.deepPurple),
                      SizedBox(
                        width: 20,
                      ),
                      PlayerForTeamPreview('assets/Players/player11.png',
                          'B Carde', Colors.blue),
                      SizedBox(
                        width: 20,
                      ),
                      PlayerForTeamPreview('assets/Players/player12.png',
                          'C Damde', Colors.deepPurple),
                    ],
                  ),
                ),
                PositionedDirectional(
                  bottom: -130,
                  start: 0,
                  end: 0,
                  child: TeamMatchContainer(color: theme.primaryColor),
                ),
              ],
            ),
          ),
          Container(
            color: bgColor,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                ),
                RichText(
                  text: TextSpan(
                      text: 'GK',
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                            text: ' (1)',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: bgTextColor,
                              fontSize: 12,
                            )),
                      ]),
                ),
                const Spacer(),
                RichText(
                  text: TextSpan(
                      text: 'DEF',
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                            text: ' (0)',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: bgTextColor,
                              fontSize: 12,
                            )),
                      ]),
                ),
                const Spacer(),
                RichText(
                  text: TextSpan(
                      text: 'MID',
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                            text: ' (0)',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: bgTextColor,
                              fontSize: 12,
                            )),
                      ]),
                ),
                const Spacer(),
                RichText(
                  text: TextSpan(
                      text: 'ST',
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                            text: ' (0)',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: bgTextColor,
                              fontSize: 12,
                            )),
                      ]),
                ),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
