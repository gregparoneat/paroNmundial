import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/entry_field.dart';
import 'package:fantacy11/features/components/social_button.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class Support extends StatefulWidget {
  const Support({super.key});

  @override
  SupportState createState() => SupportState();
}

class SupportState extends State<Support> {
  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: iconColor),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0.3, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top -
                AppBar().preferredSize.height,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  // height: MediaQuery.of(context).size.height / 6.5,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locale.support,
                        textAlign: TextAlign.left,
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        locale.connectUsForIssues,
                        textAlign: TextAlign.left,
                        style: theme.textTheme.titleSmall!.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        //margin: EdgeInsets.only(top: 184),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  SocialButton(
                                    icon: 'assets/Icons/ic_call.png',
                                    iconColor: iconColor,
                                    text: locale.callUs,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 25,
                                    color: iconColor,
                                  ),
                                  SocialButton(
                                    icon: 'assets/Icons/mail.png',
                                    iconColor: iconColor,
                                    text: locale.mailUs,
                                  )
                                ],
                              ),
                            ),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 20, left: 20),
                                      child: Text(
                                        locale.writeUs,
                                        style: theme.textTheme.bodyLarge!
                                            .copyWith(fontSize: 24),
                                      ),
                                    ),
                                    EntryField(
                                      label: locale.addYourIssuefeedback,
                                      hint: locale.writeYourMessage,
                                      maxLines: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PositionedDirectional(
                        start: 0,
                        bottom: 0,
                        end: 0,
                        child: CustomButton(
                          text: locale.submit,
                          onTap: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
