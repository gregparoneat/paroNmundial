# Fantasy 11 - Fantasy Sports Application

<p align="center">
  <img src="assets/logo.png" alt="Fantasy 11 Logo" width="200"/>
</p>

A comprehensive Fantasy Sports mobile application built with Flutter, featuring real-time sports data integration via SportMonks API, intelligent fantasy points prediction, and support for Liga MX (Mexican Football League).

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
- [Project Structure](#-project-structure)
- [API Integration](#-api-integration)
- [Fantasy Points Prediction](#-fantasy-points-prediction)
- [Localization](#-localization)
- [Dependencies](#-dependencies)
- [Documentation](#-documentation)

## ✨ Features

### Core Features
- **Player Search & Discovery**: Search players across leagues with real-time data
- **Fantasy Points Prediction**: AI-powered prediction system analyzing player form, opponent strength, and historical data
- **Tournament Statistics**: Accurate stats per tournament (handles Liga MX's Apertura/Clausura split)
- **Live Match Tracking**: Real-time fixture updates and live scores
- **Team Building**: Create and manage fantasy teams with captain/vice-captain selection
- **Contests**: Join contests and compete with other players
- **Wallet System**: In-app wallet for contest entries and winnings

### Advanced Features
- **Smart Caching**: Hive-based caching system for offline support and performance
- **Multi-language Support**: 9 languages (English, Spanish, French, Portuguese, Italian, Arabic, Turkish, Indonesian, Swahili)
- **Responsive Design**: Optimized for both mobile and tablet screens
- **Dark Theme**: Modern dark UI theme

## 🏗 Architecture

The application follows a **Repository Pattern** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                        UI Layer                              │
│  (Pages, Widgets, StatefulWidgets, StatelessWidgets)        │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                      │
│  (Cubits, Predictors, Data Processing)                      │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Repository Layer                          │
│  (PlayersRepository, FixturesRepository, SeasonsRepository) │
└─────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
┌─────────────────────────┐ ┌─────────────────────────┐
│     API Client          │ │     Cache Service       │
│  (SportMonksClient)     │ │   (Hive Storage)        │
└─────────────────────────┘ └─────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│                    SportMonks API                           │
│              (External Football Data)                       │
└─────────────────────────────────────────────────────────────┘
```

For detailed architecture documentation, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.32.5 or higher
- Dart SDK 3.8.1 or higher
- Android Studio / Xcode (for mobile development)
- SportMonks API key (for live data)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd fantasy-11
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API key** (see [Configuration](#-configuration))

4. **Run the app**
   ```bash
   # Development
   flutter run
   
   # Release build
   flutter run --release
   ```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS)
flutter build ios --release
```

## ⚙️ Configuration

### SportMonks API Setup

1. Create an account at [SportMonks](https://www.sportmonks.com/)
2. Subscribe to the Football API plan
3. Get your API token from the dashboard
4. Update `lib/api/sportmonks_config.dart`:

```dart
class SportMonksConfig {
  static const String apiToken = 'YOUR_API_TOKEN_HERE';
  // ...
}
```

### Environment Variables (Recommended for Production)

For production builds, use environment variables instead of hardcoding:

```bash
# Create a .env file (add to .gitignore)
SPORTMONKS_API_TOKEN=your_token_here
```

### Demo Mode

The app includes mock data fallback for development/demo purposes. When the API is not configured or unavailable, the app automatically uses local JSON files from `assets/MockResponses/`.

## 📁 Project Structure

```
lib/
├── api/                          # API Layer
│   ├── sportmonks_client.dart    # HTTP client for SportMonks
│   ├── sportmonks_config.dart    # API configuration
│   └── repositories/             # Data repositories
│       ├── fixtures_repository.dart
│       ├── players_repository.dart
│       └── seasons_repository.dart
│
├── app_config/                   # App Configuration
│   ├── app_config.dart           # App constants
│   ├── colors.dart               # Color definitions
│   └── styles.dart               # Theme and text styles
│
├── features/                     # Feature Modules
│   ├── account/                  # User account features
│   ├── auth/                     # Authentication (login, register, verification)
│   ├── components/               # Reusable UI components
│   ├── fantasy/                  # Fantasy points prediction
│   ├── fixtures/                 # Match fixtures
│   ├── home/                     # Home screen, team creation
│   ├── language/                 # Language/locale management
│   ├── match/                    # Match details and cards
│   ├── my_matches/               # User's matches tracking
│   ├── player/                   # Player details and stats
│   ├── players/                  # Player search
│   └── wallet/                   # Wallet management
│
├── generated/                    # Auto-generated localization
├── l10n/                         # Localization source files
├── local_data_layer/             # Local data management
├── routes/                       # Navigation routes
├── services/                     # App services
│   └── cache_service.dart        # Hive caching service
│
└── main.dart                     # Application entry point
```

## 🔌 API Integration

### SportMonks Endpoints Used

| Endpoint | Description |
|----------|-------------|
| `/players/search/{name}` | Search players by name |
| `/players/{id}` | Get player details with statistics |
| `/fixtures/date/{date}` | Get fixtures for a specific date |
| `/fixtures/between/{start}/{end}/{teamId}` | Get team fixtures in date range |
| `/teams/{id}` | Get team details |
| `/seasons` | Get seasons for a league |

### Data Includes

The API requests use "includes" to fetch related data in a single request:

```dart
// Player includes
['nationality', 'position', 'detailedposition', 
 'teams.team', 'statistics.details', 'statistics.season',
 'trophies', 'transfers']

// Fixture includes
['participants', 'venue', 'state', 'league', 
 'scores', 'events', 'lineups', 'coaches']
```

### Rate Limiting

SportMonks has rate limits based on your subscription plan. The app implements:
- Response caching to minimize API calls
- Error handling for 429 (Too Many Requests) responses
- Fallback to cached/mock data when limits are reached

## 🎯 Fantasy Points Prediction

The prediction system (`FantasyPointsPredictor`) uses multiple factors:

### Scoring Components

| Component | Weight | Description |
|-----------|--------|-------------|
| Base Score | 50 pts | Starting point for all players |
| Position Bonus | 0-10 pts | Based on player position |
| Form Score | -10 to +15 pts | Based on last 5 matches performance |
| Opponent Analysis | -10 to +10 pts | Opponent's defensive/offensive strength |
| Home Advantage | +3 pts | When playing at home |
| Season Stats | 0-12 pts | Goals, assists, clean sheets |

### Prediction Tiers

| Tier | Score Range | Color |
|------|-------------|-------|
| Elite Pick | 80+ | Gold |
| Strong Pick | 65-79 | Green |
| Good Pick | 50-64 | Blue |
| Risky Pick | 35-49 | Orange |
| Avoid | <35 | Red |

### Tournament-Specific Stats

For leagues like Liga MX with split seasons (Apertura/Clausura), the app:
1. Identifies the current active stage/tournament
2. Fetches fixtures within the tournament date range
3. Calculates accurate tournament-specific statistics

## 🌍 Localization

Supported languages:
- 🇺🇸 English (en)
- 🇪🇸 Spanish (es)
- 🇫🇷 French (fr)
- 🇵🇹 Portuguese (pt)
- 🇮🇹 Italian (it)
- 🇸🇦 Arabic (ar)
- 🇹🇷 Turkish (tr)
- 🇮🇩 Indonesian (id)
- 🇹🇿 Swahili (sw)

### Adding a New Language

1. Create a new ARB file in `lib/l10n/`:
   ```
   lib/l10n/intl_XX.arb  (where XX is the language code)
   ```

2. Run the localization generator:
   ```bash
   flutter pub run intl_utils:generate
   ```

## 📦 Dependencies

### Core Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_bloc | ^9.1.1 | State management |
| http | ^1.6.0 | HTTP client |
| hive_flutter | ^1.1.0 | Local storage/caching |
| cached_network_image | ^3.4.1 | Image caching |
| intl | ^0.20.2 | Internationalization |

### UI Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| animation_wrappers | ^3.0.0 | Animations |
| carousel_slider | ^5.1.1 | Carousels |
| blur | ^4.0.2 | Blur effects |

### Development Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_launcher_icons | ^0.14.4 | App icon generation |
| flutter_lints | ^6.0.0 | Code linting |

## 📚 Documentation

- [Architecture & LLD](docs/ARCHITECTURE.md) - Detailed system design
- [API Reference](docs/API.md) - API endpoints and models
- [Contributing Guide](docs/CONTRIBUTING.md) - How to contribute

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

## 📝 License

This project is licensed under the CodeCanyon Regular License. See the LICENSE file for details.

## 🤝 Support

For support, please contact through CodeCanyon or open an issue in the repository.

---

<p align="center">
  Made with ❤️ using Flutter
</p>
