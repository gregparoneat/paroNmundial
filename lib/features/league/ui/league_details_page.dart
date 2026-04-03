import 'dart:async';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/models/league_models_ui.dart';
import 'package:fantacy11/features/league/ui/team_builder_page.dart';
import 'package:fantacy11/features/league/ui/widgets/soccer_field_widget.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
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

class _LeagueDetailsPageState extends State<LeagueDetailsPage>
    with SingleTickerProviderStateMixin {
  final LeagueRepository _repository = LeagueRepository();
  final PlayersRepository _playersRepository = PlayersRepository();
  late TabController _tabController;
  Timer? _draftCountdownTimer;

  late League _league;
  List<LeagueMember> _members = [];
  List<FantasyTeam> _teams = [];
  LeagueMember? _currentMember;
  FantasyTeam? _myTeam;
  FantasyTeam? _opponent; // Next matchup opponent
  bool _isLoading = true;
  bool _isMember = false;
  bool _isRefreshingDraftResults = false;
  bool _isAwaitingDraftedTeam = false;

  // Formation for team visualization
  Formation _selectedFormation = Formation.f433;

  @override
  void initState() {
    super.initState();
    _league = _asClassicLeague(widget.league);
    _isMember = widget.league.isJoined;
    _tabController = TabController(length: 3, vsync: this);
    _startDraftCountdownTicker();
    _loadData();
  }

  @override
  void dispose() {
    _draftCountdownTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startDraftCountdownTicker() {
    if (!_league.isDraftMode) return;

    _draftCountdownTimer?.cancel();
    _draftCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  bool _isDraftCompletedForUi([FantasyTeam? team]) {
    if (!_league.isDraftMode) return false;

    final rosterSize = _league.draftSettings?.rosterSize ?? _league.rosterSize;
    final playerCount = (team ?? _myTeam)?.players.length ?? 0;
    return _isAwaitingDraftedTeam ||
        _league.status != LeagueStatus.draft ||
        playerCount >= rosterSize;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _repository.init();

      final updatedLeague = await _repository.getLeague(_league.id);
      if (updatedLeague != null) {
        _league = _asClassicLeague(
          updatedLeague.copyWith(
            isJoined: _league.isJoined || updatedLeague.isJoined,
          ),
        );
      }

      final members = await _repository.getLeagueMembers(_league.id);
      final teams = await _repository.getLeagueTeams(_league.id);
      final currentUser = await _repository.getCurrentUser();
      LeagueMember? currentMember = members
          .where((m) => m.oderId == currentUser.oderId)
          .firstOrNull;

      FantasyTeam? myTeam;
      FantasyTeam? opponent;
      if (currentMember != null) {
        myTeam = await _repository.getFantasyTeam(
          _league.id,
          currentUser.oderId,
        );
      }

      // Fallback for legacy/mock IDs: resolve from existing saved team/member by name/id.
      myTeam ??= teams.where((t) => t.userId == currentUser.oderId).firstOrNull;
      myTeam ??= teams
          .where(
            (t) =>
                t.userName.trim().toLowerCase() ==
                currentUser.userName.trim().toLowerCase(),
          )
          .firstOrNull;

      if (currentMember == null && myTeam != null) {
        currentMember = members
            .where(
              (m) =>
                  m.oderId == myTeam!.userId || m.userName == myTeam.userName,
            )
            .firstOrNull;

        currentMember ??= LeagueMember(
          id: 'derived-${myTeam.userId}',
          leagueId: _league.id,
          oderId: myTeam.userId,
          userName: myTeam.userName,
          joinedAt: _league.createdAt,
          fantasyTeamId: myTeam.id,
        );
      }

      if (currentMember == null &&
          (_league.isJoined || widget.league.isJoined)) {
        currentMember = LeagueMember(
          id: 'joined-${currentUser.oderId}-${_league.id}',
          leagueId: _league.id,
          oderId: currentUser.oderId,
          userName: currentUser.userName,
          userImageUrl: currentUser.userImageUrl,
          joinedAt: _league.createdAt,
        );
      }

      if (currentMember != null) {
        opponent = await _repository.getNextMatchup(_league.id);
      }

      if (mounted) {
        final hasDraftedTeam = myTeam != null && myTeam.players.isNotEmpty;
        setState(() {
          _members = members;
          _teams = teams;
          _currentMember = currentMember;
          _isMember =
              currentMember != null ||
              myTeam != null ||
              _league.isJoined ||
              widget.league.isJoined;
          _myTeam = myTeam;
          _opponent = opponent;
          if (hasDraftedTeam) {
            _isAwaitingDraftedTeam = false;
          }
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

  Future<void> _refreshDraftResults() async {
    if (_isRefreshingDraftResults) return;

    setState(() => _isRefreshingDraftResults = true);
    try {
      await _loadData();
    } finally {
      if (mounted) {
        setState(() => _isRefreshingDraftResults = false);
      }
    }
  }

  Future<void> _joinLeague() async {
    final teamName = await _showTeamNameDialog();
    if (teamName == null || teamName.isEmpty) return;

    final member = await _repository.joinLeague(_league.id);
    if (member == null) return;

    await _repository.createEmptyTeam(
      leagueId: _league.id,
      budget: _league.budget,
      teamName: teamName,
    );

    _loadData();
    if (mounted) {
      final s = S.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.welcomeToLeagueTeamReady(teamName)),
          backgroundColor: Colors.green,
        ),
      );
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
        title: Text(S.of(context).nameYourTeam),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).chooseTeamNamePrompt,
              style: TextStyle(color: bgTextColor),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: S.of(context).teamNameExampleHint,
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
            child: Text(S.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: Text(S.of(context).createTeam),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveLeague() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).leaveLeagueQuestion),
        content: Text(S.of(context).leaveLeagueConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.of(context).leaveLabel),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _repository.leaveLeague(_league.id);
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).leftLeagueMessage)),
        );
      }
    }
  }

  Future<void> _deleteLeague() async {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    String tr(String en, String es) => isSpanish ? es : en;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Delete League?', '¿Eliminar liga?')),
        content: Text(
          tr(
            'This will permanently delete the league. It is only allowed while you are the only member.',
            'Esto eliminará la liga permanentemente. Solo se permite mientras seas el único miembro.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('Delete', 'Eliminar')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _repository.deleteLeague(_league.id);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('League deleted', 'Liga eliminada'))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tr(
            'Only the creator can delete a league, and only while it has one member.',
            'Solo el creador puede eliminar una liga, y solo mientras tenga un miembro.',
          ),
        ),
      ),
    );
  }

  void _shareInvite() {
    if (_league.inviteCode != null) {
      Share.share(_league.shareText);
    } else {
      // For public leagues, share the name
      Share.share(S.of(context).joinLeagueOnFantasy11(_league.name));
    }
  }

  void _copyInviteCode() {
    if (_league.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _league.inviteCode!));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.of(context).inviteCodeCopied)));
    }
  }

  Future<void> _navigateToPlayerProfile(int playerId) async {
    final player = await _playersRepository.getPlayerById(playerId);
    if (!mounted) return;

    if (player != null) {
      Navigator.pushNamed(context, PageRoutes.playerDetails, arguments: player);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          Localizations.localeOf(context).languageCode == 'es'
              ? 'No se pudieron cargar los detalles del jugador'
              : 'Could not load player details',
        ),
      ),
    );
  }

  void _navigateToTeamBuilder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TeamBuilderPage(league: _league, existingTeam: _myTeam),
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = S.of(context);

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
                      tabs: [
                        Tab(text: locale.overview),
                        Tab(text: locale.members),
                        Tab(text: locale.standings),
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
    final canDeleteLeague =
        (_currentMember?.isCreator ?? false) && _members.length == 1;

    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(_league.name, style: const TextStyle(fontSize: 16)),
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
            tooltip: S.of(context).shareInvite,
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
              case 'delete':
                _deleteLeague();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20),
                  SizedBox(width: 12),
                  Text(S.of(context).share),
                ],
              ),
            ),
            if (_league.inviteCode != null)
              PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 12),
                    Text(S.of(context).copyCode),
                  ],
                ),
              ),
            if (_isMember && !(_currentMember?.isCreator ?? false))
              PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    const Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      S.of(context).leaveLabel,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            if (canDeleteLeague)
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_forever,
                      size: 20,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Localizations.localeOf(context).languageCode == 'es'
                          ? 'Eliminar liga'
                          : 'Delete League',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildLeagueInfoCard(ThemeData theme) {
    final s = S.of(context);
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
                      _localizedLeagueStatus(_league.status, s),
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
                      _league.isPublic ? s.publicLeague : s.privateLeague,
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
                child: Text(
                  s.freeLabel,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (_league.description != null &&
              _league.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _league.description!,
              style: theme.textTheme.bodyMedium?.copyWith(color: bgTextColor),
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
                S.of(context).members,
              ),
              if (_league.isClassicMode)
                _buildStatColumn(
                  Icons.account_balance_wallet,
                  '${_league.budget.toInt()}',
                  s.budgetLabel,
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
                Text('${s.inviteCode}: ', style: TextStyle(color: bgTextColor)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                  tooltip: S.of(context).copyCode,
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: _shareInvite,
                  tooltip: S.of(context).share,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    IconData icon,
    String value,
    String label, {
    Color? color,
  }) {
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
        Text(label, style: TextStyle(color: bgTextColor, fontSize: 12)),
      ],
    );
  }

  Widget _buildOverviewTab(ThemeData theme) {
    final locale = S.of(context);
    final isDraftCompleted = _isDraftCompletedForUi();
    final isDraftOverviewActive =
        _league.isDraftMode &&
        _league.status == LeagueStatus.draft &&
        !isDraftCompleted;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isDraftOverviewActive) _buildDraftScheduleCard(theme),

        if (isDraftOverviewActive) const SizedBox(height: 16),

        if (isDraftOverviewActive) _buildDraftGuideCard(theme),

        if (isDraftOverviewActive) const SizedBox(height: 16),

        // Next Fantasy Matchup
        if (_isMember && _myTeam != null) _buildFantasyMatchupCard(theme),

        if (_isMember && _myTeam != null) const SizedBox(height: 16),

        // My Team visualization (if member)
        if (_isMember) _buildMyTeamSection(theme),

        if (_isMember) const SizedBox(height: 16),

        // Rules
        _buildSectionCard(
          theme,
          locale.rules,
          Icons.rule,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleItem(
                _league.isDraftMode
                    ? locale.ruleSelect18PlayersDraft
                    : locale.ruleSelect18PlayersBudget(_league.budget.toInt()),
              ),
              _buildRuleItem(locale.ruleSquad18Players),
              _buildRuleItem(locale.ruleCaptainViceCaptainPoints),
              if (_league.isClassicMode)
                _buildRuleItem(locale.ruleMax4PlayersOneTeam),
              _buildRuleItem(locale.ruleTeamLocksWhenMatchStarts),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDraftScheduleCard(ThemeData theme) {
    final draftDateTime = _league.draftSettings?.draftDateTime;
    final isLive =
        draftDateTime != null && !DateTime.now().isBefore(draftDateTime);
    final isDraftCompleted = _isDraftCompletedForUi();
    final canEnterDraft =
        !isDraftCompleted &&
        _isMember &&
        draftDateTime != null &&
        DateTime.now().isAfter(
          draftDateTime.subtract(const Duration(minutes: 15)),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.18),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive
              ? Colors.green.withValues(alpha: 0.45)
              : theme.primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLive
                  ? Colors.green.withValues(alpha: 0.16)
                  : isDraftCompleted
                  ? Colors.green.withValues(alpha: 0.16)
                  : theme.primaryColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDraftCompleted
                  ? Icons.check_circle
                  : isLive
                  ? Icons.timer
                  : Icons.schedule,
              color: isDraftCompleted || isLive
                  ? Colors.green
                  : theme.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).draftSchedule,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  draftDateTime == null
                      ? S.of(context).timePending
                      : DateFormat(
                          'EEEE, MMM d • h:mm:ss a',
                        ).format(draftDateTime),
                  style: TextStyle(color: bgTextColor, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  isDraftCompleted
                      ? S.of(context).draftCompleted
                      : _formatDraftCountdown(draftDateTime),
                  style: TextStyle(
                    color: isDraftCompleted || isLive
                        ? Colors.green
                        : theme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                if (_isMember) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: isDraftCompleted
                        ? null
                        : (canEnterDraft ? _navigateToDraftRoom : null),
                    icon: Icon(
                      isDraftCompleted
                          ? Icons.check_circle
                          : (canEnterDraft ? Icons.play_arrow : Icons.schedule),
                    ),
                    label: Text(
                      isDraftCompleted
                          ? S.of(context).draftCompleted
                          : canEnterDraft
                          ? S.of(context).joinDraftNow
                          : S.of(context).draftRoomOpens15MinBeforeStart,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftGuideCard(ThemeData theme) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.menu_book_rounded, color: theme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).howDraftLeaguesWork,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      S.of(context).quickDraftGuideSubtitle,
                      style: TextStyle(color: bgTextColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildGuideBullet(s.draftGuideBullet1),
          _buildGuideBullet(s.draftGuideBullet2),
          _buildGuideBullet(s.draftGuideBullet3),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _showDraftGuideSheet,
                icon: const Icon(Icons.help_outline),
                label: Text(S.of(context).fullDraftGuide),
              ),
              TextButton.icon(
                onPressed: _showDraftGuideSheet,
                icon: const Icon(Icons.compare_arrows),
                label: Text(S.of(context).draftVsClassic),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuideBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: bgTextColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: bgTextColor, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection(ThemeData theme, String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in items) _buildGuideBullet(item),
      ],
    );
  }

  Future<void> _showDraftGuideSheet() async {
    final s = S.of(context);
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: theme.primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s.draftLeagueGuideTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildGuideSection(theme, s.guideHowDraftWorksTitle, [
                  s.guideHowDraftWorksItem1,
                  s.guideHowDraftWorksItem2,
                  s.guideHowDraftWorksItem3,
                  s.guideHowDraftWorksItem4,
                ]),
                const SizedBox(height: 16),
                _buildGuideSection(theme, s.guideWhatYouAreBuildingTitle, [
                  s.guideWhatYouAreBuildingItem1,
                  s.guideWhatYouAreBuildingItem2,
                  s.guideWhatYouAreBuildingItem3,
                ]),
                const SizedBox(height: 16),
                _buildGuideSection(theme, s.guideDraftVsClassicTitle, [
                  s.guideDraftVsClassicItem1,
                  s.guideDraftVsClassicItem2,
                  s.guideDraftVsClassicItem3,
                  s.guideDraftVsClassicItem4,
                ]),
                const SizedBox(height: 16),
                _buildGuideSection(theme, s.guidePracticalTipsTitle, [
                  s.guidePracticalTipsItem1,
                  s.guidePracticalTipsItem2,
                  s.guidePracticalTipsItem3,
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFantasyMatchupCard(ThemeData theme) {
    final s = S.of(context);
    final myTeamName = _myTeam?.teamName ?? s.myTeamLabel;
    final myPoints = _myTeam?.totalPredictedPoints ?? 0.0;
    final opponentName = _opponent?.teamName ?? s.waitingForOpponentEllipsis;
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
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3)),
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
                s.nextMatchupTitle,
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
                        border: Border.all(color: theme.primaryColor, width: 2),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s.pointsAbbrev(myPoints.toStringAsFixed(1)),
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
                    s.vsUpper,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          s.pointsAbbrev(opponentPoints.toStringAsFixed(1)),
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
                    ? s.projectedWinBy(
                        (myPoints - opponentPoints).toStringAsFixed(1),
                      )
                    : myPoints < opponentPoints
                    ? s.behindByEditTeam(
                        (opponentPoints - myPoints).toStringAsFixed(1),
                      )
                    : s.closeMatchup,
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
    final s = S.of(context);
    final hasTeam = _myTeam != null && _myTeam!.players.isNotEmpty;
    final rosterSize = _league.isDraftMode
        ? (_league.draftSettings?.rosterSize ?? _league.rosterSize)
        : _league.rosterSize;
    final isDraftCompleted = _isDraftCompletedForUi();

    if (!hasTeam) {
      if (isDraftCompleted) {
        final isSyncingDraftedTeam = _isLoading || _isRefreshingDraftResults;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  strokeWidth: 5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.draftCompleted,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSyncingDraftedTeam
                    ? 'Loading your drafted team...'
                    : 'Your drafted team is still syncing.',
                textAlign: TextAlign.center,
                style: TextStyle(color: bgTextColor),
              ),
              if (!isSyncingDraftedTeam) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _refreshDraftResults,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        );
      }

      if (_league.isDraftMode) {
        final draftDateTime = _league.draftSettings?.draftDateTime;
        final canEnterDraft =
            draftDateTime != null &&
            DateTime.now().isAfter(
              draftDateTime.subtract(const Duration(minutes: 15)),
            );

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
                  canEnterDraft ? Icons.gavel : Icons.schedule,
                  size: 40,
                  color: canEnterDraft ? theme.primaryColor : bgTextColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                canEnterDraft ? s.draftRoomReady : s.teamWillBeDraftedLive,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                canEnterDraft
                    ? s.draftLiveEnterRoomDescription
                    : s.teamCreatedThroughLiveDraftDescription,
                textAlign: TextAlign.center,
                style: TextStyle(color: bgTextColor),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: canEnterDraft ? _navigateToDraftRoom : null,
                icon: Icon(canEnterDraft ? Icons.play_arrow : Icons.schedule),
                label: Text(
                  canEnterDraft
                      ? S.of(context).enterDraftRoom
                      : s.waitingForDraftStart,
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      }

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
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(Icons.groups_outlined, size: 40, color: bgTextColor),
            ),
            const SizedBox(height: 16),
            Text(
              s.noTeamYet,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.buildFantasyTeamCompete,
              textAlign: TextAlign.center,
              style: TextStyle(color: bgTextColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToTeamBuilder,
              icon: const Icon(Icons.add),
              label: Text(S.of(context).buildTeam),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Load formation from saved team if available
    if (_myTeam!.formation != null &&
        _selectedFormation.name != _myTeam!.formation) {
      final savedFormation = Formation.values.firstWhere(
        (f) => f.name == _myTeam!.formation,
        orElse: () => Formation.f433,
      );
      // Update formation without setState to avoid infinite loop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedFormation != savedFormation) {
          setState(() => _selectedFormation = savedFormation);
        }
      });
    }

    final hasConfiguredLineup =
        _myTeam!.formation != null &&
        _canFillFormation(_selectedFormation, _myTeam!.players);
    final starters = hasConfiguredLineup
        ? _getStartingXI(_myTeam!.players)
        : const <FantasyTeamPlayer>[];
    final validationErrors = _myTeam!.validationErrorsForRosterSize(rosterSize);

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
                          s.myTeamLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _league.isDraftMode
                              ? s.playersCountOfTotal(
                                  _myTeam!.players.length,
                                  rosterSize,
                                )
                              : s.playersAndBudgetLeft(
                                  _myTeam!.players.length,
                                  rosterSize,
                                  _myTeam!.budgetRemaining.toStringAsFixed(1),
                                ),
                          style: TextStyle(color: bgTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _navigateToTeamBuilder,
                    icon: const Icon(Icons.edit),
                    tooltip: S.of(context).editTeam,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Projected Points Card for Next Matchup
              _buildProjectedPointsCard(theme),
            ],
          ),
        ),
        if (!hasConfiguredLineup)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.22),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, color: theme.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s.pickStartersAndFormation,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.draftSquadReadySetStarters,
                    style: TextStyle(color: bgTextColor, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: _navigateToTeamBuilder,
                    icon: const Icon(Icons.edit),
                    label: Text(s.setStarters),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Text(
                  s.currentFormation,
                  style: TextStyle(
                    fontSize: 12,
                    color: bgTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _selectedFormation.name,
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SoccerFieldWidget(
              players: starters,
              formation: _selectedFormation,
              isEditable: false,
              showPredictedPoints: _league.status == LeagueStatus.draft,
              onPlayerTap: (player) =>
                  _navigateToPlayerProfile(player.playerId),
            ),
          ),
        ],

        // Team validation status - only show if there are actual issues
        if (!_myTeam!.isValidForRosterSize(rosterSize) &&
            validationErrors.isNotEmpty)
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
                    validationErrors.first,
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
    final gks = allPlayers
        .where((p) => p.position == PlayerPosition.goalkeeper)
        .take(1)
        .toList();
    final defs = allPlayers
        .where((p) => p.position == PlayerPosition.defender)
        .take(_selectedFormation.lines[0])
        .toList();
    final mids = allPlayers
        .where((p) => p.position == PlayerPosition.midfielder)
        .take(_selectedFormation.lines[1])
        .toList();
    final fwds = allPlayers
        .where(
          (p) =>
              p.position == PlayerPosition.attacker ||
              p.position == PlayerPosition.forward,
        )
        .take(_selectedFormation.lines[2])
        .toList();

    return [...gks, ...defs, ...mids, ...fwds];
  }

  /// Get substitute players
  List<FantasyTeamPlayer> _getSubstitutes(List<FantasyTeamPlayer> allPlayers) {
    final starters = _getStartingXI(allPlayers);
    final starterIds = starters.map((p) => p.playerId).toSet();
    return allPlayers.where((p) => !starterIds.contains(p.playerId)).toList();
  }

  bool _canFillFormation(
    Formation formation,
    List<FantasyTeamPlayer> allPlayers,
  ) {
    final goalkeeperCount = allPlayers
        .where((p) => p.position == PlayerPosition.goalkeeper)
        .length;
    final defenderCount = allPlayers
        .where((p) => p.position == PlayerPosition.defender)
        .length;
    final midfielderCount = allPlayers
        .where((p) => p.position == PlayerPosition.midfielder)
        .length;
    final forwardCount = allPlayers
        .where(
          (p) =>
              p.position == PlayerPosition.attacker ||
              p.position == PlayerPosition.forward,
        )
        .length;

    return allPlayers.length >= 11 &&
        goalkeeperCount >= 1 &&
        defenderCount >= formation.lines[0] &&
        midfielderCount >= formation.lines[1] &&
        forwardCount >= formation.lines[2];
  }

  /// Build the projected points card for next matchup
  Widget _buildProjectedPointsCard(ThemeData theme) {
    final s = S.of(context);
    final totalProjectedPoints = _myTeam?.totalPredictedPoints ?? 0.0;

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
            child: Icon(Icons.trending_up, color: theme.primaryColor, size: 26),
          ),
          const SizedBox(width: 16),

          // Points info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.projectedPoints,
                  style: TextStyle(color: bgTextColor, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  s.nextMatchupTitle,
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
                s.ptsShort,
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
        child: Text(
          S.of(context).noMembersYet,
          style: TextStyle(color: bgTextColor),
        ),
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
    final s = S.of(context);
    final isMe = member.oderId == _currentMember?.oderId;

    return Card(
      color: isMe
          ? theme.primaryColor.withValues(alpha: 0.1)
          : theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMe
            ? BorderSide(color: theme.primaryColor, width: 1)
            : BorderSide.none,
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
                child: Text(
                  s.youUpper,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
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
                child: Text(
                  s.creatorUpper,
                  style: const TextStyle(fontSize: 10, color: Colors.black),
                ),
              ),
          ],
        ),
        subtitle: Text(
          member.hasTeam ? s.teamCreated : s.noTeamYet,
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
                    s.pointsAbbrev(member.totalPoints.toStringAsFixed(1)),
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
    final s = S.of(context);
    final theme = Theme.of(context);
    final totalPredicted = team.totalPredictedPoints;
    final opponentName = _opponent?.teamName ?? s.waitingForOpponent;

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
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.trending_up, color: theme.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.yourPredictedPoints,
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
                s.nextOpponent,
                style: TextStyle(color: bgTextColor, fontSize: 11),
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
    final s = S.of(context);
    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 64, color: bgTextColor),
            const SizedBox(height: 16),
            Text(
              s.noStandingsYet,
              style: theme.textTheme.titleMedium?.copyWith(color: bgTextColor),
            ),
            const SizedBox(height: 8),
            Text(
              s.standingsAppearAfterMatchStarts,
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
    final s = S.of(context);
    final isMe = team.userId == _currentMember?.oderId;

    Color? positionColor;
    if (position == 1)
      positionColor = Colors.amber;
    else if (position == 2)
      positionColor = Colors.grey[400];
    else if (position == 3)
      positionColor = Colors.orange[300];

    return Card(
      color: isMe
          ? theme.primaryColor.withValues(alpha: 0.1)
          : theme.colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isMe
            ? BorderSide(color: theme.primaryColor, width: 1)
            : BorderSide.none,
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
                child: Text(
                  s.youUpper,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        subtitle: Text(
          s.playersAndMoneyLeft(
            team.players.length,
            team.budgetRemaining.toStringAsFixed(1),
          ),
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
              S.of(context).points,
              style: TextStyle(color: bgTextColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    ThemeData theme,
    String title,
    IconData icon,
    Widget child,
  ) {
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
            ? _buildMemberBottomButton(theme)
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
                          ? S.of(context).leagueFull
                          : S.of(context).joinLeague,
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

  Widget _buildMemberBottomButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _league.status == LeagueStatus.draft
          ? _navigateToTeamBuilder
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                ? S.of(context).editTeam
                : S.of(context).buildTeam,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _navigateToDraftRoom() {
    _navigateToTeamBuilder();
  }

  League _asClassicLeague(League league) {
    return league.copyWith(
      mode: LeagueMode.classic,
      draftSettings: null,
      tradeSettings: null,
    );
  }

  String _formatDraftTime(DateTime? dateTime) {
    final s = S.of(context);
    if (dateTime == null) return s.tbd;

    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return s.now;
    } else if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } else if (difference.inHours > 0) {
      return s.hoursMinutesShort(difference.inHours, difference.inMinutes % 60);
    } else {
      return s.minutesShort(difference.inMinutes);
    }
  }

  String _formatDraftCountdown(DateTime? dateTime) {
    final s = S.of(context);
    if (dateTime == null) return s.draftTimeNotScheduledYet;

    final difference = dateTime.difference(DateTime.now());
    if (difference.isNegative) {
      return s.draftIsLiveNow;
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (difference.inDays > 0) {
      return s.startsInDaysHoursMinutes(difference.inDays, hours % 24, minutes);
    }

    return s.startsInCountdown(
      hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0'),
    );
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, this.backgroundColor);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
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
