import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/account/models/account_item_data.dart';
import 'package:fantacy11/features/language/language_ui.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

class Account extends StatelessWidget {
  const Account({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    List<AccountItemData> accountItems = [
      AccountItemData(
        locale.leaderboard,
        locale.knowWhereYouStand,
        Icons.person_pin_rounded,
        Colors.blue,
        PageRoutes.leaderboard,
      ),
      AccountItemData(
        locale.support,
        locale.connectUsForIssues,
        Icons.mail,
        Colors.purple,
        PageRoutes.support,
      ),
      AccountItemData(
        locale.privacyPolicy,
        locale.knowOurPrivacyPolicies,
        Icons.event_note_sharp,
        Colors.yellow,
        PageRoutes.privacyPolicy,
      ),
      AccountItemData(
        locale.changeLanguage,
        locale.setYourPreferredLanguage,
        Icons.language,
        Colors.green,
        PageRoutes.changeLanguage,
      ),
      AccountItemData(
        locale.faqs,
        locale.getYourQuestionsAnswered,
        Icons.question_answer_rounded,
        Colors.cyanAccent,
        PageRoutes.faqs,
      ),
      AccountItemData(
        locale.logout,
        "",
        Icons.logout,
        Colors.red,
        "/",
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.account),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            onTap: () {
              Navigator.pushNamed(context, PageRoutes.profile);
            },
            leading: FadedScaleAnimation(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset('assets/Teams/accountTeam.png'),
              ),
            ),
            title: Text(
              'Samanthateam123',
              style: theme.textTheme.titleLarge!.copyWith(
                color: iconColor,
              ),
            ),
            subtitle: Text(locale.viewProfile,
                style: theme.textTheme.titleLarge!.copyWith(
                  fontSize: 14,
                )),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, PageRoutes.level);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 20, top: 16, bottom: 8, right: 20),
                          child: Row(
                            children: [
                              FadedScaleAnimation(
                                child: const Icon(
                                  Icons.whatshot,
                                  color: Colors.yellow,
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              Text(
                                '${locale.level} 89',
                                style: theme.textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              Text(
                                '8,871 ${locale.points}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, PageRoutes.level);
                        },
                        child: FadedScaleAnimation(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(60, 8, 16, 8),
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [
                                  theme.primaryColor,
                                  bgTextColor,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, PageRoutes.level);
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.only(bottom: 24.0, left: 60),
                          child: Text(
                            locale.earnOneHundred,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: bgTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 150),
                          itemCount: accountItems.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: FadedScaleAnimation(
                                child: Icon(
                                  accountItems[index].icon,
                                  color: accountItems[index].color,
                                ),
                              ),
                              title: Text(
                                accountItems[index].title,
                                style: theme.textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                accountItems[index].subtitle,
                                style: theme.textTheme.bodyMedium!.copyWith(
                                  color: bgTextColor,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                if (accountItems[index].title ==
                                    locale.changeLanguage) {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) =>
                                        const LanguageUI(fromRoot: true),
                                  );
                                } else if (accountItems[index].title ==
                                    locale.logout) {
                                  Phoenix.rebirth(context);
                                } else {
                                  Navigator.pushNamed(
                                      context, accountItems[index].routeName);
                                }
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
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
