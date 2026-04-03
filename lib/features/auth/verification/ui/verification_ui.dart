import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/features/auth/verification/ui/verification_column.dart';
import 'package:fantacy11/features/auth/verification/ui/verification_interactor.dart';
import 'package:flutter/material.dart';

class VerificationUi extends StatelessWidget {
  final VerificationInteractor verificationInteractor;
  final TextEditingController? otpController;
  final int resendCooldownSeconds;
  final ValueChanged<String>? onOtpChanged;

  const VerificationUi(
    this.verificationInteractor, {
    super.key,
    this.otpController,
    this.resendCooldownSeconds = 0,
    this.onOtpChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.vertical,
            child: Stack(
              children: [
                Image.asset(
                  'assets/bg.png',
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.fill,
                ),
                VerificationColumn(
                  verificationInteractor,
                  otpController: otpController,
                  resendCooldownSeconds: resendCooldownSeconds,
                  onOtpChanged: onOtpChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
