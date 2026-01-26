import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/features/auth/login/ui/login_column.dart';
import 'package:fantacy11/features/auth/login/ui/login_interactor.dart';
import 'package:flutter/material.dart';

class LoginUi extends StatelessWidget {
  final LoginInteractor loginInteractor;

  const LoginUi(this.loginInteractor, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/bg.png',
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.fill,
            ),
            Column(
              children: [
                const Spacer(),
                Image.asset(
                  "assets/logo.png",
                  scale: 3,
                ),
                const Spacer(),
                SingleChildScrollView(
                  child: LoginColumn(loginInteractor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
