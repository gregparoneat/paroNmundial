import 'package:fantacy11/features/auth/login/ui/login_column.dart';
import 'package:fantacy11/features/auth/widgets/country_code_picker_sheet.dart';
import 'package:flutter/material.dart';

import 'login_interactor.dart';

class LoginUiWeb extends StatelessWidget {
  final LoginInteractor loginInteractor;
  final TextEditingController? phoneController;
  final CountryDialCode selectedCountry;
  final VoidCallback? onSelectCountry;
  const LoginUiWeb(
    this.loginInteractor, {
    super.key,
    this.phoneController,
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
            child: LoginColumn(
              loginInteractor,
              phoneController: phoneController,
              selectedCountry: selectedCountry,
              onSelectCountry: onSelectCountry,
            ),
          ),
        ],
      ),
    );
  }
}
