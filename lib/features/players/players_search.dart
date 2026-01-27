import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/player/models/player_info.dart';
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
  
  // Debounce timer
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadRecentPlayers();
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
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear your recent players history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
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
        const SnackBar(
          content: Text('Search history cleared'),
          duration: Duration(seconds: 2),
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
        _lastQuery = '';
        _error = null;
      });
      return;
    }

    if (query.length < 3) {
      // Don't search for very short queries
      return;
    }

    // Check cache first
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
        title: const Text('Players'),
        centerTitle: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search players by name...',
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
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Search results
    if (_lastQuery.isNotEmpty) {
      if (_players.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_search, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text(
                  'No players found for "$_lastQuery"',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      }

      return _buildPlayersList(_players, 'Search Results');
    }

    // Initial state - show recent players or hint
    if (_recentPlayers.isNotEmpty) {
      return _buildPlayersList(_recentPlayers, 'Recent Players', showClearButton: true);
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
              'Search for Players',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter at least 3 characters to search',
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
                    label: const Text('Clear'),
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

