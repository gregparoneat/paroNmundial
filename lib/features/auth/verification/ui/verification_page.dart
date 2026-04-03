import 'dart:async';

import 'package:fantacy11/features/auth/auth_session_cubit.dart';
import 'package:fantacy11/features/auth/verification/ui/verification_ui_web.dart';
import 'package:fantacy11/features/responsive_widget.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'verification_interactor.dart';
import 'verification_ui.dart';

class VerificationPage extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback onVerificationDone;

  const VerificationPage(this.phoneNumber, this.onVerificationDone, {super.key});

  @override
  VerificationPageState createState() => VerificationPageState();
}

class VerificationPageState extends State<VerificationPage>
    implements VerificationInteractor {
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _resendCooldownSeconds = 30;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendCooldown([int seconds = 30]) {
    _resendTimer?.cancel();
    setState(() => _resendCooldownSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _resendCooldownSeconds = 0);
      } else {
        setState(() => _resendCooldownSeconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = ResponsiveWidget.isLargeScreen(context)
        ? VerificationUiWeb(
            this,
            otpController: _otpController,
            resendCooldownSeconds: _resendCooldownSeconds,
            onOtpChanged: _onOtpChanged,
          )
        : VerificationUi(
            this,
            otpController: _otpController,
            resendCooldownSeconds: _resendCooldownSeconds,
            onOtpChanged: _onOtpChanged,
          );

    return BlocListener<AuthSessionCubit, AuthSessionState>(
      listener: (context, state) {
        if (state.status == AuthSessionStatus.authenticatedNeedsOnboarding ||
            state.status == AuthSessionStatus.authenticatedReady) {
          widget.onVerificationDone();
        } else if (state.status == AuthSessionStatus.failure &&
            state.errorMessage != null) {
          if (_isVerifying && mounted) {
            setState(() => _isVerifying = false);
          }
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
  void verify(String otp) async {
    final locale = S.of(context);
    if (_isVerifying) return;
    final code = otp.trim().isNotEmpty ? otp.trim() : _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(locale.enterSixDigitVerificationCode)),
      );
      return;
    }
    setState(() => _isVerifying = true);
    await context.read<AuthSessionCubit>().verifyOtp(code);
    if (mounted) {
      setState(() => _isVerifying = false);
    }
  }

  @override
  void resend() async {
    final locale = S.of(context);
    if (_resendCooldownSeconds > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locale.pleaseWaitBeforeResending(_resendCooldownSeconds),
          ),
        ),
      );
      return;
    }

    final state = context.read<AuthSessionCubit>().state;
    final phoneNumber = state.phoneNumber ?? widget.phoneNumber;
    if (phoneNumber.isEmpty) return;

    final success = await context.read<AuthSessionCubit>().requestOtp(
      phoneNumber: phoneNumber,
    );
    if (success) {
      _startResendCooldown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(locale.verificationCodeResent)),
        );
      }
    }
  }

  void _onOtpChanged(String value) {
    if (value.length == 6) {
      verify(value);
    }
  }
}
