import 'dart:developer';
import 'dart:io';

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/match/ui/match_list.dart';
import 'package:fantacy11/features/responsive_widget.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:fantacy11/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  static const AdRequest request = AdRequest(
    keywords: <String>['foo', 'bar'],
    contentUrl: 'http://foo.com/bar.html',
    nonPersonalizedAds: true,
  );

  BannerAd? _anchoredBanner;
  bool _loadingAnchoredBanner = false;
  
  // Date filter state
  DateTime? _selectedDate;
  final List<DateTime> _quickDates = [];

  @override
  void initState() {
    super.initState();
    _initQuickDates();
  }

  void _initQuickDates() {
    final now = DateTime.now();
    // Generate next 7 days for quick selection
    for (int i = 0; i < 7; i++) {
      _quickDates.add(DateTime(now.year, now.month, now.day + i));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.primaryColor,
              onPrimary: Colors.white,
              surface: theme.colorScheme.surface,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: theme.scaffoldBackgroundColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDateChip(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    if (date.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow';
    } else {
      return DateFormat('EEE, MMM d').format(date);
    }
  }

  bool _isDateSelected(DateTime date) {
    if (_selectedDate == null) {
      // If no date selected, "Today" is the default
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return date.isAtSameMomentAs(today);
    }
    return _selectedDate!.year == date.year &&
           _selectedDate!.month == date.month &&
           _selectedDate!.day == date.day;
  }

  Future<void> _createAnchoredBanner(BuildContext context) async {
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      MediaQuery.of(context).size.width.truncate(),
    );

    if (size == null) {
      return;
    }

    final BannerAd banner = BannerAd(
      size: size,
      request: request,
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _anchoredBanner = ad as BannerAd?;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
        onAdOpened: (Ad ad) => log('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => log('$BannerAd onAdClosed.'),
      ),
    );
    return banner.load();
  }

  @override
  void dispose() {
    super.dispose();
    _anchoredBanner?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var locale = S.of(context);
    return Builder(
      builder: (BuildContext context) {
        if (!_loadingAnchoredBanner) {
          _loadingAnchoredBanner = true;
          if (ResponsiveWidget.isSmallScreen(context)) {
            _createAnchoredBanner(context);
          }
        }
        return Stack(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
              child: Image.asset(
                'assets/img_header.png',
                height: 172,
                width: double.infinity,
                fit: BoxFit.fill,
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Image.asset('assets/logo_home.png', scale: 3),
                actions: [
                  Icon(Icons.sports_soccer, color: iconColor),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: theme.scaffoldBackgroundColor,
                          content: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(locale.noOtherSportsAvailableContactAdmin),
                            ],
                          ),
                        ),
                      );
                    },
                    child: DropdownButton<String>(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      iconSize: 20,
                      iconEnabledColor: iconColor,
                      iconDisabledColor: iconColor,
                      hint: Padding(
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(8, 8, 8, 0),
                        child: Text(
                          locale.football,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      items: const [],
                      underline: const SizedBox.shrink(),
                      onChanged: (value) {},
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              body: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      locale.myMatches,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  MatchList.horizontal(
                    locale.live,
                    '',
                    (matchInfo) => Navigator.pushNamed(
                      context,
                      PageRoutes.matchLive,
                      arguments: matchInfo,
                    ),
                    key: const ValueKey('my_matches_horizontal'),
                  ),
                  if (_anchoredBanner != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      width: _anchoredBanner!.size.width.toDouble(),
                      height: _anchoredBanner!.size.height.toDouble(),
                      child: AdWidget(ad: _anchoredBanner!),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          locale.upcomingMatches,
                          style: theme.textTheme.headlineSmall!.copyWith(
                            fontSize: 16,
                          ),
                        ),
                        // Calendar button
                        IconButton(
                          icon: Icon(Icons.calendar_month, color: theme.primaryColor),
                          onPressed: () => _selectDate(context),
                          tooltip: 'Select date',
                        ),
                      ],
                    ),
                  ),
                  // Date filter chips
                  Container(
                    height: 44,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _quickDates.length,
                      itemBuilder: (context, index) {
                        final date = _quickDates[index];
                        final isSelected = _isDateSelected(date);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(_formatDateChip(date)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedDate = selected ? date : null;
                              });
                            },
                            backgroundColor: theme.colorScheme.surface,
                            selectedColor: theme.primaryColor.withValues(alpha: 0.3),
                            checkmarkColor: theme.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? theme.primaryColor : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? theme.primaryColor : Colors.transparent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  FadedSlideAnimation(
                    beginOffset: const Offset(0, 2),
                    endOffset: const Offset(0, 0),
                    slideCurve: Curves.linearToEaseOut,
                    child: MatchList.vertical(
                      '0h 9m',
                      'Lineup Announced',
                      (matchInfo) => Navigator.pushNamed(
                        context,
                        PageRoutes.contests,
                        arguments: matchInfo,
                      ),
                      key: ValueKey('matches_${_selectedDate?.toIso8601String() ?? 'default'}'),
                      selectedDate: _selectedDate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
