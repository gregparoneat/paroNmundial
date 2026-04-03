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

  /// Get the position type for a given slot position string
  static PlayerPosition? getPositionType(String position) {
    switch (position.toUpperCase()) {
      case 'GK':
        return PlayerPosition.goalkeeper;
      case 'DEF':
        return PlayerPosition.defender;
      case 'MID':
        return PlayerPosition.midfielder;
      case 'FWD':
        return PlayerPosition.attacker;
      default:
        return null;
    }
  }

  /// Check if a player can be placed in a position slot
  static bool canPlayerFillSlot(FantasyTeamPlayer player, String slotPosition) {
    final slotType = getPositionType(slotPosition);
    if (slotType == null) return false;

    // Forward position accepts both forward and attacker
    if (slotPosition.toUpperCase() == 'FWD') {
      return player.position == PlayerPosition.forward ||
          player.position == PlayerPosition.attacker;
    }

    return player.position == slotType;
  }
}

/// Soccer field widget to display team formation with drag-and-drop support
class SoccerFieldWidget extends StatefulWidget {
  final List<FantasyTeamPlayer> players;
  final Formation formation;
  final Function(String position, int slotIndex)? onSlotTap;
  final Function(FantasyTeamPlayer player)? onPlayerTap;

  /// Called when players are swapped via drag-and-drop
  /// Parameters: (draggedPlayer, targetPlayer or null, targetPosition, targetSlotIndex)
  final Function(
    FantasyTeamPlayer draggedPlayer,
    FantasyTeamPlayer? targetPlayer,
    String targetPosition,
    int targetSlotIndex,
  )?
  onPlayerSwap;
  final bool isEditable;
  final double? height;
  final bool showPredictedPoints;

  const SoccerFieldWidget({
    super.key,
    required this.players,
    this.formation = Formation.f433,
    this.onSlotTap,
    this.onPlayerTap,
    this.onPlayerSwap,
    this.isEditable = false,
    this.height,
    this.showPredictedPoints = false,
  });

  @override
  State<SoccerFieldWidget> createState() => _SoccerFieldWidgetState();
}

class _SoccerFieldWidgetState extends State<SoccerFieldWidget> {
  FantasyTeamPlayer? _draggedPlayer;
  String? _highlightedPosition;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 450,
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
            CustomPaint(size: Size.infinite, painter: _FieldPainter()),

