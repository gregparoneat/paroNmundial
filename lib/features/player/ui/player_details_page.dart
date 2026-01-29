import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/api/repositories/seasons_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/fantasy/fantasy_points_predictor.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:fantacy11/features/player/models/player_info.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/services/cache_service.dart';
import 'package:flutter/material.dart';

class PlayerDetailsPage extends StatefulWidget {
  final Player? player;

  const PlayerDetailsPage({super.key, this.player});

  @override
  State<PlayerDetailsPage> createState() => _PlayerDetailsPageState();
}

class _PlayerDetailsPageState extends State<PlayerDetailsPage> {
  final PlayersRepository _repository = PlayersRepository();
  final FixturesRepository _fixturesRepository = FixturesRepository();
  final CacheService _cacheService = CacheService();
  Player? _player;
  bool _isLoading = true;
  bool _isLoadingNextMatch = false;
  bool _isLoadingRecentForm = false;
  MatchInfo? _nextMatch;
  OpponentInfo? _opponentInfo;
  RecentMatchStats? _recentMatchStats;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    if (widget.player != null) {
      // Use the passed player - it already has data from Firestore/cache
      _player = widget.player;
      _isLoading = false;
      
      // Only load what's needed: next match and recent form for predictions
      // These run in parallel
      _loadNextMatch();
      _loadRecentForm();
    } else {
      // No player provided - show error
      setState(() {
        _error = 'No player provided';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNextMatch() async {
    if (_player == null) {
      debugPrint('_loadNextMatch: Player is null, skipping');
      return;
    }

    debugPrint('_loadNextMatch: Starting to load next match');
    setState(() {
      _isLoadingNextMatch = true;
    });

    try {
      final teamId = _player!.currentTeam?.teamId;
      debugPrint('_loadNextMatch: Team ID: $teamId');
      
      MatchInfo? nextMatch;
      if (teamId != null && teamId > 0) {
        nextMatch = await _fixturesRepository.getNextMatchForTeam(teamId);
      } else {
        // No team ID - still try to get a fixture for demo purposes
        debugPrint('_loadNextMatch: No valid team ID, fetching demo fixture');
        nextMatch = await _fixturesRepository.getNextMatchForTeam(0);
      }
      
      debugPrint('_loadNextMatch: Result - ${nextMatch?.team1Name} vs ${nextMatch?.team2Name}');
      
      if (mounted && nextMatch != null) {
        // Determine opponent info
        final isHomeTeam = teamId != null && nextMatch.homeTeam?.id == teamId;
        final opponent = isHomeTeam ? nextMatch.awayTeam : nextMatch.homeTeam;
        
        debugPrint('_loadNextMatch: isHomeTeam=$isHomeTeam, opponent=${opponent?.name}');
        
        // Create opponent info (use away team if no match or for demo)
        final opponentTeam = opponent ?? nextMatch.awayTeam;
        if (opponentTeam != null) {
          _opponentInfo = OpponentInfo(
            name: opponentTeam.name,
            logoUrl: opponentTeam.imagePath,
            leaguePosition: opponentTeam.leaguePosition,
            isHomeGame: isHomeTeam,
            matchDateTime: nextMatch.startDateTime,
            venueName: nextMatch.venue?.name,
          );
          debugPrint('_loadNextMatch: Created OpponentInfo for ${opponentTeam.name}');
        } else {
          // Fallback: create basic opponent info from match data
          _opponentInfo = OpponentInfo(
            name: nextMatch.team2Name.isNotEmpty ? nextMatch.team2Name : 'Opponent',
            logoUrl: nextMatch.team2Logo,
            isHomeGame: true,
            matchDateTime: nextMatch.startDateTime,
            venueName: nextMatch.venue?.name,
          );
          debugPrint('_loadNextMatch: Created fallback OpponentInfo for ${nextMatch.team2Name}');
        }
        
        setState(() {
          _nextMatch = nextMatch;
          _isLoadingNextMatch = false;
        });
        debugPrint('_loadNextMatch: State updated with next match');
      } else if (mounted) {
        debugPrint('_loadNextMatch: No next match found or widget not mounted');
        setState(() {
          _isLoadingNextMatch = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('_loadNextMatch: Error - $e');
      debugPrint('_loadNextMatch: Stack trace - $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingNextMatch = false;
        });
      }
    }
  }

  Future<void> _loadRecentForm() async {
    if (_player == null) {
      debugPrint('_loadRecentForm: Player is null, skipping');
      return;
    }

    final teamId = _player!.currentTeam?.teamId;
    final playerId = _player!.id;

    if (teamId == null || teamId <= 0) {
      debugPrint('_loadRecentForm: No valid team ID, skipping');
      return;
    }

    debugPrint('_loadRecentForm: Loading recent form for player $playerId');
    setState(() {
      _isLoadingRecentForm = true;
    });

    try {
      // Step 1: Check Hive cache first
      final cachedStats = _cacheService.getPlayerFormStats(playerId);
      if (cachedStats != null) {
        debugPrint('_loadRecentForm: Found cached form stats for player $playerId');
        final recentStats = RecentMatchStats(
          matchesPlayed: cachedStats['matchesPlayed'] as int? ?? 0,
          goals: cachedStats['goals'] as int? ?? 0,
          assists: cachedStats['assists'] as int? ?? 0,
          minutesPlayed: cachedStats['minutesPlayed'] as int? ?? 0,
          cleanSheets: cachedStats['cleanSheets'] as int? ?? 0,
          yellowCards: cachedStats['yellowCards'] as int? ?? 0,
          redCards: cachedStats['redCards'] as int? ?? 0,
          saves: cachedStats['saves'] as int? ?? 0,
          averageRating: cachedStats['averageRating'] as double?,
          fixturesAnalyzed: cachedStats['fixturesAnalyzed'] as int?,
        );
        
        if (mounted) {
          setState(() {
            _recentMatchStats = recentStats;
            _isLoadingRecentForm = false;
          });
        }
        return;
      }

      // Step 2: Fetch from API if not cached
      debugPrint('_loadRecentForm: No cache, fetching from API for player $playerId on team $teamId');
      final recentStats = await _fixturesRepository.getPlayerRecentStats(
        playerId,
        teamId,
        matchCount: 5,
      );

      if (mounted) {
        setState(() {
          _recentMatchStats = recentStats;
          _isLoadingRecentForm = false;
        });

        // Step 3: Cache the results in Hive
        if (recentStats != null) {
          debugPrint('_loadRecentForm: Got stats from ${recentStats.matchesPlayed} matches');
          debugPrint('_loadRecentForm: Goals: ${recentStats.goals}, Assists: ${recentStats.assists}, Minutes: ${recentStats.minutesPlayed}');
          
          // Save to cache
          await _cacheService.savePlayerFormStats(playerId, {
            'matchesPlayed': recentStats.matchesPlayed,
            'goals': recentStats.goals,
            'assists': recentStats.assists,
            'minutesPlayed': recentStats.minutesPlayed,
            'cleanSheets': recentStats.cleanSheets,
            'yellowCards': recentStats.yellowCards,
            'redCards': recentStats.redCards,
            'saves': recentStats.saves,
            'averageRating': recentStats.averageRating,
            'fixturesAnalyzed': recentStats.fixturesAnalyzed,
          });
        } else {
          debugPrint('_loadRecentForm: No recent stats available');
        }
      }
    } catch (e) {
      debugPrint('_loadRecentForm: Error - $e');
      if (mounted) {
        setState(() {
          _isLoadingRecentForm = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    _fixturesRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _player == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(S.of(context).playerDetails),
        ),
        body: Center(
          child: Text(
            _error ?? S.of(context).playerNotFound,
            style: TextStyle(color: iconColor),
          ),
        ),
      );
    }

    return _PlayerDetailsContent(
      player: _player!,
      isLoadingNextMatch: _isLoadingNextMatch,
      isLoadingRecentForm: _isLoadingRecentForm,
      nextMatch: _nextMatch,
      opponentInfo: _opponentInfo,
      recentMatchStats: _recentMatchStats,
      // These use defaults (false/null) since we don't load them separately
      // The player already has stats from Firestore/API include
    );
  }
}

class _PlayerDetailsContent extends StatelessWidget {
  final Player player;
  final bool isLoadingTeams;
  final bool isLoadingNextMatch;
  final bool isLoadingRecentForm;
  final bool isLoadingTournamentStats;
  final MatchInfo? nextMatch;
  final OpponentInfo? opponentInfo;
  final RecentMatchStats? recentMatchStats;
  final RecentMatchStats? tournamentStats;
  final SeasonInfo? currentSeason;

  const _PlayerDetailsContent({
    required this.player,
    this.isLoadingTeams = false,
    this.isLoadingNextMatch = false,
    this.isLoadingRecentForm = false,
    this.isLoadingTournamentStats = false,
    this.nextMatch,
    this.opponentInfo,
    this.recentMatchStats,
    this.tournamentStats,
    this.currentSeason,
  });

  /// Get the stats for the current season, with fallback to latest stats
  /// Uses the player's most recent stats since we don't need to fetch season separately
  PlayerStatistics? get currentSeasonStats {
    // Use null to get the latest stats from the player's statistics
    return player.getStatsForCurrentSeason(null);
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Custom App Bar with player header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.arrow_back, color: iconColor, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildPlayerHeader(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadedSlideAnimation(
              beginOffset: const Offset(0, 0.1),
              endOffset: Offset.zero,
              slideCurve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fantasy Points Prediction
                    _buildFantasyPrediction(context),
                    const SizedBox(height: 20),

                    // Quick Stats
                    _buildQuickStats(context),
                    const SizedBox(height: 20),

                    // Bio Section
                    _buildBioSection(context),
                    const SizedBox(height: 20),

                    // Statistics Section (current tournament only)
                    if (currentSeasonStats != null) ...[
                      _buildStatisticsSection(context),
                      const SizedBox(height: 20),
                    ],

                    // Career Section
                    if (player.transfers.isNotEmpty) ...[
                      _buildCareerSection(context),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerHeader(BuildContext context) {
    var theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            player.position?.color.withValues(alpha: 0.8) ?? theme.primaryColor,
            theme.colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Player Image
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: player.hasRealImage
                        ? CachedNetworkImage(
                            imageUrl: player.imagePath!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                _buildPlaceholderAvatar(theme),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholderAvatar(theme),
                          )
                        : _buildPlaceholderAvatar(theme),
                  ),
                ),
                // Jersey Number Badge
                if (player.jerseyNumber != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#${player.jerseyNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Player Name
            Text(
              player.displayName,
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),

            // Position & Nationality
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (player.position != null) ...[
                  Icon(
                    player.position!.icon,
                    color: player.position!.color,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    player.detailedPosition?.name ?? player.position!.name,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
                if (player.nationality != null) ...[
                  const SizedBox(width: 16),
                  if (player.nationality!.imagePath != null)
                    CachedNetworkImage(
                      imageUrl: player.nationality!.imagePath!,
                      width: 20,
                      height: 14,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const SizedBox.shrink(),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    player.nationality!.fifaName ?? player.nationality!.name,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),

            // Current Team (compact inline display)
            if (player.currentTeam != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (player.currentTeamLogo != null)
                    CachedNetworkImage(
                      imageUrl: player.currentTeamLogo!,
                      width: 20,
                      height: 20,
                      errorWidget: (context, url, error) => Icon(
                        Icons.shield,
                        color: theme.primaryColor,
                        size: 18,
                      ),
                    )
                  else
                    Icon(Icons.shield, color: theme.primaryColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    player.currentTeam!.teamDisplay,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (player.isCaptain) ...[
                    const SizedBox(width: 8),
                    Text(
                      '⭐',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(ThemeData theme) {
    return Container(
      color: bgColor,
      child: Icon(
        Icons.person,
        size: 60,
        color: bgTextColor,
      ),
    );
  }

  Widget _buildFantasyPrediction(BuildContext context) {
    var theme = Theme.of(context);
    final prediction = FantasyPointsPredictor.predict(
      player,
      recentForm: recentMatchStats,
      opponent: opponentInfo,
      currentSeasonId: currentSeason?.id,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(prediction.tierColorValue).withValues(alpha: 0.3),
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(prediction.tierColorValue).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_graph, color: Color(prediction.tierColorValue), size: 20),
              const SizedBox(width: 8),
              Text(
                S.of(context).fantasyPointsPrediction,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(prediction.tierColorValue).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  prediction.tier,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: Color(prediction.tierColorValue),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Score
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${prediction.totalPoints}',
                style: theme.textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(prediction.tierColorValue),
                  fontSize: 48,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text(
                  '/ 100',
                  style: theme.textTheme.bodyLarge!.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const Spacer(),
              // Recent Form indicator
              if (prediction.recentFormScore != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      S.of(context).last5Form,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      prediction.formDescription,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Color(prediction.formColorValue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    S.of(context).confidence,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    prediction.confidenceDescription,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prediction.totalPoints / 100,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation<Color>(Color(prediction.tierColorValue)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Top Factors
          Text(
            S.of(context).keyFactors,
            style: theme.textTheme.bodySmall!.copyWith(
              color: bgTextColor,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          ...prediction.topFactors.map((factor) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(
                  factor.value >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  size: 14,
                  color: factor.value >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    factor.key,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  factor.value >= 0 
                      ? '+${factor.value.toStringAsFixed(1)}'
                      : factor.value.toStringAsFixed(1),
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: factor.value >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )),

          // Next Match section (if available) - shows above opponent analysis
          if (nextMatch != null || isLoadingNextMatch) ...[
            const SizedBox(height: 12),
            _buildNextMatchSection(context, theme, prediction),
          ],

          // Data source note
          const SizedBox(height: 8),
          Row(
            children: [
              if (isLoadingRecentForm)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  _getDataSourceDescription(context, prediction),
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDataSourceDescription(BuildContext context, FantasyPrediction prediction) {
    final hasRealRecentForm = recentMatchStats != null && recentMatchStats!.matchesPlayed > 0;
    final matchCount = recentMatchStats?.matchesPlayed ?? 0;
    
    String base = S.of(context).basedOnMetrics(prediction.position);
    
    if (hasRealRecentForm) {
      base += ' • ${S.of(context).lastMatchesPlus(matchCount)}';
    } else {
      base += ' • ${S.of(context).seasonAverages}';
    }
    
    if (prediction.hasOpponentAnalysis) {
      base += ' ${S.of(context).plusMatchup}';
    }
    
    return base;
  }

  Widget _buildNextMatchSection(BuildContext context, ThemeData theme, FantasyPrediction prediction) {
    if (isLoadingNextMatch) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              S.of(context).loadingNextMatch,
              style: theme.textTheme.bodySmall!.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (nextMatch == null) return const SizedBox.shrink();

    final opponent = opponentInfo;
    final difficultyColor = opponent != null 
        ? Color(opponent.difficultyColorValue) 
        : theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            difficultyColor.withValues(alpha: 0.15),
            theme.colorScheme.surface.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: difficultyColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with "Next Match" label and time remaining
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: difficultyColor,
              ),
              const SizedBox(width: 6),
              Text(
                S.of(context).nextMatch,
                style: theme.textTheme.bodySmall!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: difficultyColor,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  opponent?.timeRemaining ?? nextMatch!.getTimeRemaining(),
                  style: theme.textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: difficultyColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Match info row
          Row(
            children: [
              // Home team
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        nextMatch!.homeTeam?.name ?? nextMatch!.team1Name,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildTeamLogo(nextMatch!.team1Logo, 24),
                  ],
                ),
              ),
              
              // VS separator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      'vs',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      opponent?.formattedMatchTime ?? nextMatch!.formattedDateTime,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: Colors.grey[600],
                        fontSize: 9,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Away team
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildTeamLogo(nextMatch!.team2Logo, 24),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        nextMatch!.awayTeam?.name ?? nextMatch!.team2Name,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Venue and matchup difficulty info
          const SizedBox(height: 8),
          Row(
            children: [
              if (nextMatch!.venue?.name != null || opponent?.venueName != null) ...[
                Icon(
                  Icons.stadium,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    nextMatch!.venue?.name ?? opponent?.venueName ?? '',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: Colors.grey[500],
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              // Matchup difficulty if available
              if (opponent != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: difficultyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        opponent.difficultyLabel,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: difficultyColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        opponent.isHomeGame ? '(H)' : '(A)',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: Colors.grey[500],
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(String logoUrl, double size) {
    if (logoUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.shield, size: size * 0.6, color: Colors.grey[600]),
      );
    }
    
    if (logoUrl.startsWith('assets/')) {
      return Image.asset(
        logoUrl,
        width: size,
        height: size,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shield, size: size * 0.6, color: Colors.grey[600]),
        ),
      );
    }
    
    return CachedNetworkImage(
      imageUrl: logoUrl,
      width: size,
      height: size,
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.shield, size: size * 0.6, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    var theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, S.of(context).age, '${player.age ?? "-"}', Icons.cake),
          _buildStatDivider(),
          // Show goals if stats available, otherwise height
          if (currentSeasonStats?.goals != null)
            _buildStatItem(context, S.of(context).goals, '${currentSeasonStats!.goals}', Icons.sports_score)
          else
            _buildStatItem(context, S.of(context).height, player.formattedHeight, Icons.height),
          _buildStatDivider(),
          // Show assists if stats available, otherwise weight
          if (currentSeasonStats?.assists != null)
            _buildStatItem(context, S.of(context).assists, '${currentSeasonStats!.assists}', Icons.handshake)
          else
            _buildStatItem(context, S.of(context).weight, player.formattedWeight, Icons.fitness_center),
          _buildStatDivider(),
          // Show appearances if stats available, otherwise transfers
          if (currentSeasonStats?.appearances != null)
            _buildStatItem(context, S.of(context).apps, '${currentSeasonStats!.appearances}', Icons.sports_soccer)
          else
            _buildStatItem(context, S.of(context).transfers, '${player.transfers.length}', Icons.swap_horiz),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    var theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.primaryColor, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall!.copyWith(
            color: bgTextColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: bgTextColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildBioSection(BuildContext context) {
    var theme = Theme.of(context);

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
              Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                S.of(context).playerInfo,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(context, S.of(context).fullName, player.name),
          _buildInfoRow(context, S.of(context).dateOfBirth, player.dateOfBirth ?? '-'),
          _buildInfoRow(
              context, S.of(context).nationality, player.nationality?.name ?? '-'),
          _buildInfoRow(context, S.of(context).position,
              player.detailedPosition?.name ?? player.position?.name ?? '-'),
          if (player.isCaptain) _buildInfoRow(context, S.of(context).role, '⭐ ${S.of(context).captain}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium!.copyWith(
              color: bgTextColor,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    var theme = Theme.of(context);
    final stats = currentSeasonStats;

    // Use tournament stats if available, otherwise fall back to recent form
    final tournamentOrRecentStats = tournamentStats ?? recentMatchStats;
    final hasTournamentData = tournamentOrRecentStats != null && tournamentOrRecentStats.matchesPlayed > 0;

    if (stats == null && !hasTournamentData) return const SizedBox.shrink();

    // Get the current stage/tournament name if available
    final currentStageName = currentSeason?.currentStage?.name;

    return Column(
      children: [
        // Current Tournament Stats (from fixtures within tournament date range - most accurate)
        if (hasTournamentData || isLoadingTournamentStats)
          _buildCurrentTournamentStats(context, theme, currentStageName),
        
        if (hasTournamentData && stats != null)
          const SizedBox(height: 16),
        
        // Full Season Stats (aggregated from both tournaments)
        if (stats != null)
          _buildSeasonStats(context, theme, stats),
      ],
    );
  }

  /// Builds the current tournament stats section using actual fixture data
  Widget _buildCurrentTournamentStats(BuildContext context, ThemeData theme, String? stageName) {
    // Use tournament stats if available, otherwise fall back to recent form
    final stats = tournamentStats ?? recentMatchStats;
    final isTournamentData = tournamentStats != null;
    
    // Show loading indicator while fetching
    if (isLoadingTournamentStats && stats == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: theme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  stageName != null ? S.of(context).stageStatistics(stageName) : S.of(context).tournamentStatistics,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: bgTextColor,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                S.of(context).loadingTournamentStats,
                style: theme.textTheme.bodySmall!.copyWith(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }
    
    if (stats == null) return const SizedBox.shrink();
    
    // Determine the label based on whether we have actual tournament data or just recent form
    final sectionTitle = isTournamentData && stageName != null 
        ? S.of(context).stageStatistics(stageName) 
        : S.of(context).recentForm;
    final badgeText = isTournamentData 
        ? S.of(context).nMatches(stats.matchesPlayed) 
        : S.of(context).lastNMatches(stats.matchesPlayed);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sectionTitle,
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: bgTextColor,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.primaryColor,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats from tournament matches
          Row(
            children: [
              _buildStatBox(context, S.of(context).games, stats.matchesPlayed.toString(), Icons.sports_soccer),
              const SizedBox(width: 12),
              _buildStatBox(context, S.of(context).goals, stats.goals.toString(), Icons.sports_score),
              const SizedBox(width: 12),
              _buildStatBox(context, S.of(context).assists, stats.assists.toString(), Icons.handshake),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBox(context, S.of(context).minutes, _formatMinutes(stats.minutesPlayed), Icons.timer),
              const SizedBox(width: 12),
              _buildStatBox(context, S.of(context).yellow, stats.yellowCards.toString(), Icons.square, color: Colors.amber),
              const SizedBox(width: 12),
              _buildStatBox(context, S.of(context).red, stats.redCards.toString(), Icons.square, color: Colors.red),
            ],
          ),

          // Goalkeeper-specific stats
          if (player.isGoalkeeper && (stats.cleanSheets > 0 || stats.saves > 0)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildStatBox(context, S.of(context).cleanSheets, stats.cleanSheets.toString(), Icons.shield)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatBox(context, S.of(context).saves, stats.saves.toString(), Icons.sports_handball)),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()), // Placeholder
              ],
            ),
          ],

          // Average rating if available
          if (stats.averageRating != null && stats.averageRating! > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${S.of(context).avgRating}: ${stats.averageRating!.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the full season statistics section
  Widget _buildSeasonStats(BuildContext context, ThemeData theme, PlayerStatistics stats) {
    // Get the season name from the stats
    final seasonDisplayName = stats.seasonName ?? currentSeason?.name;

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
              Icon(Icons.bar_chart, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                S.of(context).fullSeasonStatistics,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (seasonDisplayName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    seasonDisplayName,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          // Note about full season data
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              S.of(context).includesAperturaClausura,
              style: theme.textTheme.bodySmall!.copyWith(
                color: Colors.grey[500],
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main stats grid
          Row(
            children: [
              _buildStatBox(context, S.of(context).appearances, stats.appearances?.toString() ?? '-', Icons.sports_soccer),
              const SizedBox(width: 12),
              _buildStatBox(context, S.of(context).goals, stats.goals?.toString() ?? '-', Icons.sports_score),
              const SizedBox(width: 12),
              _buildStatBox(context, S.of(context).assists, stats.assists?.toString() ?? '-', Icons.handshake),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatBox(context, S.of(context).minutes, stats.formattedMinutes, Icons.timer),
              const SizedBox(width: 12),
              _buildStatBox(context, S.of(context).yellow, stats.yellowCards?.toString() ?? '-', Icons.square, color: Colors.amber),
              const SizedBox(width: 12),
              _buildStatBox(context, S.of(context).red, stats.redCards?.toString() ?? '-', Icons.square, color: Colors.red),
            ],
          ),

          // Goalkeeper-specific stats (only show for goalkeepers)
          if (player.isGoalkeeper && (stats.cleanSheets != null || stats.saves != null)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (stats.cleanSheets != null)
                  Expanded(child: _buildStatBox(context, S.of(context).cleanSheets, stats.cleanSheets.toString(), Icons.shield)),
                if (stats.cleanSheets != null && stats.saves != null)
                  const SizedBox(width: 12),
                if (stats.saves != null)
                  Expanded(child: _buildStatBox(context, S.of(context).saves, stats.saves.toString(), Icons.sports_handball)),
                // Placeholder to maintain grid
                if (stats.cleanSheets != null && stats.saves == null)
                  const Spacer(),
                if (stats.cleanSheets == null && stats.saves != null)
                  const Spacer(),
              ],
            ),
          ],

          // Rating if available
          if (stats.rating != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.2),
                    theme.primaryColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context).averageRating,
                    style: theme.textTheme.bodyMedium!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    stats.rating!.toStringAsFixed(2),
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Career totals
          if (player.statistics.length > 1) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).careerTotals,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: bgTextColor,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCareerStat(context, S.of(context).apps, player.careerAppearances.toString()),
                      _buildCareerStat(context, S.of(context).goals, player.careerGoals.toString()),
                      _buildCareerStat(context, S.of(context).assists, player.careerAssists.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Format minutes played for display
  String _formatMinutes(int minutes) {
    if (minutes >= 1000) {
      return '${(minutes / 1000).toStringAsFixed(1)}k min';
    }
    return '$minutes min';
  }

  Widget _buildStatBox(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    var theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? theme.primaryColor, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall!.copyWith(
                color: bgTextColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerStat(BuildContext context, String label, String value) {
    var theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall!.copyWith(
            color: bgTextColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCareerSection(BuildContext context) {
    var theme = Theme.of(context);

    // Sort transfers by date (newest first)
    final sortedTransfers = List<TransferInfo>.from(player.transfers)
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

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
              Icon(Icons.swap_horiz, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                S.of(context).transferHistory,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
              if (isLoadingTeams) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ...sortedTransfers.take(5).map((transfer) => _buildTransferItem(
                context,
                transfer,
              )),
        ],
      ),
    );
  }

  Widget _buildTransferItem(BuildContext context, TransferInfo transfer) {
    var theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Date
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transfer.date ?? '-',
              style: theme.textTheme.bodySmall!.copyWith(
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          // Transfer info
          Expanded(
            child: Row(
              children: [
                // From team
                if (transfer.fromTeamLogo != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CachedNetworkImage(
                      imageUrl: transfer.fromTeamLogo!,
                      width: 16,
                      height: 16,
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                Flexible(
                  child: Text(
                    transfer.fromTeamDisplay,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.arrow_forward, size: 12, color: theme.primaryColor),
                ),
                // To team
                if (transfer.toTeamLogo != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CachedNetworkImage(
                      imageUrl: transfer.toTeamLogo!,
                      width: 16,
                      height: 16,
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    ),
                  ),
                Flexible(
                  child: Text(
                    transfer.toTeamDisplay,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: transfer.amount != null
                  ? theme.primaryColor.withValues(alpha: 0.2)
                  : bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              transfer.formattedAmount,
              style: theme.textTheme.bodySmall!.copyWith(
                color: transfer.amount != null ? theme.primaryColor : bgTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

}

