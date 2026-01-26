import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 2),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        slideDuration: const Duration(milliseconds: 10),
        fadeDuration: const Duration(milliseconds: 10),
        child: Column(
          children: [
            const SizedBox(
              height: 30,
            ),
            Image.asset(
              'assets/logo.png',
              scale: 3,
            ),
            const SizedBox(
              height: 50,
            ),
            Expanded(
              child: Container(
                height: MediaQuery.of(context).size.height / 1.7,
                padding: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Text(
                        '${locale.whoWeAre}\n',
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontSize: 15,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source.'
                        '\n\n',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        '${locale.howWeStarted}\n',
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontSize: 15,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. Richard McClintock.\n\nLatin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words, consectetur, from a Lorem Ipsum passage, and going through the cites of the word in classical literature, discovered the undoubtable source.'
                        '\n\n',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
