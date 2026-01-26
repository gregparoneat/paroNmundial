import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:flutter/material.dart';

class SingleTeamContainer extends StatelessWidget {
  final String? text;
  final TextStyle? match;
  final bool showScore;

  const SingleTeamContainer(
      {super.key, this.text, this.match, this.showScore = false});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
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
                width: 10,
              ),
              FadedScaleAnimation(
                child: Image.asset(
                  'assets/TeamLogo/Vector Smart Object-6.png',
                  scale: 2,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Column(
                children: [
                  Text(
                    'WLS',
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontSize: 14,
                    ),
                  ),
                  if (showScore)
                    Text(
                      '0',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                text ?? 'VS',
                style: match ??
                    theme.textTheme.bodySmall!
                        .copyWith(color: bgTextColor, fontSize: 10),
              ),
              const Spacer(),
              Column(
                children: [
                  Text(
                    'CBR',
                    style:
                        theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
                  ),
                  if (showScore)
                    Text(
                      '2',
                      style:
                          theme.textTheme.headlineSmall!.copyWith(fontSize: 14),
                    ),
                ],
              ),
              const SizedBox(
                width: 10,
              ),
              FadedScaleAnimation(
                child: Image.asset(
                  'assets/TeamLogo/Vector Smart Object-5.png',
                  scale: 2,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
