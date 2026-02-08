import 'dart:ui';
import 'package:flutter/material.dart';
import 'league_models.dart';

/// Flutter UI extensions for PlayerPosition
extension PlayerPositionUIExtension on PlayerPosition {
  /// Get color as a Flutter Color object
  Color get color => Color(colorValue);
  
  /// Get icon as IconData
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

/// Flutter UI extensions for LeagueType
extension LeagueTypeUIExtension on LeagueType {
  /// Get icon as IconData
  IconData get icon {
    switch (iconName) {
      case 'public':
        return Icons.public;
      case 'lock':
        return Icons.lock;
      default:
        return Icons.help;
    }
  }
}

/// Flutter UI extensions for LeagueStatus
extension LeagueStatusUIExtension on LeagueStatus {
  /// Get color as a Flutter Color object
  Color get color => Color(colorValue);
}

/// Helper to convert LeagueColors constants to Flutter Color
class LeagueColorsUI {
  static Color get orange => Color(LeagueColors.orange);
  static Color get green => Color(LeagueColors.green);
  static Color get blue => Color(LeagueColors.blue);
  static Color get red => Color(LeagueColors.red);
  
  /// Convert any int color value to a Flutter Color
  static Color fromValue(int value) => Color(value);
}

