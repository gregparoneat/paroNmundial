import 'package:fantacy11/app_config/colors.dart';
import 'package:flutter/material.dart';

import 'colored_tabbar.dart';

class CustomScaffold extends StatelessWidget {
  final String pageTitle;
  final List<Widget> actions;
  final List<Widget> tabBarItems;
  final Widget? tabBarChild;
  final double? tabBarHeight;
  final List<Widget> tabBarViewItems;
  final Color? tabBarColor;
  final bool centerTitle;
  final bool isRoot;
  final Widget? secondPage;

  const CustomScaffold({
    super.key,
    required this.pageTitle,
    this.actions = const [],
    required this.tabBarItems,
    required this.tabBarChild,
    this.tabBarHeight,
    required this.tabBarViewItems,
    this.tabBarColor,
    this.centerTitle = true,
    this.isRoot = false,
    this.secondPage,
  });

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return DefaultTabController(
      length: tabBarItems.length,
      child: Stack(
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
              title: Text(
                pageTitle,
                style: theme.textTheme.bodyLarge!.copyWith(
                  fontSize: 16,
                ),
              ),
              centerTitle: centerTitle,
              actions: actions,
              bottom: ColoredTabBar(
                color: tabBarColor ?? Theme.of(context).colorScheme.surface,
                tabBar: TabBar(
                  indicatorColor: Colors.transparent,
                  unselectedLabelColor: Colors.white,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  indicator: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(30)),
                  labelStyle: theme.textTheme.bodySmall!.copyWith(
                    color: Colors.black,
                    fontSize: 10,
                  ),
                  tabs: tabBarItems,
                ),
                height:
                    tabBarHeight ?? MediaQuery.of(context).size.height * 0.21,
                child: tabBarChild,
              ),
            ),
            body: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: tabBarViewItems,
                    ),
                  ),
                  if (secondPage != null) Expanded(child: secondPage!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
