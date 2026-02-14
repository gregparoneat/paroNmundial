import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/services/draft_service.dart';
import 'package:flutter/material.dart';

/// Draft Room page for live drafting
class DraftRoomPage extends StatefulWidget {
  final League league;
  
  const DraftRoomPage({super.key, required this.league});

  @override
  State<DraftRoomPage> createState() => _DraftRoomPageState();
}

class _DraftRoomPageState extends State<DraftRoomPage> with SingleTickerProviderStateMixin {
  final LeagueRepository _leagueRepository = LeagueRepository();
  final PlayersRepository _playerRepository = PlayersRepository();
  
  DraftService? _draftService;
  List<LeagueMember> _members = [];
  List<RosterPlayer> _allPlayers = [];
  bool _isLoading = true;
  String? _error;
  String _currentUserId = '';
  
  // Filter state
  PlayerPosition? _positionFilter;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  
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
      
      // Get all Liga MX players
      _allPlayers = await _playerRepository.getLigaMxRosterPlayers();
      
      // Initialize draft service
      _draftService = DraftService(
        league: widget.league,
        currentUserId: _currentUserId,
        allPlayers: _allPlayers,
      );
      
      _draftService!.onDraftComplete = _onDraftComplete;
      _draftService!.onPickMade = _onPickMade;
      _draftService!.addListener(_onDraftStateChanged);
      
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
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
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
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to league
              },
              child: const Text('View My Team'),
            ),
          ],
        ),
      );
    }
  }
  
  void _onPickMade(DraftPick pick) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pick.isAutoPick
                ? '⏱️ Auto-pick: ${pick.playerName} to ${pick.userName}'
                : '✅ ${pick.userName} selected ${pick.playerName}',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: pick.userId == _currentUserId 
              ? Colors.green 
              : bgColor,
        ),
      );
    }
  }
  
  Future<void> _onPlayerSelected(RosterPlayer player) async {
    if (_draftService == null) return;
    
    if (!_draftService!.isMyTurn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait for your turn to pick'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Confirm selection
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Draft ${player.displayName}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (player.imagePath != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: CachedNetworkImageProvider(player.imagePath!),
              ),
            const SizedBox(height: 12),
            Text(
              player.teamName,
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              player.position,
              style: TextStyle(
                color: _getPositionColor(player.position),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Draft'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final success = await _draftService!.makePick(player);
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to draft player'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    
    // Get current picker name
    final currentPickerId = _draftService?.currentPickingUserId;
    final currentPicker = _members.where((m) => m.oderId == currentPickerId).firstOrNull;
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
              Container(
                width: 1,
                height: 50,
                color: Colors.white24,
              ),
              
              // Current picker
              Column(
                children: [
                  Text(
                    isMyTurn ? 'YOUR PICK!' : pickerName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isMyTurn ? Colors.white : Colors.white70,
                      fontWeight: isMyTurn ? FontWeight.bold : FontWeight.normal,
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
          ],
        ],
      ),
    );
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
                  itemBuilder: (context, index) => _buildPlayerTile(theme, players[index]),
                ),
        ),
      ],
    );
  }
  
  Widget _buildFilterChip(ThemeData theme, PlayerPosition? position, String label) {
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
        labelStyle: TextStyle(
          color: isSelected ? theme.primaryColor : null,
        ),
      ),
    );
  }
  
  Widget _buildPlayerTile(ThemeData theme, RosterPlayer player) {
    final isMyTurn = _draftService?.isMyTurn ?? false;
    
    return ListTile(
      onTap: isMyTurn ? () => _onPlayerSelected(player) : null,
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
        '${player.teamName} • ${player.position}',
        style: TextStyle(color: bgTextColor),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getPositionColor(player.position).withValues(alpha: 0.2),
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
                _buildStatColumn(theme, '${rosterSize - myPicks.length}', 'Remaining'),
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
  
  Widget _buildPositionSection(ThemeData theme, PlayerPosition position, List<DraftPick> picks) {
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
            Text(
              '${picks.length}',
              style: TextStyle(color: bgTextColor),
            ),
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
          ...picks.map((pick) => Container(
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
                        style: TextStyle(
                          color: bgTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'R${pick.round} P${pick.pickNumber}',
                  style: TextStyle(
                    color: bgTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )),
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
    
    return players;
  }
  
  PlayerPosition _mapPlayerPosition(String positionName) {
    final lower = positionName.toLowerCase();
    if (lower.contains('goalkeeper') || lower.contains('gk')) {
      return PlayerPosition.goalkeeper;
    } else if (lower.contains('defender') || lower.contains('def') || lower.contains('back')) {
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
      builder: (context) => AlertDialog(
        title: const Text('Leave Draft?'),
        content: const Text(
          'If you leave, the draft will continue and auto-pick will '
          'select players for you when it\'s your turn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Leave draft room
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

