import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/player/models/player_info.dart';
import 'package:flutter/material.dart';

class PlayerDetailsPage extends StatefulWidget {
  final Player? player;

  const PlayerDetailsPage({super.key, this.player});

  @override
  State<PlayerDetailsPage> createState() => _PlayerDetailsPageState();
}

class _PlayerDetailsPageState extends State<PlayerDetailsPage> {
  final PlayersRepository _repository = PlayersRepository();
  Player? _player;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.player != null) {
      _player = widget.player;
      _isLoading = false;
    } else {
      _loadDemoPlayer();
    }
  }

  Future<void> _loadDemoPlayer() async {
    try {
      // Uses the repository which falls back to mock data if API not configured
      final player = await _repository.getDemoPlayer();
      if (player != null) {
        setState(() {
          _player = player;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No player data found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load player: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _player == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Player Details'),
        ),
        body: Center(
          child: Text(
            _error ?? 'Player not found',
            style: TextStyle(color: iconColor),
          ),
        ),
      );
    }

    return _PlayerDetailsContent(player: _player!);
  }
}

class _PlayerDetailsContent extends StatelessWidget {
  final Player player;

  const _PlayerDetailsContent({required this.player});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar with player header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back, color: iconColor, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildPlayerHeader(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadedSlideAnimation(
              beginOffset: const Offset(0, 0.1),
              endOffset: Offset.zero,
              slideCurve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats
                    _buildQuickStats(context),
                    const SizedBox(height: 20),

                    // Bio Section
                    _buildBioSection(context),
                    const SizedBox(height: 20),

                    // Career Section
                    if (player.transfers.isNotEmpty) ...[
                      _buildCareerSection(context),
                      const SizedBox(height: 20),
                    ],

                    // Trophies Section
                    if (player.trophies.isNotEmpty) ...[
                      _buildTrophiesSection(context),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader(BuildContext context) {
    var theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            player.position?.color.withValues(alpha: 0.8) ?? theme.primaryColor,
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Player Image
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: player.hasRealImage
                        ? CachedNetworkImage(
                            imageUrl: player.imagePath!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                _buildPlaceholderAvatar(theme),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholderAvatar(theme),
                          )
                        : _buildPlaceholderAvatar(theme),
                  ),
                ),
                // Jersey Number Badge
                if (player.jerseyNumber != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${player.jerseyNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Player Name
            Text(
              player.displayName,
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),

            // Position & Nationality
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (player.position != null) ...[
                  Icon(
                    player.position!.icon,
                    color: player.position!.color,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    player.detailedPosition?.name ?? player.position!.name,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
                if (player.nationality != null) ...[
                  const SizedBox(width: 16),
                  if (player.nationality!.imagePath != null)
                    CachedNetworkImage(
                      imageUrl: player.nationality!.imagePath!,
                      width: 20,
                      height: 14,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    player.nationality!.fifaName ?? player.nationality!.name,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(ThemeData theme) {
    return Container(
      color: bgColor,
      child: Icon(
        Icons.person,
        size: 60,
        color: bgTextColor,
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    var theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Age', '${player.age ?? "-"}', Icons.cake),
          _buildStatDivider(),
          _buildStatItem(
              context, 'Height', player.formattedHeight, Icons.height),
          _buildStatDivider(),
          _buildStatItem(context, 'Weight', player.formattedWeight,
              Icons.fitness_center),
          _buildStatDivider(),
          _buildStatItem(context, 'Trophies', '${player.trophies.length}',
              Icons.emoji_events),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    var theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.primaryColor, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall!.copyWith(
            color: bgTextColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: bgTextColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildBioSection(BuildContext context) {
    var theme = Theme.of(context);

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
              Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Player Info',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, 'Full Name', player.name),
          _buildInfoRow(context, 'Date of Birth', player.dateOfBirth ?? '-'),
          _buildInfoRow(
              context, 'Nationality', player.nationality?.name ?? '-'),
          _buildInfoRow(context, 'Position',
              player.detailedPosition?.name ?? player.position?.name ?? '-'),
          if (player.isCaptain) _buildInfoRow(context, 'Role', '⭐ Captain'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: bgTextColor,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerSection(BuildContext context) {
    var theme = Theme.of(context);

    // Sort transfers by date (newest first)
    final sortedTransfers = List<TransferInfo>.from(player.transfers)
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

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
              Icon(Icons.swap_horiz, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Transfer History',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedTransfers.take(5).map((transfer) => _buildTransferItem(
                context,
                transfer,
              )),
        ],
      ),
    );
  }

  Widget _buildTransferItem(BuildContext context, TransferInfo transfer) {
    var theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Date
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transfer.date ?? '-',
              style: theme.textTheme.bodySmall!.copyWith(
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Transfer info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Team ${transfer.fromTeamId ?? "?"}',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: bgTextColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 12, color: theme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Team ${transfer.toTeamId ?? "?"}',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: bgTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: transfer.amount != null
                  ? theme.primaryColor.withValues(alpha: 0.2)
                  : bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transfer.formattedAmount,
              style: theme.textTheme.bodySmall!.copyWith(
                color: transfer.amount != null ? theme.primaryColor : bgTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophiesSection(BuildContext context) {
    var theme = Theme.of(context);

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
              Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Trophies & Awards',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              player.trophies.length,
              (index) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.3),
                      Colors.orange.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Trophy ${index + 1}',
                      style: theme.textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

