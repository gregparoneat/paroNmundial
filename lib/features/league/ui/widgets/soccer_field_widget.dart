import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:flutter/material.dart';

/// Available formations for the starting XI
enum Formation {
  f442('4-4-2', [4, 4, 2]),
  f433('4-3-3', [4, 3, 3]),
  f352('3-5-2', [3, 5, 2]),
  f451('4-5-1', [4, 5, 1]),
  f343('3-4-3', [3, 4, 3]),
  f532('5-3-2', [5, 3, 2]),
  f541('5-4-1', [5, 4, 1]);

  final String name;
  final List<int> lines; // DEF, MID, FWD

  const Formation(this.name, this.lines);
}

/// Soccer field widget to display team formation
class SoccerFieldWidget extends StatelessWidget {
  final List<FantasyTeamPlayer> players;
  final Formation formation;
  final Function(String position, int slotIndex)? onSlotTap;
  final Function(FantasyTeamPlayer player)? onPlayerTap;
  final bool isEditable;
  final double? height;

  const SoccerFieldWidget({
    super.key,
    required this.players,
    this.formation = Formation.f433,
    this.onSlotTap,
    this.onPlayerTap,
    this.isEditable = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 450,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1B5E20), // Dark green
            const Color(0xFF2E7D32), // Medium green
            const Color(0xFF388E3C), // Light green
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
              size: Size.infinite,
              painter: _FieldPainter(),
            ),
            
            // Players on field
            _buildFormationLayout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationLayout(BuildContext context) {
    // Get players by position
    final goalkeepers = players.where((p) => p.position == PlayerPosition.goalkeeper).toList();
    final defenders = players.where((p) => p.position == PlayerPosition.defender).toList();
    final midfielders = players.where((p) => p.position == PlayerPosition.midfielder).toList();
    final forwards = players.where((p) => 
        p.position == PlayerPosition.attacker || p.position == PlayerPosition.forward).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // Forwards (top)
          Expanded(
            flex: 2,
            child: _buildPositionRow(
              'FWD',
              formation.lines[2],
              forwards,
            ),
          ),
          
          // Midfielders
          Expanded(
            flex: 2,
            child: _buildPositionRow(
              'MID',
              formation.lines[1],
              midfielders,
            ),
          ),
          
          // Defenders
          Expanded(
            flex: 2,
            child: _buildPositionRow(
              'DEF',
              formation.lines[0],
              defenders,
            ),
          ),
          
          // Goalkeeper (bottom)
          Expanded(
            flex: 1,
            child: _buildPositionRow(
              'GK',
              1,
              goalkeepers.take(1).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionRow(String position, int slots, List<FantasyTeamPlayer> positionPlayers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(slots, (index) {
        final player = index < positionPlayers.length ? positionPlayers[index] : null;
        return _buildPlayerSlot(position, index, player);
      }),
    );
  }

  Widget _buildPlayerSlot(String position, int slotIndex, FantasyTeamPlayer? player) {
    final isEmpty = player == null;
    
    return GestureDetector(
      onTap: () {
        if (isEmpty && isEditable && onSlotTap != null) {
          onSlotTap!(position, slotIndex);
        } else if (!isEmpty && onPlayerTap != null) {
          onPlayerTap!(player);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player avatar or empty slot
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEmpty 
                  ? Colors.white24 
                  : _getPositionColor(position),
              border: Border.all(
                color: isEmpty 
                    ? Colors.white38 
                    : Colors.white,
                width: 2,
              ),
              boxShadow: isEmpty ? null : [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isEmpty
                ? Icon(
                    isEditable ? Icons.add : Icons.person_outline,
                    color: Colors.white54,
                    size: 24,
                  )
                : ClipOval(
                    child: player!.playerImageUrl != null && player.playerImageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: player.playerImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _buildInitials(player),
                            errorWidget: (_, __, ___) => _buildInitials(player),
                          )
                        : _buildInitials(player),
                  ),
          ),
          
          const SizedBox(height: 4),
          
          // Player name or position label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isEmpty 
                  ? Colors.black38 
                  : _getPositionColor(position).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isEmpty ? position : _getShortName(player!.playerName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Captain/Vice-captain badge
          if (player != null && (player.isCaptain || player.isViceCaptain))
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: player.isCaptain ? Colors.amber : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.isCaptain ? 'C' : 'VC',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInitials(FantasyTeamPlayer player) {
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
          fontSize: 16,
        ),
      ),
    );
  }

  String _getShortName(String fullName) {
    final parts = fullName.split(' ');
    if (parts.length <= 1) return fullName;
    // Return last name or first if last is too long
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
      case 'ATT':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }
}

/// Custom painter for soccer field markings
class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
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
      40,
      paint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      dotPaint,
    );

    // Top penalty area
    final topPenaltyWidth = size.width * 0.5;
    final topPenaltyHeight = size.height * 0.15;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, 10 + topPenaltyHeight / 2),
        width: topPenaltyWidth,
        height: topPenaltyHeight,
      ),
      paint,
    );

    // Bottom penalty area (goal area)
    final bottomPenaltyWidth = size.width * 0.5;
    final bottomPenaltyHeight = size.height * 0.15;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 10 - bottomPenaltyHeight / 2),
        width: bottomPenaltyWidth,
        height: bottomPenaltyHeight,
      ),
      paint,
    );

    // Small goal areas
    final goalAreaWidth = size.width * 0.25;
    final goalAreaHeight = size.height * 0.06;
    
    // Top goal area
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width / 2, 10 + goalAreaHeight / 2),
        width: goalAreaWidth,
        height: goalAreaHeight,
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

    // Corner arcs
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Top-left corner
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(10, 10), radius: 15),
      0,
      1.57,
      false,
      arcPaint,
    );

    // Top-right corner
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width - 10, 10), radius: 15),
      1.57,
      1.57,
      false,
      arcPaint,
    );

    // Bottom-left corner
    canvas.drawArc(
      Rect.fromCircle(center: Offset(10, size.height - 10), radius: 15),
      -1.57,
      1.57,
      false,
      arcPaint,
    );

    // Bottom-right corner
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width - 10, size.height - 10), radius: 15),
      3.14,
      1.57,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Bench widget to display substitute players
