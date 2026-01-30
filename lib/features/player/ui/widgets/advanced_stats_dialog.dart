import 'package:flutter/material.dart';
import 'package:fantacy11/features/fantasy/fantasy_points_predictor.dart';
import 'package:fantacy11/generated/l10n.dart';

/// Dialog that displays detailed advanced statistics for a player
/// Shows metrics like key passes, tackles, interceptions, shot accuracy, etc.
class AdvancedStatsDialog extends StatelessWidget {
  final RecentMatchStats stats;
  final String playerName;
  final String? positionCode;

  const AdvancedStatsDialog({
    super.key,
    required this.stats,
    required this.playerName,
    this.positionCode,
  });

  /// Show the dialog
  static Future<void> show(
    BuildContext context, {
    required RecentMatchStats stats,
    required String playerName,
    String? positionCode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedStatsDialog(
        stats: stats,
        playerName: playerName,
        positionCode: positionCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final advanced = stats.advancedStats;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Statistics',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$playerName • Last ${stats.matchesPlayed} matches',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Stats content
          Flexible(
            child: advanced == null
                ? _buildNoAdvancedStats(context, theme)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Basic stats summary
                        _buildBasicStatsSummary(context, theme),
                        const SizedBox(height: 20),
                        
                        // Attacking stats
                        _buildSection(
                          context, theme,
                          title: '⚽ Attacking',
                          icon: Icons.sports_soccer,
                          color: Colors.red,
                          stats: _getAttackingStats(advanced),
                        ),
                        
                        // Creative stats
                        _buildSection(
                          context, theme,
                          title: '🎯 Creativity',
                          icon: Icons.lightbulb,
                          color: Colors.orange,
                          stats: _getCreativeStats(advanced),
                        ),
                        
                        // Passing stats
                        _buildSection(
                          context, theme,
                          title: '📊 Passing',
                          icon: Icons.compare_arrows,
                          color: Colors.blue,
                          stats: _getPassingStats(advanced),
                        ),
                        
                        // Defensive stats
                        _buildSection(
                          context, theme,
                          title: '🛡️ Defensive',
                          icon: Icons.shield,
                          color: Colors.green,
                          stats: _getDefensiveStats(advanced),
                        ),
                        
                        // Duels & Physical
                        _buildSection(
                          context, theme,
                          title: '💪 Duels & Physical',
                          icon: Icons.fitness_center,
                          color: Colors.purple,
                          stats: _getDuelStats(advanced),
                        ),
                        
                        // Discipline
                        _buildSection(
                          context, theme,
                          title: '📋 Discipline',
                          icon: Icons.gavel,
                          color: Colors.amber,
                          stats: _getDisciplineStats(advanced),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Rating breakdown
                        if (advanced.ratings.isNotEmpty)
                          _buildRatingBreakdown(context, theme, advanced),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoAdvancedStats(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Advanced Stats Available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detailed statistics will appear here once the player has recent match data with advanced metrics.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBasicStatsSummary(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Summary',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(theme, 'Games', stats.matchesPlayed.toString(), Icons.sports_soccer),
              _buildSummaryItem(theme, 'Goals', stats.goals.toString(), Icons.sports_score),
              _buildSummaryItem(theme, 'Assists', stats.assists.toString(), Icons.handshake),
              _buildSummaryItem(theme, 'Mins', stats.minutesPlayed.toString(), Icons.timer),
            ],
          ),
          if (stats.averageRating != null && stats.averageRating! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getRatingColor(stats.averageRating!).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: _getRatingColor(stats.averageRating!), size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Avg Rating: ${stats.averageRating!.toStringAsFixed(2)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _getRatingColor(stats.averageRating!),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSummaryItem(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSection(
    BuildContext context,
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Color color,
    required List<_StatItem> stats,
  }) {
    // Filter out zero values for cleaner display
    final nonZeroStats = stats.where((s) => s.value != '0' && s.value != '0.0%' && s.value != '0%').toList();
    
    if (nonZeroStats.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: nonZeroStats.map((stat) => _buildStatChip(theme, stat, color)).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatChip(ThemeData theme, _StatItem stat, Color accentColor) {
    final isHighlight = stat.isHighlight;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlight 
            ? accentColor.withValues(alpha: 0.2)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? accentColor : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            stat.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight ? accentColor : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingBreakdown(BuildContext context, ThemeData theme, AdvancedStats advanced) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Match Ratings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: advanced.ratings.asMap().entries.map((entry) {
              final rating = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRatingColor(rating).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getRatingColor(rating)),
                ),
                child: Text(
                  rating.toStringAsFixed(1),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getRatingColor(rating),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.green[700]!;
    if (rating >= 7.0) return Colors.green;
    if (rating >= 6.5) return Colors.amber[700]!;
    if (rating >= 6.0) return Colors.orange;
    return Colors.red;
  }
  
  // Stat getters
  List<_StatItem> _getAttackingStats(AdvancedStats advanced) {
    return [
      _StatItem('Shots', advanced.shotsTotal.toString(), isHighlight: advanced.shotsTotal > 5),
      _StatItem('On Target', advanced.shotsOnTarget.toString(), isHighlight: advanced.shotsOnTarget > 3),
      _StatItem('Off Target', advanced.shotsOffTarget.toString()),
      _StatItem('Shot Acc.', '${advanced.shotAccuracy.toStringAsFixed(1)}%', isHighlight: advanced.shotAccuracy > 50),
      _StatItem('Hit Woodwork', advanced.hitWoodwork.toString()),
      _StatItem('Hattricks', advanced.hattricks.toString(), isHighlight: advanced.hattricks > 0),
    ];
  }
  
  List<_StatItem> _getCreativeStats(AdvancedStats advanced) {
    return [
      _StatItem('Key Passes', advanced.keyPasses.toString(), isHighlight: advanced.keyPasses > 5),
      _StatItem('Big Chances', advanced.bigChancesCreated.toString(), isHighlight: advanced.bigChancesCreated > 2),
      _StatItem('Big Misses', advanced.bigChancesMissed.toString()),
      _StatItem('Crosses', advanced.totalCrosses.toString()),
      _StatItem('Acc. Crosses', advanced.accurateCrosses.toString(), isHighlight: advanced.accurateCrosses > 3),
      _StatItem('Cross Acc.', '${advanced.crossAccuracy.toStringAsFixed(1)}%'),
      _StatItem('Through Balls', advanced.throughBalls.toString()),
    ];
  }
  
  List<_StatItem> _getPassingStats(AdvancedStats advanced) {
    return [
      _StatItem('Total Passes', advanced.totalPasses.toString()),
      _StatItem('Accurate', advanced.accuratePasses.toString()),
      _StatItem('Pass Acc.', '${advanced.passAccuracy.toStringAsFixed(1)}%', isHighlight: advanced.passAccuracy > 85),
      _StatItem('Long Balls', advanced.longBalls.toString()),
      _StatItem('Long Won', advanced.longBallsWon.toString()),
      _StatItem('Long Acc.', '${advanced.longBallSuccessRate.toStringAsFixed(1)}%'),
    ];
  }
  
  List<_StatItem> _getDefensiveStats(AdvancedStats advanced) {
    return [
      _StatItem('Tackles', advanced.tackles.toString(), isHighlight: advanced.tackles > 10),
      _StatItem('Interceptions', advanced.interceptions.toString(), isHighlight: advanced.interceptions > 5),
      _StatItem('Clearances', advanced.clearances.toString(), isHighlight: advanced.clearances > 10),
      _StatItem('Blocks', advanced.blocks.toString(), isHighlight: advanced.blocks > 3),
      _StatItem('Dribbled Past', advanced.dribbledPast.toString()),
      _StatItem('Errors to Goal', advanced.errorLeadToGoal.toString(), isHighlight: advanced.errorLeadToGoal > 0),
      // Goalkeeper stats
      if (advanced.saves > 0)
        _StatItem('Saves', advanced.saves.toString(), isHighlight: true),
      if (advanced.savesInsideBox > 0)
        _StatItem('Saves (Box)', advanced.savesInsideBox.toString(), isHighlight: true),
      if (advanced.goalsConceeded > 0)
        _StatItem('Goals Conceeded', advanced.goalsConceeded.toString()),
    ];
  }
  
  List<_StatItem> _getDuelStats(AdvancedStats advanced) {
    return [
      _StatItem('Total Duels', advanced.totalDuels.toString()),
      _StatItem('Duels Won', advanced.duelsWon.toString(), isHighlight: advanced.duelsWon > 15),
      _StatItem('Duel Rate', '${advanced.duelSuccessRate.toStringAsFixed(1)}%', isHighlight: advanced.duelSuccessRate > 55),
      _StatItem('Aerials Won', advanced.aerialsWon.toString(), isHighlight: advanced.aerialsWon > 5),
      _StatItem('Dispossessed', advanced.dispossessed.toString()),
    ];
  }
  
  List<_StatItem> _getDisciplineStats(AdvancedStats advanced) {
    return [
      _StatItem('Fouls', advanced.fouls.toString()),
      _StatItem('Fouls Drawn', advanced.foulsDrawn.toString(), isHighlight: advanced.foulsDrawn > 5),
      _StatItem('Offsides', advanced.offsides.toString()),
      _StatItem('Yellow Cards', stats.yellowCards.toString()),
      _StatItem('Red Cards', stats.redCards.toString(), isHighlight: stats.redCards > 0),
    ];
  }
}

class _StatItem {
  final String label;
  final String value;
  final bool isHighlight;
  
  _StatItem(this.label, this.value, {this.isHighlight = false});
}

