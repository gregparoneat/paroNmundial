/// SportMonks API Configuration
/// 
/// Get your API key from: https://www.sportmonks.com/
/// Documentation: https://docs.sportmonks.com/football
class SportMonksConfig {
  /// Base URL for SportMonks Football API v3
  static const String baseUrl = 'https://api.sportmonks.com/v3/football';

  /// Your SportMonks API token
  /// TODO: Replace with your actual API key or load from environment
  static const String apiToken = 'gsZEnYqYpLsfVPRhca4EJSSxVnfwJjTxBvX7ZwSx1cv90QHGcA6YnJzaZqf9';

  /// Default timezone for API responses (Mexico City for Liga MX)
  static const String timezone = 'America/Mexico_City';

  /// Common includes for fixture requests
  static const List<String> fixtureIncludes = [
    'participants',
    'venue',
    'state',
    'league',
    'scores',
    'events',
    'lineups',
    'coaches',
  ];

  /// Common includes for player requests
  static const List<String> playerIncludes = [
    'nationality',
    'position',
    'detailedposition',
    'teams.team',          // Include team details (name, logo, etc.)
    'statistics.details',  // Include details for goals, assists, appearances, etc.
    'statistics.season',   // Include season info for naming
    'trophies',
    'transfers',
  ];

  /// Common includes for team requests
  static const List<String> teamIncludes = [
    'players',
    'coaches',
    'venue',
    'league',
  ];

  /// Build includes query parameter
  static String buildIncludes(List<String> includes) {
    return includes.join(';');
  }

  /// Check if API is configured
  static bool get isConfigured => apiToken != 'YOUR_API_TOKEN_HERE' && apiToken.isNotEmpty;
}

