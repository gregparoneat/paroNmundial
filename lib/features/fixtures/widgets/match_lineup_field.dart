import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/features/fixtures/models/completed_match.dart';
import 'package:flutter/material.dart';

/// Soccer field widget showing both team lineups for a completed match
class MatchLineupField extends StatelessWidget {
  final TeamLineup? homeLineup;
  final TeamLineup? awayLineup;
  final Function(PlayerMatchPerformance player)? onPlayerTap;
  
  const MatchLineupField({
    super.key,
    this.homeLineup,
    this.awayLineup,
    this.onPlayerTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1B5E20), // Dark green
            const Color(0xFF2E7D32), // Medium green
            const Color(0xFF1B5E20), // Dark green (for away half)
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Field markings
            CustomPaint(
              size: const Size(double.infinity, 700),
              painter: _FullFieldPainter(),
            ),
            
            // Players overlay
            SizedBox(
              height: 700,
              child: Column(
                children: [
                  // Away team (top half - attacking down)
                  Expanded(
                    child: _buildTeamHalf(
                      awayLineup,
                      isHome: false,
                    ),
                  ),
                  
                  // Divider with team names
                  _buildCenterLine(context),
                  
                  // Home team (bottom half - attacking up)
                  Expanded(
                    child: _buildTeamHalf(
                      homeLineup,
                      isHome: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCenterLine(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (homeLineup != null) ...[
            Text(
              homeLineup!.teamName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white38,
              shape: BoxShape.circle,
            ),
          ),
          if (awayLineup != null) ...[
            const SizedBox(width: 8),
            Text(
              awayLineup!.teamName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTeamHalf(TeamLineup? lineup, {required bool isHome}) {
    if (lineup == null) {
      return const Center(
        child: Text(
          'Lineup unavailable',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    
    // Parse formation to get total number of lines
    // e.g., "4-3-3" = 3 outfield lines + GK = 4 total lines
    // e.g., "4-2-3-1" = 4 outfield lines + GK = 5 total lines
    final totalLines = _getTotalLinesFromFormation(lineup.formation);
    
    // Group players by their formation_field line
    final playersByLine = <int, List<PlayerMatchPerformance>>{};
    
    for (final player in lineup.starters) {
      final line = player.formationLine ?? _inferLineFromPosition(player.position, totalLines);
      playersByLine.putIfAbsent(line, () => []).add(player);
    }
    
    // Sort players within each line by their horizontal position (formationPosition)
    for (final line in playersByLine.keys) {
      playersByLine[line]!.sort((a, b) {
        final posA = a.formationPosition ?? 1;
        final posB = b.formationPosition ?? 1;
        return posA.compareTo(posB);
      });
    }
    
    // Get all unique lines and sort them
    final lines = playersByLine.keys.toList()..sort();
    
    // Build rows for each line
    // For home team: highest line (attackers) at top, GK at bottom
    // For away team: GK at top, attackers at bottom (near center line)
    final orderedLines = isHome ? lines.reversed.toList() : lines;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: orderedLines.map((line) {
          final players = playersByLine[line] ?? [];
          final positionLabel = _getPositionLabelForLine(line, totalLines);
          return Expanded(
            child: _buildPositionRow(players, positionLabel),
          );
        }).toList(),
      ),
    );
  }
  
  /// Get total number of lines from formation string
  /// e.g., "4-3-3" = 4 lines (GK + 3 outfield), "4-2-3-1" = 5 lines (GK + 4 outfield)
  int _getTotalLinesFromFormation(String formation) {
    final parts = formation.split('-');
    // Number of dashes + 1 = number of outfield lines, plus 1 for GK
    return parts.length + 1;
  }
  
  /// Infer formation line from position string (fallback if formation_field is missing)
  int _inferLineFromPosition(String position, int totalLines) {
    switch (position.toUpperCase()) {
      case 'GK':
        return 1;
      case 'DEF':
        return 2;
      case 'MID':
        // Middle lines - roughly in the center
        return (totalLines / 2).ceil();
      case 'FWD':
        return totalLines; // Last line is always forwards
      default:
        return (totalLines / 2).ceil(); // Default to midfield
    }
  }
  
  /// Get position label for display based on formation line and total lines
  /// Line 1 = GK, Line 2 = DEF, Last line = FWD, everything else = MID
  String _getPositionLabelForLine(int line, int totalLines) {
    if (line == 1) {
      return 'GK';
    } else if (line == 2) {
      return 'DEF';
    } else if (line == totalLines) {
      return 'FWD';
    } else {
      return 'MID';
    }
  }
  
  Widget _buildPositionRow(List<PlayerMatchPerformance> players, String position) {
    if (players.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Spread players across the full width of the field
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: players.map((player) => _buildPlayerWidget(player, position)).toList(),
    );
  }
  
  Widget _buildPlayerWidget(PlayerMatchPerformance player, String linePosition) {
    // Use player's actual position for color coding (more accurate)
    final position = player.position;
    
    return GestureDetector(
      onTap: onPlayerTap != null ? () => onPlayerTap!(player) : null,
      // Use FittedBox to scale down the content if it doesn't fit
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating badge (above avatar)
            if (player.rating != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: Color(player.ratingColorValue),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  player.formattedRating,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            // Player avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getPositionColor(position),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: player.playerImageUrl != null && player.playerImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: player.playerImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildInitials(player.playerName),
                        errorWidget: (_, __, ___) => _buildInitials(player.playerName),
                      )
                    : _buildInitials(player.playerName),
              ),
            ),
            
            const SizedBox(height: 2),
            
            // Player name
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getPositionColor(position).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getShortName(player.playerName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            // Goal/assist indicators
            if (player.goals > 0 || player.assists > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (player.goals > 0)
                      ...List.generate(
                        player.goals > 3 ? 3 : player.goals,
                        (_) => const Text('⚽', style: TextStyle(fontSize: 8)),
                      ),
                    if (player.assists > 0)
                      ...List.generate(
                        player.assists > 3 ? 3 : player.assists,
                        (_) => const Text('🅰️', style: TextStyle(fontSize: 8)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInitials(String name) {
    final initials = name
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
          fontSize: 14,
        ),
      ),
    );
  }
  
  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length <= 1) return fullName;
    final lastName = parts.last;
    return lastName.length <= 10 ? lastName : parts.first;
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

/// Custom painter for full soccer field with both halves
class _FullFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // Field border
    canvas.drawRect(
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
      paint,
    );

    // Center line
    canvas.drawLine(
      Offset(10, size.height / 2),
      Offset(size.width - 10, size.height / 2),
      paint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      50,
      paint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      5,
      dotPaint,
    );

    // Top penalty area (away team's goal end)
    final penaltyWidth = size.width * 0.55;
    final penaltyHeight = size.height * 0.12;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, 10 + penaltyHeight / 2),
        width: penaltyWidth,
        height: penaltyHeight,
      ),
      paint,
    );

    // Top goal area
    final goalAreaWidth = size.width * 0.3;
    final goalAreaHeight = size.height * 0.05;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, 10 + goalAreaHeight / 2),
        width: goalAreaWidth,
        height: goalAreaHeight,
      ),
      paint,
    );

    // Top penalty arc
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, 10 + penaltyHeight),
        width: 60,
        height: 40,
      ),
      0,
      3.14,
      false,
      paint,
    );

    // Bottom penalty area (home team's goal end)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 10 - penaltyHeight / 2),
        width: penaltyWidth,
        height: penaltyHeight,
      ),
      paint,
    );

    // Bottom goal area
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 10 - goalAreaHeight / 2),
        width: goalAreaWidth,
        height: goalAreaHeight,
      ),
      paint,
    );

    // Bottom penalty arc
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 10 - penaltyHeight),
        width: 60,
        height: 40,
      ),
      3.14,
      3.14,
      false,
      paint,
    );

    // Corner arcs
    const cornerRadius = 12.0;
    
    // Top-left
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(10, 10), radius: cornerRadius),
      0, 1.57, false, paint,
    );
    
    // Top-right
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width - 10, 10), radius: cornerRadius),
      1.57, 1.57, false, paint,
    );
    
    // Bottom-left
    canvas.drawArc(
      Rect.fromCircle(center: Offset(10, size.height - 10), radius: cornerRadius),
      -1.57, 1.57, false, paint,
    );
    
    // Bottom-right
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width - 10, size.height - 10), radius: cornerRadius),
      3.14, 1.57, false, paint,
    );

    // Grass stripes effect (subtle)
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 14; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(10, 10 + (i * (size.height - 20) / 14), size.width - 20, (size.height - 20) / 14),
          stripePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

