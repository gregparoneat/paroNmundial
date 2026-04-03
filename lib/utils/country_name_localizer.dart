import 'package:flutter/widgets.dart';

class CountryNameLocalizer {
  static const Map<String, String> _es = {
    'Algeria': 'Argelia',
    'Argentina': 'Argentina',
    'Australia': 'Australia',
    'Austria': 'Austria',
    'Belgium': 'Bélgica',
    'Bosnia-Herzegovina': 'Bosnia y Herzegovina',
    'Bosnia and Herzegovina': 'Bosnia y Herzegovina',
    'Brazil': 'Brasil',
    'Canada': 'Canadá',
    'Cape Verde': 'Cabo Verde',
    'Cape Verde Islands': 'Cabo Verde',
    'Chile': 'Chile',
    'Colombia': 'Colombia',
    'Croatia': 'Croacia',
    'Curacao': 'Curazao',
    'Curaçao': 'Curazao',
    'Czechia': 'Chequia',
    'Czech Republic': 'Chequia',
    'DR Congo': 'R. D. del Congo',
    'Congo DR': 'R. D. del Congo',
    'Democratic Republic of the Congo': 'R. D. del Congo',
    'Ecuador': 'Ecuador',
    'Egypt': 'Egipto',
    'England': 'Inglaterra',
    'France': 'Francia',
    'Germany': 'Alemania',
    'Ghana': 'Ghana',
    'Haiti': 'Haití',
    'Iran': 'Irán',
    'IR Iran': 'Irán',
    'Iraq': 'Irak',
    'Italy': 'Italia',
    'Ivory Coast': 'Costa de Marfil',
    'Cote dIvoire': 'Costa de Marfil',
    "Cote d'Ivoire": 'Costa de Marfil',
    "Côte d'Ivoire": 'Costa de Marfil',
    'India': 'India',
    'Indonesia': 'Indonesia',
    'Japan': 'Japón',
    'Jordan': 'Jordania',
    'Mexico': 'México',
    'Morocco': 'Marruecos',
    'Netherlands': 'Países Bajos',
    'Holland': 'Países Bajos',
    'New Zealand': 'Nueva Zelanda',
    'Norway': 'Noruega',
    'Panama': 'Panamá',
    'Paraguay': 'Paraguay',
    'Peru': 'Perú',
    'Portugal': 'Portugal',
    'Qatar': 'Catar',
    'Saudi Arabia': 'Arabia Saudita',
    'Saudi Arabia KSA': 'Arabia Saudita',
    'Scotland': 'Escocia',
    'Senegal': 'Senegal',
    'South Africa': 'Sudáfrica',
    'South Korea': 'Corea del Sur',
    'Korea Republic': 'Corea del Sur',
    'Republic of Korea': 'Corea del Sur',
    'Korea, South': 'Corea del Sur',
    'Spain': 'España',
    'Sweden': 'Suecia',
    'Switzerland': 'Suiza',
    'Turkey': 'Turquía',
    'Tunisia': 'Túnez',
    'Turkiye': 'Turquía',
    'Türkiye': 'Turquía',
    'United States': 'Estados Unidos',
    'United States of America': 'Estados Unidos',
    'USA': 'Estados Unidos',
    'US': 'Estados Unidos',
    'United Kingdom': 'Reino Unido',
    'UK': 'Reino Unido',
    'Uruguay': 'Uruguay',
    'Uzbekistan': 'Uzbekistán',
  };

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r"[\\.'’,()-]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static final Map<String, String> _normalizedEs = {
    for (final entry in _es.entries) _normalize(entry.key): entry.value,
  };

  static String localize(BuildContext context, String? rawName) {
    if (rawName == null || rawName.isEmpty) return rawName ?? '';
    if (Localizations.localeOf(context).languageCode != 'es') return rawName;
    return _es[rawName] ?? _normalizedEs[_normalize(rawName)] ?? rawName;
  }
}
