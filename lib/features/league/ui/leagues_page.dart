import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/models/league_models_ui.dart';
import 'package:fantacy11/features/league/ui/create_league_page.dart';
import 'package:fantacy11/features/league/ui/join_league_dialog.dart';
import 'package:fantacy11/features/league/ui/league_details_page.dart';
import 'package:fantacy11/generated/l10n.dart';
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
          _error = S.of(context).failedToLoadLeagues(e.toString());
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
    final s = S.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.leaguesTitle),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_link),
            tooltip: s.joinWithCode,
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
            Tab(text: '${s.publicLeagues} (${_publicLeagues.length})'),
            Tab(text: '${s.myLeagues} (${_myLeagues.length})'),
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
        label: Text(s.createLeagueLabel),
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
              child: Text(S.of(context).retry),
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
    final s = S.of(context);
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
              isPublic ? s.noPublicLeaguesAvailable : s.noLeaguesYet,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPublic
                  ? s.createPublicLeagueOrWait
                  : s.createOrJoinFirstLeague,
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
                  label: Text(s.create),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showJoinLeagueDialog,
                  icon: const Icon(Icons.link),
                  label: Text(s.join),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueCard(League league) {
    final s = S.of(context);
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
                                _localizedLeagueStatus(league.status, s),
                                style: TextStyle(
                                  color: league.status.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.membersCount(league.memberCount, league.maxMembers),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: bgTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Free badge (all leagues are free now)
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
                      league.matchName ?? s.matchTbd,
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
              
              // Budget row
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.account_balance_wallet,
                    label: '\$${league.budget.toInt()}M',
                  ),
                  const Spacer(),
                  if (league.isJoined)
                    TextButton(
                      onPressed: () => _navigateToLeague(league),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                      child: Text(s.viewArrow),
                    )
                  else if (league.canJoin)
                    TextButton(
                      onPressed: () => _navigateToLeague(league),
                      child: Text(s.joinArrow),
                    )
                  else if (league.isFull)
                    Text(
                      s.full,
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
    final s = S.of(context);
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      return s.started;
    } else if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return s.minutesShort(difference.inMinutes);
      }
      return s.hoursMinutesShort(difference.inHours, difference.inMinutes % 60);
    } else if (difference.inDays == 1) {
      return s.tomorrow;
    } else if (difference.inDays < 7) {
      return s.daysShort(difference.inDays);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  String _localizedLeagueStatus(LeagueStatus status, S s) {
    switch (status) {
      case LeagueStatus.draft:
        return s.upcoming;
      case LeagueStatus.active:
        return s.live;
      case LeagueStatus.completed:
        return s.completed;
      case LeagueStatus.cancelled:
        return s.cancelled;
    }
  }
}
