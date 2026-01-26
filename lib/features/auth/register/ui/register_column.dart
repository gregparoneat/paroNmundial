import 'package:blur/blur.dart';
import 'package:fantacy11/features/auth/register/ui/register_interactor.dart';
import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/entry_field.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class RegisterColumn extends StatelessWidget {
  final RegisterInteractor interactor;

  const RegisterColumn(this.interactor, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var locale = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  locale.register,
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  locale.inLessThanAMinute,
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EntryField(
                      label: locale.fullName,
                      hint: locale.enterFullName,
                    ),
                    EntryField(
                      label: locale.emailAddress,
                      hint: locale.enterEmailAddress,
                    ),
                    EntryField(
                      label: locale.phoneNumber,
                      hint: locale.enterPhoneNumber,
                    ),
                    EntryField(
                      label: locale.birthdate,
                      hint: locale.selectBirthdate,
                    ),
                    const SizedBox(
                      height: 28,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text(
                        locale.weWillSendVerificationCode,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ).frosted(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                frostColor: Theme.of(context).colorScheme.surface,
                frostOpacity: 0.5,
                blur: 8,
              ),
              PositionedDirectional(
                bottom: 0,
                start: 0,
                end: 0,
                child: CustomButton(
                  onTap: () {
                    interactor.register(null, "", "", null);
                  },
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
