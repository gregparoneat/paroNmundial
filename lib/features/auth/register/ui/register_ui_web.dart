import 'package:fantacy11/features/auth/register/ui/register_column.dart';
import 'package:fantacy11/features/auth/register/ui/register_interactor.dart';
import 'package:fantacy11/features/auth/widgets/country_code_picker_sheet.dart';
import 'package:flutter/material.dart';

class RegisterUiWeb extends StatelessWidget {
  final RegisterInteractor interactor;
  final TextEditingController? nameController;
  final TextEditingController? emailController;
  final TextEditingController? phoneController;
  final TextEditingController? birthdateController;
  final CountryDialCode selectedCountry;
  final VoidCallback? onSelectCountry;
  const RegisterUiWeb(
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
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Image.asset(
                  'assets/bg.png',
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fill,
                ),
                Positioned(
                  top: 100,
                  child: Image.asset(
                    "assets/paroNmundialTransparent.png",
                    scale: 3,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RegisterColumn(
              interactor,
              nameController: nameController,
              emailController: emailController,
              phoneController: phoneController,
              birthdateController: birthdateController,
              selectedCountry: selectedCountry,
              onSelectCountry: onSelectCountry,
            ),
          ),
        ],
      ),
    );
  }
}
