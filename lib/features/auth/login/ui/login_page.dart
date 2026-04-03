import 'package:fantacy11/features/auth/auth_session_cubit.dart';
import 'package:fantacy11/features/auth/login/ui/login_ui_web.dart';
import 'package:fantacy11/features/auth/login_navigator.dart';
import 'package:fantacy11/features/auth/widgets/country_code_picker_sheet.dart';
import 'package:fantacy11/features/language/language_ui.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../responsive_widget.dart';
import 'login_interactor.dart';
import 'login_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> implements LoginInteractor {
  final TextEditingController _phoneController = TextEditingController();
  CountryDialCode _selectedCountry = countryByDialCode('+52');

  @override
  void initState() {
    super.initState();
    _showLanguageSheet();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showLanguageSheet() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
       showModalBottomSheet(
        context: context,
        builder: (context) => const LanguageUI(fromRoot: true),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = ResponsiveWidget.isLargeScreen(context)
        ? LoginUiWeb(
            this,
            phoneController: _phoneController,
            selectedCountry: _selectedCountry,
            onSelectCountry: _onSelectCountry,
          )
        : LoginUi(
            this,
            phoneController: _phoneController,
            selectedCountry: _selectedCountry,
            onSelectCountry: _onSelectCountry,
          );

    return BlocListener<AuthSessionCubit, AuthSessionState>(
      listener: (context, state) {
        if (state.status == AuthSessionStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: child,
    );
  }

  @override
  void loginWithFacebook() {
    Navigator.pushNamed(context, LoginRoutes.registration);
  }

  @override
  void loginWithGoogle() async {
    await context.read<AuthSessionCubit>().signInWithGoogle();
  }

  @override
  void loginWithMobile(String isoCode, String mobileNumber) {
    final locale = S.of(context);
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.pleaseEnterPhoneNumber)),
      );
      return;
    }

    final code = isoCode.isNotEmpty ? isoCode : _selectedCountry.dialCode;
    final normalizedPhone = rawPhone.startsWith('+')
        ? rawPhone
        : '$code$rawPhone';
    Navigator.pushNamed(
      context,
      LoginRoutes.registration,
      arguments: {'phoneNumber': normalizedPhone},
    );
  }

  Future<void> _onSelectCountry() async {
    final selected = await showCountryCodePicker(
      context,
      initialCountry: _selectedCountry,
    );
    if (selected != null && mounted) {
      setState(() => _selectedCountry = selected);
    }
  }
}
