import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/components/signle_team_container.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';

class Contests extends StatelessWidget {
  final MatchInfo? matchInfo;

  const Contests({super.key, this.matchInfo});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    // Use calculated time remaining from matchInfo or fallback to default
    final pageTitle = matchInfo != null
        ? '${matchInfo!.getTimeRemaining()} left'
        : 'Match Details';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Header background
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            child: Image.asset(
              'assets/img_header.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.fill,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: iconColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          pageTitle,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_outlined, color: iconColor),
          onPressed: () {
                          _showReminderSheet(context);
                        },
                      ),
                    ],
                  ),
                ),
                // Team Header
                SingleTeamContainer(matchInfo: matchInfo),
                // Content
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: FadedSlideAnimation(
                      beginOffset: const Offset(0, 0.2),
                      endOffset: Offset.zero,
                      slideCurve: Curves.easeOut,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          // Match Date & Time
                          _buildSectionCard(
                            context,
                            icon: Icons.calendar_today,
                            title: 'Match Schedule',
                            child: Text(
                              matchInfo?.formattedDateTime ?? 'TBD',
                              style: theme.textTheme.headlineSmall!.copyWith(
                                fontSize: 18,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Venue Section
                          if (matchInfo?.venue != null)
                            _buildVenueCard(context, matchInfo!.venue!),
                          if (matchInfo?.venue != null)
                            const SizedBox(height: 16),

                          // Coaches Section
                          if (matchInfo != null &&
                              (matchInfo!.homeCoach != null ||
                                  matchInfo!.awayCoach != null))
                            _buildCoachesSection(context),
                          if (matchInfo != null &&
                              (matchInfo!.homeCoach != null ||
                                  matchInfo!.awayCoach != null))
                            const SizedBox(height: 16),

                          // Team Stats
                          if (matchInfo?.homeTeam != null &&
                              matchInfo?.awayTeam != null)
                            _buildTeamStatsCard(context),
                          if (matchInfo?.homeTeam != null &&
                              matchInfo?.awayTeam != null)
                            const SizedBox(height: 16),

                          // Players Section
                          _buildPlayersSection(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
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
              Icon(icon, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
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

  Widget _buildVenueCard(BuildContext context, VenueInfo venue) {
    var theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Venue Image
          if (venue.imagePath != null && venue.imagePath!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: venue.imagePath!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 150,
                  color: bgColor,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: theme.primaryColor,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  color: bgColor,
                  child: Icon(Icons.stadium, color: bgTextColor, size: 48),
                ),
              ),
            ),
              Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stadium, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Venue',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: bgTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  venue.name,
                  style: theme.textTheme.headlineSmall!.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (venue.cityName != null)
                  _buildVenueDetail(
                    context,
                    Icons.location_on_outlined,
                    venue.cityName!,
                  ),
                if (venue.capacity != null)
                  _buildVenueDetail(
                    context,
                    Icons.people_outline,
                    'Capacity: ${_formatNumber(venue.capacity!)}',
                  ),
                if (venue.surface != null)
                  _buildVenueDetail(
                    context,
                    Icons.grass,
                    'Surface: ${venue.surface!.toUpperCase()}',
                  ),
                if (venue.address != null)
                  _buildVenueDetail(
                    context,
                    Icons.map_outlined,
                    venue.address!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueDetail(BuildContext context, IconData icon, String text) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, color: bgTextColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachesSection(BuildContext context) {
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
              Icon(Icons.person, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Head Coaches',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Home Team Coach
              Expanded(
                child: _buildCoachCard(
                  context,
                  matchInfo!.homeCoach,
                  matchInfo!.homeTeam?.name ?? matchInfo!.team1Name,
                  true,
                ),
              ),
              const SizedBox(width: 12),
              // Away Team Coach
              Expanded(
                child: _buildCoachCard(
                  context,
                  matchInfo!.awayCoach,
                  matchInfo!.awayTeam?.name ?? matchInfo!.team2Name,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoachCard(
    BuildContext context,
    CoachInfo? coach,
    String teamName,
    bool isHome,
  ) {
    var theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHome
              ? (matchInfo?.team1Color ?? Colors.blue).withValues(alpha: 0.5)
              : (matchInfo?.team2Color ?? Colors.red).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
            children: [
          // Coach Image
          CircleAvatar(
            radius: 30,
            backgroundColor: bgTextColor.withValues(alpha: 0.3),
            child: coach?.imagePath != null &&
                    coach!.imagePath!.isNotEmpty &&
                    !coach.imagePath!.contains('placeholder')
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: coach.imagePath!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          Icon(Icons.person, color: iconColor, size: 32),
                    ),
                  )
                : Icon(Icons.person, color: iconColor, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            coach?.displayName ?? 'Unknown',
            style: theme.textTheme.bodyMedium!.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            teamName,
            style: theme.textTheme.bodySmall!.copyWith(
              color: bgTextColor,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (coach?.age != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Age: ${coach!.age}',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: bgTextColor,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeamStatsCard(BuildContext context) {
    var theme = Theme.of(context);
    final home = matchInfo!.homeTeam!;
    final away = matchInfo!.awayTeam!;

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
              Icon(Icons.analytics_outlined,
                  color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Team Info',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats rows
          if (home.leaguePosition != null || away.leaguePosition != null)
            _buildStatRow(
              context,
              'League Position',
              home.leaguePosition != null ? '#${home.leaguePosition}' : '-',
              away.leaguePosition != null ? '#${away.leaguePosition}' : '-',
            ),
          if (home.founded != null || away.founded != null)
            _buildStatRow(
              context,
              'Founded',
              home.founded?.toString() ?? '-',
              away.founded?.toString() ?? '-',
            ),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String homeValue,
    String awayValue,
  ) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              homeValue,
              style: theme.textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall!.copyWith(
                color: bgTextColor,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              awayValue,
              style: theme.textTheme.bodyLarge!.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildPlayersSection(BuildContext context) {
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
              Icon(Icons.groups, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Players',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: bgTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'View detailed player profiles and statistics',
            style: theme.textTheme.bodyMedium!.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, PageRoutes.playerDetails);
              },
              icon: const Icon(Icons.person_search, size: 20),
              label: const Text('View Demo Player'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _SetReminderSheet(matchInfo: matchInfo),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}k';
    }
    return number.toString();
  }
}

class _SetReminderSheet extends StatefulWidget {
  final MatchInfo? matchInfo;

  const _SetReminderSheet({this.matchInfo});

  @override
  _SetReminderSheetState createState() => _SetReminderSheetState();
}

class _SetReminderSheetState extends State<_SetReminderSheet> {
  bool matchReminder = false;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
          children: [
              Icon(Icons.notifications, color: theme.primaryColor),
              const SizedBox(width: 12),
              Text(
                'Set Match Reminder',
                style: theme.textTheme.headlineSmall!.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.matchInfo != null
                            ? '${widget.matchInfo!.team1Name} vs ${widget.matchInfo!.team2Name}'
                            : 'Match Reminder',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get notified when lineup is announced',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: bgTextColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: matchReminder,
                activeColor: theme.primaryColor,
                onChanged: (value) {
                    setState(() => matchReminder = value);
                },
              ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ],
      ),
    );
  }
}
