# Contributing to Fantasy 11

Thank you for your interest in contributing to Fantasy 11! This guide will help you get started.

## Table of Contents

1. [Development Setup](#development-setup)
2. [Code Style Guide](#code-style-guide)
3. [Architecture Guidelines](#architecture-guidelines)
4. [Testing Requirements](#testing-requirements)
5. [Pull Request Process](#pull-request-process)

---

## Development Setup

### Prerequisites

```bash
# Required versions
Flutter: 3.32.5+
Dart: 3.8.1+
```

### Initial Setup

```bash
# 1. Clone the repository
git clone <repository-url>
cd fantasy-11

# 2. Install dependencies
flutter pub get

# 3. Generate localization files
flutter pub run intl_utils:generate

# 4. Run the app
flutter run
```

### API Configuration

For development, create a `lib/api/sportmonks_config_local.dart` file (gitignored):

```dart
class SportMonksConfigLocal {
  static const String apiToken = 'YOUR_DEV_TOKEN';
}
```

---

## Code Style Guide

### Dart/Flutter Conventions

1. **Naming Conventions**
   ```dart
   // Classes: PascalCase
   class PlayerDetailsPage {}
   
   // Variables/methods: camelCase
   final playerName = 'Paulinho';
   void loadPlayerData() {}
   
   // Constants: lowerCamelCase with 'k' prefix for local
   const kMaxPlayersPerTeam = 4;
   
   // Private: underscore prefix
   final _privateField = 'value';
   void _privateMethod() {}
   ```

2. **File Organization**
   ```dart
   // 1. Imports (dart, package, relative - in that order)
   import 'dart:async';
   
   import 'package:flutter/material.dart';
   
   import '../models/player.dart';
   
   // 2. Constants
   const kDefaultTimeout = Duration(seconds: 30);
   
   // 3. Main class
   class MyWidget extends StatefulWidget {}
   
   // 4. State class
   class _MyWidgetState extends State<MyWidget> {}
   
   // 5. Helper classes/functions
   class _HelperClass {}
   ```

3. **Widget Structure**
   ```dart
   class MyWidget extends StatefulWidget {
     // 1. Constructor parameters
     final String title;
     final VoidCallback? onTap;
     
     const MyWidget({super.key, required this.title, this.onTap});
     
     @override
     State<MyWidget> createState() => _MyWidgetState();
   }
   
   class _MyWidgetState extends State<MyWidget> {
     // 2. State variables
     bool _isLoading = false;
     
     // 3. Lifecycle methods
     @override
     void initState() {
       super.initState();
       _loadData();
     }
     
     @override
     void dispose() {
       // Clean up
       super.dispose();
     }
     
     // 4. Business logic methods
     Future<void> _loadData() async {
       setState(() => _isLoading = true);
       // ...
       setState(() => _isLoading = false);
     }
     
     // 5. Build methods
     @override
     Widget build(BuildContext context) {
       return _buildContent();
     }
     
     Widget _buildContent() {
       // ...
     }
   }
   ```

### Documentation

1. **Public APIs must have documentation**
   ```dart
   /// Fetches player details from the API or cache.
   /// 
   /// [playerId] - The unique identifier for the player.
   /// [forceRefresh] - If true, bypasses cache and fetches from API.
   /// 
   /// Returns [Player] or null if not found.
   /// 
   /// Throws [SportMonksException] on API errors.
   Future<Player?> getPlayerById(int playerId, {bool forceRefresh = false}) async {
     // ...
   }
   ```

2. **Complex logic needs inline comments**
   ```dart
   // Normalize position codes to standard format:
   // SportMonks uses various codes (A, F, CF, ST) for forwards
   // We standardize to: GK, DEF, MID, FWD
   String _normalizePositionCode(String? code) {
     // ...
   }
   ```

---

## Architecture Guidelines

### Repository Pattern

All data access should go through repositories:

```dart
// ✅ Good
class PlayerDetailsPage extends StatefulWidget {
  @override
  _PlayerDetailsPageState createState() => _PlayerDetailsPageState();
}

class _PlayerDetailsPageState extends State<PlayerDetailsPage> {
  final _repository = PlayersRepository();
  
  Future<void> _loadPlayer() async {
    final player = await _repository.getPlayerById(123);
    // ...
  }
}

// ❌ Bad - Direct API calls in UI
class _PlayerDetailsPageState extends State<PlayerDetailsPage> {
  final _client = SportMonksClient();
  
  Future<void> _loadPlayer() async {
    final response = await _client.getPlayerById(123); // Don't do this!
    // ...
  }
}
```

### Caching Strategy

Always implement caching in repositories:

```dart
Future<List<RosterPlayer>> getLigaMxRosterPlayers() async {
  // 1. Check cache first
  final cached = await _cacheService.getLigaMxRoster();
  if (cached != null && cached.isNotEmpty) {
    return cached.map((j) => RosterPlayer.fromJson(j)).toList();
  }
  
  // 2. Fetch from API
  final players = await _fetchFromApi();
  
  // 3. Cache the results
  await _cacheService.saveLigaMxRoster(
    players.map((p) => p.toJson()).toList(),
  );
  
  return players;
}
```

### Error Handling

Use consistent error handling:

```dart
try {
  final response = await _client.getPlayerById(id);
  return Player.fromJson(response['data']);
} on SportMonksException catch (e) {
  debugPrint('API Error: ${e.message} (${e.statusCode})');
  
  // Try cache fallback
  final cached = _cacheService.getCachedPlayer(id);
  if (cached != null) return cached;
  
  rethrow;
} catch (e, stackTrace) {
  debugPrint('Unexpected error: $e\n$stackTrace');
  rethrow;
}
```

### State Management

Use `StatefulWidget` with `setState` for local state. Use Cubits for shared state:

```dart
// Local state (single widget)
class _MyWidgetState extends State<MyWidget> {
  bool _isExpanded = false;
  
  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }
}

// Shared state (Cubit)
class LeagueCubit extends Cubit<LeagueState> {
  final LeagueRepository _repository;
  
  LeagueCubit(this._repository) : super(LeagueInitial());
  
  Future<void> loadLeagues() async {
    emit(LeagueLoading());
    try {
      final leagues = await _repository.getUserLeagues();
      emit(LeagueLoaded(leagues));
    } catch (e) {
      emit(LeagueError(e.toString()));
    }
  }
}
```

---

## Testing Requirements

### Unit Tests

All repositories and business logic must have unit tests:

```dart
// test/repositories/players_repository_test.dart
void main() {
  late PlayersRepository repository;
  late MockSportMonksClient mockClient;
  late MockCacheService mockCache;
  
  setUp(() {
    mockClient = MockSportMonksClient();
    mockCache = MockCacheService();
    repository = PlayersRepository(
      client: mockClient,
      cache: mockCache,
    );
  });
  
  group('getPlayerById', () {
    test('returns cached player when available', () async {
      // Arrange
      when(mockCache.getCachedPlayer(123)).thenReturn(mockPlayer);
      
      // Act
      final result = await repository.getPlayerById(123);
      
      // Assert
      expect(result, equals(mockPlayer));
      verifyNever(mockClient.getPlayerById(any));
    });
    
    test('fetches from API when cache is empty', () async {
      // Arrange
      when(mockCache.getCachedPlayer(123)).thenReturn(null);
      when(mockClient.getPlayerById(123)).thenAnswer(
        (_) async => {'data': mockPlayerJson},
      );
      
      // Act
      final result = await repository.getPlayerById(123);
      
      // Assert
      expect(result?.id, equals(123));
      verify(mockClient.getPlayerById(123)).called(1);
    });
  });
}
```

### Widget Tests

UI components should have widget tests:

```dart
// test/widgets/player_card_test.dart
void main() {
  testWidgets('PlayerCard displays player name', (tester) async {
    final player = Player(
      id: 1,
      name: 'Test Player',
      displayName: 'T. Player',
      commonName: 'Test',
    );
    
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerCard(player: player),
      ),
    );
    
    expect(find.text('T. Player'), findsOneWidget);
  });
  
  testWidgets('PlayerCard handles tap', (tester) async {
    bool tapped = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: PlayerCard(
          player: mockPlayer,
          onTap: () => tapped = true,
        ),
      ),
    );
    
    await tester.tap(find.byType(PlayerCard));
    expect(tapped, isTrue);
  });
}
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/repositories/players_repository_test.dart

# Run tests matching pattern
flutter test --name "PlayerCard"
```

---

## Pull Request Process

### Before Submitting

1. **Run analysis**
   ```bash
   flutter analyze
   ```

2. **Format code**
   ```bash
   dart format lib/ test/
   ```

3. **Run tests**
   ```bash
   flutter test
   ```

4. **Update documentation** if needed

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Widget tests added/updated
- [ ] Manual testing completed

## Screenshots (if UI changes)
[Add screenshots here]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
```

### Review Process

1. Submit PR with clear description
2. Wait for CI checks to pass
3. Address reviewer feedback
4. Squash and merge when approved

---

## Questions?

For questions about contributing, please open an issue with the "question" label.

---

*Last Updated: January 2026*

