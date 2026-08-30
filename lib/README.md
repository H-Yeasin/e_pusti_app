# e-Pushti App Structure

This project uses a feature-first Flutter layout with Riverpod-oriented presentation layers.

- `core/`: app-wide config, theme, localization, errors, network clients, and shared widgets.
- `features/*/data`: API/local data sources, DTO models, and repository implementations.
- `features/*/domain`: entities, repository contracts, and use cases.
- `features/*/presentation`: screens, feature widgets, and Riverpod providers.

Flavor entry points:

- `main_dev.dart`
- `main_staging.dart`
- `main_prod.dart`
