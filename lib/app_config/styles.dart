import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  fontFamily: 'Poppins',
  scaffoldBackgroundColor: Colors.black,
  primaryColor: const Color(0xff25CB3C),
  hintColor: const Color(0xff4C5862),
  unselectedWidgetColor: const Color(0xff4C5862),
  appBarTheme: const AppBarTheme(
    color: Colors.transparent,
    elevation: 0,
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    unselectedItemColor: Colors.white.withValues(alpha: 0.5),
  ),
  iconTheme: const IconThemeData(
    color: Colors.white,
  ),
  textTheme: const TextTheme(
      labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 18,
          letterSpacing: 2,
          fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      displayMedium: TextStyle(),
      displaySmall: TextStyle(),
      bodySmall: TextStyle(
        color: Colors.white,
      ),
      displayLarge: TextStyle(),
      titleMedium: TextStyle(
        color: Colors.white,
      ),
      titleLarge: TextStyle(color: Color(0xff4C5862), fontSize: 16),
      bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      titleSmall: TextStyle(
        color: Colors.white,
      ),
      headlineSmall: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      )),
  colorScheme: ColorScheme.fromSwatch(
    backgroundColor: const Color(0xff191F26),
    cardColor: const Color(0xff191F26),
  ),
);

/// NAME         SIZE  WEIGHT  SPACING
/// headline1    96.0  light   -1.5
/// headline2    60.0  light   -0.5
/// headline3    48.0  regular  0.0
/// headline4    34.0  regular  0.25
/// headline5    24.0  regular  0.0
/// headline6    20.0  medium   0.15
/// subtitle1    16.0  regular  0.15
/// subtitle2    14.0  medium   0.1
/// body1        16.0  regular  0.5   (bodyText1)
/// body2        14.0  regular  0.25  (bodyText2)
/// button       14.0  medium   1.25
/// caption      12.0  regular  0.4
/// overline     10.0  regular  1.5
