import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class ContestModel {
  final String entryType;
  final String winner;
  final String amount;
  final String? spotsFilled;
  final String? spotsLeft;
  final Color color1;
  final Color color2;
  final Color color3;
  final Color color4;
  final String entryTicket;
  final bool myTeam;
  final EdgeInsets? margin;
  final BorderRadius? radius;

  ContestModel({
    required this.entryType,
    required this.winner,
    required this.amount,
    this.spotsFilled,
    this.spotsLeft,
    required this.color1,
    required this.color2,
    required this.color3,
    required this.color4,
    required this.entryTicket,
    this.myTeam = false,
    this.margin,
    this.radius,
  });
}

class ContestContainer extends StatelessWidget {
  final ContestModel contestModel;

  const ContestContainer(this.contestModel, {super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var s = S.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, PageRoutes.winnings);
      },
      child: Container(
        margin: contestModel.margin ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: contestModel.radius ?? BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12, top: 12),
              child: Row(
                children: [
                  Text(
                    s.prizePool,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 10,
                      color: bgTextColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    contestModel.entryType,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontSize: 10,
                      color: bgTextColor,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                ),
                Text(
                  contestModel.amount,
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    contestModel.winner,
                    style: theme.textTheme.bodySmall!
                        .copyWith(color: bgTextColor, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Spacer(),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: theme.primaryColor,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                  margin: const EdgeInsets.all(8),
                  child: Text(
                    contestModel.entryTicket,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              height: 4,
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    contestModel.color1,
                    contestModel.color2,
                    contestModel.color3,
                    contestModel.color4,
                  ]),
                  borderRadius: BorderRadius.circular(24)),
            ),
            Row(
              children: [
                const SizedBox(
                  width: 20,
                ),
                Text(
                  '${contestModel.spotsFilled!} ${s.spots}',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: bgTextColor,
                    fontSize: 10,
                  ),
                ),
                const Spacer(),
                Text(
                  '${contestModel.spotsLeft!} ${s.spotsLeft}',
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.primaryColor,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            contestModel.myTeam == true
                ? Container(
                    width: MediaQuery.of(context).size.width * 0.92,
                    padding: const EdgeInsets.only(
                        left: 10, top: 4, bottom: 4, right: 10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18)),
                    ),
                    height: 24,
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          s.joinedWithTwoTeams,
                          style: theme.textTheme.bodySmall!.copyWith(
                            color: bgTextColor,
                            fontSize: 8,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                              color: bgTextColor,
                              borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'T1',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: iconColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Container(
                          decoration: BoxDecoration(
                              color: bgTextColor,
                              borderRadius: BorderRadius.circular(4)),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'T2',
                            style: theme.textTheme.bodySmall!.copyWith(
                              color: iconColor,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
