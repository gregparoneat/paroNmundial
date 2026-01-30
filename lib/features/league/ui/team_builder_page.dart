import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/ui/widgets/soccer_field_widget.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

/// Sort options for player list
enum PlayerSortOption {
  priceHigh,
  priceLow,
  pointsHigh,
  pointsLow,
  selectedPercent,
  nameAZ;

  String get displayName {
    switch (this) {
      case PlayerSortOption.priceHigh:
        return 'Price: High to Low';
      case PlayerSortOption.priceLow:
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
const int kBenchSize = 4;
// No strict position limits - user can have any combination as long as
// they can fill 11 players according to their chosen formation

class _TeamBuilderPageState extends State<TeamBuilderPage> {
  final LeagueRepository _leagueRepository = LeagueRepository();
  final PlayersRepository _playersRepository = PlayersRepository();
  
  // All available players (loaded lazily)
  List<RosterPlayer> _allRosterPlayers = [];
  
  // Selected players for the fantasy team
  List<FantasyTeamPlayer> _selectedPlayers = [];
  
  // UI State
  double _budget = 100.0;
  double _budgetRemaining = 100.0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  String _searchQuery = '';
  PlayerSortOption _sortOption = PlayerSortOption.pointsHigh;
  LigaMxTeam? _selectedTeamFilter;
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  // Liga MX teams list
  List<LigaMxTeam> _ligaMxTeams = [];
  
  // Pagination state
  int _currentTeamIndex = 0;
  int _currentPage = 1;
  bool _hasMorePlayers = true;
  
  // Formation and field view state
  Formation _selectedFormation = Formation.f433;
  bool _showFieldView = false; // Start collapsed to avoid overflow

  @override
  void initState() {
    super.initState();
    _budget = widget.league.budget;
    _budgetRemaining = _budget;
    
    // Load existing team if any
    if (widget.existingTeam != null) {
      _selectedPlayers = List.from(widget.existingTeam!.players);
      // Recalculate budget based on actual player prices (don't trust stored value)
      _budgetRemaining = _recalculateBudget();
    }
    
    // Setup scroll listener for infinite scroll
    _scrollController.addListener(_onScroll);
    
    _loadInitialData();
  }
  
  /// Recalculate the budget remaining based on selected players
  double _recalculateBudget() {
    final usedAmount = _selectedPlayers.fold(0.0, (sum, p) => sum + p.price);
    return _budget - usedAmount;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMorePlayers();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load teams first (uses Hive cache or Firestore)
      _ligaMxTeams = await _playersRepository.getLigaMxTeams();
      
      // Load players from Firestore (this handles caching and stats enrichment)
      // Prices are recalculated from stats on each load to ensure latest pricing logic
      debugPrint('Loading players with stats enrichment...');
      final players = await _playersRepository.loadAllPlayersFromFirestore();
      debugPrint('Loaded ${players.length} players (with stats for pricing)');
      
      if (players.isNotEmpty) {
        // Log sample prices for debugging
        final forwards = players.where((p) => p.positionCode == 'FWD').take(5);
        for (final fwd in forwards) {
          debugPrint('FWD ${fwd.displayName}: \$${fwd.price}M (goals: ${fwd.stats?['goals']}, assists: ${fwd.stats?['assists']})');
        }
        
        if (mounted) {
          setState(() {
            _allRosterPlayers = players;
            _hasMorePlayers = false; // All players loaded from Firestore
            _isLoading = false;
          });
        }
        return;
      }
      
      // Fallback - load from SportMonks API (shouldn't happen if Firestore is set up)
      debugPrint('No Firestore data, falling back to SportMonks API');
      await _loadPlayersPage();
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _loadPlayersPage() async {
    if (_isLoadingMore || !_hasMorePlayers) return;
    
    setState(() => _isLoadingMore = true);
    
    try {
      if (_selectedTeamFilter != null) {
        // Load from specific team
        final result = await _playersRepository.getTeamPlayers(
          teamId: _selectedTeamFilter!.id,
          teamName: _selectedTeamFilter!.name,
          teamLogo: _selectedTeamFilter!.logo,
          page: _currentPage,
          pageSize: 20,
        );
        
        if (mounted) {
          setState(() {
            _allRosterPlayers.addAll(result.players);
            _hasMorePlayers = result.hasMore;
            _currentPage++;
            _isLoadingMore = false;
          });
        }
      } else {
        // Load from all teams (team by team)
        final result = await _playersRepository.getAllPlayersPage(
          teamIndex: _currentTeamIndex,
          page: _currentPage,
          pageSize: 20,
        );
        
        if (mounted) {
          setState(() {
            _allRosterPlayers.addAll(result.players);
            
            if (result.hasMoreInTeam) {
              _currentPage++;
            } else if (result.hasMoreTeams) {
              _currentTeamIndex++;
              _currentPage = 1;
            } else {
              _hasMorePlayers = false;
            }
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading players page: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }
  
  void _loadMorePlayers() {
    if (!_isLoadingMore && _hasMorePlayers) {
      _loadPlayersPage();
    }
  }
  
  void _onTeamFilterChanged(LigaMxTeam? team) {
    setState(() {
      _selectedTeamFilter = team;
      _allRosterPlayers.clear();
      _currentTeamIndex = 0;
      _currentPage = 1;
      _hasMorePlayers = true;
    });
    _loadPlayersPage();
  }

  /// Get filtered and sorted players
  List<RosterPlayer> _getFilteredPlayers() {
    var players = _allRosterPlayers.where((p) {
      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(query) &&
            !p.displayName.toLowerCase().contains(query) &&
            !p.teamName.toLowerCase().contains(query)) {
          return false;
        }
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
        case PlayerSortOption.priceHigh:
          return b.price.compareTo(a.price);
        case PlayerSortOption.priceLow:
          return a.price.compareTo(b.price);
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
        _budgetRemaining += removed.price;
      } else {
        // Check constraints before adding
        if (_selectedPlayers.length >= kTotalSquadSize) {
          _showError('Maximum $kTotalSquadSize players allowed (11 starters + 4 subs)');
          return;
        }
        
        if (rosterPlayer.price > _budgetRemaining) {
          _showError('Not enough budget');
          return;
        }
        
        // Convert position code to PlayerPosition
        final position = _positionCodeToEnum(rosterPlayer.positionCode);
        
        // Check team limit (max 4 from one team - more realistic)
        final teamCount = _selectedPlayers.where((p) => p.teamName == rosterPlayer.teamName).length;
        if (teamCount >= 4) {
          _showError('Maximum 4 players from one team');
          return;
        }
        
        // Add player - no strict position limits, just total squad size
        final teamPlayer = FantasyTeamPlayer(
          playerId: rosterPlayer.id,
          playerName: rosterPlayer.displayName,
          playerImageUrl: rosterPlayer.imagePath,
          position: position,
          teamName: rosterPlayer.teamName,
          price: rosterPlayer.price,
        );
        _selectedPlayers.add(teamPlayer);
        _budgetRemaining -= rosterPlayer.price;
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

  /// Handle player swap via drag-and-drop on the soccer field
  void _handlePlayerSwap(
    FantasyTeamPlayer draggedPlayer,
    FantasyTeamPlayer? targetPlayer,
    String targetPosition,
    int targetSlotIndex,
  ) {
    setState(() {
      if (targetPlayer != null) {
        // Swap the two players in the list
        final draggedIndex = _selectedPlayers.indexWhere((p) => p.playerId == draggedPlayer.playerId);
        final targetIndex = _selectedPlayers.indexWhere((p) => p.playerId == targetPlayer.playerId);
        
        if (draggedIndex >= 0 && targetIndex >= 0) {
          final temp = _selectedPlayers[draggedIndex];
          _selectedPlayers[draggedIndex] = _selectedPlayers[targetIndex];
          _selectedPlayers[targetIndex] = temp;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Swapped ${draggedPlayer.playerName} with ${targetPlayer.playerName}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        // Dropping onto an empty slot - this should only happen for positions
        // that the player can fill. The validation is done in the drag target.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${draggedPlayer.playerName} moved to $targetPosition position'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 1),
          ),
        );
      }
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

  /// Validate if the current squad can fill the selected formation
  /// Returns error message if invalid, null if valid
  String? _validateFormation() {
    // Count players by position
    final gkCount = _selectedPlayers.where((p) => p.position == PlayerPosition.goalkeeper).length;
    final defCount = _selectedPlayers.where((p) => p.position == PlayerPosition.defender).length;
    final midCount = _selectedPlayers.where((p) => p.position == PlayerPosition.midfielder).length;
    final fwdCount = _selectedPlayers.where((p) => 
        p.position == PlayerPosition.attacker || p.position == PlayerPosition.forward).length;
    
    // Formation requires: 1 GK + DEF + MID + FWD according to formation.lines
    final requiredDef = _selectedFormation.lines[0];
    final requiredMid = _selectedFormation.lines[1];
    final requiredFwd = _selectedFormation.lines[2];
    
    // Need at least 1 GK for lineup
    if (gkCount < 1) {
      return 'You need at least 1 goalkeeper';
    }
    
    // Check formation requirements
    if (defCount < requiredDef) {
      return 'Formation ${_selectedFormation.name} requires $requiredDef defenders, you have $defCount';
    }
    if (midCount < requiredMid) {
      return 'Formation ${_selectedFormation.name} requires $requiredMid midfielders, you have $midCount';
    }
    if (fwdCount < requiredFwd) {
      return 'Formation ${_selectedFormation.name} requires $requiredFwd forwards, you have $fwdCount';
    }
    
    return null; // Valid!
  }
  
  /// Get formation suggestions based on current squad
  List<Formation> _getSuggestedFormations() {
    final defCount = _selectedPlayers.where((p) => p.position == PlayerPosition.defender).length;
    final midCount = _selectedPlayers.where((p) => p.position == PlayerPosition.midfielder).length;
    final fwdCount = _selectedPlayers.where((p) => 
        p.position == PlayerPosition.attacker || p.position == PlayerPosition.forward).length;
    
    return Formation.values.where((f) {
      return defCount >= f.lines[0] && midCount >= f.lines[1] && fwdCount >= f.lines[2];
    }).toList();
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
    
    // Validate formation can be filled
    final validationError = _validateFormation();
    if (validationError != null) {
      _showError(validationError);
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
        teamName: currentUser.userName,
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
        teams: _ligaMxTeams,
        onSortChanged: (sort) {
          setState(() => _sortOption = sort);
          Navigator.pop(context);
        },
        onTeamFilterChanged: (team) {
          Navigator.pop(context);
          _onTeamFilterChanged(team);
        },
        onClearFilters: () {
          Navigator.pop(context);
          _onTeamFilterChanged(null);
          setState(() => _sortOption = PlayerSortOption.pointsHigh);
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildFieldBasedView(theme),
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
                'Budget: \$${_budgetRemaining.toStringAsFixed(1)}M / \$${_budget.toInt()}M',
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

  /// Main field-based view - shows soccer field with clickable slots
  Widget _buildFieldBasedView(ThemeData theme) {
    final startingXI = _selectedPlayers.take(11).toList();
    final bench = _selectedPlayers.skip(11).toList();
    
    // Calculate total projected points
    double totalProjectedPoints = 0;
    for (final player in _selectedPlayers) {
      final rosterPlayer = _allRosterPlayers.where((p) => p.id == player.playerId).firstOrNull;
      if (rosterPlayer != null) {
        totalProjectedPoints += rosterPlayer.projectedPoints;
      }
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          // Projected points header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: theme.colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Build Your Squad',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.primaryColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 16, color: theme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '${totalProjectedPoints.toStringAsFixed(1)} pts',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Formation selector
          Container(
            height: 44,
            color: theme.colorScheme.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: Formation.values.map((formation) {
                final isSelected = formation == _selectedFormation;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(formation.name),
                    selectedColor: theme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : bgTextColor,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedFormation = formation),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // Soccer field - main area with drag-and-drop support
          Padding(
            padding: const EdgeInsets.all(12),
            child: SoccerFieldWidget(
              players: startingXI,
              formation: _selectedFormation,
              isEditable: true,
              height: 320,
              onPlayerTap: (player) => _showSubstitutionDialog(player),
              onSlotTap: (position, index) => _showPlayerSelectionSheet(_positionFromString(position)),
              onPlayerSwap: _handlePlayerSwap,
            ),
          ),
          
          // Bench section
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _buildBenchSection(theme, bench),
          ),
          
          // Quick add button
          if (_selectedPlayers.length < kTotalSquadSize)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: () => _showPlayerSelectionSheet(null),
                icon: const Icon(Icons.person_add),
                label: Text('Add Player (${_selectedPlayers.length}/$kTotalSquadSize)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build bench section with 4 slots
  Widget _buildBenchSection(ThemeData theme, List<FantasyTeamPlayer> bench) {
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
                'Substitutes (${bench.length}/4)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: bgTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(4, (index) {
              final player = index < bench.length ? bench[index] : null;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                  child: _buildBenchSlot(theme, player, index),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
  
  /// Build individual bench slot
  Widget _buildBenchSlot(ThemeData theme, FantasyTeamPlayer? player, int index) {
    final positionNeeded = _getBenchPositionNeeded(index);
    
    return GestureDetector(
      onTap: player != null 
          ? () => _showSubstitutionDialog(player)
          : () => _showPlayerSelectionSheet(positionNeeded),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: player != null 
                ? _getPositionColor(player.position) 
                : bgTextColor.withValues(alpha: 0.3),
          ),
        ),
        child: player != null
            ? _buildFilledBenchSlot(theme, player)
            : _buildEmptyBenchSlot(theme, positionNeeded),
      ),
    );
  }
  
  Widget _buildFilledBenchSlot(ThemeData theme, FantasyTeamPlayer player) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _getPositionColor(player.position),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              player.position.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            player.playerName.split(' ').last,
            style: const TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyBenchSlot(ThemeData theme, PlayerPosition? position) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bgTextColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: bgTextColor.withValues(alpha: 0.5), style: BorderStyle.solid),
          ),
          child: Icon(Icons.add, size: 16, color: bgTextColor),
        ),
        const SizedBox(height: 4),
        Text(
          position != null ? _getPositionAbbr(position) : 'SUB',
          style: TextStyle(fontSize: 10, color: bgTextColor),
        ),
      ],
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
  
  PlayerPosition? _getBenchPositionNeeded(int index) {
    // Bench should have: 1 GK, 1 DEF, 1 MID, 1 FWD
    switch (index) {
      case 0:
        return PlayerPosition.goalkeeper;
      case 1:
        return PlayerPosition.defender;
      case 2:
        return PlayerPosition.midfielder;
      case 3:
        return PlayerPosition.forward;
      default:
        return null;
    }
  }
  
  PlayerPosition? _positionFromString(String position) {
    switch (position.toUpperCase()) {
      case 'GK':
      case 'GOALKEEPER':
        return PlayerPosition.goalkeeper;
      case 'DEF':
      case 'DEFENDER':
        return PlayerPosition.defender;
      case 'MID':
      case 'MIDFIELDER':
        return PlayerPosition.midfielder;
      case 'FWD':
      case 'FORWARD':
      case 'ATT':
      case 'ATTACKER':
        return PlayerPosition.forward;
      default:
        return null;
    }
  }
  
  /// Show player selection bottom sheet
  void _showPlayerSelectionSheet(PlayerPosition? filterPosition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PlayerSelectionSheet(
        allPlayers: _allRosterPlayers,
        selectedPlayers: _selectedPlayers,
        budgetRemaining: _budgetRemaining,
        filterPosition: filterPosition,
        ligaMxTeams: _ligaMxTeams,
        onPlayerSelected: (rosterPlayer) {
          _togglePlayer(rosterPlayer);
          Navigator.pop(context);
        },
        onViewProfile: (rosterPlayer) => _navigateToPlayerProfile(rosterPlayer.id),
      ),
    );
  }

  /// Build collapsible field visualization showing squad slots (legacy - kept for reference)
  Widget _buildFieldVisualization(ThemeData theme) {
    // Convert selected RosterPlayers to FantasyTeamPlayers for the field
    final startingXI = _selectedPlayers.take(11).toList();
    final bench = _selectedPlayers.skip(11).toList();
    
    // Calculate total projected points
    double totalProjectedPoints = 0;
    for (final player in _selectedPlayers) {
      // Find the roster player to get projected points
      final rosterPlayer = _allRosterPlayers.where((p) => p.id == player.playerId).firstOrNull;
      if (rosterPlayer != null) {
        totalProjectedPoints += rosterPlayer.projectedPoints;
      }
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Column(
        children: [
          // Header with toggle and projected points
          InkWell(
            onTap: () => setState(() => _showFieldView = !_showFieldView),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: theme.colorScheme.surface,
              child: Row(
                children: [
                  Icon(
                    _showFieldView ? Icons.expand_less : Icons.expand_more,
                    color: bgTextColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Squad View',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  // Projected points badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.primaryColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 14, color: theme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          '${totalProjectedPoints.toStringAsFixed(1)} pts',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Collapsible field
          if (_showFieldView) ...[
            // Formation selector
            Container(
              height: 40,
              color: theme.colorScheme.surface,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: Formation.values.map((formation) {
                  final isSelected = formation == _selectedFormation;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(formation.name),
                      selectedColor: theme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : bgTextColor,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedFormation = formation),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Soccer field - compact height with drag-and-drop support
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: SoccerFieldWidget(
                players: startingXI,
                formation: _selectedFormation,
                isEditable: true,
                height: 200,
                onPlayerTap: (player) => _showSubstitutionDialog(player),
                onSlotTap: (position, index) => _scrollToPosition(position),
                onPlayerSwap: _handlePlayerSwap,
              ),
            ),
            
            // Bench display - compact
            if (bench.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: SizedBox(
                  height: 60,
                  child: BenchWidget(
                    benchPlayers: bench,
                    isEditable: true,
                    compact: true,
                    onPlayerTap: (player) => _showSubstitutionDialog(player),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
  
  /// Show substitution dialog when tapping a player on the field
  void _showSubstitutionDialog(FantasyTeamPlayer player) {
    final theme = Theme.of(context);
    
    // Get players that can substitute for this position
    final playerIndex = _selectedPlayers.indexOf(player);
    final isOnBench = playerIndex >= 11;
    
    // Get compatible substitutes
    List<FantasyTeamPlayer> availableSwaps;
    if (isOnBench) {
      // Bench player - can swap with starting XI of same position
      availableSwaps = _selectedPlayers
          .take(11)
          .where((p) => p.position == player.position)
          .toList();
    } else {
      // Starting XI - can swap with bench players of same position
      availableSwaps = _selectedPlayers
          .skip(11)
          .where((p) => p.position == player.position)
          .toList();
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getPositionColor(player.position),
                  child: Text(
                    player.playerName.split(' ').take(2).map((s) => s.isNotEmpty ? s[0] : '').join(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.playerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${_getPositionName(player.position)} • ${player.teamName ?? ""}',
                        style: TextStyle(color: bgTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnBench ? Colors.grey : Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isOnBench ? 'BENCH' : 'STARTING',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Substitution options
            if (availableSwaps.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: bgTextColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isOnBench 
                            ? 'No starting players with same position to swap with'
                            : 'No substitutes with same position available',
                        style: TextStyle(color: bgTextColor),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Text(
                'Swap with:',
                style: TextStyle(color: bgTextColor, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...availableSwaps.map((swapPlayer) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _getPositionColor(swapPlayer.position),
                  child: Text(
                    swapPlayer.playerName.split(' ').take(2).map((s) => s.isNotEmpty ? s[0] : '').join(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                title: Text(swapPlayer.playerName),
                subtitle: Text(swapPlayer.teamName ?? '', style: TextStyle(color: bgTextColor)),
                trailing: ElevatedButton(
                  onPressed: () {
                    _swapPlayers(player, swapPlayer);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Swap', style: TextStyle(color: Colors.white)),
                ),
              )),
            ],
            
            const SizedBox(height: 16),
            
            // Remove from squad option
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _removePlayerFromSquad(player);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                label: const Text('Remove from Squad', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  /// Swap two players in the squad
  void _swapPlayers(FantasyTeamPlayer player1, FantasyTeamPlayer player2) {
    setState(() {
      final index1 = _selectedPlayers.indexOf(player1);
      final index2 = _selectedPlayers.indexOf(player2);
      if (index1 != -1 && index2 != -1) {
        _selectedPlayers[index1] = player2;
        _selectedPlayers[index2] = player1;
      }
    });
  }
  
  /// Remove player from squad
  void _removePlayerFromSquad(FantasyTeamPlayer player) {
    setState(() {
      _selectedPlayers.remove(player);
      _budgetRemaining += player.price;
    });
  }
  
  /// Scroll to a position section when empty slot is tapped
  void _scrollToPosition(String position) {
    // Just show a hint that they need to select a player
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Select a $position from the list below'),
        duration: const Duration(seconds: 2),
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
  
  String _getPositionName(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return 'Goalkeeper';
      case PlayerPosition.defender:
        return 'Defender';
      case PlayerPosition.midfielder:
        return 'Midfielder';
      case PlayerPosition.attacker:
      case PlayerPosition.forward:
        return 'Forward';
    }
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
                        _selectedTeamFilter?.name ?? 'All Teams',
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
                        onTap: () => _onTeamFilterChanged(null),
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
                        Navigator.pop(context);
                        _onTeamFilterChanged(null);
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
                      Navigator.pop(context);
                      _onTeamFilterChanged(null);
                    },
                  ),
                  const Divider(height: 1),
                  // Team list
                  ..._ligaMxTeams.map((team) {
                    final isSelected = _selectedTeamFilter?.id == team.id;
                    final playerCount = _allRosterPlayers.where((p) => p.teamId == team.id).length;
                    return ListTile(
                      leading: team.logo != null
                          ? CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(team.logo!),
                              backgroundColor: Colors.transparent,
                              radius: 16,
                            )
                          : Icon(
                              Icons.shield,
                              color: isSelected ? theme.primaryColor : bgTextColor,
                            ),
                      title: Text(
                        team.name,
                        style: TextStyle(
                          color: isSelected ? theme.primaryColor : null,
                          fontWeight: isSelected ? FontWeight.w600 : null,
                        ),
                      ),
                      subtitle: playerCount > 0 
                          ? Text(
                              '$playerCount loaded',
                              style: TextStyle(fontSize: 12, color: bgTextColor),
                            )
                          : null,
                      trailing: isSelected 
                          ? Icon(Icons.check, color: theme.primaryColor) 
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _onTeamFilterChanged(team);
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
      case PlayerSortOption.priceHigh:
      case PlayerSortOption.priceLow:
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
    final availableCount = _getFilteredPlayers().where((p) => p.positionCode.toUpperCase() == positionCode).length;
    
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
  
  /// Build horizontal team filter chips
  Widget _buildTeamFilterChips(ThemeData theme) {
    return Container(
      height: 50,
      color: theme.colorScheme.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _ligaMxTeams.length + 1, // +1 for "All Teams"
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All Teams" chip
            final isSelected = _selectedTeamFilter == null;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: const Text('All Teams'),
                selectedColor: theme.primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : bgTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) => _onTeamFilterChanged(null),
              ),
            );
          }
          
          final team = _ligaMxTeams[index - 1];
          final isSelected = _selectedTeamFilter?.id == team.id;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              avatar: team.logo != null
                  ? CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(team.logo!),
                      backgroundColor: Colors.transparent,
                    )
                  : null,
              label: Text(team.name),
              selectedColor: theme.primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : bgTextColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (_) => _onTeamFilterChanged(isSelected ? null : team),
            ),
          );
        },
      ),
    );
  }
  
  /// Build player list with infinite scroll
  Widget _buildPlayerListWithInfiniteScroll(ThemeData theme) {
    final filteredPlayers = _getFilteredPlayers();
    
    if (filteredPlayers.isEmpty && !_isLoadingMore) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: bgTextColor),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'No players found for "$_searchQuery"'
                  : 'Loading players...',
              style: TextStyle(color: bgTextColor),
            ),
            if (_selectedTeamFilter != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _onTeamFilterChanged(null),
                child: const Text('Clear team filter'),
              ),
            ],
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: filteredPlayers.length + (_hasMorePlayers ? 1 : 0),
      itemBuilder: (context, index) {
        // Loading indicator at the bottom
        if (index >= filteredPlayers.length) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }
        
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

  Widget _buildPlayerList(ThemeData theme, String positionCode) {
    final filteredPlayers = _getFilteredPlayers();
    
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
    final canAfford = player.price <= _budgetRemaining || isSelected;
    
    // Get position color
    final posColor = _getPositionColorFromCode(player.positionCode);
    
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
              // Player image with optional deceased banner
              Stack(
                children: [
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
                  // Easter egg: deceased banner for player 253780
                  if (player.id == 253780)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                        ),
                        child: const Text(
                          '💀 RIP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Star player badge (good recent form)
                  if (player.isStarPlayer && player.id != 253780)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: player.isElitePlayer ? Colors.amber : Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.star,
                          size: 12,
                          color: player.isElitePlayer ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                  // Cheeks badge (poor recent form) 🍑
                  if (player.isCheeks && player.id != 253780)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade400,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Text(
                          '🍑',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                ],
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
              
              // Price badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: canAfford 
                      ? theme.primaryColor.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${player.price.toStringAsFixed(1)}M',
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
    final canAfford = player.price <= _budgetRemaining || isSelected;
    final posColor = _getPositionColorFromCode(player.positionCode);
    
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
                                '\$${player.price.toStringAsFixed(1)}M',
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
                              : 'Add to Squad (\$${player.price.toStringAsFixed(1)}M)',
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

  Color _getPositionColorFromCode(String positionCode) {
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
  final LigaMxTeam? selectedTeam;
  final List<LigaMxTeam> teams;
  final Function(PlayerSortOption) onSortChanged;
  final Function(LigaMxTeam?) onTeamFilterChanged;
  final VoidCallback onClearFilters;

  const _SortFilterSheet({
    required this.currentSort,
    required this.selectedTeam,
    required this.teams,
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
          DropdownButtonFormField<int?>(
            value: selectedTeam?.id,
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
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All Teams'),
              ),
              ...teams.map((team) => DropdownMenuItem<int?>(
                value: team.id,
                child: Text(team.name, overflow: TextOverflow.ellipsis),
              )),
            ],
            onChanged: (int? teamId) {
              final team = teamId == null 
                  ? null 
                  : teams.firstWhere((t) => t.id == teamId);
              onTeamFilterChanged(team);
            },
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
          '${player.teamName ?? 'Unknown'} • \$${player.price.toStringAsFixed(1)}M',
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

// ==================== PLAYER SELECTION SHEET ====================

class _PlayerSelectionSheet extends StatefulWidget {
  final List<RosterPlayer> allPlayers;
  final List<FantasyTeamPlayer> selectedPlayers;
  final double budgetRemaining;
  final PlayerPosition? filterPosition;
  final List<LigaMxTeam> ligaMxTeams;
  final Function(RosterPlayer) onPlayerSelected;
  final Function(RosterPlayer) onViewProfile;
  
  const _PlayerSelectionSheet({
    required this.allPlayers,
    required this.selectedPlayers,
    required this.budgetRemaining,
    this.filterPosition,
    required this.ligaMxTeams,
    required this.onPlayerSelected,
    required this.onViewProfile,
  });
  
  @override
  State<_PlayerSelectionSheet> createState() => _PlayerSelectionSheetState();
}

class _PlayerSelectionSheetState extends State<_PlayerSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  PlayerSortOption _sortOption = PlayerSortOption.pointsHigh;
  LigaMxTeam? _selectedTeam;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  /// Handle search query change
  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
  }
  
  List<RosterPlayer> get _filteredPlayers {
    var players = widget.allPlayers.where((p) {
      // Don't show already selected players
      if (widget.selectedPlayers.any((sp) => sp.playerId == p.id)) {
        return false;
      }

      // Filter by position if specified
      if (widget.filterPosition != null) {
        final playerPos = _positionFromCode(p.positionCode);
        if (playerPos != widget.filterPosition) {
          return false;
        }
      }
      
      // Filter by search query - check name, displayName, and teamName
      // Also normalize accents for better matching
      if (_searchQuery.isNotEmpty) {
        final query = _normalizeString(_searchQuery.toLowerCase());
        final normalizedName = _normalizeString(p.name.toLowerCase());
        final normalizedDisplayName = _normalizeString(p.displayName.toLowerCase());
        final normalizedTeamName = _normalizeString(p.teamName.toLowerCase());
        
        final nameMatch = normalizedName.contains(query);
        final displayNameMatch = normalizedDisplayName.contains(query);
        final teamMatch = normalizedTeamName.contains(query);
        
        if (!nameMatch && !displayNameMatch && !teamMatch) {
          return false;
        }
      }
      
      // Filter by team
      if (_selectedTeam != null && p.teamId != _selectedTeam!.id) {
        return false;
      }
      
      return true;
    }).toList();
    
    debugPrint('Filtered to ${players.length} players');
    
    // Sort
    switch (_sortOption) {
      case PlayerSortOption.pointsHigh:
        players.sort((a, b) => b.projectedPoints.compareTo(a.projectedPoints));
        break;
      case PlayerSortOption.pointsLow:
        players.sort((a, b) => a.projectedPoints.compareTo(b.projectedPoints));
        break;
      case PlayerSortOption.priceHigh:
        players.sort((a, b) => b.price.compareTo(a.price));
        break;
      case PlayerSortOption.priceLow:
        players.sort((a, b) => a.price.compareTo(b.price));
        break;
      case PlayerSortOption.nameAZ:
        players.sort((a, b) => a.name.compareTo(b.name));
        break;
      case PlayerSortOption.selectedPercent:
        // No selected percent data, fallback to points
        players.sort((a, b) => b.projectedPoints.compareTo(a.projectedPoints));
        break;
    }
    
    return players;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredPlayers = _filteredPlayers;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
                    Icon(
                      widget.filterPosition != null 
                          ? _getPositionIcon(widget.filterPosition!)
                          : Icons.person_add,
                      color: theme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.filterPosition != null 
                            ? 'Select ${_getPositionName(widget.filterPosition!)}'
                            : 'Add Player',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.budgetRemaining > 0 
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.budgetRemaining.toStringAsFixed(1)} left',
                        style: TextStyle(
                          color: widget.budgetRemaining > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or team...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: bgColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Filter/Sort row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Sort dropdown
                    Expanded(
                      child: DropdownButtonFormField<PlayerSortOption>(
                        value: _sortOption,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        items: PlayerSortOption.values.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(_getSortLabel(opt), style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _sortOption = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Team filter dropdown
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedTeam?.id,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: bgColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<int?>(value: null, child: Text('All Teams', style: TextStyle(fontSize: 12))),
                          ...widget.ligaMxTeams.map((team) => DropdownMenuItem<int?>(
                            value: team.id,
                            child: Text(team.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                          )),
                        ],
                        onChanged: (teamId) {
                          setState(() {
                            _selectedTeam = teamId == null 
                                ? null 
                                : widget.ligaMxTeams.firstWhere((t) => t.id == teamId);
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${filteredPlayers.length} players',
                      style: TextStyle(color: bgTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              
              // Player list
              Expanded(
                child: filteredPlayers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 48, color: bgTextColor),
                            const SizedBox(height: 8),
                            Text('No players found', style: TextStyle(color: bgTextColor)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPlayers.length,
                        itemBuilder: (context, index) {
                          final player = filteredPlayers[index];
                          final canAfford = player.price <= widget.budgetRemaining;
                          
                          return _buildPlayerCard(theme, player, canAfford);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPlayerCard(ThemeData theme, RosterPlayer player, bool canAfford) {
    final posColor = _getPositionColorFromCode(player.positionCode);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: bgColor,
      child: InkWell(
        onTap: () => widget.onViewProfile(player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player image with position indicator
              Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                  // Position badge overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: posColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: bgColor, width: 1),
                      ),
                      child: Text(
                        player.positionCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                  // Easter egg: deceased banner for player 253780 😂
                  if (player.id == 253780)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                        ),
                        child: const Text(
                          '💀 RIP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Star player badge (good recent form) ⭐
                  if (player.isStarPlayer && player.id != 253780)
                    Positioned(
                      top: -2,
                      left: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: player.isElitePlayer ? Colors.amber : Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Cheeks badge (poor recent form) 🍑
                  if (player.isCheeks && player.id != 253780)
                    Positioned(
                      top: -2,
                      left: -2,
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade400,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        child: const Text(
                          '🍑',
                          style: TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              
              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        if (player.teamLogo != null && player.teamLogo!.isNotEmpty) ...[
                          CachedNetworkImage(
                            imageUrl: player.teamLogo!,
                            width: 14,
                            height: 14,
                            placeholder: (_, __) => const SizedBox.shrink(),
                            errorWidget: (_, __, ___) => const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            player.teamName,
                            style: TextStyle(color: bgTextColor, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 14, color: theme.primaryColor),
                      const SizedBox(width: 2),
                      Text(
                        '${player.projectedPoints.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${player.price.toStringAsFixed(1)}M',
                    style: TextStyle(
                      color: canAfford ? bgTextColor : Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              
              // Add button
              IconButton(
                onPressed: canAfford ? () => widget.onPlayerSelected(player) : null,
                icon: Icon(
                  Icons.add_circle,
                  color: canAfford ? Colors.green : bgTextColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
  
  IconData _getPositionIcon(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return Icons.sports_handball;
      case PlayerPosition.defender:
        return Icons.shield;
      case PlayerPosition.midfielder:
        return Icons.swap_horiz;
      case PlayerPosition.attacker:
      case PlayerPosition.forward:
        return Icons.sports_soccer;
    }
  }
  
  String _getPositionName(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return 'Goalkeeper';
      case PlayerPosition.defender:
        return 'Defender';
      case PlayerPosition.midfielder:
        return 'Midfielder';
      case PlayerPosition.attacker:
      case PlayerPosition.forward:
        return 'Forward';
    }
  }
  
  String _getSortLabel(PlayerSortOption option) {
    return option.displayName;
  }
  
  /// Normalize string by removing accents for better search matching
  String _normalizeString(String input) {
    const accentsLower = 'àáâãäåæçèéêëìíîïðñòóôõöøùúûüýÿ';
    const accentsUpper = 'ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝŸ';
    const withoutAccentsLower = 'aaaaaaaceeeeiiiidnooooooouuuuyy';
    const withoutAccentsUpper = 'AAAAAAACEEEEIIIIDNOOOOOOOUUUUYY';
    
    var result = input;
    for (var i = 0; i < accentsLower.length; i++) {
      result = result.replaceAll(accentsLower[i], withoutAccentsLower[i]);
      result = result.replaceAll(accentsUpper[i], withoutAccentsUpper[i]);
    }
    return result;
  }
  
  PlayerPosition _positionFromCode(String code) {
    switch (code.toUpperCase()) {
      case 'GK':
        return PlayerPosition.goalkeeper;
      case 'DEF':
        return PlayerPosition.defender;
      case 'MID':
        return PlayerPosition.midfielder;
      case 'ATT':
      return PlayerPosition.attacker;
      case 'ST':
      case 'FWD':
      case 'CF':
        return PlayerPosition.forward;
      default:
        return PlayerPosition.midfielder;
    }
  }
  
  Color _getPositionColorFromCode(String positionCode) {
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
}
