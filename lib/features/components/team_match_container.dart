import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class TeamMatchContainer extends StatelessWidget {
  final Color? color;

  const TeamMatchContainer({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    List<Color> colors = [
      theme.primaryColor,
      theme.primaryColor,
      theme.primaryColor,
      Colors.white.withValues(alpha: 0.2),
      Colors.white.withValues(alpha: 0.2),
      Colors.white.withValues(alpha: 0.2),
      Colors.white.withValues(alpha: 0.2),
      Colors.white.withValues(alpha: 0.2),
      Colors.white.withValues(alpha: 0.2),
      Colors.white.withValues(alpha: 0.2),
      Colors.white.withValues(alpha: 0.2),
    ];
    return Container(
      width: MediaQuery.of(context).size.width,
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
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
                  locale.maxSevenPlayers,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: bgTextColor,
                    fontSize: 10,
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
          Row(
            children: [
              const SizedBox(
                width: 20,
              ),
              FadedScaleAnimation(
                child: Image.asset(
                  'assets/TeamLogo/Vector Smart Object-6.png',
                  scale: 2.2,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                'WLS',
                style: theme.textTheme.headlineSmall!.copyWith(
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text('2  :  1', style: theme.textTheme.bodyMedium),
              const Spacer(),
              Text(
                'CBR',
                style: theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
              ),
              const SizedBox(
                width: 10,
              ),
              FadedScaleAnimation(
                child: Image.asset(
                  'assets/TeamLogo/Vector Smart Object-5.png',
                  scale: 2.2,
                ),
              ),
              const SizedBox(
                width: 20,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 16.0, right: 16, top: 16, bottom: 5),
            child: Row(
              children: [
                Text(
                  '    ' '3/11',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                SizedBox(
                  height: 20,
                  child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: 11,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(3),
                          child: FadedScaleAnimation(
                            child: CircleAvatar(
                              radius: 7,
                              backgroundColor: color ?? colors[index],
                            ),
                          ),
                        );
                      }),
                ),
                const Spacer(),
                Text(
                  '85.5' '  ',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, right: 26, left: 30),
            child: Row(
              children: [
                Text(
                  'Selection',
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontSize: 8,
                  ),
                ),
                const Spacer(),
                Text(
                  'Credit',
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
