import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/fixtures/models/completed_match.dart';
import 'package:fantacy11/features/fixtures/widgets/match_lineup_field.dart';
import 'package:fantacy11/features/fixtures/widgets/player_match_performance_sheet.dart';
import 'package:flutter/material.dart';

/// Page showing detailed match information with lineups and player stats
class MatchDetailsPage extends StatefulWidget {
  final int fixtureId;
  
  const MatchDetailsPage({super.key, required this.fixtureId});

  @override
  State<MatchDetailsPage> createState() => _MatchDetailsPageState();
}

class _MatchDetailsPageState extends State<MatchDetailsPage> with SingleTickerProviderStateMixin {
  final FixturesRepository _repository = FixturesRepository();
  
  CompletedMatch? _match;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMatchDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMatchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final fixtureData = await _repository.getCompletedMatchDetails(widget.fixtureId);
      
      if (fixtureData == null) {
        setState(() {
          _error = 'Match not found';
          _isLoading = false;
        });
        return;
      }
      
      final match = CompletedMatch.fromJson(fixtureData);
      
      setState(() {
        _match = match;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load match details: $e';
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
            onPressed: _loadMatchDetails,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(ThemeData theme) {
    final match = _match!;
    
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        // Custom app bar with match header
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: theme.colorScheme.surface,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.8),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: SafeArea(
                child: _buildMatchHeader(match, theme),
              ),
            ),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: const [
              Tab(text: 'LINEUPS'),
              Tab(text: 'STATS'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabController,
        children: [
          // Lineups tab with soccer field
          _buildLineupsTab(match, theme),
          // Stats tab
          _buildStatsTab(match, theme),
        ],
      ),
    );
  }
  
  Widget _buildMatchHeader(CompletedMatch match, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          // League and venue
          Text(
            match.leagueName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          if (match.venueName != null) ...[
            const SizedBox(height: 4),
            Text(
              '${match.venueName}${match.venueCity != null ? ', ${match.venueCity}' : ''}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white54,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Teams and score
          Row(
            children: [
              // Home team
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(match.homeTeamLogo, 56),
                    const SizedBox(height: 8),
                    Text(
                      match.homeTeamName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: match.isHomeWin ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${match.homeScore}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '-',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: Colors.white54,
                            ),
                          ),
                        ),
                        Text(
                          '${match.awayScore}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'FULL TIME',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Away team
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(match.awayTeamLogo, 56),
                    const SizedBox(height: 8),
                    Text(
                      match.awayTeamName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: match.isAwayWin ? FontWeight.bold : FontWeight.normal,
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
          
          const SizedBox(height: 12),
          
          // Date
          Text(
            match.formattedDate,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTeamLogo(String? logoUrl, double size) {
    if (logoUrl == null || logoUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.shield, size: size * 0.5, color: Colors.white54),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: logoUrl,
      width: size,
      height: size,
      placeholder: (_, __) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      errorWidget: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white24,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.shield, size: size * 0.5, color: Colors.white54),
      ),
    );
  }
  
  Widget _buildLineupsTab(CompletedMatch match, ThemeData theme) {
    if (match.homeLineup == null && match.awayLineup == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'Lineups not available',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Player data for this match is unavailable',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Soccer field with both lineups
          MatchLineupField(
            homeLineup: match.homeLineup,
            awayLineup: match.awayLineup,
            onPlayerTap: (player) => _showPlayerPerformance(player),
          ),
          
          const SizedBox(height: 24),
          
          // Substitutes section
          if (match.homeLineup != null && match.homeLineup!.substitutes.isNotEmpty) ...[
            _buildSubstitutesSection(
              match.homeTeamName,
              match.homeLineup!.substitutes,
              theme,
            ),
            const SizedBox(height: 16),
          ],
          
          if (match.awayLineup != null && match.awayLineup!.substitutes.isNotEmpty) ...[
            _buildSubstitutesSection(
              match.awayTeamName,
              match.awayLineup!.substitutes,
              theme,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSubstitutesSection(
    String teamName,
    List<PlayerMatchPerformance> substitutes,
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
              Text(
                '$teamName - Substitutes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: substitutes.map((player) => _buildSubstituteChip(player, theme)).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubstituteChip(PlayerMatchPerformance player, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showPlayerPerformance(player),
      child: Container(
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
            if (player.rating != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(player.ratingColorValue).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.formattedRating,
                  style: TextStyle(
                    color: Color(player.ratingColorValue),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsTab(CompletedMatch match, ThemeData theme) {
    final allPlayers = <PlayerMatchPerformance>[
      ...?match.homeLineup?.allPlayers,
      ...?match.awayLineup?.allPlayers,
    ];
    
    if (allPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'Stats not available',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Sort by rating
    allPlayers.sort((a, b) {
      final aRating = a.rating ?? 0;
      final bRating = b.rating ?? 0;
      return bRating.compareTo(aRating);
    });
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allPlayers.length,
      itemBuilder: (context, index) {
        final player = allPlayers[index];
        return _buildPlayerStatCard(player, theme);
      },
    );
  }
  
  Widget _buildPlayerStatCard(PlayerMatchPerformance player, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () => _showPlayerPerformance(player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Position badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getPositionColor(player.position),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    player.position,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.playerName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${player.teamName} • ${player.minutesPlayed}\'',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Key stats
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (player.goals > 0)
                    _buildStatBadge('⚽', player.goals.toString(), Colors.green),
                  if (player.assists > 0)
                    _buildStatBadge('🅰️', player.assists.toString(), Colors.blue),
                  if (player.yellowCards > 0)
                    _buildStatBadge('🟨', '', Colors.yellow),
                  if (player.redCards > 0)
                    _buildStatBadge('🟥', '', Colors.red),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(player.ratingColorValue).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.formattedRating,
                  style: TextStyle(
                    color: Color(player.ratingColorValue),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatBadge(String emoji, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          if (value.isNotEmpty) ...[
            const SizedBox(width: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
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
  
  void _showPlayerPerformance(PlayerMatchPerformance player) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerMatchPerformanceSheet(player: player),
    );
  }
}

