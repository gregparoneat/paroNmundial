import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/entry_field.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class SendToBankSheet extends StatelessWidget {
  const SendToBankSheet({super.key});

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ListView(
            children: [
              EntryField(
                label: s.amount,
                hint: s.enterAmount,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Text(s.bankDetails),
              ),
              EntryField(
                label: s.accountName,
                hint: s.accountHolderName,
              ),
              EntryField(
                label: s.accountNumber,
                hint: s.enterAccountNumber,
              ),
              EntryField(
                label: s.ifscCode,
                hint: s.bankIfscCode,
              ),
              const SizedBox(height: 80),
            ],
          ),
          CustomButton(
            text: s.sendToBank,
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
