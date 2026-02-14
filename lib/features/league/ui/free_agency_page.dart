// Free Agency Page for Draft Leagues
// UI for dropping and picking up players from the available pool

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/features/league/models/draft_models.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/services/free_agency_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FreeAgencyPage extends StatefulWidget {
  final League league;
  final List<RosterPlayer> allPlayers;
  final String currentUserId;
  final Map<int, String> playerOwnership; // playerId -> userId
  
  const FreeAgencyPage({
    super.key,
    required this.league,
    required this.allPlayers,
    required this.currentUserId,
    required this.playerOwnership,
  });

  @override
  State<FreeAgencyPage> createState() => _FreeAgencyPageState();
}

class _FreeAgencyPageState extends State<FreeAgencyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late FreeAgencyService _freeAgencyService;
  
  // Filters
  PlayerPosition? _positionFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
  // For swap mode
  bool _isSwapMode = false;
  RosterPlayer? _playerToAdd;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _freeAgencyService = FreeAgencyService(
      league: widget.league,
      currentUserId: widget.currentUserId,
      allPlayers: widget.allPlayers,
      initialOwnedPlayers: widget.playerOwnership,
    );
    _freeAgencyService.addListener(_onServiceUpdate);
  }
  
  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _freeAgencyService.removeListener(_onServiceUpdate);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Agency'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Roster'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Roster status banner
          _buildRosterBanner(theme),
          
          // Search and filter (for available tab)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _tabController.index == 0 ? null : 0,
            child: _buildSearchAndFilter(theme),
          ),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableTab(theme),
                _buildMyRosterTab(theme),
                _buildTransactionsTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRosterBanner(ThemeData theme) {
    final rosterSize = _freeAgencyService.myRosterSize;
    final maxSize = _freeAgencyService.maxRosterSize;
    final isFull = rosterSize >= maxSize;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Icon(
            isFull ? Icons.warning : Icons.people,
            color: isFull ? Colors.orange : theme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Roster: $rosterSize / $maxSize',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (isFull)
            Text(
              'Roster Full - Drop a player to add',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
              ),
            )
          else
            Text(
              '${maxSize - rosterSize} spots available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildSearchAndFilter(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800),
        ),
      ),
      child: Column(
        children: [
          // Search
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
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          
          const SizedBox(height: 8),
          
          // Position filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(theme, null, 'All'),
                const SizedBox(width: 8),
                _buildFilterChip(theme, PlayerPosition.goalkeeper, 'GK'),
                const SizedBox(width: 8),
                _buildFilterChip(theme, PlayerPosition.defender, 'DEF'),
                const SizedBox(width: 8),
                _buildFilterChip(theme, PlayerPosition.midfielder, 'MID'),
                const SizedBox(width: 8),
                _buildFilterChip(theme, PlayerPosition.attacker, 'FWD'),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(ThemeData theme, PlayerPosition? position, String label) {
    final isSelected = _positionFilter == position;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _positionFilter = position),
      selectedColor: theme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
  
  Widget _buildAvailableTab(ThemeData theme) {
    var players = _freeAgencyService.getAvailableByPosition(_positionFilter);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      players = players.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.displayName.toLowerCase().contains(query) ||
          p.teamName.toLowerCase().contains(query)
      ).toList();
    }
    
    if (players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No players found',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return _buildAvailablePlayerCard(theme, player);
      },
    );
  }
  
  Widget _buildAvailablePlayerCard(ThemeData theme, RosterPlayer player) {
    final canAdd = _freeAgencyService.canAddPlayer;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: () => _showPlayerDetails(player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player image
              _buildPlayerAvatar(player, 40),
              const SizedBox(width: 12),
              
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          player.teamName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildPositionBadge(theme, player.position),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Projected points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${player.projectedPoints?.toStringAsFixed(1) ?? "-"} pts',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'projected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              
              // Add button
              ElevatedButton(
                onPressed: canAdd 
                    ? () => _addPlayer(player)
                    : () => _showSwapDialog(player),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAdd ? Colors.green : Colors.orange,
                  minimumSize: const Size(70, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(canAdd ? 'Add' : 'Swap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMyRosterTab(ThemeData theme) {
    final roster = _freeAgencyService.myRoster;
    
    if (roster.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No players on roster',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Add players from the Available tab',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    // Group by position
    final byPosition = <PlayerPosition, List<RosterPlayer>>{};
    for (final player in roster) {
      final pos = _mapPosition(player.position);
      byPosition.putIfAbsent(pos, () => []).add(player);
    }
    
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final position in [
          PlayerPosition.goalkeeper,
          PlayerPosition.defender,
          PlayerPosition.midfielder,
          PlayerPosition.attacker,
        ])
          if (byPosition.containsKey(position)) ...[
            _buildPositionHeader(theme, position, byPosition[position]!.length),
            ...byPosition[position]!.map((p) => _buildRosterPlayerCard(theme, p)),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
  
  Widget _buildPositionHeader(ThemeData theme, PlayerPosition position, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPositionColor(position).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              position.name.toUpperCase(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getPositionColor(position),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRosterPlayerCard(ThemeData theme, RosterPlayer player) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: _buildPlayerAvatar(player, 36),
        title: Text(
          player.displayName,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          player.teamName,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${player.projectedPoints?.toStringAsFixed(1) ?? "-"}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'pts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _confirmDropPlayer(player),
              tooltip: 'Drop player',
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionsTab(ThemeData theme) {
    final transactions = _freeAgencyService.transactions;
    
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No transactions yet',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(theme, transaction);
      },
    );
  }
  
  Widget _buildTransactionCard(ThemeData theme, FreeAgentTransaction transaction) {
    IconData icon;
    Color color;
    
    if (transaction.isSwap) {
      icon = Icons.swap_horiz;
      color = Colors.blue;
    } else if (transaction.isAdd) {
      icon = Icons.add_circle;
      color = Colors.green;
    } else {
      icon = Icons.remove_circle;
      color = Colors.red;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          transaction.description,
          style: theme.textTheme.bodyMedium,
        ),
        subtitle: Text(
          DateFormat('MMM d, yyyy HH:mm').format(transaction.transactionAt),
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        trailing: transaction.userId == widget.currentUserId
            ? const Chip(
                label: Text('You', style: TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )
            : null,
      ),
    );
  }
  
  Widget _buildPlayerAvatar(RosterPlayer player, double size) {
    if (player.imagePath != null && player.imagePath!.isNotEmpty) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: player.imagePath!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildDefaultAvatar(player, size),
          errorWidget: (_, __, ___) => _buildDefaultAvatar(player, size),
        ),
      );
    }
    return _buildDefaultAvatar(player, size);
  }
  
  Widget _buildDefaultAvatar(RosterPlayer player, double size) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _getPositionColor(_mapPosition(player.position)).withValues(alpha: 0.2),
      child: Text(
        player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?',
        style: TextStyle(
          color: _getPositionColor(_mapPosition(player.position)),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildPositionBadge(ThemeData theme, String position) {
    final pos = _mapPosition(position);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPositionColor(pos).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        pos.abbreviation,
        style: theme.textTheme.bodySmall?.copyWith(
          color: _getPositionColor(pos),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _showPlayerDetails(RosterPlayer player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _PlayerDetailsSheet(
        player: player,
        onAdd: _freeAgencyService.canAddPlayer ? () => _addPlayer(player) : null,
        onSwap: () => _showSwapDialog(player),
      ),
    );
  }
  
  Future<void> _addPlayer(RosterPlayer player) async {
    Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name != null);
    
    final locked = await _freeAgencyService.isPlayerLocked(player.id);
    if (locked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add player - fixture has already started'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final result = await _freeAgencyService.addPlayer(player.id);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${player.displayName}')),
      );
    }
  }
  
  void _showSwapDialog(RosterPlayer playerToAdd) {
    final roster = _freeAgencyService.myRoster;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Select player to drop'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: roster.length,
            itemBuilder: (context, index) {
              final player = roster[index];
              return ListTile(
                leading: _buildPlayerAvatar(player, 32),
                title: Text(player.displayName),
                subtitle: Text(player.teamName),
                trailing: _buildPositionBadge(Theme.of(context), player.position),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _swapPlayers(player, playerToAdd);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _swapPlayers(RosterPlayer dropPlayer, RosterPlayer addPlayer) async {
    final result = await _freeAgencyService.swapPlayers(
      dropPlayerId: dropPlayer.id,
      addPlayerId: addPlayer.id,
    );
    
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Swapped ${dropPlayer.displayName} for ${addPlayer.displayName}')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to complete swap'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _confirmDropPlayer(RosterPlayer player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Drop Player?'),
        content: Text(
          'Are you sure you want to drop ${player.displayName}? They will become available to other teams.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _dropPlayer(player);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Drop'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _dropPlayer(RosterPlayer player) async {
    final result = await _freeAgencyService.dropPlayer(player.id);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dropped ${player.displayName}')),
      );
    }
  }
  
  PlayerPosition _mapPosition(String positionName) {
    final lower = positionName.toLowerCase();
    if (lower.contains('goalkeeper') || lower.contains('gk')) {
      return PlayerPosition.goalkeeper;
    } else if (lower.contains('defender') || lower.contains('def') || lower.contains('back')) {
      return PlayerPosition.defender;
    } else if (lower.contains('midfielder') || lower.contains('mid')) {
      return PlayerPosition.midfielder;
    } else if (lower.contains('forward') || lower.contains('fwd') || 
               lower.contains('attacker') || lower.contains('striker')) {
      return PlayerPosition.attacker;
    }
    return PlayerPosition.midfielder;
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
}

/// Bottom sheet showing player details
class _PlayerDetailsSheet extends StatelessWidget {
  final RosterPlayer player;
  final VoidCallback? onAdd;
  final VoidCallback? onSwap;
  
  const _PlayerDetailsSheet({
    required this.player,
    this.onAdd,
    this.onSwap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Player info
          Row(
            children: [
              if (player.imagePath != null && player.imagePath!.isNotEmpty)
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: player.imagePath!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                )
              else
                CircleAvatar(
                  radius: 30,
                  child: Text(player.displayName[0].toUpperCase()),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${player.teamName} • ${player.position}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(theme, 'Projected', '${player.projectedPoints?.toStringAsFixed(1) ?? "-"}'),
              _buildStatItem(theme, 'Price', '\$${player.price}M'),
              _buildStatItem(theme, 'Position', player.position),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Actions
          Row(
            children: [
              if (onSwap != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSwap!();
                    },
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Swap'),
                  ),
                ),
              if (onSwap != null && onAdd != null)
                const SizedBox(width: 12),
              if (onAdd != null)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onAdd!();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Roster'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(ThemeData theme, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

