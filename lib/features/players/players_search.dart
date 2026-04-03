import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/player/models/player_info.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:fantacy11/services/cache_service.dart';
import 'package:fantacy11/utils/country_name_localizer.dart';
import 'package:flutter/material.dart';

/// Helper to convert position icon name to IconData
IconData _getPositionIcon(String iconName) {
  switch (iconName) {
    case 'sports_handball':
      return Icons.sports_handball;
    case 'shield':
      return Icons.shield;
    case 'swap_horiz':
      return Icons.swap_horiz;
    case 'sports_soccer':
      return Icons.sports_soccer;
    default:
      return Icons.person;
  }
}

/// Players search screen with local caching
/// Searches active Liga MX players from cached team rosters
class PlayersSearch extends StatefulWidget {
  const PlayersSearch({super.key});

  @override
  State<PlayersSearch> createState() => _PlayersSearchState();
}

// Sort options enum
enum PlayerSortOption {
  pointsHighToLow,
  pointsLowToHigh,
  priceHighToLow,
  priceLowToHigh,
  nameAZ,
}

class _PlayersSearchState extends State<PlayersSearch> {
  final PlayersRepository _repository = PlayersRepository();
  final CacheService _cache = CacheService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Current state
  List<Player> _recentPlayers = [];
  String? _error;
  String _lastQuery = '';

  // Active Liga MX players from cached team rosters
  List<RosterPlayer> _cachedPlayers = [];
  List<RosterPlayer> _searchResults = [];
  List<RosterPlayer> _filteredPlayers = [];
  bool _isLoadingInitial = true;

  // Filters
  String? _selectedTeam;
  String? _selectedPosition;
  PlayerSortOption _sortOption = PlayerSortOption.pointsHighToLow;
  bool _showFilters = false;

  // Available filter options (populated from data)
  List<String> _availableTeams = [];
  final List<String> _availablePositions = ['GK', 'DEF', 'MID', 'FWD'];

  String _tr(String en, String es) =>
      Localizations.localeOf(context).languageCode == 'es' ? es : en;

