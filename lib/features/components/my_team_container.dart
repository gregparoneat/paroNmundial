import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/player_circle_avatar.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class MyTeamContainer extends StatelessWidget {
  const MyTeamContainer({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, PageRoutes.matchLive);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/img_header.png',
                height: MediaQuery.of(context).size.height * 0.21,
                width: MediaQuery.of(context).size.width,
                fit: BoxFit.fill,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: 0,
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Samanthateam123 (11)',
                        style: theme.textTheme.titleSmall!.copyWith(
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: iconColor,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            '5     6',
                            style: theme.textTheme.headlineSmall,
                          ),
                          Text(
                            'WLS        CBR',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Spacer(),
                      FadedScaleAnimation(
                        child: const PlayerCircleAvatar('P Williamson', 'C',
                            Colors.deepPurple, 'assets/Players/player1.png'),
                      ),
                      const SizedBox(width: 16),
                      FadedScaleAnimation(
                        child: const PlayerCircleAvatar(
                            'B Corden',
                            'VC',
                            Colors.lightBlueAccent,
                            'assets/Players/player2.png'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18)),
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      'GK',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      ' (1)',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: bgTextColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'DEF',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      ' (4)',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: bgTextColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'MID',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      ' (3)',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: bgTextColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ST',
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      ' (3)',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: bgTextColor,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
