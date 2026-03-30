// Trade Page for Draft Leagues
// UI for proposing, viewing, and managing trades

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/features/league/models/draft_models.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/services/trade_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TradePage extends StatefulWidget {
  final League league;
  final List<FantasyTeam> teams; // All teams in the league
  final String currentUserId;

  const TradePage({
    super.key,
    required this.league,
    required this.teams,
    required this.currentUserId,
  });

  @override
  State<TradePage> createState() => _TradePageState();
}

class _TradePageState extends State<TradePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TradeService _tradeService;

  // For proposing trades
  String? _selectedRecipientId;
  final List<FantasyTeamPlayer> _playersToOffer = [];
  final List<FantasyTeamPlayer> _playersToRequest = [];
  final _messageController = TextEditingController();
  final _playerSearchController = TextEditingController();
  String _playerSearchQuery = '';

  FantasyTeam? get _myTeam => widget.teams.firstWhere(
    (t) => t.userId == widget.currentUserId,
    orElse: () => throw Exception('Your team not found'),
  );

  FantasyTeam? get _selectedRecipientTeam => _selectedRecipientId != null
      ? widget.teams.firstWhere(
          (t) => t.userId == _selectedRecipientId,
          orElse: () => throw Exception('Recipient team not found'),
        )
      : null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tradeService = TradeService(
      league: widget.league,
      currentUserId: widget.currentUserId,
    );
    _tradeService.addListener(_onTradeServiceUpdate);
  }

  void _onTradeServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tradeService.removeListener(_onTradeServiceUpdate);
    _tradeService.dispose();
    _messageController.dispose();
    _playerSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Badge(
                isLabelVisible: _tradeService.incomingTrades.isNotEmpty,
                label: Text('${_tradeService.incomingTrades.length}'),
                child: const Text('Inbox'),
              ),
            ),
            const Tab(text: 'Propose'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Trade deadline banner
          if (widget.league.tradeSettings?.hasDeadline ?? false)
            _buildDeadlineBanner(theme),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInboxTab(theme),
                _buildProposeTab(theme),
                _buildHistoryTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineBanner(ThemeData theme) {
    final deadline = widget.league.tradeSettings?.tradeDeadline;
    if (deadline == null) return const SizedBox.shrink();

    final isPassed = DateTime.now().isAfter(deadline);
    final color = isPassed ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: color.withValues(alpha: 0.2),
      child: Row(
        children: [
          Icon(isPassed ? Icons.lock : Icons.schedule, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isPassed
                  ? 'Trade deadline has passed'
                  : 'Trade deadline: ${DateFormat('MMM d, yyyy').format(deadline)}',
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxTab(ThemeData theme) {
    final incoming = _tradeService.incomingTrades;
    final outgoing = _tradeService.outgoingTrades;
    final awaitingVote = _tradeService.tradesAwaitingVote;

    if (incoming.isEmpty && outgoing.isEmpty && awaitingVote.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No pending trades',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Propose a trade to get started',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (incoming.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Incoming Trades', incoming.length),
          ...incoming.map((t) => _buildTradeCard(theme, t, isIncoming: true)),
          const SizedBox(height: 16),
        ],
        if (outgoing.isNotEmpty) ...[
          _buildSectionHeader(theme, 'Outgoing Trades', outgoing.length),
          ...outgoing.map((t) => _buildTradeCard(theme, t, isIncoming: false)),
          const SizedBox(height: 16),
        ],
        if (awaitingVote.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            'Awaiting League Vote',
            awaitingVote.length,
          ),
          ...awaitingVote.map(
            (t) => _buildTradeCard(theme, t, showVoting: true),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeCard(
    ThemeData theme,
    Trade trade, {
    bool isIncoming = false,
    bool showVoting = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.primaryColor.withValues(alpha: 0.2),
                  child: Text(
                    isIncoming
                        ? trade.proposerName[0].toUpperCase()
                        : trade.recipientName[0].toUpperCase(),
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isIncoming
                            ? 'From: ${trade.proposerName}'
                            : 'To: ${trade.recipientName}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d, HH:mm').format(trade.proposedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(theme, trade.status),
              ],
            ),

            const Divider(height: 24),

            // Trade details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You receive:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...(isIncoming
                              ? trade.proposerPlayers
                              : trade.recipientPlayers)
                          .map((p) => _buildPlayerRow(theme, p)),
                    ],
                  ),
                ),
                Container(width: 1, height: 60, color: Colors.grey.shade700),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'You give:',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...(isIncoming
                              ? trade.recipientPlayers
                              : trade.proposerPlayers)
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(left: 12),
                              child: _buildPlayerRow(theme, p),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),

            // Message
            if (trade.message != null && trade.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.message, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trade.message!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            if (trade.isPending && isIncoming) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectTrade(trade),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _acceptTrade(trade),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],

            if (trade.isPending && !isIncoming) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _cancelTrade(trade),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                  child: const Text('Cancel Trade'),
                ),
              ),
            ],

            // Voting
            if (showVoting) ...[
              const SizedBox(height: 16),
              _buildVotingSection(theme, trade),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRow(ThemeData theme, TradePlayer player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          if (player.playerImageUrl != null)
            CachedNetworkImage(
              imageUrl: player.playerImageUrl!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              placeholder: (_, __) => const CircleAvatar(radius: 12),
              errorWidget: (_, __, ___) => const CircleAvatar(radius: 12),
            )
          else
            const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              player.playerName,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _getPositionColor(player.position).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              player.position.abbreviation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getPositionColor(player.position),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme, TradeStatus status) {
    Color color;
    switch (status) {
      case TradeStatus.pending:
        color = Colors.orange;
        break;
      case TradeStatus.accepted:
        color = Colors.blue;
        break;
      case TradeStatus.approved:
        color = Colors.green;
        break;
      case TradeStatus.rejected:
      case TradeStatus.vetoed:
      case TradeStatus.cancelled:
        color = Colors.red;
        break;
      case TradeStatus.expired:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVotingSection(ThemeData theme, Trade trade) {
    final votesFor = trade.votesFor ?? 0;
    final votesAgainst = trade.votesAgainst ?? 0;
    final hasVoted = trade.voters?.contains(widget.currentUserId) ?? false;
    final isParticipant =
        trade.proposerId == widget.currentUserId ||
        trade.recipientId == widget.currentUserId;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'League Vote',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildVoteCount(theme, 'For', votesFor, Colors.green),
              const SizedBox(width: 16),
              _buildVoteCount(theme, 'Against', votesAgainst, Colors.red),
            ],
          ),
          if (!hasVoted && !isParticipant) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _voteOnTrade(trade, approve: false),
                    icon: const Icon(Icons.thumb_down, size: 16),
                    label: const Text('Vote Against'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _voteOnTrade(trade, approve: true),
                    icon: const Icon(Icons.thumb_up, size: 16),
                    label: const Text('Vote For'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (isParticipant) ...[
            const SizedBox(height: 8),
            Text(
              'You cannot vote on your own trade',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'You have already voted',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoteCount(
    ThemeData theme,
    String label,
    int count,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$count',
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildProposeTab(ThemeData theme) {
    if (!_tradeService.isTradingEnabled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'Trading is closed',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'The trade deadline has passed',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find a player to target',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _playerSearchController,
            decoration: InputDecoration(
              hintText: 'Search players in other squads...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _playerSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _playerSearchController.clear();
                        setState(() => _playerSearchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) => setState(() => _playerSearchQuery = value),
          ),
          const SizedBox(height: 12),
          _buildTradeTargetSearch(theme),

          if (_selectedRecipientId != null) ...[
            const SizedBox(height: 24),

            _buildSelectedTradeTarget(theme),

            const SizedBox(height: 24),

            // Players to offer
            Text(
              'Choose one of your players to offer:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildPlayerSelector(
              theme,
              _myTeam!.players,
              _playersToOffer,
              isOffer: true,
            ),

            const SizedBox(height: 24),

            // Message
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.message),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _canProposeTrade ? _proposeTrade : null,
                icon: const Icon(Icons.send),
                label: const Text('Propose Trade'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.primaryColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<(FantasyTeam team, FantasyTeamPlayer player)>
  get _searchableTradeTargets {
    final query = _playerSearchQuery.trim().toLowerCase();
    final results = <(FantasyTeam, FantasyTeamPlayer)>[];

    for (final team in widget.teams.where(
      (t) => t.userId != widget.currentUserId,
    )) {
      for (final player in team.players) {
        final matches =
            query.isEmpty ||
            player.playerName.toLowerCase().contains(query) ||
            (player.teamName ?? '').toLowerCase().contains(query);
        if (matches) {
          results.add((team, player));
        }
      }
    }

    results.sort(
      (a, b) => b.$2.predictedPoints.compareTo(a.$2.predictedPoints),
    );
    return results;
  }

  Widget _buildTradeTargetSearch(ThemeData theme) {
    final targets = _searchableTradeTargets;

    if (targets.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No trade targets found',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: targets.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade900),
        itemBuilder: (context, index) {
          final target = targets[index];
          final team = target.$1;
          final player = target.$2;
          final isSelected = _playersToRequest.any(
            (p) => p.playerId == player.playerId,
          );

          return ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: _getPositionColor(
                player.position,
              ).withValues(alpha: 0.18),
              child: Text(
                player.position.abbreviation,
                style: TextStyle(
                  color: _getPositionColor(player.position),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              player.playerName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
            subtitle: Text(
              '${player.teamName ?? ''} • Owned by ${team.teamName ?? team.userName} • ${player.predictedPoints.toStringAsFixed(1)} next',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: theme.primaryColor)
                : const Icon(Icons.chevron_right),
            onTap: () {
              setState(() {
                _selectedRecipientId = team.userId;
                _playersToRequest
                  ..clear()
                  ..add(player);
                _playersToOffer.clear();
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedTradeTarget(ThemeData theme) {
    final requestedPlayer = _playersToRequest.isEmpty
        ? null
        : _playersToRequest.first;
    final recipientTeam = _selectedRecipientTeam;
    if (requestedPlayer == null || recipientTeam == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _getPositionColor(
              requestedPlayer.position,
            ).withValues(alpha: 0.18),
            child: Text(
              requestedPlayer.position.abbreviation,
              style: TextStyle(
                color: _getPositionColor(requestedPlayer.position),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requestedPlayer.playerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Owned by ${recipientTeam.teamName ?? recipientTeam.userName}',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
                Text(
                  '${requestedPlayer.predictedPoints.toStringAsFixed(1)} next • ${requestedPlayer.teamName ?? ''}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedRecipientId = null;
                _playersToRequest.clear();
                _playersToOffer.clear();
              });
            },
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSelector(
    ThemeData theme,
    List<FantasyTeamPlayer> players,
    List<FantasyTeamPlayer> selected, {
    required bool isOffer,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Selected players
          if (selected.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isOffer ? Colors.red : Colors.green).withValues(
                  alpha: 0.1,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selected
                    .map(
                      (p) => Chip(
                        label: Text(p.playerName),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            selected.remove(p);
                          });
                        },
                        backgroundColor: (isOffer ? Colors.red : Colors.green)
                            .withValues(alpha: 0.2),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Available players
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final isSelected = selected.contains(player);

                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _getPositionColor(
                      player.position,
                    ).withValues(alpha: 0.2),
                    child: Text(
                      player.position.abbreviation,
                      style: TextStyle(
                        color: _getPositionColor(player.position),
                        fontSize: 10,
                      ),
                    ),
                  ),
                  title: Text(
                    player.playerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Text(
                    player.teamName ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selected
                            ..clear()
                            ..add(player);
                        } else {
                          selected.remove(player);
                        }
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selected.remove(player);
                      } else {
                        selected
                          ..clear()
                          ..add(player);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    final history = _tradeService.myTradeHistory;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text(
              'No trade history',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final trade = history[index];
        final isIncoming = trade.recipientId == widget.currentUserId;
        return _buildTradeCard(theme, trade, isIncoming: isIncoming);
      },
    );
  }

  bool get _canProposeTrade =>
      _selectedRecipientId != null &&
      _playersToOffer.isNotEmpty &&
      _playersToRequest.isNotEmpty;

  Future<void> _proposeTrade() async {
    if (_selectedRecipientId == null) return;

    final trade = await _tradeService.proposeTrade(
      recipientId: _selectedRecipientId!,
      recipientName:
          _selectedRecipientTeam?.teamName ??
          _selectedRecipientTeam?.userName ??
          '',
      playersOffered: _playersToOffer
          .map((p) => TradePlayer.fromFantasyTeamPlayer(p))
          .toList(),
      playersRequested: _playersToRequest
          .map((p) => TradePlayer.fromFantasyTeamPlayer(p))
          .toList(),
      message: _messageController.text.isEmpty ? null : _messageController.text,
    );

    if (trade != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trade proposed successfully')),
      );

      // Clear form
      setState(() {
        _playersToOffer.clear();
        _playersToRequest.clear();
        _messageController.clear();
        _selectedRecipientId = null;
      });

      // Switch to inbox tab
      _tabController.animateTo(0);
    }
  }

  Future<void> _acceptTrade(Trade trade) async {
    final success = await _tradeService.acceptTrade(trade.id);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trade accepted')));
    }
  }

  Future<void> _rejectTrade(Trade trade) async {
    final success = await _tradeService.rejectTrade(trade.id);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trade rejected')));
    }
  }

  Future<void> _cancelTrade(Trade trade) async {
    final success = await _tradeService.cancelTrade(trade.id);
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trade cancelled')));
    }
  }

  Future<void> _voteOnTrade(Trade trade, {required bool approve}) async {
    final success = await _tradeService.voteOnTrade(trade.id, approve: approve);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vote recorded: ${approve ? "For" : "Against"}'),
        ),
      );
    }
  }

  Color _getPositionColor(PlayerPosition position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return Colors.orange;
      case PlayerPosition.defender:
        return Colors.blue;
      case PlayerPosition.midfielder:
        return Colors.green;
      case PlayerPosition.attacker:
      case PlayerPosition.forward:
        return Colors.red;
    }
  }
}