  String _sortLabel(PlayerSortOption option) {
    switch (option) {
      case PlayerSortOption.pointsHighToLow:
        return _tr('Points (High → Low)', 'Puntos (Mayor → Menor)');
      case PlayerSortOption.pointsLowToHigh:
        return _tr('Points (Low → High)', 'Puntos (Menor → Mayor)');
      case PlayerSortOption.priceHighToLow:
        return _tr('Price (High → Low)', 'Precio (Mayor → Menor)');
      case PlayerSortOption.priceLowToHigh:
        return _tr('Price (Low → High)', 'Precio (Menor → Mayor)');
      case PlayerSortOption.nameAZ:
        return _tr('Name (A → Z)', 'Nombre (A → Z)');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Load players - first from Hive cache, then from Firestore if needed
  Future<void> _loadInitialData() async {
    setState(() => _isLoadingInitial = true);

    try {
      // Load recent players for display
      final cachedPlayersList = _cache.getRecentPlayers();
      if (cachedPlayersList.isNotEmpty) {
        _recentPlayers = cachedPlayersList
            .map((json) => Player.fromJson(json))
            .toList();
      }

      // First try to get from Hive cache
      _cachedPlayers = _repository.getCachedPlayers();
      debugPrint(
        'PlayersSearch: Found ${_cachedPlayers.length} players in Hive cache',
      );

      // If cache is empty or has very few players, load from Firestore
      if (_cachedPlayers.length < 100) {
        debugPrint(
          'PlayersSearch: Cache insufficient, loading from Firestore...',
        );
        final firestorePlayers = await _repository
            .loadAllPlayersFromFirestore();
        if (firestorePlayers.isNotEmpty) {
          _cachedPlayers = firestorePlayers;
          debugPrint(
            'PlayersSearch: Loaded ${_cachedPlayers.length} players from Firestore',
          );
        }
      }

      // Extract unique teams for filter
      _extractAvailableTeams();

      // Apply initial filters
      _applyFilters();

      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (mounted) {
        setState(() => _isLoadingInitial = false);
      }
    }
  }

  /// Extract unique teams from cached players
  void _extractAvailableTeams() {
    final teams = _cachedPlayers
        .map((p) => p.teamName)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    teams.sort();
    _availableTeams = teams;
  }

  /// Apply filters and sorting to players
  void _applyFilters() {
    List<RosterPlayer> result = List.from(_cachedPlayers);

    // Filter by team
    if (_selectedTeam != null) {
      result = result.where((p) => p.teamName == _selectedTeam).toList();
    }

    // Filter by position
    if (_selectedPosition != null) {
      result = result
          .where((p) => p.positionCode.toUpperCase() == _selectedPosition)
          .toList();
    }

    // Apply text search if active
    if (_lastQuery.isNotEmpty && _lastQuery.length >= 2) {
      final normalizedQuery = _normalizeString(_lastQuery);
      result = result.where((p) {
        return _normalizeString(p.name).contains(normalizedQuery) ||
            _normalizeString(p.displayName).contains(normalizedQuery) ||
            _normalizeString(p.teamName).contains(normalizedQuery);
      }).toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case PlayerSortOption.pointsHighToLow:
        result.sort((a, b) => b.projectedPoints.compareTo(a.projectedPoints));
        break;
      case PlayerSortOption.pointsLowToHigh:
        result.sort((a, b) => a.projectedPoints.compareTo(b.projectedPoints));
        break;
      case PlayerSortOption.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case PlayerSortOption.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case PlayerSortOption.nameAZ:
        result.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
    }

    _filteredPlayers = result;
    if (_lastQuery.isNotEmpty) {
      _searchResults = result.take(50).toList();
    }
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedTeam = null;
      _selectedPosition = null;
      _sortOption = PlayerSortOption.pointsHighToLow;
      _applyFilters();
    });
  }