class BenchWidget extends StatelessWidget {
  final List<FantasyTeamPlayer> benchPlayers;
  final Function(FantasyTeamPlayer player)? onPlayerTap;
  final bool isEditable;

  const BenchWidget({
    super.key,
    required this.benchPlayers,
    this.onPlayerTap,
    this.isEditable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.airline_seat_recline_normal, size: 18, color: bgTextColor),
              const SizedBox(width: 8),
              Text(
                'Substitutes (${benchPlayers.length}/4)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: bgTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (benchPlayers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No substitutes selected',
                  style: TextStyle(color: bgTextColor),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: benchPlayers.map((player) => _buildBenchPlayer(player, theme)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBenchPlayer(FantasyTeamPlayer player, ThemeData theme) {
    return GestureDetector(
      onTap: onPlayerTap != null ? () => onPlayerTap!(player) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Position badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _getPositionColor(player.position),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getPositionAbbr(player.position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Player info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.playerName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  player.teamName ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 10,
                    color: bgTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return Colors.orange.shade700;
      case PlayerPosition.defender:
        return Colors.blue.shade700;
      case PlayerPosition.midfielder:
        return Colors.green.shade700;
      case PlayerPosition.attacker:
      case PlayerPosition.forward:
        return Colors.red.shade700;
    }
  }

  String _getPositionAbbr(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return 'GK';
      case PlayerPosition.defender:
        return 'DEF';
      case PlayerPosition.midfielder:
        return 'MID';
      case PlayerPosition.attacker:
      case PlayerPosition.forward:
        return 'FWD';
    }
  }
}

/// Formation selector widget
class FormationSelector extends StatelessWidget {
  final Formation selectedFormation;
  final Function(Formation) onFormationChanged;

  const FormationSelector({
    super.key,
    required this.selectedFormation,
    required this.onFormationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: Formation.values.length,
        itemBuilder: (context, index) {
          final formation = Formation.values[index];
          final isSelected = formation == selectedFormation;
          
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == Formation.values.length - 1 ? 0 : 4,
            ),
            child: FilterChip(
              label: Text(
                formation.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : bgTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onFormationChanged(formation),
              backgroundColor: bgColor,
              selectedColor: theme.primaryColor,
              checkmarkColor: Colors.white,
              side: BorderSide.none,
            ),
          );
        },
      ),
    );
  }
}

