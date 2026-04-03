import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/utils/country_name_localizer.dart';
import 'package:flutter/material.dart';

class CountryDialCode {
  const CountryDialCode({
    required this.name,
    required this.dialCode,
    required this.flag,
  });

  final String name;
  final String dialCode;
  final String flag;
}

const kCountryDialCodes = <CountryDialCode>[
  CountryDialCode(name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
  CountryDialCode(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  CountryDialCode(name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  CountryDialCode(name: 'Argentina', dialCode: '+54', flag: '🇦🇷'),
  CountryDialCode(name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
  CountryDialCode(name: 'Chile', dialCode: '+56', flag: '🇨🇱'),
  CountryDialCode(name: 'Colombia', dialCode: '+57', flag: '🇨🇴'),
  CountryDialCode(name: 'Peru', dialCode: '+51', flag: '🇵🇪'),
  CountryDialCode(name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  CountryDialCode(name: 'France', dialCode: '+33', flag: '🇫🇷'),
  CountryDialCode(name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  CountryDialCode(name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  CountryDialCode(name: 'Portugal', dialCode: '+351', flag: '🇵🇹'),
  CountryDialCode(name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  CountryDialCode(name: 'Turkey', dialCode: '+90', flag: '🇹🇷'),
  CountryDialCode(name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  CountryDialCode(name: 'India', dialCode: '+91', flag: '🇮🇳'),
  CountryDialCode(name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  CountryDialCode(name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  CountryDialCode(name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
];

CountryDialCode countryByDialCode(String dialCode) {
  return kCountryDialCodes.firstWhere(
    (c) => c.dialCode == dialCode,
    orElse: () => kCountryDialCodes.first,
  );
}

Future<CountryDialCode?> showCountryCodePicker(
  BuildContext context, {
  required CountryDialCode initialCountry,
}) {
  return showModalBottomSheet<CountryDialCode>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _CountryCodePickerSheet(initialCountry: initialCountry),
  );
}

class _CountryCodePickerSheet extends StatefulWidget {
  const _CountryCodePickerSheet({required this.initialCountry});

  final CountryDialCode initialCountry;

  @override
  State<_CountryCodePickerSheet> createState() =>
      _CountryCodePickerSheetState();
}

class _CountryCodePickerSheetState extends State<_CountryCodePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = S.of(context);
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? kCountryDialCodes
        : kCountryDialCodes
              .where(
                (c) =>
                    c.name.toLowerCase().contains(q) ||
                    CountryNameLocalizer.localize(
                      context,
                      c.name,
                    ).toLowerCase().contains(q) ||
                    c.dialCode.contains(q) ||
                    c.flag.contains(q),
              )
              .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                labelText: locale.searchCountryOrCode,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final country = filtered[index];
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      CountryNameLocalizer.localize(context, country.name),
                    ),
                    trailing: Text(
                      country.dialCode,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () => Navigator.of(context).pop(country),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
