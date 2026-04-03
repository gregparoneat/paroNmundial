import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/fixtures/models/predicted_lineup.dart';
import 'package:fantacy11/features/fixtures/services/lineup_prediction_service.dart';
import 'package:fantacy11/features/fixtures/widgets/predicted_lineup_field.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Page showing predicted lineups for an upcoming match
class UpcomingMatchDetailsPage extends StatefulWidget {
  final MatchInfo matchInfo;

  const UpcomingMatchDetailsPage({super.key, required this.matchInfo});

  @override
  State<UpcomingMatchDetailsPage> createState() =>
      _UpcomingMatchDetailsPageState();
}

class _UpcomingMatchDetailsPageState extends State<UpcomingMatchDetailsPage>
    with SingleTickerProviderStateMixin {
  final LineupPredictionService _predictionService = LineupPredictionService();

  PredictedLineup? _homeLineup;
  PredictedLineup? _awayLineup;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPredictions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final matchDate = widget.matchInfo.startingAtTimestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(
              widget.matchInfo.startingAtTimestamp! * 1000,
            )
          : null;

      // Load predictions in parallel
      final results = await Future.wait([
        _predictionService.predictLineup(
          widget.matchInfo.homeTeam?.id ?? 0,
          widget.matchInfo.team1Name,
          teamLogo: widget.matchInfo.team1Logo,
          matchDate: matchDate,
        ),
        _predictionService.predictLineup(
          widget.matchInfo.awayTeam?.id ?? 0,
          widget.matchInfo.team2Name,
          teamLogo: widget.matchInfo.team2Logo,
          matchDate: matchDate,
        ),
      ]);

      setState(() {
        _homeLineup = results[0];
        _awayLineup = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load predictions: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(theme)
          : _buildContent(theme),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPredictions,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: theme.colorScheme.surface,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryColor.withOpacity(0.8),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: SafeArea(child: _buildMatchHeader(theme)),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(text: 'PREDICTED LINEUPS'),
              Tab(text: 'MATCH INFO'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [_buildLineupsTab(theme), _buildMatchInfoTab(theme)],
      ),
    );
  }

  Widget _buildMatchHeader(ThemeData theme) {
    final match = widget.matchInfo;
    final matchTime = match.startingAtTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(match.startingAtTimestamp! * 1000)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          // League name
          Text(
            match.leagueName,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),

          // Teams
          Row(
            children: [
              // Home team
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(match.team1Logo, 56),
                    const SizedBox(height: 8),
                    Text(
                      match.team1Name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // VS and time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            matchTime != null
                                ? DateFormat('HH:mm').format(matchTime)
                                : 'TBD',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            matchTime != null
                                ? DateFormat('EEE, d MMM').format(matchTime)
                                : '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Away team
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(match.team2Logo, 56),
                    const SizedBox(height: 8),
                    Text(
                      match.team2Name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String? logoUrl, double size) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => Icon(Icons.shield, size: size),
        errorWidget: (_, __, ___) => Icon(Icons.shield, size: size),
      );
    }
    return Icon(Icons.shield, size: size);
  }

  Widget _buildLineupsTab(ThemeData theme) {
    final hasPredictions =
        (_homeLineup?.hasPrediction ?? false) ||
        (_awayLineup?.hasPrediction ?? false);

    if (!hasPredictions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No prediction data available',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'We need historical lineup data to make predictions',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadPredictions,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPredictions,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prediction disclaimer
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Predicted lineups based on last ${_homeLineup?.matchesAnalyzed ?? 0} matches. '
                      'Actual lineups may differ.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Predicted lineups field
            PredictedLineupField(
              homeLineup: _homeLineup,
              awayLineup: _awayLineup,
              onPlayerTap: (player) => _showPlayerDetails(player, theme),
            ),

            const SizedBox(height: 24),

            // Returning players section
            if (_hasReturningPlayers()) _buildReturningPlayersSection(theme),

            const SizedBox(height: 16),

            // Bench predictions
            if (_homeLineup != null && _homeLineup!.likelyBench.isNotEmpty) ...[
              _buildBenchSection(
                _homeLineup!.teamName,
                _homeLineup!.likelyBench,
                theme,
              ),
              const SizedBox(height: 16),
            ],

            if (_awayLineup != null && _awayLineup!.likelyBench.isNotEmpty)
              _buildBenchSection(
                _awayLineup!.teamName,
                _awayLineup!.likelyBench,
                theme,
              ),
          ],
        ),
      ),
    );
  }

  bool _hasReturningPlayers() {
    final homeReturning = _homeLineup?.returningPlayers ?? [];
    final awayReturning = _awayLineup?.returningPlayers ?? [];
    return homeReturning.isNotEmpty || awayReturning.isNotEmpty;
  }

  Widget _buildReturningPlayersSection(ThemeData theme) {
    final homeReturning = _homeLineup?.returningPlayers ?? [];
    final awayReturning = _awayLineup?.returningPlayers ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing, size: 18, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Players Returning',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (homeReturning.isNotEmpty) ...[
            Text(
              _homeLineup!.teamName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: homeReturning
                  .map((p) => _buildReturningPlayerChip(p, theme))
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          if (awayReturning.isNotEmpty) ...[
            Text(
              _awayLineup!.teamName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: awayReturning
                  .map((p) => _buildReturningPlayerChip(p, theme))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReturningPlayerChip(PredictedPlayer player, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            player.isReturningFromInjury ? Icons.healing : Icons.gavel,
            size: 14,
            color: player.isReturningFromInjury ? Colors.green : Colors.blue,
          ),
          const SizedBox(width: 6),
          Text(
            player.playerName.split(' ').last,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildBenchSection(
    String teamName,
    List<PredictedPlayer> bench,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.airline_seat_recline_normal, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$teamName - Likely Bench',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bench
                .map((player) => _buildBenchChip(player, theme))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchChip(PredictedPlayer player, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _getPositionColor(player.position),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.position,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            player.playerName.split(' ').last,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInfoTab(ThemeData theme) {
    final match = widget.matchInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Venue info
          if (match.venue != null)
            _buildInfoCard('Venue', Icons.stadium, [
              _InfoRow('Stadium', match.venue!.name),
              if (match.venue!.cityName != null)
                _InfoRow('City', match.venue!.cityName!),
              if (match.venue!.capacity != null)
                _InfoRow('Capacity', '${match.venue!.capacity}'),
              if (match.venue!.surface != null)
                _InfoRow('Surface', match.venue!.surface!),
            ], theme),

          const SizedBox(height: 16),

          // Match info card
          _buildInfoCard('Match', Icons.sports_soccer, [
            _InfoRow('League', match.leagueName),
            _InfoRow('Kickoff', match.formattedDateTime),
          ], theme),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    IconData icon,
    List<_InfoRow> rows,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      row.value,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerDetails(PredictedPlayer player, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Player header
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getPositionColor(player.position),
                  ),
                  child: player.playerImageUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: player.playerImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            player.playerName
                                .split(' ')
                                .take(2)
                                .map((s) => s[0])
                                .join(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.playerName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getPositionColor(player.position),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              player.position,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (player.jerseyNumber != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '#${player.jerseyNumber}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        'Starts',
                        '${player.startCount}/${player.totalMatches}',
                        theme,
                      ),
                      _buildStatColumn(
                        'Start Rate',
                        '${(player.startPercentage * 100).toInt()}%',
                        theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (player.isReturningFromInjury ||
                player.isReturningFromSuspension) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      player.isReturningFromInjury
                          ? Icons.healing
                          : Icons.gavel,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        player.isReturningFromInjury
                            ? 'Returning from injury${player.injuryNote != null ? ": ${player.injuryNote}" : ""}'
                            : 'Returning from suspension',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Color _getPositionColor(String position) {
    switch (position.toUpperCase()) {
      case 'GK':
        return Colors.orange.shade700;
      case 'DEF':
        return Colors.blue.shade700;
      case 'MID':
        return Colors.green.shade700;
      case 'FWD':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}
