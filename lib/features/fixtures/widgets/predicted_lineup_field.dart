import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/features/fixtures/models/predicted_lineup.dart';
import 'package:flutter/material.dart';

/// Soccer field widget showing predicted lineups for an upcoming match
class PredictedLineupField extends StatelessWidget {
  final PredictedLineup? homeLineup;
  final PredictedLineup? awayLineup;
  final Function(PredictedPlayer player)? onPlayerTap;
  
  const PredictedLineupField({
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
            const Color(0xFF1B5E20),
            const Color(0xFF2E7D32),
            const Color(0xFF1B5E20),
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
            
            // "Predicted" banner
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'PREDICTED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Players overlay
            SizedBox(
              height: 700,
              child: Column(
                children: [
                  // Away team (top half)
                  Expanded(
                    child: _buildTeamHalf(awayLineup, isHome: false),
                  ),
                  
                  // Divider with team names and formations
                  _buildCenterLine(context),
                  
                  // Home team (bottom half)
                  Expanded(
                    child: _buildTeamHalf(homeLineup, isHome: true),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (homeLineup != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  homeLineup!.teamName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      homeLineup!.predictedFormation,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildConfidenceBadge(homeLineup!.formationConfidence),
                  ],
                ),
              ],
            )
          else
            const SizedBox.shrink(),
          
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white38,
              shape: BoxShape.circle,
            ),
          ),
          
          if (awayLineup != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  awayLineup!.teamName,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    _buildConfidenceBadge(awayLineup!.formationConfidence),
                    const SizedBox(width: 4),
                    Text(
                      awayLineup!.predictedFormation,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
  
  Widget _buildConfidenceBadge(double confidence) {
    Color color;
    if (confidence >= 0.7) {
      color = Colors.green;
    } else if (confidence >= 0.4) {
      color = Colors.amber;
    } else {
      color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${(confidence * 100).toInt()}%',
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildTeamHalf(PredictedLineup? lineup, {required bool isHome}) {
    if (lineup == null || !lineup.hasPrediction) {
      return const Center(
        child: Text(
          'Prediction unavailable',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    
    // Parse formation to get total number of lines
    final totalLines = _getTotalLinesFromFormation(lineup.predictedFormation);
    
    // Group players by their formation line if available, otherwise by position
    final playersByLine = <int, List<PredictedPlayer>>{};
    
    for (final player in lineup.starters) {
      // Use formation line if available, otherwise infer from position
      final line = player.formationLine ?? _inferLineFromPosition(player.position, totalLines);
      playersByLine.putIfAbsent(line, () => []).add(player);
    }
    
    // Sort players within each line by their horizontal position
    for (final line in playersByLine.keys) {
      playersByLine[line]!.sort((a, b) {
        final posA = a.formationPosition ?? 1;
        final posB = b.formationPosition ?? 1;
        return posA.compareTo(posB);
      });
    }
    
    // Get all unique lines and sort them
    final lines = playersByLine.keys.toList()..sort();
    
    // Order for display (home: attackers top, away: GK top)
    final orderedLines = isHome ? lines.reversed.toList() : lines;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: orderedLines.map((line) {
          final players = playersByLine[line] ?? [];
          return Expanded(
            child: _buildPositionRow(players),
          );
        }).toList(),
      ),
    );
  }
  
  /// Get total number of lines from formation string
  int _getTotalLinesFromFormation(String formation) {
    final parts = formation.split('-');
    return parts.length + 1; // +1 for goalkeeper
  }
  
  /// Infer formation line from position string (fallback)
  int _inferLineFromPosition(String position, int totalLines) {
    switch (position.toUpperCase()) {
      case 'GK':
        return 1;
      case 'DEF':
        return 2;
      case 'MID':
        return (totalLines / 2).ceil();
      case 'FWD':
        return totalLines;
      default:
        return (totalLines / 2).ceil();
    }
  }
  
  Widget _buildPositionRow(List<PredictedPlayer> players) {
    if (players.isEmpty) return const SizedBox.shrink();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: players.map((player) => 
        FittedBox(
          fit: BoxFit.scaleDown,
          child: _buildPlayerWidget(player),
        ),
      ).toList(),
    );
  }
  
  Widget _buildPlayerWidget(PredictedPlayer player) {
    return GestureDetector(
      onTap: onPlayerTap != null ? () => onPlayerTap!(player) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Confidence badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              color: Color(player.confidenceColorValue),
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
              '${(player.confidence * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Player avatar with returning indicator
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getPositionColor(player.position),
                  border: Border.all(
                    color: player.isReturningFromInjury || player.isReturningFromSuspension
                        ? Colors.amber
                        : Colors.white,
                    width: 2,
                  ),
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
              
              // Returning indicator
              if (player.isReturningFromInjury || player.isReturningFromSuspension)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: player.isReturningFromInjury ? Colors.green : Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      player.isReturningFromInjury ? Icons.healing : Icons.gavel,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 2),
          
          // Player name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPositionColor(player.position).withOpacity(0.9),
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
          
          // Start frequency
          Text(
            '${player.startCount}/${player.totalMatches}',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 8,
            ),
          ),
        ],
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

/// Custom painter for full soccer field
class _FullFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

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
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      5,
      dotPaint,
    );

    // Penalty areas
    final penaltyWidth = size.width * 0.55;
    final penaltyHeight = size.height * 0.12;
    
    // Top
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, 10 + penaltyHeight / 2),
        width: penaltyWidth,
        height: penaltyHeight,
      ),
      paint,
    );
    
    // Bottom
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 10 - penaltyHeight / 2),
        width: penaltyWidth,
        height: penaltyHeight,
      ),
      paint,
    );

    // Goal areas
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
    
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 10 - goalAreaHeight / 2),
        width: goalAreaWidth,
        height: goalAreaHeight,
      ),
      paint,
    );

    // Grass stripes
    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
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

