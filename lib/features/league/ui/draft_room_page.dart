import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/services/draft_service.dart';
import 'package:fantacy11/features/player/ui/player_details_page.dart';
import 'package:flutter/material.dart';

/// Draft Room page for live drafting
class DraftRoomPage extends StatefulWidget {
  final League league;

  const DraftRoomPage({super.key, required this.league});

  @override
  State<DraftRoomPage> createState() => _DraftRoomPageState();
}

class _DraftRoomPageState extends State<DraftRoomPage>
    with SingleTickerProviderStateMixin {
  final LeagueRepository _leagueRepository = LeagueRepository();
  final PlayersRepository _playerRepository = PlayersRepository();

  DraftService? _draftService;
  List<LeagueMember> _members = [];
  List<RosterPlayer> _allPlayers = [];
  bool _isLoading = true;
  String? _error;
  String _currentUserId = '';
  final List<int> _queuedPlayerIds = [];

  // Filter state
  PlayerPosition? _positionFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  DraftPlayerSort _sortOption = DraftPlayerSort.projectedPointsHigh;
  bool _isQueueExpanded = false;

  // Tab controller for bottom section
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeDraft();
  }

  @override
  void dispose() {
    _draftService?.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeDraft() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _leagueRepository.init();

      // Get current user
      final currentUser = await _leagueRepository.getCurrentUser();
      _currentUserId = currentUser.oderId;

      // Get league members
      _members = await _leagueRepository.getLeagueMembers(widget.league.id);

      // Load current player pool with a forced refresh so transfers/team moves
      // are reflected in draft mode.
      _allPlayers = await _loadDraftablePlayers();
      if (_allPlayers.isEmpty) {
        // Synthetic fallback should only be used in explicit local test leagues.
        if (widget.league.name.startsWith('TEST:')) {
          _allPlayers = _buildFallbackDraftPool();
        } else {
          throw Exception('Unable to load current player pool for draft.');
        }
      }

      // Initialize draft service
      _draftService = DraftService(
        league: widget.league,
        currentUserId: _currentUserId,
        allPlayers: _allPlayers,
      );

      _draftService!.onDraftComplete = _onDraftComplete;
      _draftService!.onPickMade = _onPickMade;
      _draftService!.addListener(_onDraftStateChanged);
      _draftService!.setUserQueuedPlayers(_queuedPlayerIds);

      // Start the draft
      await _draftService!.startDraft(_members);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize draft: $e';
        _isLoading = false;
      });
    }
  }

  void _onDraftStateChanged() {
    if (mounted) setState(() {});
  }

  void _onDraftComplete() {
    _persistDraftResults().then((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Text('Draft Complete!'),
            ],
          ),
          content: const Text(
            'The draft is complete. All teams have been filled. '
            'Good luck this season!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _exitDraftRoom();
              },
              child: const Text('View My Team'),
            ),
          ],
        ),
      );
    });
  }

  void _onPickMade(DraftPick pick) {
    final wasQueued = _queuedPlayerIds.remove(pick.playerId);
    _draftService?.setUserQueuedPlayers(_queuedPlayerIds);

    if (mounted) {
      final isCurrentUserPick = pick.userId == _currentUserId;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pick.isAutoPick
                ? '⏱️ Auto-pick: ${pick.playerName} to ${pick.userName}'
                : '✅ ${pick.userName} selected ${pick.playerName}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: isCurrentUserPick
              ? Colors.green.shade600
              : const Color(0xFF31414F),
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (wasQueued && !isCurrentUserPick) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A queued player was drafted by another manager and removed from your queue.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _onPlayerSelected(RosterPlayer player) async {
    await _showPlayerDetailsSheet(player);
  }

  Future<void> _navigateToPlayerProfile(RosterPlayer player) async {
    final fullPlayer = await _playerRepository.getPlayerById(player.id);
    if (!mounted) return;

    if (fullPlayer != null) {
      final isQueued = _queuedPlayerIds.contains(player.id);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerDetailsPage(
            player: fullPlayer,
            actions: PlayerDetailsActions(
              isQueued: isQueued,
              canPrimaryAction: _draftService?.isMyTurn ?? false,
              primaryLabel: (_draftService?.isMyTurn ?? false)
                  ? 'Draft Player'
                  : 'Wait For Turn',
              primaryIcon: (_draftService?.isMyTurn ?? false)
                  ? Icons.gavel
                  : Icons.hourglass_top,
              onToggleQueue: () {
                _toggleQueue(player);
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              onPrimaryAction: (_draftService?.isMyTurn ?? false)
                  ? () async {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      final success = await _draftService!.makePick(player);
                      if (!mounted) return;
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Unable to draft that player.'),
                          ),
                        );
                      }
                    }
                  : null,
            ),
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not load player details')),
    );
  }

  Future<void> _showPlayerDetailsSheet(RosterPlayer player) async {
    if (_draftService == null) return;

    final canDraft = _draftService!.isMyTurn;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final isQueued = _queuedPlayerIds.contains(player.id);
        final stats = player.stats ?? const <String, dynamic>{};
        final appearances = stats['appearances']?.toString() ?? 'N/A';
        final goals = stats['goals']?.toString() ?? '0';
        final assists = stats['assists']?.toString() ?? '0';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: player.imagePath != null
                            ? CachedNetworkImageProvider(player.imagePath!)
                            : null,
                        child: player.imagePath == null
                            ? Text(player.displayName.substring(0, 1))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.displayName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${player.teamName} • ${player.positionCode}',
                              style: TextStyle(color: bgTextColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildDetailChip(
                        'Next Match',
                        player.projectedPoints.toStringAsFixed(1),
                      ),
                      _buildDetailChip(
                        'Season Projection',
                        player.projectedSeasonPoints.toStringAsFixed(1),
                      ),
                      _buildDetailChip('Price', player.formattedPrice),
                      _buildDetailChip(
                        'Selected',
                        '${player.selectedByPercent.toStringAsFixed(1)}%',
                      ),
                      _buildDetailChip(
                        'Jersey',
                        player.jerseyNumber?.toString() ?? 'N/A',
                      ),
                      _buildDetailChip('Appearances', appearances),
                      _buildDetailChip('Goals', goals),
                      _buildDetailChip('Assists', assists),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Auto-pick priority is driven by season-based projected points, with roster-balance checks layered on top.',
                    style: TextStyle(color: bgTextColor),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _toggleQueue(player);
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            isQueued
                                ? Icons.playlist_remove
                                : Icons.playlist_add,
                          ),
                          label: Text(
                            isQueued ? 'Remove Queue' : 'Queue Player',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: canDraft
                              ? () async {
                                  Navigator.pop(context);
                                  final success = await _draftService!.makePick(
                                    player,
                                  );
                                  if (!success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to draft player'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: Icon(canDraft ? Icons.gavel : Icons.schedule),
                          label: Text(
                            canDraft ? 'Draft Player' : 'Wait For Turn',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getPositionColor(String positionName) {
    final lower = positionName.toLowerCase();
    if (lower.contains('goalkeeper') || lower.contains('gk')) {
      return Colors.amber;
    } else if (lower.contains('defender') || lower.contains('def')) {
      return Colors.blue;
    } else if (lower.contains('midfielder') || lower.contains('mid')) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Room')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Draft Room')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeDraft,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with timer and pick info
            _buildDraftHeader(theme),

            // Main content
            Expanded(
              child: Column(
                children: [
                  // Tab bar
                  Container(
                    color: theme.colorScheme.surface,
                    child: TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Available'),
                        Tab(text: 'Draft Board'),
                        Tab(text: 'My Team'),
                      ],
                      labelColor: theme.primaryColor,
                      unselectedLabelColor: bgTextColor,
                      indicatorColor: theme.primaryColor,
                    ),
                  ),

                  // Tab content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAvailablePlayersTab(theme),
                        _buildDraftBoardTab(theme),
                        _buildMyTeamTab(theme),
                      ],
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

  Widget _buildDraftHeader(ThemeData theme) {
    final isMyTurn = _draftService?.isMyTurn ?? false;
    final remainingSeconds = _draftService?.remainingSeconds ?? 0;
    final currentRound = _draftService?.currentRound ?? 1;
    final overallPick = _draftService?.overallPickNumber ?? 1;
    final totalPicks = _draftService?.totalPicks ?? 0;
    final turnsUntilMyPick = _getTurnsUntilMyNextPick();

    // Get current picker name
    final currentPickerId = _draftService?.currentPickingUserId;
    final currentPicker = _members
        .where((m) => m.oderId == currentPickerId)
        .firstOrNull;
    final pickerName = currentPicker?.userName ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isMyTurn
              ? [theme.primaryColor, theme.primaryColor.withValues(alpha: 0.7)]
              : [bgColor, bgColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Top row with back button and league name
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => _showExitConfirmation(),
              ),
              Expanded(
                child: Text(
                  widget.league.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),

          const SizedBox(height: 16),

          // Timer and pick info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Timer
              Column(
                children: [
                  Text(
                    _formatTime(remainingSeconds),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: remainingSeconds <= 10 ? Colors.red : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'Time Left',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),

              // Divider
              Container(width: 1, height: 50, color: Colors.white24),

              // Current picker
              Column(
                children: [
                  Text(
                    isMyTurn ? 'YOUR PICK!' : pickerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isMyTurn ? Colors.white : Colors.white70,
                      fontWeight: isMyTurn
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    'Round $currentRound • Pick $overallPick/$totalPicks',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (isMyTurn) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '🎯 Select a player from the Available tab',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ] else if (turnsUntilMyPick != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatTurnsUntilPick(turnsUntilMyPick),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  int? _getTurnsUntilMyNextPick() {
    final draftService = _draftService;
    if (draftService == null || _currentUserId.isEmpty) return null;
    if (draftService.isDraftComplete || !draftService.isDraftInProgress) {
      return null;
    }
    if (draftService.isMyTurn) return 0;

    final configuredOrder = widget.league.draftSettings?.draftOrder ?? const [];
    final draftOrder = configuredOrder.isNotEmpty
        ? configuredOrder
        : _members.map((member) => member.oderId).toList();
    if (draftOrder.isEmpty) return null;

    final currentOverallPick = draftService.overallPickNumber;
    final totalPicks = draftService.totalPicks;
    final orderType =
        widget.league.draftSettings?.orderType ?? DraftOrderType.snake;

    for (
      var overallPick = currentOverallPick;
      overallPick <= totalPicks;
      overallPick++
    ) {
      final (round, pickInRound) = DraftOrderCalculator.getRoundAndPick(
        overallPick: overallPick,
        teamsCount: draftOrder.length,
      );
      final userId = DraftOrderCalculator.getPickingUser(
        draftOrder: draftOrder,
        round: round,
        pickInRound: pickInRound,
        orderType: orderType,
      );
      if (userId == _currentUserId) {
        return overallPick - currentOverallPick;
      }
    }

    return null;
  }

  String _formatTurnsUntilPick(int turnsUntilMyPick) {
    if (turnsUntilMyPick <= 0) {
      return 'Your pick is on the clock';
    }
    if (turnsUntilMyPick == 1) {
      return '1 turn until your next pick';
    }
    return '$turnsUntilMyPick turns until your next pick';
  }

  Widget _buildAvailablePlayersTab(ThemeData theme) {
    final players = _getFilteredPlayers();

    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(12),
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search players...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: bgColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),

              const SizedBox(height: 8),

              // Position filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(theme, null, 'All'),
                    _buildFilterChip(theme, PlayerPosition.goalkeeper, 'GK'),
                    _buildFilterChip(theme, PlayerPosition.defender, 'DEF'),
                    _buildFilterChip(theme, PlayerPosition.midfielder, 'MID'),
                    _buildFilterChip(theme, PlayerPosition.attacker, 'FWD'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Sort by',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: bgTextColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<DraftPlayerSort>(
                    value: _sortOption,
                    underline: const SizedBox.shrink(),
                    items: DraftPlayerSort.values
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(option.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sortOption = value);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_queuedPlayerIds.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Queue',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    setState(() => _isQueueExpanded = !_isQueueExpanded);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${_queuedPlayerIds.length} queued',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: bgTextColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isQueueExpanded ? 'Hide queue' : 'Show queue',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _isQueueExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: bgTextColor,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isQueueExpanded) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Drag to reorder auto-pick priority',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: bgTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _queuedPlayerIds.length,
                    onReorder: _reorderQueue,
                    itemBuilder: (context, index) {
                      final player = _allPlayers
                          .where((p) => p.id == _queuedPlayerIds[index])
                          .firstOrNull;
                      if (player == null) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        key: ValueKey(player.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          onTap: () => _navigateToPlayerProfile(player),
                          onLongPress: () => _onPlayerSelected(player),
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: Icon(Icons.drag_handle, color: bgTextColor),
                          ),
                          title: Text(
                            player.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${player.positionCode} • ${player.projectedPoints.toStringAsFixed(1)} next • ${player.projectedSeasonPoints.toStringAsFixed(1)} season',
                            style: TextStyle(color: bgTextColor),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white70,
                            ),
                            onPressed: () => _toggleQueue(player),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

        // Player list
        Expanded(
          child: players.isEmpty
              ? Center(
                  child: Text(
                    'No players available',
                    style: TextStyle(color: bgTextColor),
                  ),
                )
              : ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) =>
                      _buildPlayerTile(theme, players[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    ThemeData theme,
    PlayerPosition? position,
    String label,
  ) {
    final isSelected = _positionFilter == position;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _positionFilter = selected ? position : null);
        },
        selectedColor: theme.primaryColor.withValues(alpha: 0.3),
        checkmarkColor: theme.primaryColor,
        labelStyle: TextStyle(color: isSelected ? theme.primaryColor : null),
      ),
    );
  }

  Widget _buildPlayerTile(ThemeData theme, RosterPlayer player) {
    final isMyTurn = _draftService?.isMyTurn ?? false;
    final isQueued = _queuedPlayerIds.contains(player.id);

    return ListTile(
      onTap: () => _navigateToPlayerProfile(player),
      leading: CircleAvatar(
        backgroundImage: player.imagePath != null
            ? CachedNetworkImageProvider(player.imagePath!)
            : null,
        child: player.imagePath == null
            ? Text(player.displayName.substring(0, 1))
            : null,
      ),
      title: Text(
        player.displayName,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isMyTurn ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        '${player.teamName} • ${player.position} • ${player.projectedPoints.toStringAsFixed(1)} next • ${player.projectedSeasonPoints.toStringAsFixed(1)} season',
        style: TextStyle(color: bgTextColor),
      ),
      trailing: SizedBox(
        width: 156,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _toggleQueue(player),
              icon: Icon(
                isQueued ? Icons.playlist_add_check : Icons.playlist_add,
                color: isQueued ? theme.primaryColor : bgTextColor,
                size: 20,
              ),
              tooltip: isQueued ? 'Remove from queue' : 'Add to queue',
            ),
            IconButton(
              onPressed: () => _onPlayerSelected(player),
              icon: Icon(Icons.more_horiz, color: bgTextColor, size: 20),
              tooltip: 'Player actions',
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getPositionColor(
                  player.position,
                ).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                player.positionCode,
                style: TextStyle(
                  color: _getPositionColor(player.position),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftBoardTab(ThemeData theme) {
    final picks = _draftService?.draftState.picks ?? [];

    if (picks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: bgTextColor),
            const SizedBox(height: 16),
            Text(
              'No picks yet',
              style: theme.textTheme.titleMedium?.copyWith(color: bgTextColor),
            ),
            Text(
              'Picks will appear here as they are made',
              style: theme.textTheme.bodySmall?.copyWith(color: bgTextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: picks.length,
      itemBuilder: (context, index) {
        final pick = picks[picks.length - 1 - index]; // Show newest first
        final isMyPick = pick.userId == _currentUserId;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMyPick
                ? theme.primaryColor.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: isMyPick
                ? Border.all(color: theme.primaryColor, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Pick number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${pick.pickNumber}',
                    style: theme.textTheme.titleSmall?.copyWith(
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
                      pick.playerName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${pick.teamName ?? ''} • ${pick.position.abbreviation}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: bgTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Picker name
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isMyPick ? 'You' : pick.userName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isMyPick ? theme.primaryColor : null,
                    ),
                  ),
                  Text(
                    'Round ${pick.round}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: bgTextColor,
                      fontSize: 10,
                    ),
                  ),
                  if (pick.isAutoPick)
                    Text(
                      '⏱️ Auto',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyTeamTab(ThemeData theme) {
    final myPicks = _draftService?.myPicks ?? [];
    final rosterSize = _draftService?.rosterSize ?? 18;

    // Group picks by position
    final byPosition = <PlayerPosition, List<DraftPick>>{};
    for (final pick in myPicks) {
      byPosition.putIfAbsent(pick.position, () => []).add(pick);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(theme, '${myPicks.length}', 'Drafted'),
                _buildStatColumn(theme, '$rosterSize', 'Roster Size'),
                _buildStatColumn(
                  theme,
                  '${rosterSize - myPicks.length}',
                  'Remaining',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Roster by position
          for (final position in [
            PlayerPosition.goalkeeper,
            PlayerPosition.defender,
            PlayerPosition.midfielder,
            PlayerPosition.attacker,
          ]) ...[
            _buildPositionSection(theme, position, byPosition[position] ?? []),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: bgTextColor),
        ),
      ],
    );
  }

  Widget _buildPositionSection(
    ThemeData theme,
    PlayerPosition position,
    List<DraftPick> picks,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(position.colorValue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                position.abbreviation,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              position.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text('${picks.length}', style: TextStyle(color: bgTextColor)),
          ],
        ),

        const SizedBox(height: 8),

        if (picks.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bgTextColor.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                'No ${position.name.toLowerCase()}s drafted yet',
                style: TextStyle(color: bgTextColor),
              ),
            ),
          )
        else
          ...picks.map(
            (pick) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: pick.playerImageUrl != null
                        ? CachedNetworkImageProvider(pick.playerImageUrl!)
                        : null,
                    child: pick.playerImageUrl == null
                        ? Text(pick.playerName.substring(0, 1))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pick.playerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          pick.teamName ?? '',
                          style: TextStyle(color: bgTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'R${pick.round} P${pick.pickNumber}',
                    style: TextStyle(color: bgTextColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  List<RosterPlayer> _getFilteredPlayers() {
    var players = _draftService?.availablePlayers ?? [];

    // Apply position filter
    if (_positionFilter != null) {
      players = players.where((p) {
        final position = _mapPlayerPosition(p.position);
        return position == _positionFilter;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      players = players.where((p) {
        return p.displayName.toLowerCase().contains(query) ||
            p.teamName.toLowerCase().contains(query);
      }).toList();
    }

    players.sort((a, b) {
      switch (_sortOption) {
        case DraftPlayerSort.projectedPointsHigh:
          return b.projectedSeasonPoints.compareTo(a.projectedSeasonPoints);
        case DraftPlayerSort.projectedPointsLow:
          return a.projectedSeasonPoints.compareTo(b.projectedSeasonPoints);
        case DraftPlayerSort.nameAZ:
          return a.displayName.compareTo(b.displayName);
        case DraftPlayerSort.priceHigh:
          return b.price.compareTo(a.price);
      }
    });

    return players;
  }

  PlayerPosition _mapPlayerPosition(String positionName) {
    final lower = positionName.toLowerCase();
    if (lower.contains('goalkeeper') || lower.contains('gk')) {
      return PlayerPosition.goalkeeper;
    } else if (lower.contains('defender') ||
        lower.contains('def') ||
        lower.contains('back')) {
      return PlayerPosition.defender;
    } else if (lower.contains('midfielder') || lower.contains('mid')) {
      return PlayerPosition.midfielder;
    } else {
      return PlayerPosition.attacker;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave Draft?'),
        content: const Text(
          'If you leave, the draft will continue and auto-pick will '
          'select players for you when it\'s your turn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _exitDraftRoom();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _exitDraftRoom() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_draftService?.isDraftComplete ?? false);
    }
  }

  Future<void> _persistDraftResults() async {
    if (_draftService == null || !_draftService!.isDraftComplete) return;

    await _leagueRepository.finalizeDraftResults(
      league: widget.league,
      picks: _draftService!.picks,
      rosterPlayers: _allPlayers,
    );
  }

  void _toggleQueue(RosterPlayer player) {
    setState(() {
      if (_queuedPlayerIds.contains(player.id)) {
        _queuedPlayerIds.remove(player.id);
      } else {
        _queuedPlayerIds.removeWhere((id) => id == player.id);
        _queuedPlayerIds.add(player.id);
      }
    });
    _draftService?.setUserQueuedPlayers(_queuedPlayerIds);
  }

  void _reorderQueue(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final playerId = _queuedPlayerIds.removeAt(oldIndex);
      _queuedPlayerIds.insert(newIndex, playerId);
    });
    _draftService?.setUserQueuedPlayers(_queuedPlayerIds);
  }

  Widget _buildDetailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: bgTextColor, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<List<RosterPlayer>> _loadDraftablePlayers() async {
    final freshPlayers = await _playerRepository.getLigaMxRosterPlayers(
      forceRefresh: true,
    );
    if (freshPlayers.isNotEmpty) {
      return freshPlayers;
    }

    // If refresh fails, try cached/local data before paginated API fallback.
    final cachedPlayers = await _playerRepository.getLigaMxRosterPlayers();
    if (cachedPlayers.isNotEmpty) {
      return cachedPlayers;
    }

    final players = <RosterPlayer>[];
    final seenIds = <int>{};
    int currentTeamIndex = 0;
    int currentPage = 1;
    bool hasMorePlayers = true;

    while (hasMorePlayers) {
      final result = await _playerRepository.getAllPlayersPage(
        teamIndex: currentTeamIndex,
        page: currentPage,
        pageSize: 30,
      );

      for (final player in result.players) {
        if (seenIds.add(player.id)) {
          players.add(player);
        }
      }

      if (result.hasMoreInTeam) {
        currentPage++;
      } else if (result.hasMoreTeams) {
        currentTeamIndex++;
        currentPage = 1;
      } else {
        hasMorePlayers = false;
      }
    }

    return players;
  }

  List<RosterPlayer> _buildFallbackDraftPool() {
    final rosterSize = widget.league.draftSettings?.rosterSize ?? 18;
    final requiredPlayers = (_members.length * rosterSize) + 12;

    const firstNames = [
      'Carlos',
      'Luis',
      'Jorge',
      'Mateo',
      'Diego',
      'Ramon',
      'Hector',
      'Pablo',
      'Santiago',
      'Emilio',
      'Julian',
      'Martin',
      'Adrian',
      'Bruno',
      'Tomas',
      'Rafael',
      'Leonardo',
      'Andres',
      'Fernando',
      'Ricardo',
    ];
    const lastNames = [
      'Lopez',
      'Garcia',
      'Fernandez',
      'Santos',
      'Ruiz',
      'Mendoza',
      'Vega',
      'Torres',
      'Navarro',
      'Ortega',
      'Castro',
      'Silva',
      'Rojas',
      'Salazar',
      'Campos',
      'Herrera',
      'Valdez',
      'Morales',
      'Fuentes',
      'Pineda',
    ];
    const teamNames = [
      'America',
      'Tigres',
      'Monterrey',
      'Toluca',
      'Cruz Azul',
      'Pumas',
      'Leon',
      'Pachuca',
      'Atlas',
      'Santos',
      'Necaxa',
      'Puebla',
    ];
    const positions = ['GK', 'DEF', 'DEF', 'DEF', 'MID', 'MID', 'MID', 'FWD'];

    final players = <RosterPlayer>[];
    for (int i = 0; i < requiredPlayers; i++) {
      final positionCode = positions[i % positions.length];
      final teamName = teamNames[i % teamNames.length];
      final first = firstNames[i % firstNames.length];
      final last = lastNames[(i * 3) % lastNames.length];
      final playerId = 900000 + i;
      final projectedPoints = switch (positionCode) {
        'GK' => 4.2 + ((i % 4) * 0.4),
        'DEF' => 4.8 + ((i % 5) * 0.5),
        'MID' => 6.0 + ((i % 6) * 0.55),
        _ => 6.8 + ((i % 6) * 0.65),
      };
      final price = switch (positionCode) {
        'GK' => 6.0 + ((i % 3) * 0.5),
        'DEF' => 6.5 + ((i % 4) * 0.6),
        'MID' => 7.5 + ((i % 5) * 0.7),
        _ => 8.5 + ((i % 5) * 0.8),
      };

      players.add(
        RosterPlayer(
          id: playerId,
          name: '$first $last',
          displayName: '$first $last',
          position: positionCode,
          positionCode: positionCode,
          teamId: 100 + (i % teamNames.length),
          teamName: teamName,
          jerseyNumber: (i % 30) + 1,
          price: price,
          projectedPoints: projectedPoints,
          selectedByPercent: ((i * 7) % 65).toDouble(),
        ),
      );
    }

    return players;
  }
}

enum DraftPlayerSort {
  projectedPointsHigh('Projected Points'),
  projectedPointsLow('Projected Points Asc'),
  priceHigh('Price'),
  nameAZ('Name A-Z');

  const DraftPlayerSort(this.label);
  final String label;
}
