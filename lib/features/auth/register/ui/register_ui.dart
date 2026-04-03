import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/features/auth/register/ui/register_column.dart';
import 'package:fantacy11/features/auth/widgets/country_code_picker_sheet.dart';
import 'package:flutter/material.dart';

import 'register_interactor.dart';

class RegisterUi extends StatelessWidget {
  final RegisterInteractor registerInteractor;
  final TextEditingController? nameController;
  final TextEditingController? emailController;
  final TextEditingController? phoneController;
  final TextEditingController? birthdateController;
  final CountryDialCode selectedCountry;
  final VoidCallback? onSelectCountry;

  const RegisterUi(
    this.registerInteractor, {
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
    return Scaffold(
      appBar: AppBar(),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.vertical,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/bg.png',
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fill,
                ),
                RegisterColumn(
                  registerInteractor,
                  nameController: nameController,
                  emailController: emailController,
                  phoneController: phoneController,
                  birthdateController: birthdateController,
                  selectedCountry: selectedCountry,
                  onSelectCountry: onSelectCountry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
