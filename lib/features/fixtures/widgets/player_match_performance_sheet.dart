import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/fixtures/models/completed_match.dart';
import 'package:flutter/material.dart';

/// Bottom sheet showing detailed player performance for a specific match
class PlayerMatchPerformanceSheet extends StatelessWidget {
  final PlayerMatchPerformance player;
  
  const PlayerMatchPerformanceSheet({
    super.key,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Player header
                    _buildPlayerHeader(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Match info
                    _buildMatchInfo(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Key stats
                    _buildKeyStats(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Detailed stats sections
                    if (_hasAttackingStats()) ...[
                      _buildStatSection('Attacking', _getAttackingStats(), theme),
                      const SizedBox(height: 16),
                    ],
                    
                    if (_hasPassingStats()) ...[
                      _buildStatSection('Passing', _getPassingStats(), theme),
                      const SizedBox(height: 16),
                    ],
                    
                    if (_hasDefensiveStats()) ...[
                      _buildStatSection('Defensive', _getDefensiveStats(), theme),
                      const SizedBox(height: 16),
                    ],
                    
                    if (_hasDuelStats()) ...[
                      _buildStatSection('Duels', _getDuelStats(), theme),
                      const SizedBox(height: 16),
                    ],
                    
                    if (player.position == 'GK') ...[
                      _buildStatSection('Goalkeeping', _getGoalkeepingStats(), theme),
                      const SizedBox(height: 16),
                    ],
                    
                    // Discipline
                    if (player.yellowCards > 0 || player.redCards > 0) ...[
                      _buildStatSection('Discipline', _getDisciplineStats(), theme),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPlayerHeader(ThemeData theme) {
    return Row(
      children: [
        // Player avatar
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getPositionColor(player.position),
            border: Border.all(color: Colors.white24, width: 3),
          ),
          child: ClipOval(
            child: player.playerImageUrl != null && player.playerImageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: player.playerImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildInitials(theme),
                    errorWidget: (_, __, ___) => _buildInitials(theme),
                  )
                : _buildInitials(theme),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Player info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.playerName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      player.teamName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Rating
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(player.ratingColorValue).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(player.ratingColorValue).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            children: [
              Text(
                player.formattedRating,
                style: TextStyle(
                  color: Color(player.ratingColorValue),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RATING',
                style: TextStyle(
                  color: Color(player.ratingColorValue),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInitials(ThemeData theme) {
    final initials = player.playerName
        .split(' ')
        .take(2)
        .map((s) => s.isNotEmpty ? s[0] : '')
        .join()
        .toUpperCase();
    
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
    );
  }
  
  Widget _buildMatchInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMatchInfoItem(
            Icons.access_time,
            '${player.minutesPlayed}\'',
            'Minutes',
            theme,
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade700,
          ),
          _buildMatchInfoItem(
            player.isStarter ? Icons.play_arrow : Icons.airline_seat_recline_normal,
            player.isStarter ? 'Starter' : 'Sub',
            'Status',
            theme,
          ),
          if (player.jerseyNumber != null) ...[
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade700,
            ),
            _buildMatchInfoItem(
              Icons.tag,
              '#${player.jerseyNumber}',
              'Number',
              theme,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMatchInfoItem(IconData icon, String value, String label, ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildKeyStats(ThemeData theme) {
    // Display position-specific key stats
    final position = player.position.toUpperCase();
    
    if (position == 'GK') {
      // Goalkeeper: Saves, Goals Conceded (via saves context), Minutes
      return Row(
        children: [
          Expanded(
            child: _buildKeyStat(
              '🧤',
              player.saves.toString(),
              'Saves',
              player.saves > 0 ? Colors.orange : Colors.grey,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKeyStat(
              '⏱️',
              '${player.minutesPlayed}\'',
              'Minutes',
              player.minutesPlayed > 0 ? Colors.blue : Colors.grey,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKeyStat(
              '🎯',
              player.passAccuracy != null ? '${player.passAccuracy}%' : '-',
              'Pass %',
              player.passAccuracy != null && player.passAccuracy! > 70 ? Colors.green : Colors.grey,
              theme,
            ),
          ),
        ],
      );
    } else if (position == 'DEF') {
      // Defender: Tackles, Interceptions, Clearances
      return Row(
        children: [
          Expanded(
            child: _buildKeyStat(
              '🦵',
              player.tackles?.toString() ?? '-',
              'Tackles',
              player.tackles != null && player.tackles! > 0 ? Colors.blue : Colors.grey,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKeyStat(
              '🔄',
              player.interceptions?.toString() ?? '-',
              'Intercepts',
              player.interceptions != null && player.interceptions! > 0 ? Colors.green : Colors.grey,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKeyStat(
              '🧹',
              player.clearances?.toString() ?? '-',
              'Clearances',
              player.clearances != null && player.clearances! > 0 ? Colors.purple : Colors.grey,
              theme,
            ),
          ),
        ],
      );
    } else if (position == 'MID') {
      // Midfielder: Key Passes, Pass Accuracy, Goals+Assists
      return Row(
        children: [
          Expanded(
            child: _buildKeyStat(
              '🎯',
              player.keyPasses?.toString() ?? '-',
              'Key Passes',
              player.keyPasses != null && player.keyPasses! > 0 ? Colors.green : Colors.grey,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKeyStat(
              '📊',
              player.passAccuracy != null ? '${player.passAccuracy}%' : '-',
              'Pass %',
              player.passAccuracy != null && player.passAccuracy! > 80 ? Colors.blue : Colors.grey,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKeyStat(
              '⚽',
              (player.goals + player.assists).toString(),
              'G+A',
              player.goalContributions > 0 ? Colors.purple : Colors.grey,
              theme,
            ),
          ),
        ],
      );
    } else {
      // Forward: Goals, Assists, Shots on Target
      return Row(
        children: [
          Expanded(
            child: _buildKeyStat(
              '⚽',
              player.goals.toString(),
              'Goals',
              player.goals > 0 ? Colors.green : Colors.grey,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKeyStat(
              '🅰️',
              player.assists.toString(),
              'Assists',
              player.assists > 0 ? Colors.blue : Colors.grey,
              theme,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildKeyStat(
              '🎯',
              player.shotsOnTarget?.toString() ?? '-',
              'On Target',
              player.shotsOnTarget != null && player.shotsOnTarget! > 0 ? Colors.purple : Colors.grey,
              theme,
            ),
          ),
        ],
      );
    }
  }
  
  Widget _buildKeyStat(String emoji, String value, String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatSection(String title, List<_StatItem> stats, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.map((stat) => _buildStatRow(stat, theme)),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(_StatItem stat, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (stat.icon != null) ...[
            Icon(stat.icon, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              stat.label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            stat.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: stat.highlight ? theme.primaryColor : null,
            ),
          ),
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
  
  // Stat checks
  bool _hasAttackingStats() {
    return player.shotsTotal != null || 
           player.shotsOnTarget != null || 
           player.goals > 0;
  }
  
  bool _hasPassingStats() {
    return player.passes != null || 
           player.keyPasses != null ||
           player.crosses != null;
  }
  
  bool _hasDefensiveStats() {
    return player.tackles != null || 
           player.interceptions != null ||
           player.clearances != null;
  }
  
  bool _hasDuelStats() {
    return player.duelsWon != null || 
           player.aerialsWon != null;
  }
  
  // Stat getters
  List<_StatItem> _getAttackingStats() {
    return [
      if (player.goals > 0)
        _StatItem('Goals', player.goals.toString(), highlight: true),
      if (player.assists > 0)
        _StatItem('Assists', player.assists.toString(), highlight: true),
      if (player.shotsTotal != null)
        _StatItem('Shots', player.shotsTotal.toString()),
      if (player.shotsOnTarget != null)
        _StatItem('Shots on Target', player.shotsOnTarget.toString()),
      if (player.offsides != null && player.offsides! > 0)
        _StatItem('Offsides', player.offsides.toString()),
    ];
  }
  
  List<_StatItem> _getPassingStats() {
    return [
      if (player.passes != null)
        _StatItem('Passes', player.passes.toString()),
      if (player.passAccuracy != null)
        _StatItem('Pass Accuracy', '${player.passAccuracy}%'),
      if (player.keyPasses != null)
        _StatItem('Key Passes', player.keyPasses.toString()),
      if (player.crosses != null)
        _StatItem('Crosses', player.crosses.toString()),
      if (player.crossesAccurate != null)
        _StatItem('Accurate Crosses', player.crossesAccurate.toString()),
      if (player.longBalls != null)
        _StatItem('Long Balls', player.longBalls.toString()),
    ];
  }
  
  List<_StatItem> _getDefensiveStats() {
    return [
      if (player.tackles != null)
        _StatItem('Tackles', player.tackles.toString()),
      if (player.interceptions != null)
        _StatItem('Interceptions', player.interceptions.toString()),
      if (player.clearances != null)
        _StatItem('Clearances', player.clearances.toString()),
      if (player.blocks != null)
        _StatItem('Blocks', player.blocks.toString()),
    ];
  }
  
  List<_StatItem> _getDuelStats() {
    return [
      if (player.duelsWon != null && player.duelsTotal != null)
        _StatItem('Duels Won', '${player.duelsWon}/${player.duelsTotal}'),
      if (player.aerialsWon != null)
        _StatItem('Aerials Won', player.aerialsWon.toString()),
      if (player.dribbles != null)
        _StatItem('Dribble Attempts', player.dribbles.toString()),
      if (player.dribblesWon != null)
        _StatItem('Successful Dribbles', player.dribblesWon.toString()),
      if (player.fouls != null)
        _StatItem('Fouls Committed', player.fouls.toString()),
      if (player.foulsDrawn != null)
        _StatItem('Fouls Won', player.foulsDrawn.toString()),
    ];
  }
  
  List<_StatItem> _getGoalkeepingStats() {
    return [
      _StatItem('Saves', player.saves.toString(), highlight: player.saves > 0),
      if (player.passes != null)
        _StatItem('Passes', player.passes.toString()),
      if (player.passAccuracy != null)
        _StatItem('Pass Accuracy', '${player.passAccuracy}%'),
    ];
  }
  
  List<_StatItem> _getDisciplineStats() {
    return [
      if (player.yellowCards > 0)
        _StatItem('Yellow Cards', player.yellowCards.toString(), icon: Icons.square, iconColor: Colors.yellow),
      if (player.redCards > 0)
        _StatItem('Red Cards', player.redCards.toString(), icon: Icons.square, iconColor: Colors.red),
    ];
  }
}

class _StatItem {
  final String label;
  final String value;
  final bool highlight;
  final IconData? icon;
  final Color? iconColor;
  
  const _StatItem(this.label, this.value, {this.highlight = false, this.icon, this.iconColor});
}

