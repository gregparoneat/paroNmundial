import 'package:blur/blur.dart';
import 'package:fantacy11/features/auth/register/ui/register_interactor.dart';
import 'package:fantacy11/features/auth/widgets/country_code_picker_sheet.dart';
import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/entry_field.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class RegisterColumn extends StatelessWidget {
  final RegisterInteractor interactor;
  final TextEditingController? nameController;
  final TextEditingController? emailController;
  final TextEditingController? phoneController;
  final TextEditingController? birthdateController;
  final CountryDialCode selectedCountry;
  final VoidCallback? onSelectCountry;

  const RegisterColumn(
    this.interactor, {
    super.key,
    this.nameController,
    this.emailController,
    this.phoneController,
    this.birthdateController,
    required this.selectedCountry,
    this.onSelectCountry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = S.of(context);
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
                      controller: nameController,
                    ),
                    EntryField(
                      label: locale.emailAddress,
                      hint: locale.enterEmailAddress,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    EntryField(
                      label: locale.phoneNumber,
                      hint: locale.enterPhoneNumber,
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: onSelectCountry,
                        borderRadius: BorderRadius.circular(6),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: locale.countryCode,
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          child: Row(
                            children: [
                              Text(selectedCountry.flag, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${selectedCountry.name} (${selectedCountry.dialCode})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ),
                    EntryField(
                      label: locale.birthdate,
                      hint: locale.selectBirthdate,
                      controller: birthdateController,
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
                    interactor.register(
                      selectedCountry.dialCode,
                      phoneController?.text.trim(),
                      nameController?.text.trim() ?? '',
                      emailController?.text.trim() ?? '',
                      null,
                    );
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
