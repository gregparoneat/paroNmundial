import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/api/repositories/players_repository.dart';
import 'package:fantacy11/features/components/custom_button.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/services/cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Page for selecting user's favorite Liga MX team during onboarding
class FavoriteTeamSelectionPage extends StatefulWidget {
  final VoidCallback onComplete;

  const FavoriteTeamSelectionPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<FavoriteTeamSelectionPage> createState() =>
      _FavoriteTeamSelectionPageState();
}

class _FavoriteTeamSelectionPageState extends State<FavoriteTeamSelectionPage> {
  final CacheService _cacheService = CacheService();
  final PlayersRepository _playersRepository = PlayersRepository();
  
  List<LigaMxTeam> _teams = [];
  LigaMxTeam? _selectedTeam;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teams = await _playersRepository.getLigaMxTeams();
      if (mounted) {
        setState(() {
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveFavoriteTeam() async {
    if (_selectedTeam == null) return;

    setState(() => _isSaving = true);

    try {
      // Save to cache
      await _cacheService.saveFavoriteTeam(FavoriteTeam(
        id: _selectedTeam!.id,
        name: _selectedTeam!.name,
        logo: _selectedTeam!.logo,
      ));

      // Mark onboarding as completed
      await _cacheService.setOnboardingCompleted(true);

      // Pre-load players from favorite team in background
      _preloadFavoriteTeamPlayers();

      // Navigate to main app
      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving favorite team: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _preloadFavoriteTeamPlayers() async {
    if (_selectedTeam == null) return;

    try {
      debugPrint('Pre-loading players from favorite team: ${_selectedTeam!.name}');
      // This will cache the players for faster loading later
      await _playersRepository.getTeamPlayers(
        teamId: _selectedTeam!.id,
        teamName: _selectedTeam!.name,
        teamLogo: _selectedTeam!.logo,
      );
      debugPrint('Successfully pre-loaded players from ${_selectedTeam!.name}');
    } catch (e) {
      debugPrint('Error pre-loading favorite team players: $e');
      // Non-critical, don't show error to user
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = S.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadedSlideAnimation(
                    beginOffset: const Offset(0, -0.3),
                    endOffset: Offset.zero,
                    child: Text(
                      locale.selectFavoriteTeam,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadedSlideAnimation(
                    beginOffset: const Offset(0, -0.2),
                    endOffset: Offset.zero,
                    child: Text(
                      locale.favoriteTeamDescription,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Teams grid
            Expanded(
              child: _buildTeamsGrid(theme),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                onTap: _selectedTeam != null && !_isSaving
                    ? _saveFavoriteTeam
                    : null,
                text: _isSaving ? locale.saving : locale.continueText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamsGrid(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).errorLoadingTeams,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTeams,
              child: Text(S.of(context).retry),
            ),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return Center(
        child: Text(
          S.of(context).noTeamsFound,
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    return FadedSlideAnimation(
      beginOffset: const Offset(0, 0.2),
      endOffset: Offset.zero,
      child: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _teams.length,
        itemBuilder: (context, index) {
          final team = _teams[index];
          final isSelected = _selectedTeam?.id == team.id;

          return _buildTeamCard(theme, team, isSelected);
        },
      ),
    );
  }

  Widget _buildTeamCard(ThemeData theme, LigaMxTeam team, bool isSelected) {
    final primaryColor = theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedTeam = team;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.2)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Team logo
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: team.logo != null
                    ? CachedNetworkImage(
                        imageUrl: team.logo!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.sports_soccer,
                          size: 32,
                          color: primaryColor,
                        ),
                      )
                    : Icon(
                        Icons.sports_soccer,
                        size: 32,
                        color: primaryColor,
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Team name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                team.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? primaryColor
                      : theme.textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Check mark for selected
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                size: 20,
                color: primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

