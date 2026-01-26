import 'package:fantacy11/features/auth/register/ui/register_column.dart';
import 'package:fantacy11/features/auth/register/ui/register_interactor.dart';
import 'package:flutter/material.dart';

class RegisterUiWeb extends StatelessWidget {
  final RegisterInteractor interactor;
  const RegisterUiWeb(this.interactor, {super.key});

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
                    "assets/logo.png",
                    scale: 3,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: RegisterColumn(interactor)),
        ],
      ),
    );
  }
}
