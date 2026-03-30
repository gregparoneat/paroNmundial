import 'package:flutter/material.dart';

const _primaryGreen = Color(0xFF25CB3C);
const _appBackground = Color(0xFF0F141A);
const _appSurface = Color(0xFF182029);
const _appSurfaceAlt = Color(0xFF24303C);
const _appMuted = Color(0xFFB7C3CF);
const _appHint = Color(0xFF8A98A8);

final ThemeData appTheme = ThemeData(
  fontFamily: 'Poppins',
  brightness: Brightness.dark,
  scaffoldBackgroundColor: _appBackground,
  primaryColor: _primaryGreen,
  hintColor: _appHint,
  unselectedWidgetColor: _appHint,
  dividerColor: Colors.white12,
  disabledColor: Colors.white38,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      fontFamily: 'Poppins',
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    unselectedItemColor: Colors.white.withValues(alpha: 0.5),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  cardColor: _appSurface,
  canvasColor: _appSurface,
  dialogTheme: const DialogThemeData(
    backgroundColor: _appSurface,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      fontFamily: 'Poppins',
    ),
    contentTextStyle: TextStyle(
      color: _appMuted,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      fontFamily: 'Poppins',
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: _appSurfaceAlt,
    contentTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      fontFamily: 'Poppins',
    ),
    actionTextColor: _primaryGreen,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  popupMenuTheme: PopupMenuThemeData(
    color: _appSurface,
    textStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontFamily: 'Poppins',
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: _appSurface,
    hintStyle: const TextStyle(color: _appHint),
    labelStyle: const TextStyle(color: _appMuted),
    prefixIconColor: _appMuted,
    suffixIconColor: _appMuted,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primaryGreen, width: 1.4),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
    ),
  ),
  dropdownMenuTheme: const DropdownMenuThemeData(
    textStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w500,
      fontFamily: 'Poppins',
    ),
    menuStyle: MenuStyle(
      backgroundColor: WidgetStatePropertyAll(_appSurface),
      surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
    ),
  ),
  textTheme: const TextTheme(
    labelLarge: TextStyle(
      color: Colors.white,
      fontSize: 18,
      letterSpacing: 2,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    displayMedium: TextStyle(),
    displaySmall: TextStyle(),
    bodySmall: TextStyle(color: _appMuted),
    displayLarge: TextStyle(),
    titleMedium: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white, fontSize: 16),
    bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(color: Colors.white),
    headlineSmall: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
  ),
  colorScheme: const ColorScheme.dark(
    primary: _primaryGreen,
    secondary: _primaryGreen,
    surface: _appSurface,
    error: Colors.redAccent,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.white,
    onError: Colors.white,
  ).copyWith(surfaceContainerHighest: _appSurfaceAlt),
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
