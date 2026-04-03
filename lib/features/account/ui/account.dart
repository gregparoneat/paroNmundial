import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/account/models/account_item_data.dart';
import 'package:fantacy11/features/auth/auth_repository.dart';
import 'package:fantacy11/features/auth/auth_session_cubit.dart';
import 'package:fantacy11/features/language/language_ui.dart';
import 'package:fantacy11/features/fixtures/services/lineup_prediction_service.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:fantacy11/services/cache_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

/// Clear all app caches (Hive + in-memory prediction cache)
void _clearAllCaches(BuildContext context) {
  debugPrint('Clear cache button pressed');
  final locale = S.of(context);
  
  // Store scaffold messenger before async operations
  final scaffoldMessenger = ScaffoldMessenger.of(context);
  
  // Show "clearing" message
  scaffoldMessenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 16),
          Text(locale.clearingCache),
        ],
      ),
      backgroundColor: Colors.orange,
      duration: Duration(seconds: 10), // Long duration, will be replaced
    ),
  );
  
  try {
    // Clear lineup prediction in-memory cache (synchronous)
    debugPrint('Clearing lineup prediction cache...');
    LineupPredictionService().clearCache();
    debugPrint('Lineup prediction cache cleared');
    
    // Clear Hive caches
    debugPrint('Clearing Hive caches...');
    CacheService().clearAll().then((_) {
      debugPrint('Hive caches cleared successfully');
      
      // Hide previous snackbar and show success
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 16),
              Text(locale.cacheClearedRestart),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }).catchError((e) {
      debugPrint('Error clearing Hive cache: $e');
      
      // Hide previous snackbar and show error
      scaffoldMessenger.hideCurrentSnackBar();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Text('${locale.errorLabel}: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  } catch (e) {
    debugPrint('Error clearing cache: $e');
    
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(child: Text('${locale.errorLabel}: $e')),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class Account extends StatelessWidget {
  const Account({super.key});

  Future<_AccountUserData> _loadUserData() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      return const _AccountUserData();
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
      debugPrint('Account: Failed to load profile for header: $e');
    }

    return _AccountUserData(
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
        locale.clearCacheTitle,
        locale.clearCacheSubtitle,
        Icons.cleaning_services_rounded,
        Colors.orange,
        'clear_cache',
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
            leading: FutureBuilder<_AccountUserData>(
              future: _loadUserData(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? const _AccountUserData();
                final hasPhoto =
                    data.photoUrl != null && data.photoUrl!.isNotEmpty;
                return FadedScaleAnimation(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: hasPhoto
                        ? Image.network(
                            data.photoUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Image.asset('assets/Teams/accountTeam.png'),
                          )
                        : Image.asset('assets/Teams/accountTeam.png'),
                  ),
                );
              },
            ),
            title: FutureBuilder<_AccountUserData>(
              future: _loadUserData(),
              builder: (context, snapshot) {
                final data = snapshot.data ?? const _AccountUserData();
                final displayName =
                    (data.name != null && data.name!.isNotEmpty)
                        ? data.name!
                        : (data.email != null && data.email!.isNotEmpty)
                        ? data.email!
                        : (data.phone != null && data.phone!.isNotEmpty)
                        ? data.phone!
                        : 'Guest';
                return Text(
                  displayName,
                  style: theme.textTheme.titleLarge!.copyWith(
                    color: iconColor,
                  ),
                );
              },
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
                                  () async {
                                    await context
                                        .read<AuthSessionCubit>()
                                        .resetToUnauthenticated();
                                    if (!context.mounted) return;
                                    Phoenix.rebirth(context);
                                  }();
                                } else if (accountItems[index].routeName ==
                                    'clear_cache') {
                                  _clearAllCaches(context);
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

class _AccountUserData {
  final String? name;
  final String? email;
  final String? phone;
  final String? photoUrl;

  const _AccountUserData({
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
  });
}
