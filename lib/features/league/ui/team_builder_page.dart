import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

/// Sort options for player list
enum PlayerSortOption {
  creditHigh,
  creditLow,
  pointsHigh,
  pointsLow,
  selectedPercent,
  nameAZ;

  String get displayName {
    switch (this) {
      case PlayerSortOption.creditHigh:
        return 'Price: High to Low';
      case PlayerSortOption.creditLow:
        return 'Price: Low to High';
      case PlayerSortOption.pointsHigh:
        return 'Points: High to Low';
      case PlayerSortOption.pointsLow:
        return 'Points: Low to High';
      case PlayerSortOption.selectedPercent:
        return 'Most Selected';
      case PlayerSortOption.nameAZ:
        return 'Name: A-Z';
    }
  }
}

/// Team builder page for selecting players within budget
class TeamBuilderPage extends StatefulWidget {
  final League league;
  final FantasyTeam? existingTeam;
  
  const TeamBuilderPage({
    super.key,
    required this.league,
    this.existingTeam,
  });

  @override
  State<TeamBuilderPage> createState() => _TeamBuilderPageState();
}

// Squad configuration constants
const int kTotalSquadSize = 15;  // 11 starters + 4 subs
const int kStartingXI = 11;
const int kMaxGK = 2;   // 1 starter + 1 sub
const int kMaxDEF = 5;  // Up to 5 defenders
const int kMaxMID = 5;  // Up to 5 midfielders  
const int kMaxFWD = 3;  // Up to 3 forwards

class _TeamBuilderPageState extends State<TeamBuilderPage> with SingleTickerProviderStateMixin {
  final LeagueRepository _leagueRepository = LeagueRepository();
  final PlayersRepository _playersRepository = PlayersRepository();
  late TabController _tabController;
  
  // All available players from Liga MX rosters
  List<RosterPlayer> _allRosterPlayers = [];
  
  // Selected players for the fantasy team
  List<FantasyTeamPlayer> _selectedPlayers = [];
  
  // UI State
  double _budget = 100.0;
  double _budgetRemaining = 100.0;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  PlayerSortOption _sortOption = PlayerSortOption.pointsHigh;
  String? _selectedTeamFilter;
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Position tabs
  final List<String> _positionCodes = ['GK', 'DEF', 'MID', 'FWD'];

  // Team names for filter
  Set<String> _teamNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _budget = widget.league.budget;
    _budgetRemaining = _budget;
    
    // Load existing team if any
    if (widget.existingTeam != null) {
      _selectedPlayers = List.from(widget.existingTeam!.players);
      _budgetRemaining = widget.existingTeam!.budgetRemaining;
    }
    
