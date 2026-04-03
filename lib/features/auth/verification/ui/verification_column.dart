import 'package:blur/blur.dart';
import 'package:fantacy11/features/auth/verification/ui/verification_interactor.dart';
import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/entry_field.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerificationColumn extends StatelessWidget {
  final VerificationInteractor interactor;
  final TextEditingController? otpController;
  final int resendCooldownSeconds;
  final ValueChanged<String>? onOtpChanged;
  const VerificationColumn(
    this.interactor, {
    super.key,
    this.otpController,
    this.resendCooldownSeconds = 0,
    this.onOtpChanged,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var s = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  s.verification,
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  s.inLessThanAMinute,
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  s.weHaveSent,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              EntryField(
                label: s.enterCode,
                hint: s.enterSixDigit,
                controller: otpController,
                keyboardType: TextInputType.number,
                onChanged: onOtpChanged,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
              ),
              const SizedBox(
                height: 40,
              ),
              CustomButton(
                text: s.getStarted,
                onTap: () => interactor.verify(otpController?.text.trim() ?? ''),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: resendCooldownSeconds > 0
                      ? null
                      : () => interactor.resend(),
                  child: Text(
                    resendCooldownSeconds > 0
                        ? 'Resend code in ${resendCooldownSeconds}s'
                        : 'Resend code',
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ).frosted(
          height: MediaQuery.of(context).size.height * 0.75,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          frostColor: Theme.of(context).colorScheme.surface,
          frostOpacity: 0.5,
          blur: 8,
        )
      ],
    );
  }
}
