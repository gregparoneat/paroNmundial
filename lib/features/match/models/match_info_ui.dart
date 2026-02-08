import 'dart:ui';
import 'match_info.dart';

/// Flutter UI extensions for MatchInfo
/// Import this file in Flutter widgets that need to display colors
extension MatchInfoColorExtension on MatchInfo {
  /// Get team1Color as a Flutter Color object
  Color get team1Color => Color(team1ColorValue);
  
  /// Get team2Color as a Flutter Color object
  Color get team2Color => Color(team2ColorValue);
}

/// Helper to convert MatchColors constants to Flutter Color
class MatchColorsUI {
  static Color get red => Color(MatchColors.red);
  static Color get green => Color(MatchColors.green);
  static Color get blue => Color(MatchColors.blue);
  static Color get deepPurple => Color(MatchColors.deepPurple);
  static Color get purpleAccent => Color(MatchColors.purpleAccent);
  static Color get grey => Color(MatchColors.grey);
  static Color get gold => Color(MatchColors.gold);
  static Color get crimson => Color(MatchColors.crimson);
  static Color get brown => Color(MatchColors.brown);
  static Color get olive => Color(MatchColors.olive);
  
  /// Convert any int color value to a Flutter Color
  static Color fromValue(int value) => Color(value);
}

