import 'package:flutter/material.dart';

class ResponsiveWidget extends StatelessWidget {
  final Widget child;
  final Widget? mediumScreen;
  final Widget? smallScreen;
  final bool isRoot;

  const ResponsiveWidget({
    super.key,
    required this.child,
    this.mediumScreen,
    this.smallScreen,
    this.isRoot = false,
  });

  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 1200;
  }

  static bool isMediumScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 800 &&
        MediaQuery.of(context).size.width <= 1200;
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          return largeScreen(size);
        } else if (constraints.maxWidth <= 1200 &&
            constraints.maxWidth >= 800) {
          return mediumScreen ?? largeScreen(size);
        } else {
          return smallScreen ?? child;
        }
      },
    );
  }

  Widget largeScreen(Size size) {
    if (isRoot) {
      return child;
    } else {
      return Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            "assets/back.png",
            fit: BoxFit.fill,
            width: size.width,
            height: size.height,
          ),
          Positioned(
            top: 20,
            bottom: 20,
            width: size.width * 0.6,
            child: child,
          ),
        ],
      );
    }
  }
}
