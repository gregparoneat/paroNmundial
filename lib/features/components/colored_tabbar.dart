import 'package:flutter/material.dart';

class ColoredTabBar extends StatelessWidget implements PreferredSizeWidget {
  final Color color;
  final TabBar tabBar;
  final Widget? child;
  final double height;

  const ColoredTabBar({
    super.key,
    this.child,
    required this.color,
    required this.tabBar,
    required this.height,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (child != null) child!,
          Container(
            color: color,
            child: tabBar,
          ),
        ],
      );
}
