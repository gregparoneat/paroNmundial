import 'package:fantacy11/features/auth/login/ui/login_ui_web.dart';
import 'package:fantacy11/features/auth/login_navigator.dart';
import 'package:fantacy11/features/language/language_ui.dart';
import 'package:flutter/material.dart';

import '../../../responsive_widget.dart';
import 'login_interactor.dart';
import 'login_ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> implements LoginInteractor {
  @override
  void initState() {
    super.initState();
    _showLanguageSheet();
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
    if (ResponsiveWidget.isLargeScreen(context)) {
      return LoginUiWeb(this);
    } else {
      return LoginUi(this);
    }
  }

  @override
  void loginWithFacebook() {
    Navigator.pushNamed(context, LoginRoutes.registration);
  }

  @override
  void loginWithGoogle() {
    Navigator.pushNamed(context, LoginRoutes.registration);
  }

  @override
  void loginWithMobile(String isoCode, String mobileNumber) {
    Navigator.pushNamed(context, LoginRoutes.registration);
  }
}
