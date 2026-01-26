import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class Questions {
  String question;
  bool isOpen;
  Questions(this.question, this.isOpen);
}

class Faqs extends StatefulWidget {
  const Faqs({super.key});

  @override
  FaqsState createState() => FaqsState();
}

class FaqsState extends State<Faqs> {
  List<bool> isOpen = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false
  ];

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    List<String> questions = [
      locale.howToPlay,
      locale.howToAddMoney,
      locale.howToSelectMoney,
      locale.howToChangeProfile,
      locale.howToSend,
      locale.howToShop,
      locale.howToChangeLanguage,
      locale.canILogin,
      locale.howToLogoutMyAccount,
    ];
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadedSlideAnimation(
        beginOffset: const Offset(0.3, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
                padding: const EdgeInsets.only(
                    top: 50, left: 24, right: 24, bottom: 24),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context)),
            Padding(
              padding: const EdgeInsets.only(
                  left: 24, right: 24, top: 16, bottom: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(locale.faqs, style: theme.textTheme.headlineSmall),
                  Text(
                    locale.getYourAnswers,
                    style: theme.textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 18),
                decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20))),
                child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isOpen[index] = !isOpen[index];
                                });
                              },
                              child: Row(
                                children: [
                                  Text(
                                    questions[index],
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const Spacer(),
                                  isOpen[index]
                                      ? Icon(
                                          Icons.keyboard_arrow_up,
                                          color: iconColor,
                                        )
                                      : Icon(
                                          Icons.keyboard_arrow_down_sharp,
                                          color: iconColor,
                                        )
                                ],
                              ),
                            ),
                            isOpen[index]
                                ? const SizedBox(
                                    height: 15,
                                  )
                                : const SizedBox.shrink(),
                            isOpen[index]
                                ? Text(
                                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. ',
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      fontSize: 12,
                                    ),
                                  )
                                : const SizedBox.shrink()
                          ],
                        ),
                      );
                    }),
              ),
            )
          ],
        ),
      ),
    );
  }
}
