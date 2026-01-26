import 'package:fantacy11/app_config/app_config.dart';
import 'package:fantacy11/local_data_layer/local_data_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale(AppConfig.languageDefault));

  void selectLanguage(String countryCode) {
    emit(Locale(countryCode));
  }

  void getCurrentLanguage() async {
    String currLang = await LocalDataLayer().getCurrentLanguage();
    selectLanguage(currLang);
  }

  void setCurrentLanguage(String langCode) async {
    await LocalDataLayer().setCurrentLanguage(langCode);
    selectLanguage(langCode);
  }
}
