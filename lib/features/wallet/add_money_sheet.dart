import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/features/components/entry_field.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class AddMoneySheet extends StatefulWidget {
  const AddMoneySheet({super.key});

  @override
  State<AddMoneySheet> createState() => _AddMoneySheetState();
}

class _AddMoneySheetState extends State<AddMoneySheet> {
  final List<String> _paymentMethods = ["Credit/Debit Card", "PayPal"];
  String _selectedMethod = "";

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    var theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EntryField(
          label: s.amount,
          hint: s.enterAmount,
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(s.paymentMethod),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: _paymentMethods.length,
            itemBuilder: (context, index) {
              var paymentMethod = _paymentMethods[index];
              return RadioListTile(
                title: Text(paymentMethod),
                value: paymentMethod,
                groupValue: _selectedMethod,
                onChanged: (value) async {
                  setState(() {
                    _selectedMethod = value as String;
                  });
                },
                activeColor: theme.primaryColor,
              );
            },
          ),
        ),
        CustomButton(
          text: s.addMoney,
          onTap: () {
            if (_selectedMethod.isNotEmpty) Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
