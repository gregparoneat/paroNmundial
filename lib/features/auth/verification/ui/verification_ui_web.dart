import 'package:fantacy11/features/auth/verification/ui/verification_column.dart';
import 'package:fantacy11/features/auth/verification/ui/verification_interactor.dart';
import 'package:flutter/material.dart';

class VerificationUiWeb extends StatelessWidget {
  final VerificationInteractor interactor;
  const VerificationUiWeb(this.interactor, {super.key});

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
          Expanded(child: VerificationColumn(interactor)),
        ],
      ),
    );
  }
}
