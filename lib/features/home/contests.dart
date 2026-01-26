import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/contest_container.dart';
import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/custom_scaffold.dart';
import 'package:fantacy11/features/components/my_team_container.dart';
import 'package:fantacy11/features/components/signle_team_container.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class Contests extends StatelessWidget {
  final MatchInfo? matchInfo;

  const Contests({super.key, this.matchInfo});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    
    // Use match time from matchInfo or fallback to default
    final pageTitle = matchInfo?.matchTime ?? '0h 9m left';
    
    return CustomScaffold(
      pageTitle: pageTitle,
      actions: [
        IconButton(
          icon: Icon(
            Icons.notifications_sharp,
            color: iconColor,
          ),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return SetReminderSheet(matchInfo: matchInfo);
              },
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.account_balance_wallet_sharp,
            color: iconColor,
          ),
          onPressed: () => Navigator.pushNamed(context, PageRoutes.wallet),
        ),
      ],
      tabBarItems: [
        Tab(text: locale.contests),
        Tab(text: locale.myContestsTwo),
        Tab(text: locale.myTeamThree),
      ],
      tabBarChild: SingleTeamContainer(matchInfo: matchInfo),
      tabBarViewItems: [
        FadedSlideAnimation(
          beginOffset: const Offset(0, 2),
          endOffset: const Offset(0, 0),
          slideCurve: Curves.linearToEaseOut,
          child: ListView(
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: Text(
                  locale.maxContest,
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontSize: 16,
                  ),
                ),
              ),
              ContestContainer(ContestModel(
                entryType: locale.multipleEntries,
                amount: '\$5,00,000',
                winner: '60% Winners | 1st \$50,000',
                entryTicket: '\$20',
                color1: Colors.green,
                color2: Colors.red,
                color3: bgTextColor,
                color4: bgTextColor,
                spotsFilled: '10,000',
                spotsLeft: '5,670',
              )),
              ContestContainer(ContestModel(
                entryType: locale.multipleEntries,
                amount: '\$1,00,000',
                winner: '50% Winners | 1st \$10,000',
                entryTicket: '\$15',
                color1: Colors.green,
                color2: Colors.orange,
                color3: Colors.red,
                color4: bgTextColor,
                spotsFilled: '30,000',
                spotsLeft: '3,875',
              )),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  locale.headToHead,
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontSize: 16,
                  ),
                ),
              ),
              ContestContainer(ContestModel(
                entryType: locale.singleEntry,
                amount: '\$500',
                winner: '50% Winners | 1st \$10,000',
                entryTicket: '\$15',
                color1: Colors.green,
                color2: Colors.yellow,
                color3: bgTextColor,
                color4: bgTextColor,
                spotsFilled: '2',
                spotsLeft: '1',
              )),
              ContestContainer(ContestModel(
                entryType: locale.singleEntry,
                amount: '\$100',
                winner: '50% Winners | 1st \$10,000',
                entryTicket: '\$52',
                color1: bgTextColor,
                color2: bgTextColor,
                color3: bgTextColor,
                color4: bgTextColor,
                spotsFilled: '2',
                spotsLeft: '1',
              )),
              ContestContainer(ContestModel(
                entryType: locale.singleEntry,
                amount: '\$100',
                winner: '50% Winners | 1st \$10,000',
                entryTicket: '\$52',
                color1: Colors.green,
                color2: Colors.orange,
                color3: Colors.red,
                color4: bgTextColor,
                spotsFilled: '1',
                spotsLeft: '2',
              )),
            ],
          ),
        ),
        FadedSlideAnimation(
          beginOffset: const Offset(0, 2),
          endOffset: const Offset(0, 0),
          slideCurve: Curves.linearToEaseOut,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              ContestContainer(
                ContestModel(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  entryType: locale.multipleEntries,
                  amount: '\$5,00,000',
                  winner: '60% Winners | 1st \$50,000',
                  entryTicket: '\$20',
                  color1: Colors.green,
                  color2: Colors.red,
                  color3: bgTextColor,
                  color4: bgTextColor,
                  spotsFilled: '10,000',
                  spotsLeft: '5,670',
                  myTeam: true,
                ),
              ),
              ContestContainer(
                ContestModel(
                  entryType: locale.singleEntry,
                  amount: '\$100',
                  winner: '50% Winners | 1st \$10,000',
                  entryTicket: '\$52',
                  color1: Colors.green,
                  color2: Colors.orange,
                  color3: Colors.red,
                  color4: Colors.red,
                  spotsFilled: '1',
                  spotsLeft: '2',
                  myTeam: true,
                ),
              )
            ],
          ),
        ),
        FadedSlideAnimation(
          beginOffset: const Offset(0, 2),
          endOffset: const Offset(0, 0),
          slideCurve: Curves.linearToEaseOut,
          child: Stack(
            children: [
              ListView(
                children: const [
                  MyTeamContainer(),
                  MyTeamContainer(),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: FadedScaleAnimation(
                  child: CustomButton(
                    margin: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 70),
                    text: locale.createTeam,
                    onTap: () {
                      Navigator.pushNamed(context, PageRoutes.createNewTeam);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SetReminderSheet extends StatefulWidget {
  final MatchInfo? matchInfo;

  const SetReminderSheet({super.key, this.matchInfo});

  @override
  SetReminderSheetState createState() => SetReminderSheetState();
}

class SetReminderSheetState extends State<SetReminderSheet> {
  bool match = false;
  bool tour = false;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return FadedSlideAnimation(
      beginOffset: const Offset(0, 1),
      endOffset: const Offset(0, 0),
      slideCurve: Curves.linearToEaseOut,
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12), topRight: Radius.circular(12)),
          color: Colors.black,
        ),
        child: Column(
          children: [
            ListTile(
              leading: Icon(
                Icons.notifications_sharp,
                color: iconColor,
              ),
              title: Text(
                locale.setMatchReminder,
                style: theme.textTheme.titleSmall,
              ),
              onTap: () {
                Navigator.pop(context);
              },
              tileColor: Colors.black,
            ),
            ListTile(
              title: Text(
                widget.matchInfo != null
                    ? 'Match - ${widget.matchInfo!.team1Name} vs ${widget.matchInfo!.team2Name}'
                    : locale.matchvs,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 14,
                ),
              ),
              subtitle: Text(locale.willSend,
                  style: theme.textTheme.titleSmall!.copyWith(
                    fontSize: 9,
                    color: bgTextColor,
                  )),
              trailing: Switch(
                value: match,
                activeColor: theme.primaryColor,
                onChanged: (value) {
                  setState(() {
                    match = value;
                  });
                },
              ),
              tileColor: bgColor,
            ),
            ListTile(
              tileColor: bgColor,
              title: Text(
                widget.matchInfo != null
                    ? 'Tour - ${widget.matchInfo!.leagueName}'
                    : locale.tour,
                style: theme.textTheme.bodyMedium!.copyWith(
                  fontSize: 14,
                ),
              ),
              subtitle: Text(locale.willSend,
                  style: theme.textTheme.titleSmall!.copyWith(
                    fontSize: 9,
                    color: bgTextColor,
                  )),
              trailing: Switch(
                value: tour,
                activeColor: theme.primaryColor,
                onChanged: (value) {
                  setState(() {
                    tour = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
