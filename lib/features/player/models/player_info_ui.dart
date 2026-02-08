import 'dart:ui';
import 'package:flutter/material.dart';
import 'player_info.dart';

/// Flutter UI extensions for PositionInfo
/// Import this file in Flutter widgets that need to display colors/icons
extension PositionInfoUIExtension on PositionInfo {
  /// Get color for position as a Flutter Color object
  Color get color => Color(colorValue);
  
  /// Get icon for position as IconData
  IconData get icon {
    switch (iconName) {
      case 'sports_handball':
        return Icons.sports_handball;
      case 'shield':
        return Icons.shield;
      case 'swap_horiz':
        return Icons.swap_horiz;
      case 'sports_soccer':
        return Icons.sports_soccer;
      default:
        return Icons.person;
    }
  }
}

/// Helper to convert PositionColors constants to Flutter Color
class PositionColorsUI {
  static Color get goalkeeper => Color(PositionColors.goalkeeper);
  static Color get defender => Color(PositionColors.defender);
  static Color get midfielder => Color(PositionColors.midfielder);
  static Color get attacker => Color(PositionColors.attacker);
  static Color get unknown => Color(PositionColors.unknown);
  
  /// Convert any int color value to a Flutter Color
  static Color fromValue(int value) => Color(value);
}

