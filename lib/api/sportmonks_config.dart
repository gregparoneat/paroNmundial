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

  /// App competition configuration
  static const String competitionName = 'World Cup';
  static const int competitionLeagueId = 732;
  static const int internationalFriendliesLeagueId = 1082;
  static const int fallbackSeasonId = 26618;
  static const List<int> preferredInternationalLeagueIds = [
    competitionLeagueId,
    internationalFriendliesLeagueId,
  ];
  static const List<int> preferredInternationalSeasonIds = [
    26618, // World Cup 2026
    22005, // CAF World Cup Qualifiers 2026
    22294, // WC Qualification Asia 2026
    21888, // WC Qualification Concacaf 2026
    21887, // WC Qualification Europe 2026
    23962, // WC Qualification Oceania 2026
    22305, // WC Qualification South America 2026
    26682, // WC Qualification Intercontinental Playoffs 2026
  ];
  static const List<int> preferredClubLeagueIds = [
    743, // Liga MX
    636, // Liga Profesional de Futbol (Argentina)
    648, // Serie A (Brazil)
    564, // La Liga
    8, // Premier League
  ];

  /// Default timezone for API responses
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
