/// SportMonks API Layer
/// 
/// This module provides access to SportMonks Football API v3.
/// 
/// ## Setup
/// 
/// 1. Get your API key from https://www.sportmonks.com/
/// 2. Update the `apiToken` in `sportmonks_config.dart`
/// 
/// ## Usage
/// 
/// ```dart
/// import 'package:fantacy11/api/api.dart';
/// 
/// // Use repositories for data access
/// final fixturesRepo = FixturesRepository();
/// final todayMatches = await fixturesRepo.getTodayFixtures();
/// 
/// final playersRepo = PlayersRepository();
/// final players = await playersRepo.searchPlayers('Messi');
/// ```
/// 
/// ## Fallback Behavior
/// 
/// If the API token is not configured (`YOUR_API_TOKEN_HERE`), 
/// the repositories will automatically fall back to mock data
/// from the assets folder for development/demo purposes.

export 'sportmonks_config.dart';
export 'sportmonks_client.dart';
export 'repositories/fixtures_repository.dart';
export 'repositories/players_repository.dart';

