import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/social_button.dart';
import 'package:fantacy11/features/wallet/add_money_sheet.dart';
import 'package:fantacy11/features/wallet/send_to_bank_sheet.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';

class Transaction {
  String title;
  String subtitle;
  String amount;
  String date;
  Color color;

  Transaction(this.title, this.subtitle, this.amount, this.date, this.color);
}

class Wallet extends StatelessWidget {
  const Wallet({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    List<Transaction> transactions = [
      Transaction(locale.joinedAContest, 'WLS vs CBR', '\$24.00',
          '21 Jun, 11:02 a.m.', Colors.red),
      Transaction(locale.addedToWallet, 'Bank of USA', '\$200.00',
          '20 Jun, 11:02 a.m.', Colors.green),
      Transaction(locale.wonAContest, 'MKJ vs HJI', '\$24.00',
          '21 Jun, 11:02 a.m.', Colors.red),
      Transaction(locale.joinedAContest, 'KIU vs JKO', '\$24.00',
          '21 Jun, 11:02 a.m.', Colors.red),
      Transaction(locale.wonAContest, 'KOS vs HOK', '\$24.00',
          '21 Jun, 11:02 a.m.', Colors.red),
      Transaction(locale.joinedAContest, 'KOL vs DFK', '\$24.00',
          '21 Jun, 11:02 a.m.', Colors.red),
      Transaction(locale.addedToWallet, 'BAnk to USA', '\$200.00',
          '20 Jun, 11:02 a.m.', Colors.green),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          locale.wallet,
          style: theme.textTheme.headlineSmall!.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FadedSlideAnimation(
        beginOffset: const Offset(0.0, 0.3),
        endOffset: const Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '\$159.50',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                locale.availableBalance,
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SocialButton(
                                icon: 'assets/Icons/down_arrow.png',
                                iconColor: theme.primaryColor,
                                text: locale.addMoney,
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor:
                                        theme.scaffoldBackgroundColor,
                                    builder: (context) => const AddMoneySheet(),
                                  );
                                },
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: bgTextColor,
                              ),
                              SocialButton(
                                icon: 'assets/Icons/up_arrow.png',
                                iconColor: theme.primaryColor,
                                text: locale.sendToBank,
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor:
                                        theme.scaffoldBackgroundColor,
                                    builder: (context) =>
                                        const SendToBankSheet(),
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: EdgeInsets.zero,
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(
                                      transactions[index].title,
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                    subtitle: Text(
                                      transactions[index].subtitle,
                                      style:
                                          theme.textTheme.bodyMedium!.copyWith(
                                        color: bgTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 2, top: 4),
                                          child: Text(
                                            transactions[index].amount,
                                            style: TextStyle(
                                              color: transactions[index].color,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          transactions[index].date,
                                          style: TextStyle(
                                              fontSize: 12, color: iconColor),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
