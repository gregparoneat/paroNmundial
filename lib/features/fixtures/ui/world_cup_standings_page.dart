import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/utils/country_name_localizer.dart';
import 'package:flutter/material.dart';

class WorldCupStandingsPage extends StatefulWidget {
  final bool embedded;

  const WorldCupStandingsPage({super.key, this.embedded = true});

  @override
  State<WorldCupStandingsPage> createState() => _WorldCupStandingsPageState();
}

class _WorldCupStandingsPageState extends State<WorldCupStandingsPage>
    with AutomaticKeepAliveClientMixin {
  final FixturesRepository _repository = FixturesRepository();

  bool _isLoading = true;
  String? _error;
  List<_WorldCupGroupStandings> _groups = const [];

  @override
  bool get wantKeepAlive => true;

  String _tr(String en, String es) =>
      Localizations.localeOf(context).languageCode == 'es' ? es : en;

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  Future<void> _loadStandings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final standings = await _repository.getWorldCupStandings();
      final groups = _buildGroups(standings);

      if (!mounted) return;
      setState(() {
        _groups = groups;
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

  List<_WorldCupGroupStandings> _buildGroups(List<Map<String, dynamic>> raw) {
    final grouped = <String, List<_StandingRow>>{};

    for (final standing in raw) {
      final participant = standing['participant'];
      if (participant is! Map<String, dynamic>) continue;

      final teamName =
          participant['name']?.toString() ??
          participant['short_code']?.toString() ??
          'Team';
      final key = _resolveGroupName(standing);

      grouped
          .putIfAbsent(key, () => [])
          .add(
            _StandingRow(
              position: _parseInt(standing['position']),
              teamName: teamName,
              logoUrl:
                  participant['image_path']?.toString() ??
                  participant['logo_path']?.toString(),
              points: _parseInt(standing['points']),
              played: _extractStat(standing, const [
                'standing.played',
                'standing.matches_played',
                'all.played',
                'overall.played',
              ]),
              won: _extractStat(standing, const [
                'standing.won',
                'all.won',
                'overall.won',
              ]),
              drawn: _extractStat(standing, const [
                'standing.draw',
                'standing.drawn',
                'all.draw',
                'all.drawn',
                'overall.draw',
                'overall.drawn',
              ]),
              lost: _extractStat(standing, const [
                'standing.lost',
                'all.lost',
                'overall.lost',
              ]),
              goalsFor: _extractStat(standing, const [
                'standing.goals_for',
                'all.goals_for',
                'overall.goals_for',
              ]),
              goalsAgainst: _extractStat(standing, const [
                'standing.goals_against',
                'all.goals_against',
                'overall.goals_against',
              ]),
              goalDifference: _extractStat(standing, const [
                'standing.goal_difference',
                'all.goal_difference',
                'overall.goal_difference',
              ]),
            ),
          );
    }

    final groups = grouped.entries.map((entry) {
      final rows = [...entry.value];
      rows.sort((a, b) => a.position.compareTo(b.position));
      return _WorldCupGroupStandings(name: entry.key, rows: rows);
    }).toList();

    groups.sort((a, b) => a.name.compareTo(b.name));
    return groups;
  }

  String _resolveGroupName(Map<String, dynamic> standing) {
    final group = standing['group'];
    if (group is Map<String, dynamic>) {
      final groupName = group['name']?.toString();
      if (groupName != null && groupName.trim().isNotEmpty) {
        return groupName.trim();
      }
    }

    final stage = standing['stage'];
    if (stage is Map<String, dynamic>) {
      final stageName = stage['name']?.toString();
      if (stageName != null && stageName.trim().isNotEmpty) {
        return stageName.trim();
      }
    }

    final rawGroupId = standing['group_id']?.toString();
    if (rawGroupId != null && rawGroupId.isNotEmpty && rawGroupId != 'null') {
      return 'Group $rawGroupId';
    }

    return _tr('Standings', 'Clasificación');
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _extractStat(Map<String, dynamic> standing, List<String> candidates) {
    final details = standing['details'];
    if (details is! List) return 0;

    for (final entry in details) {
      if (entry is! Map<String, dynamic>) continue;
      final type = entry['type'];
      String? developerName;
      if (type is Map<String, dynamic>) {
        developerName =
            type['developer_name']?.toString() ??
            type['code']?.toString() ??
            type['name']?.toString();
      }

      final normalized = developerName?.toLowerCase().trim();
      if (normalized == null) continue;
      if (!candidates.contains(normalized)) continue;

      return _parseInt(entry['value']);
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = _buildError(theme);
    } else if (_groups.isEmpty) {
      content = _buildEmpty(theme);
    } else {
      content = RefreshIndicator(
        onRefresh: _loadStandings,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          itemCount: _groups.length,
          itemBuilder: (context, index) =>
              _buildGroupCard(theme, _groups[index]),
        ),
      );
    }

    if (widget.embedded) return content;

    return Scaffold(
      appBar: AppBar(title: Text(_tr('Groups', 'Grupos'))),
      body: content,
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(
              _tr('Could not load standings', 'No se pudo cargar la tabla'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? _tr('Unknown error', 'Error desconocido'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStandings,
              icon: const Icon(Icons.refresh),
              label: Text(S.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 56,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              _tr(
                'No standings available yet',
                'Todavía no hay tabla disponible',
              ),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _tr(
                'The World Cup groups will appear here once SportMonks publishes the standings.',
                'Los grupos del Mundial aparecerán aquí cuando SportMonks publique la tabla.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(ThemeData theme, _WorldCupGroupStandings group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 60,
                columns: [
                  DataColumn(label: Text(_tr('#', '#'))),
                  DataColumn(label: Text(_tr('Team', 'Equipo'))),
                  DataColumn(numeric: true, label: Text(_tr('P', 'PJ'))),
                  DataColumn(numeric: true, label: Text('W')),
                  DataColumn(numeric: true, label: Text('D')),
                  DataColumn(numeric: true, label: Text('L')),
                  DataColumn(numeric: true, label: Text('GF')),
                  DataColumn(numeric: true, label: Text('GA')),
                  DataColumn(numeric: true, label: Text('GD')),
                  DataColumn(numeric: true, label: Text(_tr('Pts', 'Pts'))),
                ],
                rows: group.rows.map((row) => _buildRow(theme, row)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(ThemeData theme, _StandingRow row) {
    return DataRow(
      cells: [
        DataCell(Text('${row.position}')),
        DataCell(
          SizedBox(
            width: 180,
            child: Row(
              children: [
                _TeamLogo(url: row.logoUrl),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    CountryNameLocalizer.localize(context, row.teamName),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text('${row.played}')),
        DataCell(Text('${row.won}')),
        DataCell(Text('${row.drawn}')),
        DataCell(Text('${row.lost}')),
        DataCell(Text('${row.goalsFor}')),
        DataCell(Text('${row.goalsAgainst}')),
        DataCell(Text('${row.goalDifference}')),
        DataCell(
          Text(
            '${row.points}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamLogo extends StatelessWidget {
  final String? url;

  const _TeamLogo({this.url});

  @override
  Widget build(BuildContext context) {
    final resolved = url;
    if (resolved == null || resolved.isEmpty) {
      return const CircleAvatar(radius: 14, child: Icon(Icons.flag, size: 14));
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: resolved,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            const CircleAvatar(radius: 14, child: Icon(Icons.flag, size: 14)),
      ),
    );
  }
}

class _WorldCupGroupStandings {
  final String name;
  final List<_StandingRow> rows;

  const _WorldCupGroupStandings({required this.name, required this.rows});
}

class _StandingRow {
  final int position;
  final String teamName;
  final String? logoUrl;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const _StandingRow({
    required this.position,
    required this.teamName,
    required this.logoUrl,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });
}
