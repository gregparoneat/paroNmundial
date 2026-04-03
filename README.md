# paroNmundial

<p align="center">
  <img src="assets/paroNmundialTransparent.png" alt="paroNmundial Logo" width="220" />
</p>

World Cup 2026 fantasy app built with Flutter and SportMonks.

The project was originally cloned from a league-based fantasy football app and has been refocused around the FIFA World Cup. It now uses World Cup teams, squads, fixtures, standings, localized country names, a World Cup pricing model, and a tournament predictor with exportable bracket images.

## What It Does

- World Cup-only fantasy flow
- Classic leagues only
- World Cup fixtures and group standings
- Player search, player details, and projected fantasy points
- Predicted lineups based on recent international matches, qualifiers, and friendlies
- Market-value-assisted pricing using curated CSV files under `assets/MarketValues/`
- World Cup bracket predictor with group-stage score entry and knockout generation
- Spanish localization improvements across the World Cup surfaces

## Core Configuration

Main SportMonks competition config lives in [sportmonks_config.dart](/Users/gregoriomerazholguin/Documents/projects/paroNmundial/lib/api/sportmonks_config.dart).

Current World Cup setup:

- competition: `World Cup`
- league id: `732`
- season id: `26618`
- international friendlies league id: `1082`

The app also prioritizes international seasons for projections and lineup prediction, with club data used as fallback or blend depending on the feature.

## Predictor

The predictor is available from the Fixtures section and supports:

- entering group-stage scores
- automatic standings calculation
- knockout-stage generation
- best third-place placement through `assets/world_cup_2026_third_place_matrix.csv`
- share/export of a branded knockout bracket image

Main files:

- [world_cup_predictor_page.dart](/Users/gregoriomerazholguin/Documents/projects/paroNmundial/lib/features/fixtures/ui/world_cup_predictor_page.dart)
- [world_cup_predictor_models.dart](/Users/gregoriomerazholguin/Documents/projects/paroNmundial/lib/features/fixtures/models/world_cup_predictor_models.dart)

## Getting Started

Requirements:

- Flutter `3.32.5+`
- Dart `3.8.1+`
- Xcode for iOS
- Android Studio / Android SDK for Android
- SportMonks Football API token

Install and run:

```bash
flutter pub get
flutter run
```

Useful commands:

```bash
flutter analyze
flutter run -d ios
flutter build apk --release
flutter build ios --release
```

## Assets

Important assets used by the current app:

- `assets/paroNmundial.png`
- `assets/paroNmundialTransparent.png`
- `assets/MarketValues/`
- `assets/world_cup_2026_third_place_matrix.csv`

## Notes

- Draft mode is no longer part of the intended World Cup product direction.
- Some legacy draft-related strings and files may still exist in the codebase, but the active flow is classic-only.
- Some Firestore reads still depend on backend rules and indexes outside the app repo.

## Project Areas

- `lib/api/`: SportMonks access and repositories
- `lib/features/fixtures/`: fixtures, standings, predictor, lineup prediction
- `lib/features/league/`: classic fantasy league flow and team builder
- `lib/features/player/` and `lib/features/players/`: player details and search
- `lib/services/cache_service.dart`: local cache
- `lib/l10n/`: localization source files
