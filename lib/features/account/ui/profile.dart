import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

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
        beginOffset: const Offset(0, 0.1),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        slideDuration: const Duration(milliseconds: 10),
        fadeDuration: const Duration(milliseconds: 10),
        child: Column(
          children: [
            Stack(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(30),
                  title: Text(
                    locale.myProfile,
                    style: theme.textTheme.headlineSmall,
                  ),
                  subtitle: Text(
                    locale.everythingAboutYou,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                PositionedDirectional(
                  end: 20,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FadedScaleAnimation(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.asset(
                            'assets/Teams/profile.png',
                            scale: 3.5,
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: -30,
                        top: 30,
                        child: CircleAvatar(
                          backgroundColor: theme.primaryColor,
                          radius: 20,
                          child: Icon(
                            Icons.camera_alt_sharp,
                            size: 20,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                        locale.teamName,
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Samanthateam123' '\n\n',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        locale.emailAddress,
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'samantha@mail.com' '\n\n',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        locale.phoneNumber,
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+1 987 654 3210' '\n\n',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        locale.birthdate,
                        style: theme.textTheme.titleLarge!.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '22 Jun 1990' '\n\n',
                        style: theme.textTheme.bodyMedium,
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
