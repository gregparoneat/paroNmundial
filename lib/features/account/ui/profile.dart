import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/auth/auth_repository.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  Future<_ProfileUserData> _loadProfileData() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return const _ProfileUserData();
    }

    String? name =
        authUser.displayName?.trim().isNotEmpty == true
            ? authUser.displayName!.trim()
            : null;
    final email = authUser.email?.trim();
    final phone = authUser.phoneNumber?.trim();
    final photoUrl = authUser.photoURL;

    try {
      final profile = await AuthRepository().getUserProfile(authUser.uid);
      final profileName = (profile?['name'] as String?)?.trim();
      if (profileName != null && profileName.isNotEmpty) {
        name = profileName;
      }
    } catch (e) {
      debugPrint('Profile: Failed to load profile from Firestore: $e');
    }

    return _ProfileUserData(
      name: name,
      email: email,
      phone: phone,
      photoUrl: photoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return FutureBuilder<_ProfileUserData>(
      future: _loadProfileData(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _ProfileUserData();
        final displayName =
            (data.name != null && data.name!.isNotEmpty) ? data.name! : '-';
        final displayEmail =
            (data.email != null && data.email!.isNotEmpty) ? data.email! : '-';
        final displayPhone =
            (data.phone != null && data.phone!.isNotEmpty) ? data.phone! : '-';
        final hasPhoto = data.photoUrl != null && data.photoUrl!.isNotEmpty;

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
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          backgroundImage:
                              hasPhoto ? NetworkImage(data.photoUrl!) : null,
                          child: hasPhoto
                              ? null
                              : const Icon(Icons.person, size: 30),
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
                        '$displayName\n\n',
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
                        '$displayEmail\n\n',
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
                        '$displayPhone\n\n',
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
                        '-\n\n',
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
      },
    );
  }
}

class _ProfileUserData {
  final String? name;
  final String? email;
  final String? phone;
  final String? photoUrl;

  const _ProfileUserData({
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
  });
}
