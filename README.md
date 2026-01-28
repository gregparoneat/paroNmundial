# Fantasy 11 - Fantasy Sports Application

<p align="center">
  <img src="assets/logo.png" alt="Fantasy 11 Logo" width="200"/>
</p>

A comprehensive Fantasy Sports mobile application built with Flutter, featuring real-time sports data integration via SportMonks API, intelligent fantasy points prediction, and support for Liga MX (Mexican Football League).

## 📋 Table of Contents

- [Features](#-features)
- [Screenshots](#-screenshots)
- [Architecture](#-architecture)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
- [Project Structure](#-project-structure)
- [API Integration](#-api-integration)
- [Fantasy Points Prediction](#-fantasy-points-prediction)
- [Fantasy Leagues](#-fantasy-leagues)
- [Localization](#-localization)
- [Dependencies](#-dependencies)
- [Documentation](#-documentation)

## ✨ Features

### Core Features
- **Player Search & Discovery**: Search players across leagues with real-time data
- **Fantasy Points Prediction**: AI-powered prediction system analyzing player form, opponent strength, and historical data
- **Tournament Statistics**: Accurate stats per tournament (handles Liga MX's Apertura/Clausura split)
- **Live Match Tracking**: Real-time fixture updates and live scores
- **Fantasy Leagues**: Create and join public/private fantasy leagues
- **Team Building**: Interactive team builder with soccer field visualization
- **Contests**: Join contests and compete with other players
- **Wallet System**: In-app wallet for contest entries and winnings

### Fantasy League Features
- **Public Leagues**: Open leagues anyone can join
- **Private Leagues**: Invite-only leagues with unique codes
- **Team Builder**: Build 15-player squads (11 + 4 subs) with budget constraints
- **Soccer Field View**: Visual formation display with real-time player placement
- **Captain Selection**: Designate Captain (2x) and Vice-Captain (1.5x) for bonus points
- **Multiple Formations**: Support for 4-4-2, 4-3-3, 3-5-2, 4-5-1, 3-4-3, 5-3-2
- **Player Substitution**: Swap players between starting XI and bench

### Advanced Features
- **Smart Caching**: Hive-based caching system with automatic expiry
- **Lazy Loading**: Efficient player loading with infinite scroll
- **Multi-language Support**: 9 languages (English, Spanish, French, Portuguese, Italian, Arabic, Turkish, Indonesian, Swahili)
- **Responsive Design**: Optimized for both mobile and tablet screens
- **Dark Theme**: Modern dark UI theme
- **Player Pricing Model**: Dynamic credit-based player valuation

## 🏗 Architecture

The application follows a **Clean Architecture** pattern with **Repository Pattern** for data management:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                             │
│     Pages • Widgets • StatefulWidgets • Animations • Themes             │
└─────────────────────────────────────┬───────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          BUSINESS LOGIC LAYER                            │
│         Cubits • Predictors • Data Processors • Validators              │
└─────────────────────────────────────┬───────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           REPOSITORY LAYER                               │
│     PlayersRepository • FixturesRepository • SeasonsRepository          │
└──────────────────┬──────────────────────────────────┬───────────────────┘
                   │                                  │
                   ▼                                  ▼
┌──────────────────────────────┐    ┌──────────────────────────────────────┐
│     SportMonks API Client    │    │        Hive Cache Service            │
│       (External Data)        │    │        (Local Storage)               │
└──────────────────────────────┘    └──────────────────────────────────────┘
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
2. Subscribe to the Football API plan (Liga MX coverage required)
3. Get your API token from the dashboard
4. Update `lib/api/sportmonks_config.dart`:

```dart
class SportMonksConfig {
  static const String apiToken = 'YOUR_API_TOKEN_HERE';
  static const int ligaMxLeagueId = 262;
  static const int ligaMxCurrentSeasonId = 25539;
}
```

### Liga MX Teams Configuration

The app uses a curated list of Liga MX first-division teams in `assets/Teams/LigaMxTeamIds.csv`. This ensures only valid, active Liga MX teams and players are displayed.

## 📁 Project Structure

```
lib/
├── api/                          # API Layer
│   ├── sportmonks_client.dart    # HTTP client for SportMonks
│   ├── sportmonks_config.dart    # API configuration
│   └── repositories/             # Data repositories
│       ├── fixtures_repository.dart
│       ├── players_repository.dart
│       ├── seasons_repository.dart
│       └── league_repository.dart
│
├── app_config/                   # App Configuration
│   ├── app_config.dart           # App constants
│   ├── colors.dart               # Color definitions
│   └── styles.dart               # Theme and text styles
│
├── features/                     # Feature Modules
│   ├── account/                  # User account features
│   ├── auth/                     # Authentication
│   ├── components/               # Reusable UI components
│   ├── fantasy/                  # Fantasy points prediction
│   │   └── fantasy_points_predictor.dart
│   ├── fixtures/                 # Match fixtures
│   ├── home/                     # Home screen
│   ├── language/                 # Language/locale management
│   ├── league/                   # Fantasy leagues
│   │   ├── models/
│   │   │   └── league_models.dart
│   │   ├── ui/
│   │   │   ├── create_league_page.dart
│   │   │   ├── league_details_page.dart
│   │   │   ├── team_builder_page.dart
│   │   │   └── widgets/
│   │   │       ├── soccer_field_widget.dart
│   │   │       └── bench_widget.dart
│   │   └── cubit/
│   │       └── league_cubit.dart
│   ├── match/                    # Match details
│   ├── my_matches/               # User's matches tracking
│   ├── player/                   # Player details and stats
│   │   ├── models/
│   │   │   └── player_info.dart
│   │   └── ui/
│   │       └── player_details_page.dart
│   ├── players/                  # Player search
│   │   └── players_search.dart
│   └── wallet/                   # Wallet management
│
├── generated/                    # Auto-generated localization
├── l10n/                         # Localization source files
├── routes/                       # Navigation routes
├── services/                     # App services
│   └── cache_service.dart        # Hive caching service
│
└── main.dart                     # Application entry point

assets/
├── MockResponses/                # Demo/fallback data
├── Teams/
│   └── LigaMxTeamIds.csv         # Liga MX team IDs
└── images/                       # App images and icons
```

## 🔌 API Integration

### SportMonks Endpoints Used

| Endpoint | Description |
|----------|-------------|
| `/players/search/{name}` | Search players by name |
| `/players/{id}` | Get player details with statistics |
| `/fixtures/between/{start}/{end}/{teamId}` | Get team fixtures in date range |
| `/teams/{id}` | Get team details with players |
| `/seasons/{id}` | Get season with stages/tournaments |

### Caching Strategy

| Data Type | Cache Duration | Storage |
|-----------|---------------|---------|
| Liga MX Roster | 6 hours | Hive |
| Liga MX Teams | 24 hours | Hive |
| Player Search | 1 hour | Hive |
| Recent Players | Permanent | Hive |
| Fixtures | 30 minutes | Hive |

For detailed API documentation, see [docs/API.md](docs/API.md).

## 🎯 Fantasy Points Prediction

The prediction system (`FantasyPointsPredictor`) uses multiple factors:

### Scoring Components

| Component | Weight | Description |
|-----------|--------|-------------|
| Base Score | 50 pts | Starting point for all players |
| Position Bonus | 0-10 pts | Based on player position |
| Form Score | -10 to +15 pts | Based on last 5 matches |
| Opponent Analysis | -10 to +10 pts | Opponent's strength |
| Home Advantage | +3 pts | When playing at home |
| Season Stats | 0-12 pts | Goals, assists, clean sheets |

### Prediction Tiers

| Tier | Score Range | Recommendation |
|------|-------------|----------------|
| Elite Pick | 80+ | Must-have player |
| Strong Pick | 65-79 | Highly recommended |
| Good Pick | 50-64 | Solid choice |
| Risky Pick | 35-49 | Uncertain returns |
| Avoid | <35 | Not recommended |

## ⚽ Fantasy Leagues

### League Types

- **Public Leagues**: Anyone can join, visible in browse
- **Private Leagues**: Invite-only with unique code

### Team Building Rules

| Rule | Value |
|------|-------|
| Squad Size | 15 players (11 + 4 subs) |
| Default Budget | 100 credits |
| Max Goalkeepers | 2 |
| Max Defenders | 5 |
| Max Midfielders | 5 |
| Max Forwards | 3 |
| Max per Club | 4 players |

### Captain Bonuses

| Role | Point Multiplier |
|------|-----------------|
| Captain | 2x |
| Vice-Captain | 1.5x |

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

## 📚 Documentation

- [Architecture & LLD](docs/ARCHITECTURE.md) - Detailed system design with diagrams
- [API Reference](docs/API.md) - SportMonks API endpoints and models
- [Data Flow Diagrams](docs/ARCHITECTURE.md#data-flow-diagrams) - Visual flow documentation

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

## 🔧 Development Notes

### Debug Mode

During development, demo data fallbacks are disabled to expose API issues immediately. Enable verbose logging to debug API calls:

```dart
// In sportmonks_client.dart
debugPrint('SportMonks API Request: $url');
debugPrint('SportMonks API Response: ${response.statusCode}');
```

### Common Issues

| Issue | Solution |
|-------|----------|
| API 404 errors | Check include parameters - some don't exist |
| Players missing | Verify team IDs in LigaMxTeamIds.csv |
| Stats showing 0 | Clear Hive cache and refresh |
| Minutes wrong | Ensure type_id 119 is used for minutes |

## 📝 License

This project is licensed under the CodeCanyon Regular License. See the LICENSE file for details.

## 🤝 Support

For support, please contact through CodeCanyon or open an issue in the repository.

---

<p align="center">
  Made with ❤️ using Flutter
</p>
