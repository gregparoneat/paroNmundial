import 'dart:developer';
import 'dart:io';

import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/fixtures/ui/upcoming_fixtures_page.dart';
import 'package:fantacy11/features/home/widgets/my_leagues_carousel.dart';
import 'package:fantacy11/features/responsive_widget.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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
                'assets/paroNmundialTransparent.png',
                height: 172,
                width: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: const SizedBox.shrink(),
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
                      locale.myLeagues,
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const MyLeaguesCarousel(),
                  if (_anchoredBanner != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      width: _anchoredBanner!.size.width.toDouble(),
                      height: _anchoredBanner!.size.height.toDouble(),
                      child: AdWidget(ad: _anchoredBanner!),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      locale.upcomingMatches,
                      style: theme.textTheme.headlineSmall!.copyWith(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Use the same UpcomingFixturesPage widget from fixtures tab
                  // shrinkWrap mode allows it to be embedded in a scrollable parent
                  const UpcomingFixturesPage(
                    embedded: true,
                    shrinkWrap: true,
                    maxMatches: 10, // Show up to 10 matches on home page
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