    _loadPlayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    
    try {
      // Load Liga MX roster players
      final rosterPlayers = await _playersRepository.getLigaMxRosterPlayers();
      
      // Extract unique team names for filtering
      final teams = rosterPlayers.map((p) => p.teamName).toSet();
      
      if (mounted) {
        setState(() {
          _allRosterPlayers = rosterPlayers;
          _teamNames = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading players: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading players: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Get filtered and sorted players for current tab/search
  List<RosterPlayer> _getFilteredPlayers(String positionCode) {
    var players = _allRosterPlayers.where((p) {
      // Filter by position
      if (positionCode == 'FWD') {
        // FWD includes attackers and forwards
        if (!['FWD', 'ATT', 'ST', 'CF'].contains(p.positionCode.toUpperCase())) {
          return false;
        }
      } else if (p.positionCode.toUpperCase() != positionCode) {
        return false;
      }
      
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(query) &&
            !p.displayName.toLowerCase().contains(query) &&
            !p.teamName.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Filter by team
      if (_selectedTeamFilter != null && p.teamName != _selectedTeamFilter) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort players
    players.sort((a, b) {
      // Selected players always first
      final aSelected = _isPlayerSelected(a.id);
      final bSelected = _isPlayerSelected(b.id);
      if (aSelected && !bSelected) return -1;
      if (!aSelected && bSelected) return 1;
      
      // Then apply sort option
      switch (_sortOption) {
        case PlayerSortOption.creditHigh:
          return b.credits.compareTo(a.credits);
        case PlayerSortOption.creditLow:
          return a.credits.compareTo(b.credits);
        case PlayerSortOption.pointsHigh:
          return b.projectedPoints.compareTo(a.projectedPoints);
        case PlayerSortOption.pointsLow:
          return a.projectedPoints.compareTo(b.projectedPoints);
        case PlayerSortOption.selectedPercent:
          return b.selectedByPercent.compareTo(a.selectedByPercent);
        case PlayerSortOption.nameAZ:
          return a.displayName.compareTo(b.displayName);
      }
    });
    
    return players;
  }

  bool _isPlayerSelected(int playerId) {
    return _selectedPlayers.any((p) => p.playerId == playerId);
  }

  void _togglePlayer(RosterPlayer rosterPlayer) {
    final isSelected = _isPlayerSelected(rosterPlayer.id);
    
    setState(() {
      if (isSelected) {
        // Remove player
        final removed = _selectedPlayers.firstWhere((p) => p.playerId == rosterPlayer.id);
        _selectedPlayers.removeWhere((p) => p.playerId == rosterPlayer.id);
        _budgetRemaining += removed.credits;
      } else {
        // Check constraints before adding
        if (_selectedPlayers.length >= kTotalSquadSize) {
          _showError('Maximum $kTotalSquadSize players allowed (11 starters + 4 subs)');
          return;
        }
        
        if (rosterPlayer.credits > _budgetRemaining) {
          _showError('Not enough budget');
          return;
        }
        
        // Convert position code to PlayerPosition
        final position = _positionCodeToEnum(rosterPlayer.positionCode);
        final posCount = _selectedPlayers.where((p) => p.position == position).length;
        
        // Squad limits: 2 GK, 5 DEF, 5 MID, 3 FWD = 15 total
        if (position == PlayerPosition.goalkeeper && posCount >= kMaxGK) {
          _showError('Maximum $kMaxGK goalkeepers allowed');
          return;
        }
        if (position == PlayerPosition.defender && posCount >= kMaxDEF) {
          _showError('Maximum $kMaxDEF defenders allowed');
          return;
        }
        if (position == PlayerPosition.midfielder && posCount >= kMaxMID) {
          _showError('Maximum $kMaxMID midfielders allowed');
          return;
        }
        if ((position == PlayerPosition.attacker || position == PlayerPosition.forward) && posCount >= kMaxFWD) {
          _showError('Maximum $kMaxFWD forwards allowed');
          return;
        }
        
        // Check team limit (max 4 from one team - more realistic)
        final teamCount = _selectedPlayers.where((p) => p.teamName == rosterPlayer.teamName).length;
        if (teamCount >= 4) {
          _showError('Maximum 4 players from one team');
          return;
        }
        
        // Add player
        final teamPlayer = FantasyTeamPlayer(
          playerId: rosterPlayer.id,
          playerName: rosterPlayer.displayName,
          playerImageUrl: rosterPlayer.imagePath,
          position: position,
          teamName: rosterPlayer.teamName,
          credits: rosterPlayer.credits,
        );
        _selectedPlayers.add(teamPlayer);
        _budgetRemaining -= rosterPlayer.credits;
      }
    });
  }

  PlayerPosition _positionCodeToEnum(String code) {
    switch (code.toUpperCase()) {
      case 'GK':
        return PlayerPosition.goalkeeper;
      case 'DEF':
        return PlayerPosition.defender;
      case 'MID':
        return PlayerPosition.midfielder;
      case 'FWD':
      case 'ATT':
      case 'ST':
      case 'CF':
        return PlayerPosition.attacker;
      default:
        return PlayerPosition.midfielder;
    }
  }

  void _setCaptain(int playerId) {
    setState(() {
      _selectedPlayers = _selectedPlayers.map((p) {
        return p.copyWith(
          isCaptain: p.playerId == playerId,
          isViceCaptain: p.isCaptain && p.playerId != playerId 
              ? false 
              : p.isViceCaptain,
        );
      }).toList();
    });
  }

  void _setViceCaptain(int playerId) {
    setState(() {
      _selectedPlayers = _selectedPlayers.map((p) {
        return p.copyWith(
          isViceCaptain: p.playerId == playerId,
          isCaptain: p.isViceCaptain && p.playerId != playerId 
              ? false
              : p.isCaptain,
        );
      }).toList();
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Navigate to full player profile
  Future<void> _navigateToPlayerProfile(int playerId) async {
    // Use overlay for subtle loading indicator
    OverlayEntry? overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Material(
          color: Colors.black26,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(overlayEntry);
    
    try {
      // Load full player data
      final player = await _playersRepository.getPlayerById(playerId);
      
      // Remove overlay
      overlayEntry.remove();
      
      if (!mounted) return;
      
      if (player != null) {
        Navigator.pushNamed(
          context,
          PageRoutes.playerDetails,
          arguments: player,
        );
      } else {
        _showError('Could not load player details');
      }
    } catch (e) {
      // Remove overlay
      overlayEntry.remove();
      
      if (!mounted) return;
      _showError('Error loading player: $e');
    }
  }

  Future<void> _saveTeam() async {
    // Validate squad size
    if (_selectedPlayers.length != kTotalSquadSize) {
      _showError('Select exactly $kTotalSquadSize players (11 starters + 4 subs)');
      return;
    }
    
    // Validate squad composition
    final gkCount = _selectedPlayers.where((p) => p.position == PlayerPosition.goalkeeper).length;
    final defCount = _selectedPlayers.where((p) => p.position == PlayerPosition.defender).length;
    final midCount = _selectedPlayers.where((p) => p.position == PlayerPosition.midfielder).length;
    final fwdCount = _selectedPlayers.where((p) => 
        p.position == PlayerPosition.attacker || p.position == PlayerPosition.forward).length;
    
    if (gkCount != kMaxGK) {
      _showError('You need exactly $kMaxGK goalkeepers');
      return;
    }
    if (defCount != kMaxDEF) {
      _showError('You need exactly $kMaxDEF defenders');
      return;
    }
    if (midCount != kMaxMID) {
      _showError('You need exactly $kMaxMID midfielders');
      return;
    }
    if (fwdCount != kMaxFWD) {
      _showError('You need exactly $kMaxFWD forwards');
      return;
    }
    
    final hasCaptain = _selectedPlayers.any((p) => p.isCaptain);
    final hasViceCaptain = _selectedPlayers.any((p) => p.isViceCaptain);
    
    if (!hasCaptain || !hasViceCaptain) {
      _showCaptainSelectionSheet();
      return;
    }
    
    // Save team
    try {
      await _leagueRepository.init();
      final currentUser = await _leagueRepository.getCurrentUser();
      
      final team = FantasyTeam(
        id: widget.existingTeam?.id ?? _leagueRepository.generateId(),
        leagueId: widget.league.id,
        userId: currentUser.oderId,
        userName: currentUser.userName,
        players: _selectedPlayers,
        totalCredits: _budget,
        budgetRemaining: _budgetRemaining,
        createdAt: widget.existingTeam?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _leagueRepository.saveFantasyTeam(team);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, team);
      }
    } catch (e) {
      _showError('Failed to save team: $e');
    }
  }

  void _showCaptainSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CaptainSelectionSheet(
        players: _selectedPlayers,
        onCaptainSelected: (playerId) {
          _setCaptain(playerId);
          Navigator.pop(context);
        },
        onViceCaptainSelected: (playerId) {
          _setViceCaptain(playerId);
          Navigator.pop(context);
        },
        onConfirm: () {
          Navigator.pop(context);
          _saveTeam();
        },
      ),
    );
  }

  void _showSortFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SortFilterSheet(
        currentSort: _sortOption,
        selectedTeam: _selectedTeamFilter,
        teamNames: _teamNames.toList()..sort(),
        onSortChanged: (sort) {
          setState(() => _sortOption = sort);
          Navigator.pop(context);
        },
        onTeamFilterChanged: (team) {
          setState(() => _selectedTeamFilter = team);
          Navigator.pop(context);
        },
        onClearFilters: () {
          setState(() {
            _selectedTeamFilter = null;
            _sortOption = PlayerSortOption.pointsHigh;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: _isSearching 
            ? _buildSearchField(theme)
            : const Text('Build Your Team'),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Search toggle
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          // Sort/Filter
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showSortFilterSheet,
              ),
              if (_selectedTeamFilter != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Preview button
          TextButton.icon(
            onPressed: _selectedPlayers.isNotEmpty ? _showTeamPreview : null,
            icon: const Icon(Icons.preview, size: 20),
            label: Text('${_selectedPlayers.length}/$kTotalSquadSize'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildBudgetBar(theme),
        ),
      ),
      body: Column(
        children: [
          // Position tabs
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: theme.primaryColor,
              labelColor: Colors.white,
              unselectedLabelColor: bgTextColor,
              tabs: List.generate(4, (index) => 
                _buildPositionTab(_positionCodes[index]),
              ),
            ),
          ),
          
          // Sort & Filter bar - Always visible
          _buildSortFilterBar(theme),
          
          // Player list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _positionCodes.map((posCode) {
                      return _buildPlayerList(theme, posCode);
                    }).toList(),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search players by name or team...',
        hintStyle: TextStyle(color: bgTextColor),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(color: Colors.white),
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
    );
  }

  Widget _buildBudgetBar(ThemeData theme) {
    final used = _budget - _budgetRemaining;
    final percent = (used / _budget).clamp(0.0, 1.0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget: ${_budgetRemaining.toStringAsFixed(1)} / ${_budget.toInt()} credits',
                style: TextStyle(
                  color: _budgetRemaining < 0 ? Colors.red : bgTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_selectedPlayers.length}/$kTotalSquadSize players',
                style: TextStyle(
                  color: _selectedPlayers.length == kTotalSquadSize ? Colors.green : bgTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: bgColor,
            valueColor: AlwaysStoppedAnimation(
              percent > 0.9 
                  ? Colors.red 
                  : percent > 0.7 
                      ? Colors.orange 
                      : theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Visible sort and filter bar
  Widget _buildSortFilterBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: bgColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Sort dropdown
          Expanded(
            child: InkWell(
              onTap: _showSortOptions,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sort, size: 18, color: bgTextColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _sortOption.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 20, color: bgTextColor),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Team filter dropdown
          Expanded(
            child: InkWell(
              onTap: _showTeamFilterOptions,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTeamFilter != null 
                      ? theme.primaryColor.withValues(alpha: 0.2)
                      : bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedTeamFilter != null
                      ? Border.all(color: theme.primaryColor.withValues(alpha: 0.5))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt, 
                      size: 18, 
                      color: _selectedTeamFilter != null 
                          ? theme.primaryColor 
                          : bgTextColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedTeamFilter ?? 'All Teams',
                        style: TextStyle(
                          fontSize: 13,
                          color: _selectedTeamFilter != null 
                              ? theme.primaryColor 
                              : Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedTeamFilter != null)
                      GestureDetector(
                        onTap: () => setState(() => _selectedTeamFilter = null),
                        child: Icon(
                          Icons.close, 
                          size: 16, 
                          color: theme.primaryColor,
                        ),
                      )
                    else
                      Icon(Icons.arrow_drop_down, size: 20, color: bgTextColor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show sort options popup
  void _showSortOptions() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Sort By',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),
            ...PlayerSortOption.values.map((option) => ListTile(
              leading: Icon(
                _getSortIcon(option),
                color: _sortOption == option ? theme.primaryColor : bgTextColor,
              ),
              title: Text(
                option.displayName,
                style: TextStyle(
                  color: _sortOption == option ? theme.primaryColor : null,
                  fontWeight: _sortOption == option ? FontWeight.w600 : null,
                ),
              ),
              trailing: _sortOption == option 
                  ? Icon(Icons.check, color: theme.primaryColor) 
                  : null,
              onTap: () {
                setState(() => _sortOption = option);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Show team filter options popup
  void _showTeamFilterOptions() {
    final theme = Theme.of(context);
    final sortedTeams = _teamNames.toList()..sort();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Team',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedTeamFilter != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedTeamFilter = null);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // All teams option
                  ListTile(
                    leading: Icon(
                      Icons.groups,
                      color: _selectedTeamFilter == null ? theme.primaryColor : bgTextColor,
                    ),
                    title: Text(
                      'All Teams',
                      style: TextStyle(
                        color: _selectedTeamFilter == null ? theme.primaryColor : null,
                        fontWeight: _selectedTeamFilter == null ? FontWeight.w600 : null,
                      ),
                    ),
                    trailing: _selectedTeamFilter == null 
                        ? Icon(Icons.check, color: theme.primaryColor) 
                        : null,
                    onTap: () {
                      setState(() => _selectedTeamFilter = null);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 1),
                  // Team list
                  ...sortedTeams.map((team) {
                    final playerCount = _allRosterPlayers.where((p) => p.teamName == team).length;
                    return ListTile(
                      leading: Icon(
                        Icons.shield,
                        color: _selectedTeamFilter == team ? theme.primaryColor : bgTextColor,
                      ),
                      title: Text(
                        team,
                        style: TextStyle(
                          color: _selectedTeamFilter == team ? theme.primaryColor : null,
                          fontWeight: _selectedTeamFilter == team ? FontWeight.w600 : null,
                        ),
                      ),
                      subtitle: Text(
                        '$playerCount players',
                        style: TextStyle(fontSize: 12, color: bgTextColor),
                      ),
                      trailing: _selectedTeamFilter == team 
                          ? Icon(Icons.check, color: theme.primaryColor) 
                          : null,
                      onTap: () {
                        setState(() => _selectedTeamFilter = team);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSortIcon(PlayerSortOption option) {
    switch (option) {
      case PlayerSortOption.creditHigh:
      case PlayerSortOption.creditLow:
        return Icons.monetization_on;
      case PlayerSortOption.pointsHigh:
      case PlayerSortOption.pointsLow:
        return Icons.trending_up;
      case PlayerSortOption.selectedPercent:
        return Icons.people;
      case PlayerSortOption.nameAZ:
        return Icons.sort_by_alpha;
    }
  }

  Widget _buildPositionTab(String positionCode) {
    final position = _positionCodeToEnum(positionCode);
    final count = _selectedPlayers.where((p) => p.position == position).length;
    final maxCount = positionCode == 'GK' ? 1 
        : positionCode == 'DEF' ? 5
        : positionCode == 'MID' ? 5
        : 3;
    
    // Count available players for this position
    final availableCount = _getFilteredPlayers(positionCode).length;
    
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(positionCode),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: count >= (positionCode == 'GK' ? 1 : 3)
                      ? Colors.green.withValues(alpha: 0.3)
                      : bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: count >= maxCount ? Colors.green : null,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '$availableCount available',
            style: TextStyle(fontSize: 9, color: bgTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(ThemeData theme, String positionCode) {
    final filteredPlayers = _getFilteredPlayers(positionCode);
    
    if (filteredPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: bgTextColor),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No players found for "$_searchQuery"'
                  : 'No players available',
              style: TextStyle(color: bgTextColor),
            ),
            if (_selectedTeamFilter != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _selectedTeamFilter = null),
                child: const Text('Clear team filter'),
              ),
            ],
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredPlayers.length,
      itemBuilder: (context, index) {
        final player = filteredPlayers[index];
        return FadedSlideAnimation(
          beginOffset: Offset(0, 0.03 * (index % 10 + 1)),
          endOffset: Offset.zero,
          slideDuration: const Duration(milliseconds: 150),
          child: _buildPlayerCard(theme, player),
        );
      },
    );
  }

  Widget _buildPlayerCard(ThemeData theme, RosterPlayer player) {
    final isSelected = _isPlayerSelected(player.id);
    final canAfford = player.credits <= _budgetRemaining || isSelected;
    
    // Get position color
    final posColor = _getPositionColor(player.positionCode);
    
    return Card(
      color: isSelected 
          ? theme.primaryColor.withValues(alpha: 0.15)
          : theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: theme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        // Tapping the card shows player details
        onTap: () => _showPlayerDetailsSheet(player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: posColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: player.imagePath != null && player.imagePath!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: player.imagePath!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _buildPlayerInitials(player),
                          errorWidget: (_, __, ___) => _buildPlayerInitials(player),
                        )
                      : _buildPlayerInitials(player),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.displayName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: posColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            player.positionCode,
                            style: TextStyle(
                              fontSize: 10,
                              color: posColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            player.teamName,
                            style: TextStyle(
                              fontSize: 11,
                              color: bgTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.trending_up, size: 12, color: Colors.green),
                        const SizedBox(width: 2),
                        Text(
                          '${player.projectedPoints.toStringAsFixed(1)} pts',
                          style: TextStyle(fontSize: 10, color: Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people, size: 12, color: bgTextColor),
                        const SizedBox(width: 2),
                        Text(
                          '${player.selectedByPercent.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 10, color: bgTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Credits badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: canAfford 
                      ? theme.primaryColor.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${player.credits}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canAfford ? theme.primaryColor : Colors.red,
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Add/Remove button - ONLY way to add/remove players
              IconButton(
                onPressed: canAfford ? () => _togglePlayer(player) : null,
                icon: Icon(
                  isSelected ? Icons.remove_circle : Icons.add_circle,
                  color: isSelected 
                      ? Colors.red 
                      : canAfford 
                          ? Colors.green 
                          : Colors.grey,
                  size: 28,
                ),
                tooltip: isSelected ? 'Remove from squad' : 'Add to squad',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show detailed player information in a bottom sheet
  void _showPlayerDetailsSheet(RosterPlayer player) {
    final theme = Theme.of(context);
    final isSelected = _isPlayerSelected(player.id);
    final canAfford = player.credits <= _budgetRemaining || isSelected;
    final posColor = _getPositionColor(player.positionCode);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: bgTextColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Player header
                Row(
                  children: [
                    // Large player image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgColor,
                        border: Border.all(
                          color: posColor.withValues(alpha: 0.5),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: posColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: player.imagePath != null && player.imagePath!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: player.imagePath!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _buildLargePlayerInitials(player),
                                errorWidget: (_, __, ___) => _buildLargePlayerInitials(player),
                              )
                            : _buildLargePlayerInitials(player),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Player info
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: posColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  player.position,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: posColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (player.jerseyNumber != null)
                                Text(
                                  '#${player.jerseyNumber}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: bgTextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (player.teamLogo != null && player.teamLogo!.isNotEmpty)
                                CachedNetworkImage(
                                  imageUrl: player.teamLogo!,
                                  width: 20,
                                  height: 20,
                                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  player.teamName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: bgTextColor,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Price card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primaryColor.withValues(alpha: 0.2),
                        theme.primaryColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 12,
                              color: bgTextColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.monetization_on,
                                color: theme.primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${player.credits.toStringAsFixed(1)} Credits',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isSelected)
                        Text(
                          canAfford ? 'Available' : 'Over budget',
                          style: TextStyle(
                            color: canAfford ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'In Squad',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Stats grid
                Text(
                  'Projected Performance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Projected Pts',
                        player.projectedPoints.toStringAsFixed(1),
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        'Selected By',
                        '${player.selectedByPercent.toStringAsFixed(1)}%',
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Season stats if available
                if (player.stats != null) ...[
                  Text(
                    'Season Statistics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildSeasonStatsGrid(theme, player),
                ],
                
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    // View full profile button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Load full player data and navigate
                          _navigateToPlayerProfile(player.id);
                        },
                        icon: const Icon(Icons.person),
                        label: const Text('Full Profile'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: theme.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Add/Remove button
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: canAfford 
                            ? () {
                                _togglePlayer(player);
                                Navigator.pop(context);
                              }
                            : null,
                        icon: Icon(
                          isSelected ? Icons.remove_circle : Icons.add_circle,
                        ),
                        label: Text(
                          isSelected 
                              ? 'Remove from Squad' 
                              : 'Add to Squad (${player.credits} cr)',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: isSelected 
                              ? Colors.red 
                              : canAfford 
                                  ? Colors.green 
                                  : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLargePlayerInitials(RosterPlayer player) {
    final initials = player.displayName
        .split(' ')
        .take(2)
        .map((s) => s.isNotEmpty ? s[0] : '')
        .join()
        .toUpperCase();
    
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: bgTextColor,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: bgTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonStatsGrid(ThemeData theme, RosterPlayer player) {
    final stats = player.stats!;
    
    final statItems = <Map<String, dynamic>>[];
    
    if (stats['goals'] != null) {
      statItems.add({'label': 'Goals', 'value': '${stats['goals']}', 'icon': Icons.sports_soccer});
    }
    if (stats['assists'] != null) {
      statItems.add({'label': 'Assists', 'value': '${stats['assists']}', 'icon': Icons.handshake});
    }
    if (stats['appearances'] != null) {
      statItems.add({'label': 'Matches', 'value': '${stats['appearances']}', 'icon': Icons.calendar_today});
    }
    if (stats['minutes'] != null) {
      statItems.add({'label': 'Minutes', 'value': '${stats['minutes']}', 'icon': Icons.timer});
    }
    if (stats['cleanSheets'] != null && player.positionCode == 'GK') {
      statItems.add({'label': 'Clean Sheets', 'value': '${stats['cleanSheets']}', 'icon': Icons.shield});
    }
    if (stats['saves'] != null && player.positionCode == 'GK') {
      statItems.add({'label': 'Saves', 'value': '${stats['saves']}', 'icon': Icons.pan_tool});
    }
    if (stats['yellowCards'] != null) {
      statItems.add({'label': 'Yellow Cards', 'value': '${stats['yellowCards']}', 'icon': Icons.square, 'color': Colors.yellow});
    }
    if (stats['redCards'] != null && (stats['redCards'] as num) > 0) {
      statItems.add({'label': 'Red Cards', 'value': '${stats['redCards']}', 'icon': Icons.square, 'color': Colors.red});
    }
    
    if (statItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No statistics available',
            style: TextStyle(color: bgTextColor),
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: statItems.map((stat) {
        final color = stat['color'] as Color? ?? theme.primaryColor;
        return Container(
          width: (MediaQuery.of(context).size.width - 56) / 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(stat['icon'] as IconData, color: color, size: 20),
              const SizedBox(height: 6),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat['label'] as String,
                style: TextStyle(
                  fontSize: 10,
                  color: bgTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPlayerInitials(RosterPlayer player) {
    final initials = player.displayName
        .split(' ')
        .take(2)
        .map((s) => s.isNotEmpty ? s[0] : '')
        .join()
        .toUpperCase();
    
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: bgTextColor,
        ),
      ),
    );
  }

  Color _getPositionColor(String positionCode) {
    switch (positionCode.toUpperCase()) {
      case 'GK':
        return Colors.orange;
      case 'DEF':
        return Colors.blue;
      case 'MID':
        return Colors.green;
      case 'FWD':
      case 'ATT':
      case 'ST':
      case 'CF':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBottomBar(ThemeData theme) {
    final isValid = _selectedPlayers.length == kTotalSquadSize;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isValid ? _saveTeam : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: bgColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            isValid 
                ? 'Save Team' 
                : 'Select ${kTotalSquadSize - _selectedPlayers.length} more players',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showTeamPreview() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return _TeamPreviewSheet(
            players: _selectedPlayers,
            budgetRemaining: _budgetRemaining,
            scrollController: scrollController,
            onRemovePlayer: (playerId) {
              final player = _allRosterPlayers.firstWhere((p) => p.id == playerId);
              _togglePlayer(player);
              Navigator.pop(context);
            },
            onSetCaptain: _setCaptain,
            onSetViceCaptain: _setViceCaptain,
          );
        },
      ),
    );
  }
}

// ==================== SORT/FILTER SHEET ====================

class _SortFilterSheet extends StatelessWidget {
  final PlayerSortOption currentSort;
  final String? selectedTeam;
  final List<String> teamNames;
  final Function(PlayerSortOption) onSortChanged;
  final Function(String?) onTeamFilterChanged;
  final VoidCallback onClearFilters;

  const _SortFilterSheet({
    required this.currentSort,
    required this.selectedTeam,
    required this.teamNames,
    required this.onSortChanged,
    required this.onTeamFilterChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sort & Filter',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Sort options
          Text(
            'Sort By',
            style: TextStyle(color: bgTextColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PlayerSortOption.values.map((option) {
              final isSelected = option == currentSort;
              return ChoiceChip(
                label: Text(option.displayName),
                selected: isSelected,
                onSelected: (_) => onSortChanged(option),
                selectedColor: theme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Team filter
          Text(
            'Filter by Team',
            style: TextStyle(color: bgTextColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: selectedTeam,
            decoration: InputDecoration(
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: 'All Teams',
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Teams'),
              ),
              ...teamNames.map((team) => DropdownMenuItem(
                value: team,
                child: Text(team, overflow: TextOverflow.ellipsis),
              )),
            ],
            onChanged: onTeamFilterChanged,
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ==================== TEAM PREVIEW SHEET ====================

class _TeamPreviewSheet extends StatelessWidget {
  final List<FantasyTeamPlayer> players;
  final double budgetRemaining;
  final ScrollController scrollController;
  final Function(int) onRemovePlayer;
  final Function(int) onSetCaptain;
  final Function(int) onSetViceCaptain;
  
  const _TeamPreviewSheet({
    required this.players,
    required this.budgetRemaining,
    required this.scrollController,
    required this.onRemovePlayer,
    required this.onSetCaptain,
    required this.onSetViceCaptain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Group by position
    final gk = players.where((p) => p.position == PlayerPosition.goalkeeper).toList();
    final def = players.where((p) => p.position == PlayerPosition.defender).toList();
    final mid = players.where((p) => p.position == PlayerPosition.midfielder).toList();
    final fwd = players.where((p) => 
        p.position == PlayerPosition.attacker || 
        p.position == PlayerPosition.forward
    ).toList();
    
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: bgTextColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.groups),
              const SizedBox(width: 8),
              Text(
                'Your Team (${players.length}/$kTotalSquadSize)',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${budgetRemaining.toStringAsFixed(1)} left',
                style: TextStyle(color: bgTextColor),
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Player list
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              if (gk.isNotEmpty) _buildPositionSection(context, 'Goalkeeper', gk),
              if (def.isNotEmpty) _buildPositionSection(context, 'Defenders', def),
              if (mid.isNotEmpty) _buildPositionSection(context, 'Midfielders', mid),
              if (fwd.isNotEmpty) _buildPositionSection(context, 'Forwards', fwd),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionSection(BuildContext context, String title, List<FantasyTeamPlayer> posPlayers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: bgTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...posPlayers.map((p) => _buildPlayerTile(context, p)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPlayerTile(BuildContext context, FantasyTeamPlayer player) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: player.position.color.withValues(alpha: 0.2),
          child: Text(
            player.position.abbreviation,
            style: TextStyle(
              color: player.position.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                player.playerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (player.isCaptain)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'C',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            if (player.isViceCaptain)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'VC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${player.teamName ?? 'Unknown'} • ${player.credits} credits',
          style: TextStyle(color: bgTextColor, fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'captain':
                onSetCaptain(player.playerId);
                break;
              case 'vicecaptain':
                onSetViceCaptain(player.playerId);
                break;
              case 'remove':
                onRemovePlayer(player.playerId);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!player.isCaptain)
              const PopupMenuItem(
                value: 'captain',
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Text('Make Captain'),
                  ],
                ),
              ),
            if (!player.isViceCaptain)
              const PopupMenuItem(
                value: 'vicecaptain',
                child: Row(
                  children: [
                    Icon(Icons.star_half, color: Colors.grey, size: 20),
                    SizedBox(width: 8),
                    Text('Make Vice-Captain'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.remove_circle, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Remove', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== CAPTAIN SELECTION SHEET ====================

class _CaptainSelectionSheet extends StatelessWidget {
  final List<FantasyTeamPlayer> players;
  final Function(int) onCaptainSelected;
  final Function(int) onViceCaptainSelected;
  final VoidCallback onConfirm;
  
  const _CaptainSelectionSheet({
    required this.players,
    required this.onCaptainSelected,
    required this.onViceCaptainSelected,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captain = players.where((p) => p.isCaptain).firstOrNull;
    final viceCaptain = players.where((p) => p.isViceCaptain).firstOrNull;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Captain & Vice-Captain',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Captain gets 2x points, Vice-Captain gets 1.5x points',
            style: TextStyle(color: bgTextColor),
          ),
          const SizedBox(height: 16),
          
          // Captain selection
          Text('Captain', style: TextStyle(color: bgTextColor, fontSize: 12)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: captain?.playerId,
            decoration: InputDecoration(
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.star, color: Colors.amber),
            ),
            items: players.map((p) {
              return DropdownMenuItem(
                value: p.playerId,
                child: Text(p.playerName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onCaptainSelected(value);
            },
          ),
          
          const SizedBox(height: 16),
          
          // Vice-Captain selection
          Text('Vice-Captain', style: TextStyle(color: bgTextColor, fontSize: 12)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: viceCaptain?.playerId,
            decoration: InputDecoration(
              filled: true,
              fillColor: bgColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.star_half, color: Colors.grey),
            ),
            items: players.where((p) => !p.isCaptain).map((p) {
              return DropdownMenuItem(
                value: p.playerId,
                child: Text(p.playerName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onViceCaptainSelected(value);
            },
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: captain != null && viceCaptain != null ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirm & Save'),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
