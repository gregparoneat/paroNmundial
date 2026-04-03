import 'package:blur/blur.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/entry_field.dart';
import 'package:fantacy11/features/components/social_button.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

import '../../widgets/country_code_picker_sheet.dart';
import '../../../responsive_widget.dart';
import 'login_interactor.dart';

class LoginColumn extends StatelessWidget {
  final LoginInteractor loginInteractor;
  final TextEditingController? phoneController;
  final CountryDialCode selectedCountry;
  final VoidCallback? onSelectCountry;

  const LoginColumn(
    this.loginInteractor, {
    super.key,
    this.phoneController,
    required this.selectedCountry,
    this.onSelectCountry,
  });

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    if (ResponsiveWidget.isLargeScreen(context)) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: buildColumn(context, size),
      );
    } else {
      return buildColumn(context, size).frosted(
        height: size.height / 2,
        width: double.infinity,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        frostColor: Theme.of(context).colorScheme.surface,
        frostOpacity: 0.5,
        blur: 8,
      );
    }
  }

  Widget buildColumn(BuildContext context, Size size) {
    var locale = S.of(context);
    return Column(
      crossAxisAlignment: ResponsiveWidget.isLargeScreen(context)
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        if (ResponsiveWidget.isLargeScreen(context))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              locale.letsPlay,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium!
                  .copyWith(color: iconColor),
            ),
          )
        else
          Text(
            locale.letsPlay,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        const Spacer(),
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
        const Spacer(),
        CustomButton(
          onTap: () {
            loginInteractor.loginWithMobile(
              selectedCountry.dialCode,
              phoneController?.text.trim() ?? '',
            );
          },
        ),
        const Spacer(flex: 2),
        Center(
          child: Text(
            locale.orContinueWith,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Spacer(),
        Padding(
          padding: ResponsiveWidget.isLargeScreen(context)
              ? const EdgeInsets.only(bottom: 40, top: 20)
              : const EdgeInsets.only(bottom: 20, top: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SocialButton(
                icon: 'assets/Icons/ic_fb.png',
                iconColor: iconColor,
                text: locale.facebook,
                onPressed: loginInteractor.loginWithFacebook,
              ),
              Container(
                width: 1,
                height: 25,
                color: iconColor,
              ),
              SocialButton(
                icon: 'assets/Icons/ic_ggl.png',
                iconColor: iconColor,
                text: locale.google,
                onPressed: loginInteractor.loginWithGoogle,
              )
            ],
          ),
        ).frosted(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          frostColor: Colors.grey.shade200,
          blur: 0.001,
        )
      ],
    );
  }
}
