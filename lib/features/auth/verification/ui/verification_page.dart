import 'package:fantacy11/features/auth/verification/ui/verification_ui_web.dart';
import 'package:fantacy11/features/responsive_widget.dart';
import 'package:flutter/material.dart';

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
  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isLargeScreen(context)) {
      return VerificationUiWeb(this);
    } else {
      return VerificationUi(this);
    }
  }

  @override
  void verify(String otp) {
    widget.onVerificationDone();
  }

  @override
  void resend() {}
}
