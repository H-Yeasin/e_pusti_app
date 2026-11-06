import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/localization.dart';

/// Overridden in `bootstrap` once shared preferences are loaded.
final appLocaleControllerProvider = Provider<AppLocaleController>((ref) {
  throw UnimplementedError(
    'Locale controller must be overridden at bootstrap.',
  );
});
