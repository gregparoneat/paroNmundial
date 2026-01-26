import 'package:fantacy11/features/auth/login_navigator.dart';
import 'package:fantacy11/features/auth/register/ui/register_interactor.dart';
import 'package:fantacy11/features/auth/register/ui/register_ui_web.dart';
import 'package:fantacy11/features/responsive_widget.dart';
import 'package:flutter/material.dart';

import 'register_ui.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  RegisterPageState createState() => RegisterPageState();
}

class RegisterPageState extends State<RegisterPage>
    implements RegisterInteractor {
  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isLargeScreen(context)) {
      return RegisterUiWeb(this);
    } else {
      return RegisterUi(this);
    }
  }

  @override
  void register(
      String? mobileNumber, String name, String email, String? imageUrl) {
    Navigator.pushNamed(context, LoginRoutes.verification);
  }
}
