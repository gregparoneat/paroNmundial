import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/ui/create_league_page.dart';
import 'package:fantacy11/features/league/ui/join_league_dialog.dart';
import 'package:fantacy11/features/league/ui/league_details_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Main page for browsing and managing fantasy leagues
class LeaguesPage extends StatefulWidget {
  const LeaguesPage({super.key});

  @override
  State<LeaguesPage> createState() => _LeaguesPageState();
}

class _LeaguesPageState extends State<LeaguesPage> with SingleTickerProviderStateMixin {
  final LeagueRepository _repository = LeagueRepository();
  late TabController _tabController;
  
  List<League> _publicLeagues = [];
  List<League> _myLeagues = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeagues();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeagues() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _repository.init();
      final publicLeagues = await _repository.getPublicLeagues();
      final myLeagues = await _repository.getMyLeagues();
      
      if (mounted) {
        setState(() {
          _publicLeagues = publicLeagues;
          _myLeagues = myLeagues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load leagues: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showJoinLeagueDialog() {
    showDialog(
      context: context,
      builder: (context) => JoinLeagueDialog(
        onJoined: (league) {
          _loadLeagues();
          _navigateToLeague(league);
        },
      ),
    );
  }

  void _navigateToCreateLeague() async {
    final result = await Navigator.push<League>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateLeaguePage(),
      ),
    );
    
    if (result != null) {
      _loadLeagues();
      _navigateToLeague(result);
    }
  }

  void _navigateToLeague(League league) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LeagueDetailsPage(league: league),
      ),
    ).then((_) => _loadLeagues());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Fantasy Leagues'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: 'Join with code',
            onPressed: _showJoinLeagueDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeagues,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: bgTextColor,
          tabs: [
            Tab(text: 'Public Leagues (${_publicLeagues.length})'),
            Tab(text: 'My Leagues (${_myLeagues.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaguesList(_publicLeagues, isPublic: true),
                    _buildLeaguesList(_myLeagues, isPublic: false),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateLeague,
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('Create League'),
      ),
    );
  }

  Widget _buildErrorState() {
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
              onPressed: _loadLeagues,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaguesList(List<League> leagues, {required bool isPublic}) {
    if (leagues.isEmpty) {
      return _buildEmptyState(isPublic);
    }

    return RefreshIndicator(
      onRefresh: _loadLeagues,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leagues.length,
        itemBuilder: (context, index) {
          return FadedSlideAnimation(
            beginOffset: Offset(0, 0.1 * (index + 1)),
            endOffset: Offset.zero,
            slideDuration: Duration(milliseconds: 200 + (index * 50)),
            child: _buildLeagueCard(leagues[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isPublic) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPublic ? Icons.public_off : Icons.groups,
              size: 64,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 24),
            Text(
              isPublic ? 'No Public Leagues Available' : 'No Leagues Yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPublic
                  ? 'Create a public league or wait for others to create one'
                  : 'Create your first league or join an existing one',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _navigateToCreateLeague,
                  icon: const Icon(Icons.add),
                  label: const Text('Create'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showJoinLeagueDialog,
                  icon: const Icon(Icons.link),
                  label: const Text('Join'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueCard(League league) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToLeague(league),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // League type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: league.isPublic 
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      league.type.icon,
                      color: league.isPublic ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // League name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          league.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: league.status.color.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                league.status.displayName,
                                style: TextStyle(
                                  color: league.status.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${league.memberCount}/${league.maxMembers} members',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: bgTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Entry fee badge
                  if (league.entryFee != null && league.entryFee! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '\$${league.entryFee!.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'FREE',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Description
              if (league.description != null && league.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  league.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Match info row
              Row(
                children: [
                  Icon(Icons.sports_soccer, size: 16, color: bgTextColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      league.matchName ?? 'Match TBD',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (league.matchDateTime != null) ...[
                    Icon(Icons.schedule, size: 16, color: bgTextColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatMatchTime(league.matchDateTime!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Budget and prize pool row
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.account_balance_wallet,
                    label: '${league.budget.toInt()} credits',
                  ),
                  const SizedBox(width: 12),
                  if (league.prizePool != null && league.prizePool! > 0)
                    _buildInfoChip(
                      icon: Icons.emoji_events,
                      label: '\$${league.prizePool!.toStringAsFixed(0)} prize',
                      color: Colors.amber,
                    ),
                  const Spacer(),
                  if (league.isJoined)
                    TextButton(
                      onPressed: () => _navigateToLeague(league),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                      child: const Text('View →'),
                    )
                  else if (league.canJoin)
                    TextButton(
                      onPressed: () => _navigateToLeague(league),
                      child: const Text('Join →'),
                    )
                  else if (league.isFull)
                    Text(
                      'Full',
                      style: TextStyle(
                        color: Colors.red[400],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? bgTextColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color ?? bgTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatMatchTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      return 'Started';
    } else if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

