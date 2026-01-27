import 'package:carousel_slider/carousel_slider.dart';
import 'package:fantacy11/api/repositories/fixtures_repository.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:flutter/material.dart';

import 'match_card.dart';

class MatchList extends StatefulWidget {
  final Axis axis;
  final int? itemCount;
  final String matchTime;
  final String rightText;
  final void Function(MatchInfo matchInfo)? onTap;
  final DateTime? selectedDate;

  const MatchList(
    this.axis,
    this.matchTime,
    this.rightText,
    this.onTap, {
    super.key,
    this.itemCount,
    this.selectedDate,
  });

  factory MatchList.horizontal(
    String matchTime,
    String rightText,
    void Function(MatchInfo matchInfo)? onTap, {
    Key? key,
    int? itemCount,
    DateTime? selectedDate,
  }) =>
      MatchList(Axis.horizontal, matchTime, rightText, onTap,
          key: key, itemCount: itemCount, selectedDate: selectedDate);

  factory MatchList.vertical(
    String matchTime,
    String rightText,
    void Function(MatchInfo matchInfo)? onTap, {
    Key? key,
    int? itemCount,
    DateTime? selectedDate,
  }) =>
      MatchList(Axis.vertical, matchTime, rightText, onTap,
          key: key, itemCount: itemCount, selectedDate: selectedDate);

  @override
  State<MatchList> createState() => _MatchListState();
}

class _MatchListState extends State<MatchList> {
  late Future<List<MatchInfo>> _matchesFuture;
  DateTime? _lastSelectedDate;

  @override
  void initState() {
    super.initState();
    _lastSelectedDate = widget.selectedDate;
    _loadMatches();
  }

  @override
  void didUpdateWidget(MatchList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if the selectedDate actually changed
    if (_dateChanged(oldWidget.selectedDate, widget.selectedDate)) {
      debugPrint('MatchList: Date changed from ${oldWidget.selectedDate} to ${widget.selectedDate}, reloading...');
      _lastSelectedDate = widget.selectedDate;
      _loadMatches();
    }
  }

  bool _dateChanged(DateTime? oldDate, DateTime? newDate) {
    if (oldDate == null && newDate == null) return false;
    if (oldDate == null || newDate == null) return true;
    return oldDate.year != newDate.year ||
           oldDate.month != newDate.month ||
           oldDate.day != newDate.day;
  }

  void _loadMatches() {
    debugPrint('MatchList: Loading matches for date: ${widget.selectedDate}');
    _matchesFuture = loadMatchesForDate(widget.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MatchInfo>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final List<MatchInfo> matches = snapshot.data!;

          if (matches.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_soccer, size: 48, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'No fixtures available',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[500],
                      ),
                    ),
                    if (widget.selectedDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Try selecting a different date',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }

          if (widget.axis == Axis.horizontal) {
            return HorizontalMatchListWithData(
              matches: matches,
              matchTime: widget.matchTime,
              rightText: widget.rightText,
              onTap: widget.onTap,
              itemCount: widget.itemCount,
            );
          } else {
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: widget.itemCount ?? matches.length,
              shrinkWrap: true,
              scrollDirection: widget.axis,
              itemBuilder: (context, index) {
                var matchInfo = matches[index];
                return MatchCard(
                  matchInfo,
                  widget.matchTime,
                  widget.rightText,
                  widget.onTap != null ? () => widget.onTap!(matchInfo) : null,
                );
              },
            );
          }
        } else {
          return const Center(child: Text('No data available.'));
        }
      },
    );
  }
}

/// Singleton repository for fixtures
final _fixturesRepository = FixturesRepository();

/// Load matches using the FixturesRepository
/// If date is provided, loads fixtures for that specific date
/// Otherwise, loads today's fixtures (with fallback to upcoming)
Future<List<MatchInfo>> loadMatchesForDate(DateTime? date) async {
  if (date != null) {
    debugPrint('Loading fixtures for date: $date');
    return _fixturesRepository.getFixturesByDate(date);
  }
  debugPrint('Loading fixtures from repository...');
  return _fixturesRepository.getTodayFixtures();
}

/// Legacy function for backward compatibility
Future<List<MatchInfo>> loadMatchesFromAsset() async {
  return loadMatchesForDate(null);
}

class HorizontalMatchList extends StatefulWidget {
  final int? itemCount;
  final String matchTime;
  final String rightText;
  final VoidCallback? onTap;

  const HorizontalMatchList(
    this.matchTime,
    this.rightText,
    this.onTap, {
    super.key,
    this.itemCount,
  });

  @override
  HorizontalMatchListState createState() => HorizontalMatchListState();
}

class HorizontalMatchListState extends State<HorizontalMatchList> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.itemCount ?? MatchInfo.matches.length,
          itemBuilder: (context, index, pageIndex) {
            var matchInfo = MatchInfo.matches[index];
            return MatchCard(
                matchInfo, widget.matchTime, widget.rightText, widget.onTap);
          },
          options: CarouselOptions(
              height: 162,
              enableInfiniteScroll: false,
              viewportFraction: 1,
              autoPlay: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _current = index;
                });
              }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: MatchInfo.matches.asMap().entries.map((entry) {
            return Container(
              width: 4.0,
              height: 4.0,
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white
                      .withValues(alpha: _current == entry.key ? 0.9 : 0.4)),
            );
          }).toList(),
        ),
      ],
    );
  }
}
// Helper widget for horizontal display, now correctly typed and receives the list
class HorizontalMatchListWithData extends StatefulWidget {
  final List<MatchInfo> matches; // Explicitly List<MatchInfo>
  final int? itemCount;
  final String matchTime;
  final String rightText;
  final void Function(MatchInfo matchInfo)? onTap;

  const HorizontalMatchListWithData({ // Use named parameters for clarity
    super.key,
    required this.matches, // Mark as required
    required this.matchTime,
    required this.rightText,
    this.onTap,
    this.itemCount,
  });

  @override
  HorizontalMatchListWithDataState createState() =>
      HorizontalMatchListWithDataState();
}

// Correctly type the State class
class HorizontalMatchListWithDataState extends State<HorizontalMatchListWithData> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    // widget.matches is now correctly accessed and typed as List<MatchInfo>
    final matches = widget.matches;
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: widget.itemCount ?? matches.length,
          itemBuilder: (context, index, pageIndex) {
            final matchInfo = matches[index];
            return MatchCard(
              matchInfo,
              widget.matchTime,
              widget.rightText,
              widget.onTap != null ? () => widget.onTap!(matchInfo) : null,
            );
          },
          options: CarouselOptions(
            height: 162,
            enableInfiniteScroll: false,
            viewportFraction: 1,
            autoPlay: true,
            onPageChanged: (index, reason) => setState(() => _current = index),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(matches.length, (i) {
            return Container(
              width: 4.0,
              height: 4.0,
              margin:
              const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(_current == i ? 0.9 : 0.4),
              ),
            );
          }),
        ),
      ],
    );
  }
}