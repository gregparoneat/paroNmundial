import 'dart:convert';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fantacy11/features/match/models/match_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'match_card.dart';

class MatchList extends StatelessWidget {
  final Axis axis;
  final int? itemCount;
  final String matchTime;
  final String rightText;
  final VoidCallback? onTap;

  const MatchList(
    this.axis,
    this.matchTime,
    this.rightText,
    this.onTap, {
    super.key,
    this.itemCount,
  });

  factory MatchList.horizontal(
    String matchTime,
    String rightText,
    VoidCallback? onTap, {
    int? itemCount,
  }) =>
      MatchList(Axis.horizontal, matchTime, rightText, onTap,
          itemCount: itemCount);

  factory MatchList.vertical(
    String matchTime,
    String rightText,
    VoidCallback? onTap, {
    int? itemCount,
  }) =>
      MatchList(Axis.vertical, matchTime, rightText, onTap,
          itemCount: itemCount);

  @override
  Widget build(BuildContext context) {
    // Use FutureBuilder to handle the asynchronous data loading
    return FutureBuilder<List<MatchInfo>>( // Specify the type of data the Future returns
      future: loadMatchesFromAsset(), // Your Future function
      builder: (context, snapshot) {
        // Check the state of the Future
        if (snapshot.connectionState != ConnectionState.done) {
          // While data is loading, show a CircularProgressIndicator
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // If an error occurred, display it
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          // If data is successfully loaded, use it
          final List<MatchInfo> matches = snapshot.data!; // The actual list of MatchInfo objects

          if (axis == Axis.horizontal) {
            // Pass the loaded 'matches' list to the horizontal widget
            return HorizontalMatchListWithData(
              matches: matches, // Named parameter to avoid confusion
              matchTime: matchTime,
              rightText: rightText,
              onTap: onTap,
              itemCount: itemCount,
            );
          } else {
            // Use the loaded 'matches' list for ListView.builder
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: itemCount ?? matches.length, // Use matches.length
              shrinkWrap: true,
              scrollDirection: axis,
              itemBuilder: (context, index) {
                var matchInfo = matches[index]; // Now 'matches' is a List<MatchInfo>
                return MatchCard(matchInfo, matchTime, rightText, onTap);
              },
            );
          }
        } else {
          // No data, no error, not done (shouldn't happen with .hasData check)
          return const Center(child: Text('No data available.'));
        }
      },
    );
  }
}

Future<List<MatchInfo>> loadMatchesFromAsset() async {
  debugPrint('before getting json file');
  final s = await rootBundle.loadString('assets/MockResponses/dayFixtures.json');
  debugPrint(s);
  final jsonData = json.decode(s);
  final list = jsonData is Map && jsonData['data'] != null
      ? jsonData['data'] as List
      : jsonData as List;
  return MatchInfo.fromJsonList(list);
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
  final VoidCallback? onTap;

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
                matchInfo, widget.matchTime, widget.rightText, widget.onTap);
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