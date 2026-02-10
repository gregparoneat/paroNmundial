import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Page displaying upcoming fixtures with predicted lineups option
class UpcomingFixturesPage extends StatefulWidget {
  /// If true, shows without its own Scaffold (for embedding in tabs)
  final bool embedded;
  
  /// If true, shows matches in a non-scrolling Column (for embedding in scrollable parent)
  final bool shrinkWrap;
  
  /// Maximum number of matches to show when shrinkWrap is true
  final int? maxMatches;
  
  const UpcomingFixturesPage({
    super.key, 
    this.embedded = true,
    this.shrinkWrap = false,
    this.maxMatches,
  });

  @override
  State<UpcomingFixturesPage> createState() => _UpcomingFixturesPageState();
}

class _UpcomingFixturesPageState extends State<UpcomingFixturesPage> 
    with AutomaticKeepAliveClientMixin {
  final FixturesRepository _repository = FixturesRepository();
  
  List<MatchInfo> _matches = [];
  bool _isLoading = true;
  String? _error;
  int _daysAhead = 7;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _loadUpcomingFixtures();
  }
  
  Future<void> _loadUpcomingFixtures() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final fixtures = await _repository.getUpcomingFixtures(days: _daysAhead);
      
      // Filter to only future matches
      final now = DateTime.now();
      final upcomingMatches = fixtures.where((m) {
        if (m.startingAtTimestamp == null) return true;
        final matchTime = DateTime.fromMillisecondsSinceEpoch(m.startingAtTimestamp! * 1000);
        return matchTime.isAfter(now);
      }).toList();
      
      setState(() {
        _matches = upcomingMatches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load fixtures: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    
    Widget content;
    
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = _buildError(theme);
    } else if (_matches.isEmpty) {
      content = _buildEmpty(theme);
    } else {
      content = _buildMatchList(theme);
    }
    
    if (widget.embedded) {
      return content;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Fixtures'),
      ),
      body: content,
    );
  }
  
  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Failed to load fixtures',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadUpcomingFixtures,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          Text(
            'No upcoming fixtures',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for upcoming matches',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadUpcomingFixtures,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMatchList(ThemeData theme) {
    // Limit matches if maxMatches is set and shrinkWrap is true
    List<MatchInfo> displayMatches = _matches;
    if (widget.shrinkWrap && widget.maxMatches != null) {
      displayMatches = _matches.take(widget.maxMatches!).toList();
    }
    
    // Group matches by date
    final matchesByDate = <String, List<MatchInfo>>{};
    
    for (final match in displayMatches) {
      String dateKey;
      if (match.startingAtTimestamp != null) {
        final date = DateTime.fromMillisecondsSinceEpoch(match.startingAtTimestamp! * 1000);
        dateKey = DateFormat('EEEE, d MMMM').format(date);
      } else {
        dateKey = 'Date TBD';
      }
      matchesByDate.putIfAbsent(dateKey, () => []).add(match);
    }
    
    // ShrinkWrap mode: return Column instead of ListView
    if (widget.shrinkWrap) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final dateKey in matchesByDate.keys) ...[
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      dateKey,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // Match cards
              ...matchesByDate[dateKey]!.map((match) => _buildMatchCard(match, theme)),
              const SizedBox(height: 8),
            ],
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadUpcomingFixtures,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: matchesByDate.length,
        itemBuilder: (context, index) {
          final dateKey = matchesByDate.keys.elementAt(index);
          final matches = matchesByDate[dateKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      dateKey,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Match cards
              ...matches.map((match) => _buildMatchCard(match, theme)),
              
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildMatchCard(MatchInfo match, ThemeData theme) {
    final matchTime = match.startingAtTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(match.startingAtTimestamp! * 1000)
        : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(
            context,
            PageRoutes.upcomingMatchDetails,
            arguments: match,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // League
                Text(
                  match.leagueName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Teams row
                Row(
                  children: [
                    // Home team
                    Expanded(
                      child: Column(
                        children: [
                          _buildTeamLogo(match.team1Logo, 40),
                          const SizedBox(height: 8),
                          Text(
                            match.team1Name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Time
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            matchTime != null
                                ? DateFormat('HH:mm').format(matchTime)
                                : 'TBD',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (matchTime != null)
                            Text(
                              _getTimeUntil(matchTime),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Away team
                    Expanded(
                      child: Column(
                        children: [
                          _buildTeamLogo(match.team2Logo, 40),
                          const SizedBox(height: 8),
                          Text(
                            match.team2Name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
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
                
                // Tap hint
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to view predicted lineups',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTeamLogo(String? logoUrl, double size) {
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholder: (_, __) => Icon(Icons.shield, size: size),
        errorWidget: (_, __, ___) => Icon(Icons.shield, size: size),
      );
    }
    return Icon(Icons.shield, size: size);
  }
  
  String _getTimeUntil(DateTime matchTime) {
    final now = DateTime.now();
    final difference = matchTime.difference(now);
    
    if (difference.isNegative) {
      return 'Started';
    }
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}

