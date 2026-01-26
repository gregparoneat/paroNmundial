import 'package:fantacy11/app_config/app_config.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'language_cubit.dart';

class LanguageUI extends StatefulWidget {
  final bool fromRoot;

  const LanguageUI({super.key, this.fromRoot = false});

  @override
  LanguageUIState createState() => LanguageUIState();
}

class LanguageUIState extends State<LanguageUI> {
  late LanguageCubit _languageCubit;
  String? selectedLocale;

  @override
  void initState() {
    super.initState();
    _languageCubit = BlocProvider.of<LanguageCubit>(context)
      ..getCurrentLanguage();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var s = S.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              s.selectPreferredLanguage,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: BlocBuilder<LanguageCubit, Locale>(
              builder: (context, currentLocale) {
                selectedLocale ??= currentLocale.languageCode;
                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: AppConfig.languagesSupported.length,
                  itemBuilder: (context, index) {
                    var langCode =
                        AppConfig.languagesSupported.keys.elementAt(index);
                    return RadioListTile(
                      title: Text(
                        AppConfig.languagesSupported[langCode]!,
                        style: theme.textTheme.bodyLarge,
                      ),
                      value: langCode,
                      fillColor: const WidgetStatePropertyAll(Colors.white),
                      groupValue: selectedLocale,
                      onChanged: (langCode) async {
                        setState(() {
                          selectedLocale = langCode as String;
                        });
                      },
                      activeColor: theme.primaryColor,
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () async {
          _languageCubit.setCurrentLanguage(selectedLocale!);
          Navigator.pop(context);
        },
        child: const Icon(Icons.check, size: 24),
      ),
    );
  }
}
