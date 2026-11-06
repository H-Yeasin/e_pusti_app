import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fixture_webinar_repository.dart';
import '../domain/webinar_models.dart';

final webinarRepositoryProvider = Provider<WebinarRepository>(
  (ref) => FixtureWebinarRepository(),
);

final webinarsProvider = FutureProvider<List<Webinar>>(
  (ref) => ref.watch(webinarRepositoryProvider).fetchWebinars(),
);

final webinarProvider = FutureProvider.family<Webinar, String>(
  (ref, id) => ref.watch(webinarRepositoryProvider).fetchWebinar(id),
);
