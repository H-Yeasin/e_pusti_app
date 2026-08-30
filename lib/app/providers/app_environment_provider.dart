import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';

final appEnvironmentProvider = Provider<AppEnvironment>((ref) {
  throw UnimplementedError('App environment must be overridden at bootstrap.');
});
