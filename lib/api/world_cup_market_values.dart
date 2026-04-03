import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WorldCupMarketValueEntry {
  final String playerName;
  final double marketValueEurMillions;
  final String sourceTeam;

  const WorldCupMarketValueEntry({
    required this.playerName,
    required this.marketValueEurMillions,
    required this.sourceTeam,
  });
}

class WorldCupMarketValues {
  static const String _indexAsset = 'assets/MarketValues/index.csv';

  static final Map<String, WorldCupMarketValueEntry> _entriesByName = {};
  static Future<void>? _loadFuture;
  static bool _loaded = false;

  static bool get isLoaded => _loaded;

  static Future<void> ensureLoaded() {
    return _loadFuture ??= _loadAll();
  }

  static double? lookupMarketValue(String? rawName) {
    final normalized = normalizePlayerName(rawName);
    if (normalized == null) return null;
    return _entriesByName[normalized]?.marketValueEurMillions;
  }

  static String? normalizePlayerName(String? rawName) {
    if (rawName == null) return null;
    final normalized = rawName
        .toLowerCase()
        .replaceAll(RegExp(r"[\\.'’-]"), '')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('î', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized.isEmpty ? null : normalized;
  }

  static Future<void> _loadAll() async {
    try {
      final indexCsv = await rootBundle.loadString(_indexAsset);
      final files = _parseIndex(indexCsv);

      for (final entry in files.entries) {
        final teamName = entry.key;
        final assetPath = entry.value;
        try {
          final csv = await rootBundle.loadString(assetPath);
          _parseTeamCsv(csv, teamName);
        } catch (e) {
          debugPrint(
            'WorldCupMarketValues: failed to load $assetPath for $teamName: $e',
          );
        }
      }

      _loaded = true;
      debugPrint(
        'WorldCupMarketValues: loaded ${_entriesByName.length} player market values',
      );
    } catch (e) {
      debugPrint('WorldCupMarketValues: failed to load index: $e');
      _loaded = true;
    }
  }

  static Map<String, String> _parseIndex(String csv) {
    final files = <String, String>{};
    final lines = csv.split('\n');

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length < 2) continue;

      final teamName = parts[0].trim();
      final assetPath = parts[1].trim();
      if (teamName.isEmpty || assetPath.isEmpty) continue;
      files[teamName] = assetPath;
    }

    return files;
  }

  static void _parseTeamCsv(String csv, String sourceTeam) {
    final lines = csv.split('\n');

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length < 2) continue;

      final playerName = parts[0].trim();
      final marketValue = double.tryParse(parts[1].trim());
      final normalizedName = normalizePlayerName(playerName);

      if (normalizedName == null || marketValue == null || marketValue <= 0) {
        continue;
      }

      _entriesByName[normalizedName] = WorldCupMarketValueEntry(
        playerName: playerName,
        marketValueEurMillions: marketValue,
        sourceTeam: sourceTeam,
      );
    }
  }
}