  /// Check if any filters are active
  bool get _hasActiveFilters =>
      _selectedTeam != null ||
      _selectedPosition != null ||
      _sortOption != PlayerSortOption.pointsHighToLow;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _repository.dispose();
    super.dispose();
  }

  /// Clear search history from cache and UI
  Future<void> _clearSearchHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).clearHistoryTitle),
        content: Text(S.of(context).clearHistoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.of(context).clear),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _cache.clearPlayersCache();
      setState(() {
        _recentPlayers = [];
        _cachedPlayers = [];
        _searchResults = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).searchHistoryCleared),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Search players from cached active Liga MX players only
  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _lastQuery = '';
        _error = null;
        _applyFilters();
      });
      return;
    }

    if (query.length < 2) {
      return;
    }

    _performSearch(query);
  }

  /// Search from cached active Liga MX players
  void _performSearch(String query) {
    setState(() {
      _lastQuery = query;
      _error = null;
      _applyFilters();
    });
  }

  /// Normalize string for search (remove accents, lowercase)
  String _normalizeString(String input) {
    const withAccents =
        'àáâãäåèéêëìíîïòóôõöùúûüýÿñçÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÝŸÑÇ';
    const withoutAccents =
        'aaaaaaeeeeiiiiooooouuuuyyncAAAAAAAAAEEEEIIIIOOOOOUUUUYYNC';

    var result = input.toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  /// Add player to recent list when viewed
  void _onPlayerTap(Player player) async {
    // Add to recent players cache (Hive)
    await _cache.addRecentPlayer(player.toJson());

    // Update local state
    setState(() {
      _recentPlayers.removeWhere((p) => p.id == player.id);
      _recentPlayers.insert(0, player);
      if (_recentPlayers.length > 10) {
        _recentPlayers = _recentPlayers.sublist(0, 10);
      }
    });

    // Navigate to player details
    if (mounted) {
      Navigator.pushNamed(context, PageRoutes.playerDetails, arguments: player);
    }
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _lastQuery = '';
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(S.of(context).players),
        centerTitle: false,
        elevation: 0,
        actions: [
          // Filter toggle button
          IconButton(
            icon: Badge(
              isLabelVisible: _hasActiveFilters,
              backgroundColor: Colors.red,
              child: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: _showFilters ? theme.primaryColor : Colors.white,
              ),
            ),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: _tr('Filters', 'Filtros'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: S.of(context).searchPlayersHint,
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[500]),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          // Filters section (collapsible)
          if (_showFilters) _buildFiltersSection(theme),

          // Player count info with active filter indicator
          if (_cachedPlayers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.sports_soccer, size: 14, color: bgTextColor),
                  const SizedBox(width: 6),
                  Text(
                    _hasActiveFilters
                        ? _tr(
                            '${_filteredPlayers.length} of ${_cachedPlayers.length} players',
                            '${_filteredPlayers.length} de ${_cachedPlayers.length} jugadores',
                          )
                        : _tr(
                            '${_cachedPlayers.length} players available',
                            '${_cachedPlayers.length} jugadores disponibles',
                          ),
                    style: TextStyle(fontSize: 12, color: bgTextColor),
                  ),
                  if (_hasActiveFilters) ...[
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 14),
                      label: Text(_tr('Clear filters', 'Limpiar filtros')),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 4),

          // Content
          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  /// Build the filters section
  Widget _buildFiltersSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Position filter chips
          Text(
            _tr('Position', 'Posición'),
            style: TextStyle(
              fontSize: 11,
              color: bgTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPositionChip(null, _tr('All', 'Todos'), theme),
                ..._availablePositions.map(
                  (pos) => _buildPositionChip(pos, pos, theme),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Team dropdown
          Text(
            _tr('Team', 'Equipo'),
            style: TextStyle(
              fontSize: 11,
              color: bgTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: DropdownButton<String?>(
              value: _selectedTeam,
              hint: Text(
                _tr('All Teams', 'Todos los equipos'),
                style: const TextStyle(fontSize: 13),
              ),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: theme.colorScheme.surface,
              style: TextStyle(color: Colors.white, fontSize: 13),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(_tr('All Teams', 'Todos los equipos')),
                ),
                ..._availableTeams.map(
                  (team) => DropdownMenuItem<String?>(
                    value: team,
                    child: Text(
                      CountryNameLocalizer.localize(context, team),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTeam = value;
                  _applyFilters();
                });
              },
            ),
          ),

          const SizedBox(height: 12),

          // Sort dropdown
          Text(
            _tr('Sort by', 'Ordenar por'),
            style: TextStyle(
              fontSize: 11,
              color: bgTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: DropdownButton<PlayerSortOption>(
              value: _sortOption,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: theme.colorScheme.surface,
              style: TextStyle(color: Colors.white, fontSize: 13),
              items: [
                DropdownMenuItem(
                  value: PlayerSortOption.pointsHighToLow,
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Text(_sortLabel(PlayerSortOption.pointsHighToLow)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PlayerSortOption.pointsLowToHigh,
                  child: Row(
                    children: [
                      Icon(Icons.trending_down, size: 16, color: Colors.red),
                      SizedBox(width: 8),
                      Text(_sortLabel(PlayerSortOption.pointsLowToHigh)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PlayerSortOption.priceHighToLow,
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.amber),
                      SizedBox(width: 8),
                      Text(_sortLabel(PlayerSortOption.priceHighToLow)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PlayerSortOption.priceLowToHigh,
                  child: Row(
                    children: [
                      Icon(Icons.money_off, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(_sortLabel(PlayerSortOption.priceLowToHigh)),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: PlayerSortOption.nameAZ,
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(_sortLabel(PlayerSortOption.nameAZ)),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _sortOption = value;
                    _applyFilters();
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build a position filter chip
  Widget _buildPositionChip(String? position, String label, ThemeData theme) {
    final isSelected = _selectedPosition == position;
    Color chipColor;

    switch (position) {
      case 'GK':
        chipColor = Colors.orange;
        break;
      case 'DEF':
        chipColor = Colors.blue;
        break;
      case 'MID':
        chipColor = Colors.green;
        break;
      case 'FWD':
        chipColor = Colors.red;
        break;
      default:
        chipColor = theme.primaryColor;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : bgTextColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedPosition = selected ? position : null;
            _applyFilters();
          });
        },
        backgroundColor: theme.colorScheme.surface,
        selectedColor: chipColor,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? chipColor : Colors.grey.withValues(alpha: 0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // Initial loading state
    if (_isLoadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadInitialData(),
                child: Text(S.of(context).retry),
              ),
            ],
          ),
        ),
      );
    }

    // Search results (text search active)
    if (_lastQuery.isNotEmpty) {
      if (_searchResults.isEmpty) {
        return _buildEmptySearchState();
      }
      return _buildRosterPlayersList(
        _searchResults,
        _tr('Search Results', 'Resultados de búsqueda'),
      );
    }

    // Filtered results (filters active but no text search)
    if (_hasActiveFilters && _filteredPlayers.isNotEmpty) {
      return _buildRosterPlayersList(
        _filteredPlayers.take(100).toList(),
        _tr('Filtered Players', 'Jugadores filtrados'),
        subtitle: _tr(
          '${_filteredPlayers.length} found',
          '${_filteredPlayers.length} encontrados',
        ),
      );
    }

    // Empty filter results
    if (_hasActiveFilters && _filteredPlayers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt_off, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                _tr(
                  'No players match your filters',
                  'No hay jugadores que coincidan con tus filtros',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear),
                label: Text(_tr('Clear Filters', 'Limpiar filtros')),
              ),
            ],
          ),
        ),
      );
    }

    // Initial state - show top players from cache
    if (_cachedPlayers.isNotEmpty && _lastQuery.isEmpty) {
      final popularPlayers = List<RosterPlayer>.from(
        _filteredPlayers.isNotEmpty ? _filteredPlayers : _cachedPlayers,
      )..sort((a, b) => b.projectedPoints.compareTo(a.projectedPoints));
      return _buildRosterPlayersList(
        popularPlayers.take(50).toList(),
        _tr('Top Players', 'Jugadores destacados'),
        subtitle: _tr(
          '${_cachedPlayers.length} total',
          '${_cachedPlayers.length} en total',
        ),
      );
    }

    // Show recent players if available
    if (_recentPlayers.isNotEmpty) {
      return _buildPlayersList(
        _recentPlayers,
        S.of(context).recentPlayersTitle,
        showClearButton: true,
      );
    }

    // Empty state - need to build team first
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 24),
            Text(
              _tr('No Players Loaded', 'No hay jugadores cargados'),
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _tr(
                'Create or join a league and build your team to load players',
                'Crea o únete a una liga y arma tu equipo para cargar jugadores',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersList(
    List<Player> players,
    String title, {
    bool showClearButton = false,
  }) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: players.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: bgTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${players.length})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (showClearButton) ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _clearSearchHistory,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(S.of(context).clear),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        final player = players[index - 1];
        return _buildPlayerCard(player, theme);
      },
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              S.of(context).noPlayersFoundFor(_lastQuery),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).tryDifferentSearch,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterPlayersList(
    List<RosterPlayer> players,
    String title, {
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: players.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: bgTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${players.length})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (subtitle != null) ...[
                  const Spacer(),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ],
            ),
          );
        }

        final player = players[index - 1];
        return _buildRosterPlayerCard(player, theme);
      },
    );
  }

  Widget _buildRosterPlayerCard(RosterPlayer player, ThemeData theme) {
    // Get position color
    Color positionColor;
    switch (player.positionCode.toUpperCase()) {
      case 'GK':
        positionColor = Colors.orange;
        break;
      case 'DEF':
        positionColor = Colors.blue;
        break;
      case 'MID':
        positionColor = Colors.green;
        break;
      default:
        positionColor = Colors.red;
    }

    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onRosterPlayerTap(player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player image with optional easter egg
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor,
                      border: Border.all(
                        color: positionColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child:
                          player.imagePath != null &&
                              player.imagePath!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: player.imagePath!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  _buildPlayerInitials(player),
                              errorWidget: (context, url, error) =>
                                  _buildPlayerInitials(player),
                            )
                          : _buildPlayerInitials(player),
                    ),
                  ),
                  // Easter egg: deceased banner for player 253780 💀
                  if (player.id == 253780)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                        ),
                        child: const Text(
                          '💀 RIP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Star player badge (good recent form) ⭐
                  if (player.isStarPlayer && player.id != 253780)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: player.isElitePlayer
                              ? Colors.amber
                              : Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.star,
                          size: 12,
                          color: Colors.white,
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
                        child: const Text('🍑', style: TextStyle(fontSize: 11)),
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: positionColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            player.positionCode,
                            style: TextStyle(
                              fontSize: 10,
                              color: positionColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            CountryNameLocalizer.localize(
                              context,
                              player.teamName,
                            ),
                            style: TextStyle(fontSize: 12, color: bgTextColor),
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
                          player.projectionSummary,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.attach_money, size: 12, color: bgTextColor),
                        const SizedBox(width: 2),
                        Text(
                          '\$${player.price.toStringAsFixed(1)}M',
                          style: TextStyle(fontSize: 11, color: bgTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(Icons.chevron_right, color: bgTextColor),
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
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: bgTextColor,
        ),
      ),
    );
  }

  /// Handle tap on roster player - fetch full details and navigate
  Future<void> _onRosterPlayerTap(RosterPlayer rosterPlayer) async {
    // Try to fetch full player details
    final fullPlayer = await _repository.getPlayerById(rosterPlayer.id);

    if (fullPlayer != null && mounted) {
      // Add to recent players
      await _cache.addRecentPlayer(fullPlayer.toJson());
      setState(() {
        _recentPlayers.removeWhere((p) => p.id == fullPlayer.id);
        _recentPlayers.insert(0, fullPlayer);
        if (_recentPlayers.length > 10) {
          _recentPlayers = _recentPlayers.sublist(0, 10);
        }
      });

      // Navigate to player details
      Navigator.pushNamed(
        context,
        PageRoutes.playerDetails,
        arguments: fullPlayer,
      );
    } else {
      // Show message that full details aren't available
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not load full details for ${rosterPlayer.displayName}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildPlayerCard(Player player, ThemeData theme) {
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onPlayerTap(player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player image with optional easter egg
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bgColor,
                      border: Border.all(
                        color: player.position != null
                            ? Color(
                                player.position!.colorValue,
                              ).withValues(alpha: 0.5)
                            : theme.primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: player.hasRealImage
                          ? CachedNetworkImage(
                              imageUrl: player.imagePath!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(
                                Icons.person,
                                color: bgTextColor,
                                size: 28,
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                color: bgTextColor,
                                size: 28,
                              ),
                            )
                          : Icon(Icons.person, color: bgTextColor, size: 28),
                    ),
                  ),
                  // Easter egg: deceased banner for player 253780 💀
                  if (player.id == 253780)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                        ),
                        child: const Text(
                          '💀 RIP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (player.position != null) ...[
                          Icon(
                            _getPositionIcon(player.position!.iconName),
                            size: 14,
                            color: Color(player.position!.colorValue),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            player.detailedPosition?.name ??
                                player.position!.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (player.nationality != null) ...[
                          const SizedBox(width: 12),
                          if (player.nationality!.imagePath != null)
                            CachedNetworkImage(
                              imageUrl: player.nationality!.imagePath!,
                              width: 16,
                              height: 12,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  const SizedBox.shrink(),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            player.nationality!.fifaName ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}
