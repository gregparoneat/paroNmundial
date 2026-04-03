import 'package:fantacy11/features/auth/auth_session_cubit.dart';
import 'package:fantacy11/features/auth/login_navigator.dart';
import 'package:fantacy11/features/auth/register/ui/register_interactor.dart';
import 'package:fantacy11/features/auth/register/ui/register_ui_web.dart';
import 'package:fantacy11/features/auth/widgets/country_code_picker_sheet.dart';
import 'package:fantacy11/features/responsive_widget.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'register_ui.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage>
    implements RegisterInteractor {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthdateController = TextEditingController();
  CountryDialCode _selectedCountry = countryByDialCode('+52');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      final phoneFromArgs = args['phoneNumber']?.toString();
      if (phoneFromArgs != null &&
          phoneFromArgs.isNotEmpty &&
          _phoneController.text.isEmpty) {
        if (phoneFromArgs.startsWith('+')) {
          final dialCodes = kCountryDialCodes
              .map((c) => c.dialCode)
              .toSet()
              .toList()
            ..sort((a, b) => b.length.compareTo(a.length));
          for (final code in dialCodes) {
            if (phoneFromArgs.startsWith(code)) {
              _selectedCountry = countryByDialCode(code);
              _phoneController.text = phoneFromArgs.substring(code.length);
              return;
            }
          }
        }
        _phoneController.text = phoneFromArgs;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = ResponsiveWidget.isLargeScreen(context)
        ? RegisterUiWeb(
            this,
            nameController: _nameController,
            emailController: _emailController,
            phoneController: _phoneController,
            birthdateController: _birthdateController,
            selectedCountry: _selectedCountry,
            onSelectCountry: _onSelectCountry,
          )
        : RegisterUi(
            this,
            nameController: _nameController,
            emailController: _emailController,
            phoneController: _phoneController,
            birthdateController: _birthdateController,
            selectedCountry: _selectedCountry,
            onSelectCountry: _onSelectCountry,
          );

    return BlocListener<AuthSessionCubit, AuthSessionState>(
      listener: (context, state) {
        if (state.status == AuthSessionStatus.otpRequested) {
          Navigator.pushNamed(
            context,
            LoginRoutes.verification,
            arguments: {'phoneNumber': state.phoneNumber ?? _phoneController.text},
          );
        } else if (state.status == AuthSessionStatus.failure &&
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
  void register(
    String countryCode,
    String? mobileNumber,
    String name,
    String email,
    String? imageUrl,
  ) async {
    final locale = S.of(context);
    final normalizedPhone = (mobileNumber ?? _phoneController.text).trim();
    if (name.trim().isEmpty || normalizedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.pleaseCompleteNameAndPhone)),
      );
      return;
    }

    final code = countryCode.isNotEmpty ? countryCode : _selectedCountry.dialCode;
    final phoneNumber = normalizedPhone.startsWith('+')
        ? normalizedPhone
        : '$code$normalizedPhone';
    await context.read<AuthSessionCubit>().requestOtp(
      phoneNumber: phoneNumber,
      name: name,
      email: email,
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
