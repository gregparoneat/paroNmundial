import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/ui/team_builder_page.dart';
import 'package:fantacy11/features/league/ui/widgets/soccer_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

/// League details page showing info, members, standings
class LeagueDetailsPage extends StatefulWidget {
  final League league;
  
  const LeagueDetailsPage({super.key, required this.league});

  @override
  State<LeagueDetailsPage> createState() => _LeagueDetailsPageState();
}

class _LeagueDetailsPageState extends State<LeagueDetailsPage> with SingleTickerProviderStateMixin {
  final LeagueRepository _repository = LeagueRepository();
  late TabController _tabController;
  
  late League _league;
  List<LeagueMember> _members = [];
  List<FantasyTeam> _teams = [];
  LeagueMember? _currentMember;
  FantasyTeam? _myTeam;
  FantasyTeam? _opponent; // Next matchup opponent
  bool _isLoading = true;
  bool _isMember = false;
  
  // Formation for team visualization
  Formation _selectedFormation = Formation.f433;

  @override
  void initState() {
    super.initState();
    _league = widget.league;
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      await _repository.init();
      
      // Reload league data
      debugPrint("league id inside league details page is ");
      debugPrint(_league.id);
      final updatedLeague = await _repository.getLeague(_league.id);
      if (updatedLeague != null) {
        _league = updatedLeague;
      }
      debugPrint(_league.matchName);
      // Load members
      final members = await _repository.getLeagueMembers(_league.id);
      
      // Load teams for standings
      final teams = await _repository.getLeagueTeams(_league.id);
      debugPrint(teams.first.userName);
      // Check if current user is a member
      final currentUser = await _repository.getCurrentUser();
      final currentMember = members.where((m) => m.oderId == currentUser.oderId).firstOrNull;
      
      // Load my team if I'm a member
      FantasyTeam? myTeam;
      FantasyTeam? opponent;
      if (currentMember != null) {
        myTeam = await _repository.getFantasyTeam(_league.id, currentUser.oderId);
        // Load next matchup opponent
        opponent = await _repository.getNextMatchup(_league.id);
      }
      
      if (mounted) {
        setState(() {
          _members = members;
          _teams = teams;
          _currentMember = currentMember;
          _isMember = currentMember != null;
          _myTeam = myTeam;
          _opponent = opponent;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading league data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinLeague() async {
    // First, ask for the team name
    final teamName = await _showTeamNameDialog();
    if (teamName == null || teamName.isEmpty) return;
    
    final member = await _repository.joinLeague(_league.id);
    if (member != null) {
      // Create the team with the chosen name
      await _repository.createEmptyTeam(
        leagueId: _league.id,
        budget: _league.budget,
        teamName: teamName,
      );
      
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to the league! Your team "$teamName" is ready.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  Future<String?> _showTeamNameDialog() async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('Name Your Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a name for your fantasy team:',
              style: TextStyle(color: bgTextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g., Los Galácticos FC',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.sports_soccer),
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 30,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Create Team'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveLeague() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave League?'),
        content: const Text('Are you sure you want to leave this league? Your team will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final success = await _repository.leaveLeague(_league.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the league')),
        );
      }
    }
  }

  void _shareInvite() {
    if (_league.inviteCode != null) {
      Share.share(_league.shareText);
    } else {
      // For public leagues, share the name
      Share.share('Join ${_league.name} on Fantasy 11!');
    }
  }

  void _copyInviteCode() {
    if (_league.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _league.inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite code copied!')),
      );
    }
  }

  void _navigateToTeamBuilder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamBuilderPage(
          league: _league,
          existingTeam: _myTeam,
        ),
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // App Bar with league banner
                _buildAppBar(theme),
                
                // League info card
                //SliverToBoxAdapter(child: _buildLeagueInfoCard(theme)),
                
                // Tab bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: theme.primaryColor,
                      labelColor: Colors.white,
                      unselectedLabelColor: bgTextColor,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Members'),
                        Tab(text: 'Standings'),
                      ],
                    ),
                    theme.colorScheme.surface,
                  ),
                ),
                
                // Tab content
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(theme),
                      _buildMembersTab(theme),
                      _buildStandingsTab(theme),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _league.name,
          style: const TextStyle(fontSize: 16),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.primaryColor.withValues(alpha: 0.6),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Icon(
                _league.isPrivate ? Icons.lock : Icons.public,
                size: 64,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (_league.isPrivate && _isMember)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareInvite,
            tooltip: 'Share invite',
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'share':
                _shareInvite();
                break;
              case 'copy':
                _copyInviteCode();
                break;
              case 'leave':
                _leaveLeague();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            if (_league.inviteCode != null)
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 12),
                    Text('Copy Code'),
                  ],
                ),
              ),
            if (_isMember && !_currentMember!.isCreator)
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Leave', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeagueInfoCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Status and type row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _league.status.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _league.status == LeagueStatus.active
                          ? Icons.circle
                          : Icons.schedule,
                      size: 12,
                      color: _league.status.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _league.status.displayName,
                      style: TextStyle(
                        color: _league.status.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (_league.isPublic ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _league.type.icon,
                      size: 12,
                      color: _league.isPublic ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _league.type.displayName,
                      style: TextStyle(
                        color: _league.isPublic ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Free badge (all leagues are free now)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          
          if (_league.description != null && _league.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _league.description!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: bgTextColor,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                Icons.people,
                '${_league.memberCount}/${_league.maxMembers}',
                'Members',
              ),
              _buildStatColumn(
                Icons.account_balance_wallet,
                '${_league.budget.toInt()}',
                'Budget',
              ),
            ],
          ),
          
          // Invite code for private leagues
          if (_league.isPrivate && _league.inviteCode != null && _isMember) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.vpn_key, color: bgTextColor, size: 16),
                const SizedBox(width: 8),
                Text('Invite Code: ', style: TextStyle(color: bgTextColor)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _league.inviteCode!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: _copyInviteCode,
                  tooltip: 'Copy code',
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: _shareInvite,
                  tooltip: 'Share',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? bgTextColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: bgTextColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Next Fantasy Matchup
        if (_isMember && _myTeam != null)
          _buildFantasyMatchupCard(theme),
        
        if (_isMember && _myTeam != null) const SizedBox(height: 16),
        
        // My Team visualization (if member)
        if (_isMember)
          _buildMyTeamSection(theme),
        
        if (_isMember) const SizedBox(height: 16),
        
        // Rules
        _buildSectionCard(
          theme,
          'Rules',
          Icons.rule,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleItem('Select 15 players (11 starters + 4 subs) within ${_league.budget.toInt()} credits'),
              _buildRuleItem('Squad: 2 GK, 5 DEF, 5 MID, 3 FWD'),
              _buildRuleItem('Captain gets 2x points, Vice-captain gets 1.5x'),
              _buildRuleItem('Max 4 players from one team'),
              _buildRuleItem('Team locks when match starts'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildFantasyMatchupCard(ThemeData theme) {
    final myTeamName = _myTeam?.teamName ?? 'My Team';
    final myPoints = _myTeam?.totalPredictedPoints ?? 0.0;
    final opponentName = _opponent?.teamName ?? 'Waiting for opponent...';
    final opponentPoints = _opponent?.totalPredictedPoints ?? 0.0;
    final hasOpponent = _opponent != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Next Matchup',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.emoji_events, color: Colors.amber, size: 20),
            ],
          ),
          
          if (_league.matchDateTime != null) ...[
            const SizedBox(height: 4),
            Text(
              DateFormat('EEE, MMM d • h:mm a').format(_league.matchDateTime!),
              style: TextStyle(color: bgTextColor, fontSize: 12),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Matchup display
          Row(
            children: [
              // My Team
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _getTeamInitials(myTeamName),
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      myTeamName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${myPoints.toStringAsFixed(1)} pts',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // VS
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    'VS',
                    style: TextStyle(
                      color: bgTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              // Opponent Team
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: hasOpponent 
                            ? Colors.red.withValues(alpha: 0.2)
                            : bgColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasOpponent ? Colors.red : bgTextColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: hasOpponent
                            ? Text(
                                _getTeamInitials(opponentName),
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : Icon(Icons.hourglass_empty, color: bgTextColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      opponentName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: hasOpponent ? null : bgTextColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (hasOpponent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${opponentPoints.toStringAsFixed(1)} pts',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
          
          // Prediction
          if (hasOpponent && myPoints > 0 && opponentPoints > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: myPoints > opponentPoints 
                    ? Colors.green.withValues(alpha: 0.15)
                    : myPoints < opponentPoints
                        ? Colors.red.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                myPoints > opponentPoints
                    ? '🔥 You\'re projected to win by ${(myPoints - opponentPoints).toStringAsFixed(1)} pts!'
                    : myPoints < opponentPoints
                        ? '⚠️ Behind by ${(opponentPoints - myPoints).toStringAsFixed(1)} pts - Edit your team!'
                        : '⚖️ It\'s a close matchup!',
                style: TextStyle(
                  color: myPoints > opponentPoints 
                      ? Colors.green
                      : myPoints < opponentPoints
                          ? Colors.red
                          : bgTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  String _getTeamInitials(String teamName) {
    final words = teamName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return teamName.substring(0, teamName.length.clamp(0, 2)).toUpperCase();
  }

  Widget _buildMyTeamSection(ThemeData theme) {
    final hasTeam = _myTeam != null && _myTeam!.players.isNotEmpty;
    
    if (!hasTeam) {
      // No team - show prompt to create one
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 40,
                color: bgTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Team Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Build your fantasy team to compete in this league!',
              textAlign: TextAlign.center,
              style: TextStyle(color: bgTextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToTeamBuilder,
              icon: const Icon(Icons.add),
              label: const Text('Build Team'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    // Has team - show soccer field visualization
    final players = _myTeam!.players;
    final starters = _getStartingXI(players);
    final subs = _getSubstitutes(players);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with edit button and projected points
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.groups, color: theme.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Team',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${players.length}/15 players • ${_myTeam!.budgetRemaining.toStringAsFixed(1)} credits left',
                          style: TextStyle(color: bgTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _navigateToTeamBuilder,
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit Team',
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Projected Points Card for Next Matchup
              _buildProjectedPointsCard(theme),
            ],
          ),
        ),
        
        // Formation selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Formation',
                style: TextStyle(
                  fontSize: 12,
                  color: bgTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              FormationSelector(
                selectedFormation: _selectedFormation,
                onFormationChanged: (formation) {
                  setState(() => _selectedFormation = formation);
                },
              ),
            ],
          ),
        ),
        
        // Total predicted points card
        if (_myTeam != null && _league.status == LeagueStatus.draft)
         /* Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildPredictedPointsCard(_myTeam!),
          ),*/
        
        // Soccer field
        Padding(
          padding: const EdgeInsets.all(16),
          child: SoccerFieldWidget(
            players: starters,
            formation: _selectedFormation,
            isEditable: false,
            showPredictedPoints: _league.status == LeagueStatus.draft,
            onPlayerTap: (player) => _showPlayerOptions(player),
          ),
        ),
        
        // Bench/Substitutes
        if (subs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BenchWidget(
              benchPlayers: subs,
              onPlayerTap: (player) => _showPlayerOptions(player),
            ),
          ),
        
        // Team validation status
        if (!_myTeam!.isValid)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Team incomplete - you need ${15 - players.length} more players',
                    style: const TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Get starting XI players (prioritize by position for formation)
  List<FantasyTeamPlayer> _getStartingXI(List<FantasyTeamPlayer> allPlayers) {
    // Get required starters for selected formation
    final gks = allPlayers.where((p) => p.position == PlayerPosition.goalkeeper).take(1).toList();
    final defs = allPlayers.where((p) => p.position == PlayerPosition.defender).take(_selectedFormation.lines[0]).toList();
    final mids = allPlayers.where((p) => p.position == PlayerPosition.midfielder).take(_selectedFormation.lines[1]).toList();
    final fwds = allPlayers.where((p) => 
        p.position == PlayerPosition.attacker || p.position == PlayerPosition.forward)
        .take(_selectedFormation.lines[2]).toList();
    
    return [...gks, ...defs, ...mids, ...fwds];
  }

  /// Get substitute players
  List<FantasyTeamPlayer> _getSubstitutes(List<FantasyTeamPlayer> allPlayers) {
    final starters = _getStartingXI(allPlayers);
    final starterIds = starters.map((p) => p.playerId).toSet();
    return allPlayers.where((p) => !starterIds.contains(p.playerId)).toList();
  }

  /// Build the projected points card for next matchup
  Widget _buildProjectedPointsCard(ThemeData theme) {
    // Calculate total projected points from the team
    // Using the credits as a proxy for projected points (in real implementation,
    // you'd fetch actual projected points from player stats)
    final players = _myTeam?.players ?? [];
    
    // Sum up projected points (using credits * 1.5 as an estimate since we don't have direct access)
    // In a real implementation, you'd store projectedPoints in FantasyTeamPlayer
    double totalProjectedPoints = 0;
    for (final player in players) {
      // Estimate based on credit value - higher value players typically score more
      final estimatedPoints = player.credits * 1.2 + 2.0;
      totalProjectedPoints += estimatedPoints;
    }
    
    // Apply captain/vice-captain bonuses
    final captain = players.where((p) => p.isCaptain).firstOrNull;
    final viceCaptain = players.where((p) => p.isViceCaptain).firstOrNull;
    
    if (captain != null) {
      totalProjectedPoints += captain.credits * 1.2 + 2.0; // Double captain's points
    }
    if (viceCaptain != null) {
      totalProjectedPoints += (viceCaptain.credits * 1.2 + 2.0) * 0.5; // 1.5x vice-captain's points
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.2),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Points icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up,
              color: theme.primaryColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          
          // Points info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projected Points',
                  style: TextStyle(
                    color: bgTextColor,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Next Matchup',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Points value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalProjectedPoints.toStringAsFixed(1),
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  color: theme.primaryColor.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Show options for a player (view profile, swap, etc.)
  void _showPlayerOptions(FantasyTeamPlayer player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Player info header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        player.playerName.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.playerName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${player.position.name} • ${player.teamName}',
                          style: TextStyle(color: bgTextColor),
                        ),
                      ],
                    ),
                  ),
                  if (player.isCaptain)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('C', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  if (player.isViceCaptain)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('VC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              const Divider(),
              
              // Actions
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Team'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToTeamBuilder();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: bgTextColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(ThemeData theme) {
    if (_members.isEmpty) {
      return Center(
        child: Text('No members yet', style: TextStyle(color: bgTextColor)),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final member = _members[index];
        return FadedSlideAnimation(
          beginOffset: Offset(0, 0.1 * (index + 1)),
          endOffset: Offset.zero,
          child: _buildMemberCard(theme, member, index + 1),
        );
      },
    );
  }

  Widget _buildMemberCard(ThemeData theme, LeagueMember member, int position) {
    final isMe = member.oderId == _currentMember?.oderId;
    
    return Card(
      color: isMe ? theme.primaryColor.withValues(alpha: 0.1) : theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMe ? BorderSide(color: theme.primaryColor, width: 1) : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.isCreator ? Colors.amber : bgColor,
          child: member.userImageUrl != null
              ? ClipOval(
                  child: Image.network(
                    member.userImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Text(
                      member.userName[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : Text(
                  member.userName[0].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: member.isCreator ? Colors.black : null,
                  ),
                ),
        ),
        title: Row(
          children: [
            Text(
              member.userName,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isMe)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            if (member.isCreator)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CREATOR',
                  style: TextStyle(fontSize: 10, color: Colors.black),
                ),
              ),
          ],
        ),
        subtitle: Text(
          member.hasTeam ? 'Team created' : 'No team yet',
          style: TextStyle(
            color: member.hasTeam ? Colors.green : bgTextColor,
            fontSize: 12,
          ),
        ),
        trailing: member.totalPoints > 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${member.totalPoints.toStringAsFixed(1)} pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  Text(
                    '#$position',
                    style: TextStyle(color: bgTextColor, fontSize: 12),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildPredictedPointsCard(FantasyTeam team) {
    final theme = Theme.of(context);
    final totalPredicted = team.totalPredictedPoints;
    final opponentName = _opponent?.teamName ?? 'Waiting for opponent';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.3),
            theme.primaryColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up,
              color: theme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Predicted Points',
                  style: TextStyle(
                    color: bgTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  totalPredicted.toStringAsFixed(1),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Next Opponent',
                style: TextStyle(
                  color: bgTextColor,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.sports, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    opponentName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsTab(ThemeData theme) {
    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: bgTextColor),
            const SizedBox(height: 16),
            Text(
              'No standings yet',
              style: theme.textTheme.titleMedium?.copyWith(color: bgTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Standings will appear after match starts',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teams.length,
      itemBuilder: (context, index) {
        final team = _teams[index];
        final position = index + 1;
        
        return FadedSlideAnimation(
          beginOffset: Offset(0, 0.1 * (index + 1)),
          endOffset: Offset.zero,
          child: _buildStandingCard(theme, team, position),
        );
      },
    );
  }

  Widget _buildStandingCard(ThemeData theme, FantasyTeam team, int position) {
    final isMe = team.userId == _currentMember?.oderId;
    
    Color? positionColor;
    if (position == 1) positionColor = Colors.amber;
    else if (position == 2) positionColor = Colors.grey[400];
    else if (position == 3) positionColor = Colors.orange[300];
    
    return Card(
      color: isMe ? theme.primaryColor.withValues(alpha: 0.1) : theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMe ? BorderSide(color: theme.primaryColor, width: 1) : BorderSide.none,
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: positionColor?.withValues(alpha: 0.2) ?? bgColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '#$position',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: positionColor,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              team.userName,
              style: TextStyle(
                fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isMe)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${team.players.length} players • ${team.budgetRemaining.toStringAsFixed(1)} credits left',
          style: TextStyle(color: bgTextColor, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${team.totalPoints.toStringAsFixed(1)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: theme.primaryColor,
              ),
            ),
            Text(
              'points',
              style: TextStyle(color: bgTextColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(ThemeData theme, String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    if (_isLoading) return const SizedBox.shrink();
    
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
        child: _isMember
            ? ElevatedButton(
                onPressed: _league.status == LeagueStatus.draft
                    ? _navigateToTeamBuilder
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _myTeam != null && _myTeam!.players.isNotEmpty
                          ? Icons.edit
                          : Icons.add,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _myTeam != null && _myTeam!.players.isNotEmpty
                          ? 'Edit Team'
                          : 'Build Team',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: _league.canJoin ? _joinLeague : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.login),
                    const SizedBox(width: 8),
                    Text(
                      _league.isFull
                          ? 'League Full'
                          : 'Join League',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