            // Players on field
            _buildFormationLayout(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationLayout(BuildContext context) {
    // Get players by position - maintain original order within each position group
    final goalkeepers = widget.players
        .where((p) => p.position == PlayerPosition.goalkeeper)
        .toList();
    final defenders = widget.players
        .where((p) => p.position == PlayerPosition.defender)
        .toList();
    final midfielders = widget.players
        .where((p) => p.position == PlayerPosition.midfielder)
        .toList();
    final forwards = widget.players
        .where(
          (p) =>
              p.position == PlayerPosition.attacker ||
              p.position == PlayerPosition.forward,
        )
        .toList();

    // Get formation requirements
    final requiredDef = widget.formation.lines[0];
    final requiredMid = widget.formation.lines[1];
    final requiredFwd = widget.formation.lines[2];

    // Show slots based on formation, fill with available players
    // Extra players of a position beyond the formation requirement won't be shown on field
    // (they should be moved to bench by the user)
    final displayedGoalkeepers = goalkeepers.take(1).toList();
    final displayedDefenders = defenders.take(requiredDef).toList();
    final displayedMidfielders = midfielders.take(requiredMid).toList();
    final displayedForwards = forwards.take(requiredFwd).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // Forwards (top)
          Expanded(
            flex: 2,
            child: _buildPositionRow('FWD', requiredFwd, displayedForwards),
          ),

          // Midfielders
          Expanded(
            flex: 2,
            child: _buildPositionRow('MID', requiredMid, displayedMidfielders),
          ),

          // Defenders
          Expanded(
            flex: 2,
            child: _buildPositionRow('DEF', requiredDef, displayedDefenders),
          ),

          // Goalkeeper (bottom)
          Expanded(
            flex: 1,
            child: _buildPositionRow('GK', 1, displayedGoalkeepers),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionRow(
    String position,
    int slots,
    List<FantasyTeamPlayer> positionPlayers,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(slots, (index) {
        final player = index < positionPlayers.length
            ? positionPlayers[index]
            : null;
        return _buildPlayerSlot(position, index, player);
      }),
    );
  }

  Widget _buildPlayerSlot(
    String position,
    int slotIndex,
    FantasyTeamPlayer? player,
  ) {
    final isEmpty = player == null;
    final isHighlighted = _highlightedPosition == '$position-$slotIndex';

    // Build the base slot content (never reassigned)
    final baseSlotContent = _buildSlotContent(
      position,
      player,
      isEmpty,
      isHighlighted,
    );

    // If not editable or no swap handler, just return the base content
    if (!widget.isEditable || widget.onPlayerSwap == null) {
      return baseSlotContent;
    }

    // Build draggable content for non-empty slots
    Widget draggableContent;
    if (!isEmpty) {
      draggableContent = Draggable<FantasyTeamPlayer>(
        data: player,
        onDragStarted: () {
          setState(() => _draggedPlayer = player);
        },
        onDragEnd: (_) {
          setState(() {
            _draggedPlayer = null;
            _highlightedPosition = null;
          });
        },
        feedback: Material(
          color: Colors.transparent,
          child: Opacity(opacity: 0.8, child: _buildDragFeedback(player)),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: baseSlotContent),
        child: baseSlotContent,
      );
    } else {
      draggableContent = baseSlotContent;
    }

    // Wrap with drag target for drop functionality
    return DragTarget<FantasyTeamPlayer>(
      onWillAcceptWithDetails: (details) {
        final canAccept = Formation.canPlayerFillSlot(details.data, position);
        if (canAccept) {
          setState(() => _highlightedPosition = '$position-$slotIndex');
        }
        return canAccept;
      },
      onLeave: (_) {
        setState(() => _highlightedPosition = null);
      },
      onAcceptWithDetails: (details) {
        setState(() {
          _highlightedPosition = null;
          _draggedPlayer = null;
        });
        // Swap the players
        widget.onPlayerSwap!(details.data, player, position, slotIndex);
      },
      builder: (context, candidateData, rejectedData) {
        final isValidTarget = candidateData.isNotEmpty;
        return Transform.scale(
          scale: isValidTarget ? 1.1 : 1.0,
          child: draggableContent,
        );
      },
    );
  }

  Widget _buildDragFeedback(FantasyTeamPlayer player) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getPositionColor(_getPositionString(player.position)),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: ClipOval(
        child:
            player.playerImageUrl != null && player.playerImageUrl!.isNotEmpty
            ? Image.network(player.playerImageUrl!, fit: BoxFit.cover)
            : Center(
                child: Text(
                  _getInitials(player.playerName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
      ),
    );
  }

  String _getPositionString(PlayerPosition position) {
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Widget _buildSlotContent(
    String position,
    FantasyTeamPlayer? player,
    bool isEmpty,
    bool isHighlighted,
  ) {
    return GestureDetector(
      onTap: () {
        if (isEmpty && widget.isEditable && widget.onSlotTap != null) {
          widget.onSlotTap!(position, 0);
        } else if (!isEmpty && widget.onPlayerTap != null) {
          widget.onPlayerTap!(player!);
        }
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Player avatar with overlay badges
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Player avatar or empty slot
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEmpty
                          ? (isHighlighted
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.white24)
                          : _getPositionColor(position),
                      border: Border.all(
                        color: isHighlighted
                            ? Colors.greenAccent
                            : (isEmpty ? Colors.white38 : Colors.white),
                        width: isHighlighted ? 3 : 2,
                      ),
                      boxShadow: isEmpty
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: isEmpty
                        ? Icon(
                            widget.isEditable
                                ? Icons.add
                                : Icons.person_outline,
                            color: isHighlighted
                                ? Colors.greenAccent
                                : Colors.white54,
                            size: 20,
                          )
                        : ClipOval(
                            child:
                                player!.playerImageUrl != null &&
                                    player.playerImageUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: player.playerImageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        _buildInitialsWidget(player),
                                    errorWidget: (_, __, ___) =>
                                        _buildInitialsWidget(player),
                                  )
                                : _buildInitialsWidget(player),
                          ),
                  ),

                  // Predicted points badge (top-right of avatar)
                  if (!isEmpty &&
                      widget.showPredictedPoints &&
                      player!.predictedPoints > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _getPredictedPointsColor(
                            player.effectivePredictedPoints,
                          ),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          player.effectivePredictedPoints.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Captain/Vice-captain badge (bottom-right of avatar)
                  if (player != null &&
                      (player.isCaptain || player.isViceCaptain))
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: player.isCaptain ? Colors.amber : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 2),
                          ],
                        ),
                        child: Text(
                          player.isCaptain ? 'C' : 'VC',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 3),

              // Player name or position label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isEmpty
                      ? Colors.black38
                      : _getPositionColor(position).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isEmpty ? position : _getShortName(player!.playerName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get color based on predicted points (green for high, yellow for medium, red for low)
  Color _getPredictedPointsColor(double points) {
    if (points >= 8) return Colors.green.shade600;
    if (points >= 5) return Colors.amber.shade700;
    if (points >= 3) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  Widget _buildInitialsWidget(FantasyTeamPlayer player) {
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
          fontSize: 14,
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
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40, paint);

    // Center dot
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 4, dotPaint);

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
        center: Offset(
          size.width / 2,
          size.height - 10 - bottomPenaltyHeight / 2,
        ),
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
      Rect.fromCircle(
        center: Offset(size.width - 10, size.height - 10),
        radius: 15,
      ),
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
  final bool compact;

  const BenchWidget({
    super.key,
    required this.benchPlayers,
    this.onPlayerTap,
    this.isEditable = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompactBench(theme);
    }

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
              Icon(
                Icons.airline_seat_recline_normal,
                size: 18,
                color: bgTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Substitutes (${benchPlayers.length}/7)',
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
              children: benchPlayers
                  .map((player) => _buildBenchPlayer(player, theme))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactBench(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.airline_seat_recline_normal, size: 14, color: bgTextColor),
          const SizedBox(width: 4),
          Text(
            'Bench:',
            style: TextStyle(
              fontSize: 11,
              color: bgTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: benchPlayers
                    .map((player) => _buildCompactBenchPlayer(player, theme))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBenchPlayer(FantasyTeamPlayer player, ThemeData theme) {
    return GestureDetector(
      onTap: onPlayerTap != null ? () => onPlayerTap!(player) : null,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getPositionColor(player.position),
                  width: 1.2,
                ),
              ),
              child: ClipOval(
                child:
                    player.playerImageUrl != null &&
                        player.playerImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: player.playerImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildBenchInitials(player),
                        errorWidget: (_, __, ___) =>
                            _buildBenchInitials(player),
                      )
                    : _buildBenchInitials(player),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              player.playerName.split(' ').last,
              style: const TextStyle(color: Colors.white, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPositionColor(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return Colors.orange;
      case PlayerPosition.defender:
        return Colors.blue;
      case PlayerPosition.midfielder:
        return Colors.green;
      case PlayerPosition.attacker:
      case PlayerPosition.forward:
        return Colors.red;
    }
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
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getPositionColor(player.position),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child:
                    player.playerImageUrl != null &&
                        player.playerImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: player.playerImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _buildBenchInitials(player),
                        errorWidget: (_, __, ___) =>
                            _buildBenchInitials(player),
                      )
                    : _buildBenchInitials(player),
              ),
            ),
            const SizedBox(width: 8),

            // Player info
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    player.playerName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    player.teamName ?? 'Unknown',
                    style: TextStyle(fontSize: 10, color: bgTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenchInitials(FantasyTeamPlayer player) {
    return Container(
      color: _getPositionColor(player.position),
      alignment: Alignment.center,
      child: Text(
        _getPositionAbbr(player.position),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
