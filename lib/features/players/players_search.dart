import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/player/models/player_info.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:fantacy11/services/cache_service.dart';
import 'package:flutter/material.dart';

/// Players search screen with local caching
class PlayersSearch extends StatefulWidget {
  const PlayersSearch({super.key});

  @override
  State<PlayersSearch> createState() => _PlayersSearchState();
}

class _PlayersSearchState extends State<PlayersSearch> {
  final PlayersRepository _repository = PlayersRepository();
  final CacheService _cache = CacheService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Current state
  List<Player> _players = [];
  List<Player> _recentPlayers = [];
  bool _isLoading = false;
  String? _error;
  String _lastQuery = '';
  
  // Liga MX roster mode - searches only current Liga MX players
  bool _ligaMxOnly = true; // Default to Liga MX only for better accuracy
  List<RosterPlayer> _rosterPlayers = [];
  List<RosterPlayer> _filteredRosterPlayers = [];
  bool _isLoadingRoster = false;
  
  // Debounce timer
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadRecentPlayers();
    if (_ligaMxOnly) {
      _loadLigaMxRoster();
    }
  }

  /// Load Liga MX roster players for accurate search
  Future<void> _loadLigaMxRoster() async {
    setState(() => _isLoadingRoster = true);
    try {
      final roster = await _repository.getLigaMxRosterPlayers();
      if (mounted) {
        setState(() {
          _rosterPlayers = roster;
          _isLoadingRoster = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoster = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }

  /// Load recent players from Hive cache
  Future<void> _loadRecentPlayers() async {
    final cachedPlayers = _cache.getRecentPlayers();
    if (cachedPlayers.isNotEmpty) {
      setState(() {
        _recentPlayers = cachedPlayers.map((json) => Player.fromJson(json)).toList();
      });
    } else {
      // Load demo player if no recent players
      _loadDemoPlayer();
    }
  }

  /// Load demo player as initial content (only if no recent players)
  Future<void> _loadDemoPlayer() async {
    final demoPlayer = await _repository.getDemoPlayer();
    if (demoPlayer != null && mounted) {
      await _cache.addRecentPlayer(demoPlayer.toJson());
      setState(() {
        _recentPlayers = [demoPlayer];
      });
    }
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
        _players = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).searchHistoryCleared),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Search players with debouncing
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _players = [];
        _filteredRosterPlayers = [];
        _lastQuery = '';
        _error = null;
      });
      return;
    }

    if (query.length < 2) {
      // Don't search for very short queries
      return;
    }

    // If Liga MX only mode, filter locally from roster
    if (_ligaMxOnly && _rosterPlayers.isNotEmpty) {
      _performRosterSearch(query);
      return;
    }

    // Check cache first for global search
    final cachedResults = _cache.getPlayerSearchResults(query);
    if (cachedResults != null) {
      setState(() {
        _players = cachedResults.map((json) => Player.fromJson(json)).toList();
        _lastQuery = query;
        _error = null;
      });
      return;
    }

    // Debounce API call
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  /// Perform local roster search (faster, more accurate for Liga MX)
  void _performRosterSearch(String query) {
    final lowerQuery = query.toLowerCase();
    final results = _rosterPlayers.where((p) {
      return p.name.toLowerCase().contains(lowerQuery) ||
             p.displayName.toLowerCase().contains(lowerQuery) ||
             p.teamName.toLowerCase().contains(lowerQuery);
    }).toList();
    
    // Sort by relevance (exact matches first, then by projected points)
    results.sort((a, b) {
      // Exact name start match gets priority
      final aStartsWith = a.displayName.toLowerCase().startsWith(lowerQuery) ? 0 : 1;
      final bStartsWith = b.displayName.toLowerCase().startsWith(lowerQuery) ? 0 : 1;
      if (aStartsWith != bStartsWith) return aStartsWith.compareTo(bStartsWith);
      
      // Then by projected points
      return b.projectedPoints.compareTo(a.projectedPoints);
    });
    
    setState(() {
      _filteredRosterPlayers = results.take(50).toList();
      _lastQuery = query;
      _error = null;
    });
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _repository.searchPlayers(query);
      
      if (!mounted) return;

      // Cache the results (store as JSON for Hive)
      await _cache.cachePlayerSearchResults(
        query,
        results.map((p) => p.toJson()).toList(),
      );

      setState(() {
        _players = results;
        _lastQuery = query;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to search players: $e';
        _isLoading = false;
      });
    }
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
      Navigator.pushNamed(
        context,
        PageRoutes.playerDetails,
        arguments: player,
      );
    }
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _players = [];
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
                hintText: _ligaMxOnly 
                    ? 'Search Liga MX players...'
                    : S.of(context).searchPlayersHint,
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

          // Liga MX Only Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _ligaMxOnly = !_ligaMxOnly;
                        if (_ligaMxOnly && _rosterPlayers.isEmpty) {
                          _loadLigaMxRoster();
                        }
                        // Re-search with current query
                        if (_searchController.text.isNotEmpty) {
                          _onSearchChanged(_searchController.text);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _ligaMxOnly 
                            ? theme.primaryColor.withValues(alpha: 0.2)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: _ligaMxOnly 
                            ? Border.all(color: theme.primaryColor)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _ligaMxOnly ? Icons.check_circle : Icons.circle_outlined,
                            size: 18,
                            color: _ligaMxOnly ? theme.primaryColor : bgTextColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Liga MX Only',
                            style: TextStyle(
                              color: _ligaMxOnly ? theme.primaryColor : bgTextColor,
                              fontWeight: _ligaMxOnly ? FontWeight.w600 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          if (_ligaMxOnly && _rosterPlayers.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_rosterPlayers.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isLoadingRoster)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: _buildContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    // Loading state
    if (_isLoading) {
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
                onPressed: () => _performSearch(_lastQuery),
                child: Text(S.of(context).retry),
              ),
            ],
          ),
        ),
      );
    }

    // Search results - Liga MX roster mode
    if (_lastQuery.isNotEmpty && _ligaMxOnly) {
      if (_filteredRosterPlayers.isEmpty) {
        return _buildEmptySearchState();
      }
      return _buildRosterPlayersList(_filteredRosterPlayers, 'Liga MX Results');
    }

    // Search results - Global mode
    if (_lastQuery.isNotEmpty && !_ligaMxOnly) {
      if (_players.isEmpty) {
        return _buildEmptySearchState();
      }
      return _buildPlayersList(_players, S.of(context).searchResultsTitle);
    }

    // Initial state - show Liga MX players preview if in Liga MX mode
    if (_ligaMxOnly && _rosterPlayers.isNotEmpty && _lastQuery.isEmpty) {
      // Show popular Liga MX players
      final popularPlayers = List<RosterPlayer>.from(_rosterPlayers)
        ..sort((a, b) => b.projectedPoints.compareTo(a.projectedPoints));
      return _buildRosterPlayersList(
        popularPlayers.take(30).toList(), 
        'Top Liga MX Players',
        subtitle: '${_rosterPlayers.length} players available',
      );
    }

    // Initial state - show recent players or hint
    if (_recentPlayers.isNotEmpty) {
      return _buildPlayersList(_recentPlayers, S.of(context).recentPlayersTitle, showClearButton: true);
    }

    // Empty state with hint
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 24),
            Text(
              _ligaMxOnly ? 'Search Liga MX Players' : S.of(context).searchForPlayers,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).enterAtLeast3Chars,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersList(List<Player> players, String title, {bool showClearButton = false}) {
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
              _ligaMxOnly 
                  ? 'Try disabling "Liga MX Only" for global search'
                  : S.of(context).tryDifferentSearch,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (_ligaMxOnly) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _ligaMxOnly = false);
                  _onSearchChanged(_searchController.text);
                },
                child: const Text('Search all players'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRosterPlayersList(
    List<RosterPlayer> players, 
    String title, 
    {String? subtitle}
  ) {
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
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _onRosterPlayerTap(player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player image
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
                  child: player.imagePath != null && player.imagePath!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: player.imagePath!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => _buildPlayerInitials(player),
                          errorWidget: (context, url, error) => _buildPlayerInitials(player),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            player.teamName,
                            style: TextStyle(
                              fontSize: 12,
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
                          style: const TextStyle(fontSize: 11, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.attach_money, size: 12, color: bgTextColor),
                        const SizedBox(width: 2),
                        Text(
                          '${player.credits} cr',
                          style: TextStyle(fontSize: 11, color: bgTextColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: bgTextColor,
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
            content: Text('Could not load full details for ${rosterPlayer.displayName}'),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _onPlayerTap(player),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player image
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  border: Border.all(
                    color: player.position?.color.withValues(alpha: 0.5) ?? 
                           theme.primaryColor.withValues(alpha: 0.5),
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
                      : Icon(
                          Icons.person,
                          color: bgTextColor,
                          size: 28,
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
                            player.position!.icon,
                            size: 14,
                            color: player.position!.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            player.detailedPosition?.name ?? player.position!.name,
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
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

