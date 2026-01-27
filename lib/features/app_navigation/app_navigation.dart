import 'package:fantacy11/app_config/colors.dart';
import 'package:fantacy11/features/account/ui/account.dart';
import 'package:fantacy11/features/home/home.dart';
import 'package:fantacy11/features/my_matches/my_matches.dart';
import 'package:fantacy11/features/players/players_search.dart';
import 'package:fantacy11/generated/l10n.dart';
import 'package:flutter/material.dart';


class AppNavigation extends StatefulWidget {
  const AppNavigation({super.key});

  @override
  AppNavigationState createState() => AppNavigationState();
}

class AppNavigationState extends State<AppNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _children = [
    const Home(),
    const PlayersSearch(),
    const MyMatches(),
    const Account(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);
    return Scaffold(
      body: _children[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.sports_soccer),
            label: s.home,
            backgroundColor: const Color(0xff191F26),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            label: 'Players',
            backgroundColor: const Color(0xff1C1C35),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.emoji_events_outlined),
            label: s.myMatches,
            backgroundColor: const Color(0xff1C1C35),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: s.account,
            backgroundColor: Colors.green,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: iconColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
