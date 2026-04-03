import 'package:fantacy11/features/auth/verification/ui/verification_column.dart';
import 'package:fantacy11/features/auth/verification/ui/verification_interactor.dart';
import 'package:flutter/material.dart';

class VerificationUiWeb extends StatelessWidget {
  final VerificationInteractor interactor;
  final TextEditingController? otpController;
  final int resendCooldownSeconds;
  final ValueChanged<String>? onOtpChanged;
  const VerificationUiWeb(
    this.interactor, {
    super.key,
    this.otpController,
    this.resendCooldownSeconds = 0,
    this.onOtpChanged,
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
            child: VerificationColumn(
              interactor,
              otpController: otpController,
              resendCooldownSeconds: resendCooldownSeconds,
              onOtpChanged: onOtpChanged,
            ),
          ),
        ],
      ),
    );
  }
}
