import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/fixtures/models/completed_match.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Page displaying past/completed fixtures with results
/// Can be used standalone (with Scaffold) or embedded in a tab
class PastFixturesPage extends StatefulWidget {
  /// If true, shows without its own Scaffold (for embedding in tabs)
  final bool embedded;
  
  const PastFixturesPage({super.key, this.embedded = true});

  @override
  State<PastFixturesPage> createState() => _PastFixturesPageState();
}

class _PastFixturesPageState extends State<PastFixturesPage> with AutomaticKeepAliveClientMixin {
  final FixturesRepository _repository = FixturesRepository();
  
  List<CompletedMatch> _matches = [];
  bool _isLoading = true;
  String? _error;
  int _daysBack = 7;
  
  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs
  
  @override
  void initState() {
    super.initState();
    debugPrint('>>> PastFixturesPage initState called <<<');
    _loadPastFixtures();
  }
  
  Future<void> _loadPastFixtures() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      debugPrint('Loading past fixtures for last $_daysBack days...');
      final fixtures = await _repository.getPastFixtures(daysBack: _daysBack);
      debugPrint('Received ${fixtures.length} fixtures from repository');
      
      final matches = fixtures
          .map((f) {
            try {
              return CompletedMatch.fromJson(f);
            } catch (e) {
              debugPrint('Error parsing fixture: $e');
              return null;
            }
          })
          .whereType<CompletedMatch>()
          .where((m) => m.homeTeamName.isNotEmpty && m.awayTeamName.isNotEmpty)
          .toList();
      
      debugPrint('Parsed ${matches.length} valid completed matches');
      
      if (mounted) {
        setState(() {
          _matches = matches;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading past fixtures: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        setState(() {
          _error = 'Failed to load fixtures: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    debugPrint('>>> PastFixturesPage build called, isLoading=$_isLoading, matches=${_matches.length}, error=$_error <<<');
    final theme = Theme.of(context);
    
    // When embedded in a tab, just return the body content
    if (widget.embedded) {
      return RefreshIndicator(
        onRefresh: _loadPastFixtures,
        child: _buildBody(theme),
      );
    }
    
    // Standalone mode with full Scaffold
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Past Results'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by days',
            onSelected: (days) {
              _daysBack = days;
              _loadPastFixtures();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 14, child: Text('Last 14 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPastFixtures,
        child: _buildBody(theme),
      ),
    );
  }
  
  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // DEBUG: This confirms PastFixturesPage is rendering
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.orange,
              child: const Text('PAST FIXTURES PAGE - LOADING', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading completed matches...',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadPastFixtures,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    
    if (_matches.isEmpty) {
      return ListView(
        // Use ListView so pull-to-refresh works
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Icon(Icons.sports_soccer, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No completed matches found',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'in the last $_daysBack days',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              onPressed: _loadPastFixtures,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),
        ],
      );
    }
    
    // Group matches by date
    final matchesByDate = <String, List<CompletedMatch>>{};
    for (final match in _matches) {
      final dateKey = DateFormat('yyyy-MM-dd').format(match.matchDate);
      matchesByDate.putIfAbsent(dateKey, () => []).add(match);
    }
    
    final sortedDates = matchesByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayMatches = matchesByDate[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDateHeader(date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: theme.dividerColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Matches for this date
            ...dayMatches.map((match) => _buildMatchCard(match, theme)),
          ],
        );
      },
    );
  }
  
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    
    if (DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(yesterday)) {
      return 'Yesterday';
    }
    
    return DateFormat('EEEE, MMMM d').format(date);
  }
  
  Widget _buildMatchCard(CompletedMatch match, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _openMatchDetails(match),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // League and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      match.leagueName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'FT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Teams and score
              Row(
                children: [
                  // Home team
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(match.homeTeamLogo, 48),
                        const SizedBox(height: 8),
                        Text(
                          match.homeTeamName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: match.isHomeWin ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${match.homeScore}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: match.isHomeWin ? theme.primaryColor : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '-',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          '${match.awayScore}',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: match.isAwayWin ? theme.primaryColor : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Away team
                  Expanded(
                    child: Column(
                      children: [
                        _buildTeamLogo(match.awayTeamLogo, 48),
                        const SizedBox(height: 8),
                        Text(
                          match.awayTeamName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: match.isAwayWin ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Tap hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to see lineups & player stats',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamLogo(String? logoUrl, double size) {
    if (logoUrl == null || logoUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.shield,
          size: size * 0.5,
          color: Colors.grey.shade600,
        ),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: logoUrl,
      width: size,
      height: size,
      placeholder: (_, __) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (_, __, ___) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.shield, size: size * 0.5, color: Colors.grey.shade600),
      ),
    );
  }
  
  void _openMatchDetails(CompletedMatch match) {
    Navigator.pushNamed(
      context,
      PageRoutes.matchDetails,
      arguments: match.fixtureId,
    );
  }
}

