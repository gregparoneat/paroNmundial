import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

import 'line_container.dart';

class RankWinnings {
  final String rank;
  final String winnings;

  RankWinnings(this.rank, this.winnings);
}

List<RankWinnings> rankAndWinnings = [
  RankWinnings('1', '\$ 50,000'),
  RankWinnings('1', '\$ 50,000'),
  RankWinnings('2', '\$ 25,000'),
  RankWinnings('3', '\$ 15,000'),
  RankWinnings('4', '\$ 10,000'),
  RankWinnings('5', '\$ 5,000'),
  RankWinnings('6', '\$ 2,500'),
  RankWinnings('7', '\$ 1,500'),
  RankWinnings('8', '\$ 250'),
  RankWinnings('9', '\$ 100'),
  RankWinnings('10', '\$ 50'),
  RankWinnings('11-15', '\$ 45'),
  RankWinnings('16-25', '\$ 40'),
  RankWinnings('26-50', '\$ 35'),
  RankWinnings('51-100', '\$ 30'),
  RankWinnings('101-200', '\$ 25'),
  RankWinnings('201-500', '\$ 20'),
  RankWinnings('501-1000', '\$ 20'),
  RankWinnings('1000-2000', '\$ 15'),
];

class RanksAndWinnings extends StatelessWidget {
  const RanksAndWinnings({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return FadedSlideAnimation(
      beginOffset: const Offset(0, 2),
      endOffset: const Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 32),
          shrinkWrap: true,
          itemCount: rankAndWinnings.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                index == 0
                    ? Row(
                        children: [
                          const SizedBox(
                            width: 16,
                          ),
                          Text(
                            locale.rank.toUpperCase(),
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: bgTextColor,
                              fontSize: 10,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            locale.winnings.toUpperCase(),
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: bgTextColor,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4),
                        child: Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                  text: '# ',
                                  style: theme.textTheme.bodySmall!.copyWith(
                                    color: bgTextColor,
                                    fontSize: 10,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: rankAndWinnings[index].rank,
                                      style:
                                          theme.textTheme.bodySmall!.copyWith(
                                        fontSize: 10,
                                      ),
                                    ),
                                  ]),
                            ),
                            const Spacer(),
                            Text(
                              rankAndWinnings[index].winnings,
                              style: theme.textTheme.bodySmall!.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                const LineContainer(
                  4,
                  height: 0.2,
                ),
              ],
            );
          }),
    );
  }
}
