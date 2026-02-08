import 'package:carousel_slider/carousel_slider.dart';
import 'package:fantacy11/api/repositories/league_repository.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/league/models/league_models.dart';
import 'package:fantacy11/features/league/models/league_models_ui.dart';
import 'package:fantacy11/features/league/ui/league_details_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Displays user's fantasy leagues in a horizontal carousel
class MyLeaguesCarousel extends StatefulWidget {
  const MyLeaguesCarousel({super.key});

  @override
  State<MyLeaguesCarousel> createState() => _MyLeaguesCarouselState();
}

class _MyLeaguesCarouselState extends State<MyLeaguesCarousel> {
  final LeagueRepository _repository = LeagueRepository();
  List<League> _leagues = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    try {
      await _repository.init();
      final leagues = await _repository.getMyLeagues();
      if (mounted) {
        setState(() {
          _leagues = leagues;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading my leagues: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    if (_isLoading) {
      return Container(
        height: 140,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_leagues.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _leagues.length,
          itemBuilder: (context, index, pageIndex) {
            return _buildLeagueCard(_leagues[index]);
          },
          options: CarouselOptions(
            height: 140,
            enableInfiniteScroll: _leagues.length > 1,
            viewportFraction: 0.92,
            enlargeCenterPage: true,
            autoPlay: _leagues.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
        if (_leagues.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_leagues.length, (i) {
                return Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(
                      alpha: _currentIndex == i ? 0.9 : 0.3,
                    ),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to leagues page
            DefaultTabController.of(context).animateTo(2); // Assuming leagues is tab 2
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No leagues yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create or join a fantasy league to compete',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: bgTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: bgTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueCard(League league) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => _navigateToLeague(league),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.3),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // League type badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: league.isPublic 
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          league.type.icon,
                          size: 12,
                          color: league.isPublic ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          league.isPublic ? 'Public' : 'Private',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: league.isPublic ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: league.status.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      league.status.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: league.status.color,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // League name
              Text(
                league.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Match info row
              Row(
                children: [
                  Icon(Icons.sports_soccer, size: 14, color: bgTextColor),
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
                    const SizedBox(width: 8),
                    Icon(Icons.schedule, size: 14, color: theme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      _formatMatchTime(league.matchDateTime!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
              
              const Spacer(),
              
              // Bottom row - members and projected points
              Row(
                children: [
                  Icon(Icons.group, size: 14, color: bgTextColor),
                  const SizedBox(width: 4),
                  Text(
                    '${league.memberCount}/${league.maxMembers}',
                    style: TextStyle(
                      fontSize: 12,
                      color: bgTextColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'View League →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryColor,
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

  String _formatMatchTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.isNegative) {
      return 'Started';
    } else if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m';
      }
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}

