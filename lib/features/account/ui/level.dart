import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class HowItWorks {
  final String title;
  final String subtitle;
  final IconData icon;

  HowItWorks(this.title, this.subtitle, this.icon);
}

class Level extends StatelessWidget {
  const Level({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    List<HowItWorks> howItWorks = [
      HowItWorks(locale.youWillGet, locale.LeJoined, Icons.whatshot),
      HowItWorks(locale.ifYou, locale.thatIs, Icons.thumb_up),
      HowItWorks(locale.iff, locale.that, Icons.thumb_up),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          padding: const EdgeInsets.all(30),
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: iconColor,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(2, 2),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        slideDuration: const Duration(milliseconds: 10),
        fadeDuration: const Duration(milliseconds: 10),
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(30),
              title: Text(
                locale.youAre,
                style: theme.textTheme.headlineSmall,
              ),
              subtitle: Text(
                '8,871 ${locale.points}',
                style: theme.textTheme.titleLarge!.copyWith(
                  color: theme.primaryColor,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height / 1.7,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Image.asset(
                          'assets/Medals/medal1.png',
                          scale: 2,
                        ),
                        Image.asset(
                          'assets/Medals/medal1.png',
                          scale: 2,
                        ),
                        Image.asset(
                          'assets/Medals/medal2.png',
                          scale: 2,
                        ),
                      ],
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 26),
                          height: 4,
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                            Colors.green,
                            Colors.green,
                            bgColor,
                          ], stops: const [
                            0.3,
                            0.7,
                            0.7,
                          ])),
                        ),
                        PositionedDirectional(
                          top: 18,
                          start: -30,
                          end: -30,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CircleAvatar(
                                backgroundColor: theme.primaryColor,
                                radius: 8,
                                child: Icon(
                                  Icons.check,
                                  size: 10,
                                  color: iconColor,
                                ),
                              ),
                              CircleAvatar(
                                backgroundColor: theme.primaryColor,
                                radius: 8,
                                child: Icon(
                                  Icons.check,
                                  size: 10,
                                  color: iconColor,
                                ),
                              ),
                              CircleAvatar(
                                backgroundColor: bgColor,
                                radius: 8,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          '8800 ${locale.points}',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: bgTextColor,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '8900 ${locale.points}',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: bgTextColor,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '9900 ${locale.points}',
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: bgTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.symmetric(
                          vertical: 20, horizontal: 35),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xff263228),
                      ),
                      child: Text(
                        locale.earnOneHundred,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale.howItWorks,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ListView.builder(
                              itemCount: howItWorks.length,
                              shrinkWrap: true,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xff53606B),
                                    child: Icon(
                                      howItWorks[index].icon,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  title: Text(
                                    howItWorks[index].title,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  subtitle: Text(
                                    howItWorks[index].subtitle,
                                    style: theme.textTheme.bodySmall!.copyWith(
                                      color: bgTextColor,
                                    ),
                                  ),
                                );
                              })
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
