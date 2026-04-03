import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/features/fixtures/models/world_cup_predictor_models.dart';
import 'package:fantacy11/services/cache_service.dart';
import 'package:fantacy11/utils/country_name_localizer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class WorldCupPredictorPage extends StatefulWidget {
  final bool embedded;

  const WorldCupPredictorPage({super.key, this.embedded = true});

  @override
  State<WorldCupPredictorPage> createState() => _WorldCupPredictorPageState();
}

class _WorldCupPredictorPageState extends State<WorldCupPredictorPage>
    with AutomaticKeepAliveClientMixin {
  static const _cacheKey = 'world_cup_predictor_v1';

  final FixturesRepository _repository = FixturesRepository();
  final CacheService _cacheService = CacheService();
  final GlobalKey _summaryKey = GlobalKey();
  final Map<String, FocusNode> _scoreFocusNodes = {};
  final ScrollController _scrollController = ScrollController();
  ui.Image? _exportLogoImage;

  bool _isLoading = true;
  bool _isExporting = false;
  String? _error;
  Map<String, List<PredictorTeam>> _groups = const {};
  List<GroupStageFixture> _fixtures = const [];
  WorldCupPredictionState _state = const WorldCupPredictionState();
  Map<String, List<GroupStandingRow>> _standings = const {};
  KnockoutBuildResult? _knockout;
  Map<String, Map<int, String>> _thirdPlaceMatrix = const {};

  @override
  bool get wantKeepAlive => true;

  String _tr(String en, String es) =>
      Localizations.localeOf(context).languageCode == 'es' ? es : en;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final node in _scoreFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final savedState = _loadSavedState();
      final thirdPlaceMatrix = await _loadThirdPlaceMatrix();
      final standingsRaw = await _repository.getWorldCupStandings();
      final scheduleRaw = await _repository.getWorldCupScheduleRaw();
      final groups = _buildGroups(standingsRaw);
      final fixtures = _buildGroupFixtures(scheduleRaw, groups);
      final derived = _deriveState(
        groups: groups,
        fixtures: fixtures,
        state: savedState,
        thirdPlaceMatrix: thirdPlaceMatrix,
      );

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _fixtures = fixtures;
        _thirdPlaceMatrix = thirdPlaceMatrix;
        _state = derived.$1;
        _standings = derived.$2;
        _knockout = derived.$3;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  WorldCupPredictionState _loadSavedState() {
    final raw = _cacheService.get(_cacheKey);
    if (raw == null || raw.isEmpty) {
      return const WorldCupPredictionState();
    }
    try {
      return WorldCupPredictionState.fromJson(
        json.decode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const WorldCupPredictionState();
    }
  }

  Future<void> _saveState(WorldCupPredictionState state) async {
    await _cacheService.set(_cacheKey, json.encode(state.toJson()));
  }

  (WorldCupPredictionState, Map<String, List<GroupStandingRow>>, KnockoutBuildResult)
  _deriveState({
    required Map<String, List<PredictorTeam>> groups,
    required List<GroupStageFixture> fixtures,
    required WorldCupPredictionState state,
    required Map<String, Map<int, String>> thirdPlaceMatrix,
  }) {
    final standings = WorldCupPredictorEngine.buildStandings(
      groups: groups,
      fixtures: fixtures,
      scores: state.groupScores,
    );

    var winners = Map<int, int>.from(state.knockoutWinners);
    KnockoutBuildResult knockout = WorldCupPredictorEngine.buildKnockout(
      standings: standings,
      winners: winners,
      thirdPlaceMatrix: thirdPlaceMatrix,
    );

    while (true) {
      final sanitized = _sanitizeWinners(knockout, winners);
      if (mapEquals(sanitized, winners)) {
        break;
      }
      winners = sanitized;
      knockout = WorldCupPredictorEngine.buildKnockout(
        standings: standings,
        winners: winners,
        thirdPlaceMatrix: thirdPlaceMatrix,
      );
    }

    return (
      WorldCupPredictionState(
        groupScores: state.groupScores,
        knockoutWinners: winners,
      ),
      standings,
      knockout,
    );
  }

  Future<Map<String, Map<int, String>>> _loadThirdPlaceMatrix() async {
    final raw = await rootBundle.loadString(
      'assets/world_cup_2026_third_place_matrix.csv',
    );
    final lines = const LineSplitter().convert(raw).where((line) => line.trim().isNotEmpty).toList();
    if (lines.length <= 1) return const {};

    final matrix = <String, Map<int, String>>{};
    for (final line in lines.skip(1)) {
      final row = _parseCsvLine(line);
      if (row.length < 10) continue;
      final combinationKey = row[0].trim();
      if (combinationKey.isEmpty) continue;
      matrix[combinationKey] = {
        79: row[2].trim(),
        85: row[3].trim(),
        81: row[4].trim(),
        74: row[5].trim(),
        82: row[6].trim(),
        77: row[7].trim(),
        87: row[8].trim(),
        80: row[9].trim(),
      };
    }
    return matrix;
  }

  List<String> _parseCsvLine(String line) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        values.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    values.add(buffer.toString());
    return values;
  }

  Map<int, int> _sanitizeWinners(
    KnockoutBuildResult knockout,
    Map<int, int> current,
  ) {
    final validByMatch = <int, Set<int>>{};
    final allMatches = [
      ...knockout.roundOf32,
      ...knockout.roundOf16,
      ...knockout.quarterFinals,
      ...knockout.semiFinals,
      knockout.bronzeFinal,
      knockout.finalMatch,
    ];
    for (final match in allMatches) {
      validByMatch[match.id] = {
        if (match.home.teamId != null) match.home.teamId!,
        if (match.away.teamId != null) match.away.teamId!,
      };
    }

    final sanitized = <int, int>{};
    for (final entry in current.entries) {
      final valid = validByMatch[entry.key];
      if (valid != null && valid.contains(entry.value)) {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  String _scoreFieldKey(GroupStageFixture fixture, bool isHome) =>
      '${fixture.id}_${isHome ? "h" : "a"}';

  FocusNode _focusNodeFor(GroupStageFixture fixture, bool isHome) {
    final key = _scoreFieldKey(fixture, isHome);
    return _scoreFocusNodes.putIfAbsent(key, FocusNode.new);
  }

  FocusNode? _nextFocusNodeFor(GroupStageFixture fixture, bool isHome) {
    final fixtureIndex = _fixtures.indexWhere((item) => item.id == fixture.id);
    if (fixtureIndex == -1) return null;
    if (isHome) {
      return _focusNodeFor(fixture, false);
    }
    if (fixtureIndex + 1 >= _fixtures.length) {
      return null;
    }
    return _focusNodeFor(_fixtures[fixtureIndex + 1], true);
  }

  Map<String, List<PredictorTeam>> _buildGroups(List<Map<String, dynamic>> raw) {
    final grouped = <String, List<PredictorTeam>>{};

    for (final standing in raw) {
      final participant = standing['participant'];
      if (participant is! Map<String, dynamic>) continue;

      final group = _normalizeGroupName(
        (standing['group'] as Map<String, dynamic>?)?['name']?.toString() ??
            standing['group_id']?.toString(),
      );
      if (group == null) continue;

      final team = PredictorTeam(
        id: _parseInt(participant['id']),
        name: participant['name']?.toString() ?? 'Team',
        shortName:
            participant['short_code']?.toString() ??
            participant['name']?.toString() ??
            'Team',
        logoUrl:
            participant['image_path']?.toString() ??
            participant['logo_path']?.toString(),
        group: group,
      );

      final rows = grouped.putIfAbsent(group, () => []);
      if (!rows.any((existing) => existing.id == team.id)) {
        rows.add(team);
      }
    }

    final ordered = <String, List<PredictorTeam>>{};
    for (final group in WorldCupPredictorEngine.orderedGroups) {
      final teams = grouped[group];
      if (teams == null) continue;
      teams.sort((a, b) => a.name.compareTo(b.name));
      ordered[group] = teams;
    }
    return ordered;
  }

  List<GroupStageFixture> _buildGroupFixtures(
    List<Map<String, dynamic>> raw,
    Map<String, List<PredictorTeam>> groups,
  ) {
    final teamById = <int, PredictorTeam>{};
    for (final groupTeams in groups.values) {
      for (final team in groupTeams) {
        teamById[team.id] = team;
      }
    }

    final fixtures = <GroupStageFixture>[];
    for (final fixture in raw) {
      final group = _normalizeGroupName(
        (fixture['group'] as Map<String, dynamic>?)?['name']?.toString() ??
            fixture['group_id']?.toString(),
      );
      if (group == null || !groups.containsKey(group)) continue;

      final participants = fixture['participants'] as List<dynamic>? ?? const [];
      Map<String, dynamic>? homeJson;
      Map<String, dynamic>? awayJson;
      for (final participant in participants) {
        if (participant is! Map<String, dynamic>) continue;
        final location = (participant['meta'] as Map<String, dynamic>?)?['location']
            ?.toString()
            .toLowerCase();
        if (location == 'home') {
          homeJson = participant;
        } else if (location == 'away') {
          awayJson = participant;
        }
      }
      if (homeJson == null || awayJson == null) continue;

      final homeTeam = teamById[_parseInt(homeJson['id'])];
      final awayTeam = teamById[_parseInt(awayJson['id'])];
      if (homeTeam == null || awayTeam == null) continue;

      fixtures.add(
        GroupStageFixture(
          id: _parseInt(fixture['id']),
          group: group,
          kickoff: _parseDateTime(fixture['starting_at_timestamp']),
          homeTeam: homeTeam,
          awayTeam: awayTeam,
        ),
      );
    }

    fixtures.sort((a, b) {
      final groupCompare = a.group.compareTo(b.group);
      if (groupCompare != 0) return groupCompare;
      final aTs = a.kickoff?.millisecondsSinceEpoch ?? 0;
      final bTs = b.kickoff?.millisecondsSinceEpoch ?? 0;
      return aTs.compareTo(bTs);
    });

    return fixtures;
  }

  String? _normalizeGroupName(String? raw) {
    if (raw == null) return null;
    final upper = raw.trim().toUpperCase();
    if (upper.isEmpty) return null;
    if (upper.startsWith('GROUP ')) {
      final value = upper.replaceFirst('GROUP ', '').trim();
      return value.isEmpty ? null : value;
    }
    if (upper.length == 1 &&
        WorldCupPredictorEngine.orderedGroups.contains(upper)) {
      return upper;
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic timestamp) {
    final ts = _parseInt(timestamp);
    if (ts <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts * 1000);
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _setScore(GroupStageFixture fixture, int home, int away) {
    final score = PredictorScore(home: home.clamp(0, 20), away: away.clamp(0, 20));
    final nextScores = Map<int, PredictorScore>.from(_state.groupScores)
      ..[fixture.id] = score;
    final derived = _deriveState(
      groups: _groups,
      fixtures: _fixtures,
      state: WorldCupPredictionState(
        groupScores: nextScores,
        knockoutWinners: _state.knockoutWinners,
      ),
      thirdPlaceMatrix: _thirdPlaceMatrix,
    );

    setState(() {
      _state = derived.$1;
      _standings = derived.$2;
      _knockout = derived.$3;
    });
    _saveState(derived.$1);
  }

  void _clearScore(int fixtureId) {
    final nextScores = Map<int, PredictorScore>.from(_state.groupScores)
      ..remove(fixtureId);
    final derived = _deriveState(
      groups: _groups,
      fixtures: _fixtures,
      state: WorldCupPredictionState(
        groupScores: nextScores,
        knockoutWinners: _state.knockoutWinners,
      ),
      thirdPlaceMatrix: _thirdPlaceMatrix,
    );

    setState(() {
      _state = derived.$1;
      _standings = derived.$2;
      _knockout = derived.$3;
    });
    _saveState(derived.$1);
  }

  void _toggleWinner(KnockoutMatchView match, int? teamId) {
    final nextWinners = Map<int, int>.from(_state.knockoutWinners);
    if (teamId == null || nextWinners[match.id] == teamId) {
      nextWinners.remove(match.id);
    } else {
      nextWinners[match.id] = teamId;
    }

    final derived = _deriveState(
      groups: _groups,
      fixtures: _fixtures,
      state: WorldCupPredictionState(
        groupScores: _state.groupScores,
        knockoutWinners: nextWinners,
      ),
      thirdPlaceMatrix: _thirdPlaceMatrix,
    );

    setState(() {
      _state = derived.$1;
      _standings = derived.$2;
      _knockout = derived.$3;
    });
    _saveState(derived.$1);
  }

  Future<void> _resetAll() async {
    final derived = _deriveState(
      groups: _groups,
      fixtures: _fixtures,
      state: const WorldCupPredictionState(),
      thirdPlaceMatrix: _thirdPlaceMatrix,
    );
    setState(() {
      _state = derived.$1;
      _standings = derived.$2;
      _knockout = derived.$3;
    });
    await _saveState(derived.$1);
  }

  Future<void> _exportSummaryImage() async {
    final knockout = _knockout;
    if (knockout == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                'Could not prepare the prediction image',
                'No se pudo preparar la imagen de la predicción',
              ),
            ),
          ),
        );
      }
      return;
    }

    try {
      final pngBytes = await _buildExportImage(knockout, Theme.of(context));
      final dir = await Directory.systemTemp.createTemp('wc_predictor_');
      final file = File('${dir.path}/world_cup_predictor.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: _tr('My World Cup prediction', 'Mi predicción del Mundial'),
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr('Prediction image ready to share', 'Imagen lista para compartir'),
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('WorldCupPredictor export failed: $error');
      debugPrint('$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _tr(
                'Could not export the prediction image',
                'No se pudo exportar la imagen de la predicción',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<Uint8List> _buildExportImage(
    KnockoutBuildResult knockout,
    ThemeData theme,
  ) async {
    const width = 1920.0;
    const margin = 56.0;
    const headerHeight = 236.0;
    const columnGap = 36.0;
    const cardWidth = 286.0;
    const matchCardHeight = 88.0;
    const roundOf32Spacing = 18.0;
    const finalStageWidth = 320.0;

    final columns = <(String, List<KnockoutMatchView>, double)>[
      (_tr('Round of 32', 'Dieciseisavos'), knockout.roundOf32, cardWidth),
      (_tr('Round of 16', 'Octavos'), knockout.roundOf16, cardWidth),
      (_tr('Quarter-finals', 'Cuartos'), knockout.quarterFinals, cardWidth),
      (_tr('Semi-finals', 'Semifinales'), knockout.semiFinals, cardWidth),
      (_tr('Final Stage', 'Etapa final'), [knockout.bronzeFinal, knockout.finalMatch], finalStageWidth),
    ];

    final r32Y = _initialRoundYPositions(
      count: knockout.roundOf32.length,
      topY: headerHeight + 74,
      cardHeight: matchCardHeight,
      spacing: roundOf32Spacing,
    );
    final r16Y = _derivedRoundYPositions(r32Y, matchCardHeight);
    final qfY = _derivedRoundYPositions(r16Y, matchCardHeight);
    final sfY = _derivedRoundYPositions(qfY, matchCardHeight);
    final finalY = [
      sfY.first - 92,
      sfY.first + 92,
    ];
    final contentBottom = [
      ...r32Y,
      ...r16Y,
      ...qfY,
      ...sfY,
      ...finalY,
    ].map((y) => y + matchCardHeight).reduce((a, b) => a > b ? a : b);
    final height = contentBottom + 72.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    final background = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(width, height),
        const [
          Color(0xFF0B3D2E),
          Color(0xFF12694E),
          Color(0xFF1A8A62),
          Color(0xFFF4EFE2),
        ],
        const [0.0, 0.35, 0.72, 1.0],
      );
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), background);

    final glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(width * 0.82, height * 0.14),
        width * 0.32,
        [
          const Color(0xFFD9B45C).withValues(alpha: 0.34),
          const Color(0xFFD9B45C).withValues(alpha: 0.0),
        ],
      );
    canvas.drawCircle(
      Offset(width * 0.82, height * 0.14),
      width * 0.32,
      glowPaint,
    );

    final sweepPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(width * 0.0, height * 0.82),
        Offset(width * 0.7, height * 0.28),
        [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.0),
        ],
        const [0.0, 0.55, 1.0],
      );
    final sweepPath = Path()
      ..moveTo(0, height * 0.9)
      ..quadraticBezierTo(
        width * 0.25,
        height * 0.72,
        width * 0.62,
        height * 0.46,
      )
      ..quadraticBezierTo(
        width * 0.78,
        height * 0.36,
        width,
        height * 0.22,
      )
      ..lineTo(width, height * 0.32)
      ..quadraticBezierTo(
        width * 0.74,
        height * 0.44,
        width * 0.56,
        height * 0.56,
      )
      ..quadraticBezierTo(
        width * 0.22,
        height * 0.78,
        0,
        height,
      )
      ..close();
    canvas.drawPath(sweepPath, sweepPaint);

    final fieldLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fieldRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(28, 28, width - 56, height - 56),
      const Radius.circular(34),
    );
    canvas.drawRRect(fieldRect, fieldLinePaint);
    canvas.drawLine(
      Offset(width / 2, 28),
      Offset(width / 2, height - 28),
      fieldLinePaint,
    );
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      74,
      fieldLinePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(width / 2, height / 2),
        width: 420,
        height: 420,
      ),
      -0.55,
      1.10,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28,
    );

    final titleStyle = TextStyle(
      color: Colors.black87,
      fontSize: 54,
      fontWeight: FontWeight.w800,
    );
    final subtitleStyle = TextStyle(
      color: Colors.black54,
      fontSize: 28,
      fontWeight: FontWeight.w500,
    );
    final championLabelStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontSize: 24,
      fontWeight: FontWeight.w700,
    );
    final championStyle = TextStyle(
      color: Colors.black87,
      fontSize: 44,
      fontWeight: FontWeight.w800,
    );
    final brandingLabelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.82),
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );

    _paintText(
      canvas,
      _tr('My World Cup Bracket', 'Mi cuadro del Mundial'),
      titleStyle,
      const Offset(margin, 38),
      width - (margin * 2),
    );
    _paintText(
      canvas,
      _tr('Knockout stage chart', 'Cuadro eliminatorio'),
      subtitleStyle,
      const Offset(margin, 106),
      width - (margin * 2),
    );

    final logo = await _loadExportLogo();
    if (logo != null) {
      final logoRect = Rect.fromLTWH(width - margin - 232, 34, 176, 176);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(width - margin - 256, 24, 208, 196),
          const Radius.circular(28),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.08),
      );
      canvas.drawImageRect(
        logo,
        Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
        logoRect,
        Paint(),
      );
      _paintText(
        canvas,
        _tr('Generated in', 'Generado en'),
        brandingLabelStyle,
        Offset(width - margin - 250, 198),
        190,
      );
      _paintText(
        canvas,
        'paroNmundial',
        brandingLabelStyle.copyWith(
          color: const Color(0xFFD9B45C),
          fontWeight: FontWeight.w800,
        ),
        Offset(width - margin - 250, 220),
        210,
      );
    }

    final champion = knockout.champion?.teamName ?? knockout.champion?.label;
    if (champion != null) {
      final championRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, 146, width - (margin * 2), 120),
        const Radius.circular(28),
      );
      canvas.drawRRect(
        championRect,
        Paint()..color = theme.colorScheme.primary.withValues(alpha: 0.10),
      );
      _paintText(
        canvas,
        _tr('Champion', 'Campeón'),
        championLabelStyle,
        Offset(margin + 28, 172),
        width - ((margin + 28) * 2),
      );
      _paintText(
        canvas,
        _localizedCountry(champion),
        championStyle,
        Offset(margin + 28, 204),
        width - ((margin + 28) * 2),
      );
    }

    final xPositions = <double>[];
    var currentX = margin;
    for (final column in columns) {
      xPositions.add(currentX);
      currentX += column.$3 + columnGap;
    }

    final headerY = headerHeight + 10;
    for (var i = 0; i < columns.length; i++) {
      _paintColumnHeader(
        canvas,
        theme,
        title: columns[i].$1,
        x: xPositions[i],
        y: headerY,
        width: columns[i].$3,
      );
    }

    _paintConnectors(
      canvas,
      theme,
      fromX: xPositions[0] + cardWidth,
      toX: xPositions[1],
      previousRoundY: r32Y,
      nextRoundY: r16Y,
      cardHeight: matchCardHeight,
    );
    _paintConnectors(
      canvas,
      theme,
      fromX: xPositions[1] + cardWidth,
      toX: xPositions[2],
      previousRoundY: r16Y,
      nextRoundY: qfY,
      cardHeight: matchCardHeight,
    );
    _paintConnectors(
      canvas,
      theme,
      fromX: xPositions[2] + cardWidth,
      toX: xPositions[3],
      previousRoundY: qfY,
      nextRoundY: sfY,
      cardHeight: matchCardHeight,
    );
    _paintConnectors(
      canvas,
      theme,
      fromX: xPositions[3] + cardWidth,
      toX: xPositions[4],
      previousRoundY: sfY,
      nextRoundY: [finalY[1]],
      cardHeight: matchCardHeight,
    );

    for (var i = 0; i < knockout.roundOf32.length; i++) {
      _paintExportMatchCard(
        canvas,
        theme,
        match: knockout.roundOf32[i],
        x: xPositions[0],
        y: r32Y[i],
        width: cardWidth,
        height: matchCardHeight,
      );
    }
    for (var i = 0; i < knockout.roundOf16.length; i++) {
      _paintExportMatchCard(
        canvas,
        theme,
        match: knockout.roundOf16[i],
        x: xPositions[1],
        y: r16Y[i],
        width: cardWidth,
        height: matchCardHeight,
      );
    }
    for (var i = 0; i < knockout.quarterFinals.length; i++) {
      _paintExportMatchCard(
        canvas,
        theme,
        match: knockout.quarterFinals[i],
        x: xPositions[2],
        y: qfY[i],
        width: cardWidth,
        height: matchCardHeight,
      );
    }
    for (var i = 0; i < knockout.semiFinals.length; i++) {
      _paintExportMatchCard(
        canvas,
        theme,
        match: knockout.semiFinals[i],
        x: xPositions[3],
        y: sfY[i],
        width: cardWidth,
        height: matchCardHeight,
      );
    }
    _paintExportMatchCard(
      canvas,
      theme,
      match: knockout.bronzeFinal,
      x: xPositions[4],
      y: finalY[0],
      width: finalStageWidth,
      height: matchCardHeight,
      stageLabel: _tr('Third-place match', 'Partido por el tercer lugar'),
    );
    _paintExportMatchCard(
      canvas,
      theme,
      match: knockout.finalMatch,
      x: xPositions[4],
      y: finalY[1],
      width: finalStageWidth,
      height: matchCardHeight,
      stageLabel: _tr('Final', 'Final'),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Could not encode predictor image');
    }
    return bytes.buffer.asUint8List();
  }

  Future<ui.Image?> _loadExportLogo() async {
    if (_exportLogoImage != null) return _exportLogoImage;
    try {
      final data = await rootBundle.load('assets/paroNmundialTransparent.png');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _exportLogoImage = frame.image;
      return _exportLogoImage;
    } catch (_) {
      return null;
    }
  }

  List<double> _initialRoundYPositions({
    required int count,
    required double topY,
    required double cardHeight,
    required double spacing,
  }) {
    return List<double>.generate(
      count,
      (index) => topY + (index * (cardHeight + spacing)),
    );
  }

  List<double> _derivedRoundYPositions(List<double> previous, double cardHeight) {
    final result = <double>[];
    for (var i = 0; i < previous.length; i += 2) {
      final topMid = previous[i] + (cardHeight / 2);
      final bottomMid = previous[i + 1] + (cardHeight / 2);
      result.add(((topMid + bottomMid) / 2) - (cardHeight / 2));
    }
    return result;
  }

  void _paintColumnHeader(
    Canvas canvas,
    ThemeData theme, {
    required String title,
    required double x,
    required double y,
    required double width,
  }) {
    final headerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, 42),
      const Radius.circular(999),
    );
    canvas.drawRRect(
      headerRect,
      Paint()..color = theme.colorScheme.primary.withValues(alpha: 0.10),
    );
    _paintText(
      canvas,
      title,
      TextStyle(
        color: theme.colorScheme.primary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      Offset(x + 18, y + 8),
      width - 36,
    );
  }

  void _paintConnectors(
    Canvas canvas,
    ThemeData theme, {
    required double fromX,
    required double toX,
    required List<double> previousRoundY,
    required List<double> nextRoundY,
    required double cardHeight,
  }) {
    final connectorPaint = Paint()
      ..color = theme.colorScheme.primary.withValues(alpha: 0.22)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final elbowX = fromX + ((toX - fromX) / 2);
    for (var i = 0; i < nextRoundY.length; i++) {
      final topMid = previousRoundY[i * 2] + (cardHeight / 2);
      final bottomMid = previousRoundY[(i * 2) + 1] + (cardHeight / 2);
      final nextMid = nextRoundY[i] + (cardHeight / 2);
      final path = Path()
        ..moveTo(fromX, topMid)
        ..lineTo(elbowX, topMid)
        ..moveTo(fromX, bottomMid)
        ..lineTo(elbowX, bottomMid)
        ..moveTo(elbowX, topMid)
        ..lineTo(elbowX, bottomMid)
        ..moveTo(elbowX, nextMid)
        ..lineTo(toX, nextMid);
      canvas.drawPath(path, connectorPaint);
    }
  }

  void _paintExportMatchCard(
    Canvas canvas,
    ThemeData theme, {
    required KnockoutMatchView match,
    required double x,
    required double y,
    required double width,
    required double height,
    String? stageLabel,
  }) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, width, height),
      const Radius.circular(20),
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white.withValues(alpha: 0.94));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = theme.dividerColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    if (stageLabel != null) {
      _paintText(
        canvas,
        stageLabel,
        TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        Offset(x + 16, y + 10),
        width - 32,
      );
    } else {
      _paintText(
        canvas,
        'M${match.id}',
        const TextStyle(
          color: Colors.black54,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        Offset(x + 16, y + 10),
        width - 32,
      );
    }

    _paintExportTeamLine(
      canvas,
      theme,
      slot: match.home,
      selected: match.winnerTeamId != null && match.winnerTeamId == match.home.teamId,
      x: x + 16,
      y: y + 30,
      width: width - 32,
    );
    _paintExportTeamLine(
      canvas,
      theme,
      slot: match.away,
      selected: match.winnerTeamId != null && match.winnerTeamId == match.away.teamId,
      x: x + 16,
      y: y + 54,
      width: width - 32,
    );
  }

  void _paintExportTeamLine(
    Canvas canvas,
    ThemeData theme, {
    required KnockoutTeamSlot slot,
    required bool selected,
    required double x,
    required double y,
    required double width,
  }) {
    if (selected) {
      final highlight = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 6, y - 2, width, 22),
        const Radius.circular(10),
      );
      canvas.drawRRect(
        highlight,
        Paint()..color = theme.colorScheme.primary.withValues(alpha: 0.12),
      );
    }
    _paintText(
      canvas,
      slot.teamName != null ? _localizedCountry(slot.teamName!) : slot.label,
      TextStyle(
        color: Colors.black87,
        fontSize: 18,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      Offset(x, y),
      width - 20,
    );
    if (selected) {
      _paintText(
        canvas,
        '✓',
        TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        Offset(x + width - 18, y),
        18,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset offset,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 10,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _tr('Could not load predictor', 'No se pudo cargar el predictor'),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      content = ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          ...WorldCupPredictorEngine.orderedGroups
              .where((group) => _groups[group]?.isNotEmpty ?? false)
              .map((group) => _buildGroupSection(theme, group)),
          const SizedBox(height: 24),
          if (_knockout != null) ...[
            _buildKnockoutSection(theme, _knockout!),
            const SizedBox(height: 24),
            RepaintBoundary(
              key: _summaryKey,
              child: _buildSummaryCard(theme, _knockout!),
            ),
          ],
        ],
      );
    }

    final body = content;

    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: Text(_tr('Predictor', 'Predictor'))),
      body: body,
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.18),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.10),
            theme.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _tr('Build your tournament story', 'Arma tu historia del torneo'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _tr('World Cup Predictor', 'Predictor del Mundial'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _tr(
              'Enter group-stage scores, let the bracket build itself, then pick every winner until you crown a champion.',
              'Captura tus marcadores de fase de grupos, deja que el cuadro se construya y luego elige a cada ganador hasta coronar a un campeón.',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildHeaderMetric(
                theme,
                value: '${_state.groupScores.length}/${_fixtures.length}',
                label: _tr('Group games scored', 'Partidos con marcador'),
              ),
              _buildHeaderMetric(
                theme,
                value: '${_state.knockoutWinners.length}',
                label: _tr('Knockout picks', 'Picks eliminatorios'),
              ),
              _buildHeaderMetric(
                theme,
                value: _knockout?.champion?.teamName != null
                    ? _localizedCountry(_knockout!.champion!.teamName!)
                    : _tr('Pending', 'Pendiente'),
                label: _tr('Champion', 'Campeón'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _isExporting ? null : _exportSummaryImage,
                icon: Icon(_isExporting ? Icons.hourglass_top : Icons.image_outlined),
                label: Text(_tr('Export image', 'Exportar imagen')),
              ),
              OutlinedButton.icon(
                onPressed: _resetAll,
                icon: const Icon(Icons.refresh),
                label: Text(_tr('Reset picks', 'Reiniciar picks')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(
    ThemeData theme, {
    required String value,
    required String label,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildGroupSection(ThemeData theme, String group) {
    final fixtures = _fixtures.where((fixture) => fixture.group == group).toList();
    final rows = _standings[group] ?? const <GroupStandingRow>[];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        initiallyExpanded: group == 'A',
        title: Text('${_tr('Group', 'Grupo')} $group'),
        subtitle: Text('${fixtures.length} ${_tr('matches', 'partidos')}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _buildStandingsTable(theme, rows),
          const SizedBox(height: 12),
          ...fixtures.map((fixture) => _buildFixtureEditor(theme, fixture)),
        ],
      ),
    );
  }

  Widget _buildStandingsTable(ThemeData theme, List<GroupStandingRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _tr('Team', 'Equipo'),
                  style: theme.textTheme.labelLarge,
                ),
              ),
              _buildMiniHead(theme, 'P'),
              _buildMiniHead(theme, 'GF'),
              _buildMiniHead(theme, 'GC'),
              _buildMiniHead(theme, 'DG'),
              _buildMiniHead(theme, 'Pts'),
            ],
          ),
          const SizedBox(height: 8),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          alignment: Alignment.center,
                          child: Text('${index + 1}', style: theme.textTheme.bodySmall),
                        ),
                        const SizedBox(width: 8),
                        _buildLogo(row.team.logoUrl, 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _localizedCountry(row.team.name),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildMiniCell(theme, row.played),
                  _buildMiniCell(theme, row.goalsFor),
                  _buildMiniCell(theme, row.goalsAgainst),
                  _buildMiniCell(theme, row.goalDifference),
                  _buildMiniCell(theme, row.points, bold: true),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMiniHead(ThemeData theme, String label) {
    return SizedBox(
      width: 34,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelMedium,
      ),
    );
  }

  Widget _buildMiniCell(ThemeData theme, int value, {bool bold = false}) {
    return SizedBox(
      width: 34,
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        style: bold
            ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)
            : theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildFixtureEditor(ThemeData theme, GroupStageFixture fixture) {
    final score = _state.groupScores[fixture.id];
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          if (fixture.kickoff != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${fixture.kickoff!.day}/${fixture.kickoff!.month}/${fixture.kickoff!.year}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _buildCompactTeam(theme, fixture.homeTeam),
              ),
              const SizedBox(width: 10),
              _buildScoreInput(
                theme,
                fixture: fixture,
                isHome: true,
                value: score?.home,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildScoreInput(
                theme,
                fixture: fixture,
                isHome: false,
                value: score?.away,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCompactTeam(theme, fixture.awayTeam, alignEnd: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactTeam(
    ThemeData theme,
    PredictorTeam team, {
    bool alignEnd = false,
  }) {
    final label = team.shortName.isNotEmpty ? team.shortName : team.group;
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignEnd) ...[
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            _buildLogo(team.logoUrl, 28),
          ] else ...[
            _buildLogo(team.logoUrl, 28),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreInput(
    ThemeData theme, {
    required GroupStageFixture fixture,
    required bool isHome,
    required int? value,
  }) {
    final focusNode = _focusNodeFor(fixture, isHome);
    final nextFocusNode = _nextFocusNodeFor(fixture, isHome);
    return SizedBox(
      width: 56,
      child: TextFormField(
        key: ValueKey(_scoreFieldKey(fixture, isHome)),
        initialValue: value?.toString() ?? '',
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction:
            nextFocusNode == null ? TextInputAction.done : TextInputAction.next,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(
          hintText: '0',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (raw) {
          final parsed = int.tryParse(raw.trim());
          if (raw.trim().isEmpty) {
            if (isHome) {
              if ((_state.groupScores[fixture.id]?.away) == null) {
                _clearScore(fixture.id);
              } else {
                _setScore(fixture, 0, _state.groupScores[fixture.id]!.away);
              }
            } else {
              if ((_state.groupScores[fixture.id]?.home) == null) {
                _clearScore(fixture.id);
              } else {
                _setScore(fixture, _state.groupScores[fixture.id]!.home, 0);
              }
            }
            return;
          }

          final safe = (parsed ?? 0).clamp(0, 20);
          final current = _state.groupScores[fixture.id];
          _setScore(
            fixture,
            isHome ? safe : (current?.home ?? 0),
            isHome ? (current?.away ?? 0) : safe,
          );
        },
        onFieldSubmitted: (_) {
          if (nextFocusNode != null) {
            nextFocusNode.requestFocus();
          } else {
            focusNode.unfocus();
          }
        },
      ),
    );
  }

  Widget _buildKnockoutSection(ThemeData theme, KnockoutBuildResult knockout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr('Knockout bracket', 'Fase final'),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoundColumn(
                theme,
                _tr('Round of 32', 'Dieciseisavos'),
                knockout.roundOf32,
                dense: true,
              ),
              _buildBracketSpacer(),
              _buildRoundColumn(
                theme,
                _tr('Round of 16', 'Octavos'),
                knockout.roundOf16,
              ),
              _buildBracketSpacer(),
              _buildRoundColumn(
                theme,
                _tr('Quarter-finals', 'Cuartos'),
                knockout.quarterFinals,
              ),
              _buildBracketSpacer(),
              _buildRoundColumn(
                theme,
                _tr('Semi-finals', 'Semifinales'),
                knockout.semiFinals,
              ),
              _buildBracketSpacer(),
              SizedBox(
                width: 270,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _tr('Final Stage', 'Etapa final'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _buildKnockoutMatchCard(
                      theme,
                      knockout.bronzeFinal,
                      stageLabel: _tr('Third-place match', 'Partido por el tercer lugar'),
                    ),
                    _buildKnockoutMatchCard(
                      theme,
                      knockout.finalMatch,
                      stageLabel: _tr('Final', 'Final'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoundColumn(
    ThemeData theme,
    String title,
    List<KnockoutMatchView> matches, {
    bool dense = false,
  }) {
    return SizedBox(
      width: dense ? 290 : 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...matches.map(
            (match) => _buildKnockoutMatchCard(theme, match, dense: dense),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketSpacer() {
    return const SizedBox(width: 14);
  }

  Widget _buildKnockoutMatchCard(
    ThemeData theme,
    KnockoutMatchView match, {
    bool dense = false,
    String? stageLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(dense ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stageLabel != null)
                    Text(
                      stageLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  Text(
                    'M${match.id}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (match.winnerTeamId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _tr('Picked', 'Elegido'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildWinnerOption(theme, match, match.home, dense: dense),
          const SizedBox(height: 8),
          _buildWinnerOption(theme, match, match.away, dense: dense),
        ],
      ),
    );
  }

  Widget _buildWinnerOption(
    ThemeData theme,
    KnockoutMatchView match,
    KnockoutTeamSlot team, {
    bool dense = false,
  }
  ) {
    final selected = match.winnerTeamId != null && match.winnerTeamId == team.teamId;
    return InkWell(
      onTap: team.teamId == null ? null : () => _toggleWinner(match, team.teamId),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? theme.colorScheme.primary.withValues(alpha: 0.14) : null,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            _buildLogo(team.logoUrl, dense ? 22 : 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.teamName != null
                        ? _localizedCountry(team.teamName!)
                        : team.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (team.seed != null && !dense)
                    Text(team.seed!, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    KnockoutBuildResult knockout, {
    bool forExport = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            theme.scaffoldBackgroundColor,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr('My World Cup Bracket', 'Mi cuadro del Mundial'),
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          if (knockout.champion != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
              ),
              child: Row(
                children: [
                  if (forExport)
                    _buildExportBadge(
                      knockout.champion!.teamName ?? knockout.champion!.label,
                      44,
                    )
                  else
                    _buildLogo(knockout.champion!.logoUrl, 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _tr('Champion', 'Campeón'),
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _localizedCountry(
                            knockout.champion!.teamName ?? knockout.champion!.label,
                          ),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.emoji_events_outlined),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSummaryRound(
                theme,
                _tr('Round of 32', 'Dieciseisavos'),
                knockout.roundOf32,
              ),
              _buildSummaryRound(
                theme,
                _tr('Round of 16', 'Octavos'),
                knockout.roundOf16,
              ),
              _buildSummaryRound(
                theme,
                _tr('Quarter-finals', 'Cuartos'),
                knockout.quarterFinals,
              ),
              _buildSummaryRound(
                theme,
                _tr('Semi-finals', 'Semifinales'),
                knockout.semiFinals,
              ),
              _buildSummaryRound(
                theme,
                _tr('Final', 'Final'),
                [knockout.finalMatch],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRound(ThemeData theme, String title, List<KnockoutMatchView> matches) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...matches.map((match) {
            final winner = match.winnerTeamId == match.home.teamId
                ? match.home
                : match.winnerTeamId == match.away.teamId
                    ? match.away
                    : null;
            final label = winner?.teamName != null
                ? _localizedCountry(winner!.teamName!)
                : '${match.home.teamName ?? match.home.label} vs ${match.away.teamName ?? match.away.label}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(label, style: theme.textTheme.bodyMedium),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogo(String? url, double size) {
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.shield_outlined, size: size * 0.65),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorWidget: (context, urlValue, error) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildExportBadge(String label, double size) {
    final cleaned = label.trim();
    final parts = cleaned.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : parts.take(2).map((part) => part.characters.first.toUpperCase()).join();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _localizedCountry(String raw) {
    return CountryNameLocalizer.localize(context, raw);
  }
}
