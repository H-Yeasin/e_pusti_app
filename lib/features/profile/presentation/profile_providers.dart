import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../../../core/config/backend_config.dart';
import '../../auth/data/local_backend.dart';
import '../../auth/data/supabase_backend.dart';
import '../../auth/presentation/providers/auth_controller.dart';
import '../domain/profile_models.dart';

/// Account-scoped repositories; null while logged out.
final profileRepositoryProvider = Provider<ProfileRepository?>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return null;
  return switch (ref.watch(backendKindProvider)) {
    BackendKind.supabase => SupabaseProfileRepository(Supabase.instance.client),
    BackendKind.local => LocalProfileRepository(
      ref.watch(sharedPreferencesProvider),
      userId,
    ),
    BackendKind.none => null,
  };
});

final measurementRepositoryProvider = Provider<MeasurementRepository?>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return null;
  return switch (ref.watch(backendKindProvider)) {
    BackendKind.supabase => SupabaseMeasurementRepository(
      Supabase.instance.client,
    ),
    BackendKind.local => LocalMeasurementRepository(
      ref.watch(sharedPreferencesProvider),
      userId,
    ),
    BackendKind.none => null,
  };
});

final consentRepositoryProvider = Provider<ConsentRepository?>((ref) {
  final userId = ref.watch(authControllerProvider.select((s) => s.userId));
  if (userId == null) return null;
  return switch (ref.watch(backendKindProvider)) {
    BackendKind.supabase => SupabaseConsentRepository(Supabase.instance.client),
    BackendKind.local => LocalConsentRepository(
      ref.watch(sharedPreferencesProvider),
      userId,
    ),
    BackendKind.none => null,
  };
});

String newId() {
  final r = Random.secure();
  String hex(int n) =>
      List.generate(n, (_) => r.nextInt(16).toRadixString(16)).join();
  // RFC 4122 version 4 layout, accepted by Postgres uuid columns.
  return '${hex(8)}-${hex(4)}-4${hex(3)}-'
      '${(8 + r.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
}

/// The holder and dependants. The holder record is created on first load.
class FamilyController extends AsyncNotifier<List<Person>> {
  @override
  Future<List<Person>> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    if (repo == null) return const [];
    var people = await repo.loadFamily();
    if (!people.any((p) => p.isHolder)) {
      final holder = Person(id: newId(), relationship: Relationship.holder);
      await repo.savePerson(holder);
      people = [holder, ...people];
    }
    people.sort((a, b) {
      if (a.isHolder != b.isHolder) return a.isHolder ? -1 : 1;
      return 0;
    });
    return people;
  }

  Future<void> save(Person person) async {
    final repo = ref.read(profileRepositoryProvider);
    if (repo == null) return;
    await repo.savePerson(person);
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String personId) async {
    final repo = ref.read(profileRepositoryProvider);
    if (repo == null) return;
    await repo.deletePerson(personId);
    ref.invalidate(measurementsProvider(personId));
    ref.invalidateSelf();
    await future;
  }
}

final familyProvider = AsyncNotifierProvider<FamilyController, List<Person>>(
  FamilyController.new,
);

final holderProvider = Provider<Person?>((ref) {
  final family = ref.watch(familyProvider).value ?? const [];
  return family.where((p) => p.isHolder).firstOrNull;
});

class ConsentController extends AsyncNotifier<ConsentRecord> {
  @override
  Future<ConsentRecord> build() async {
    final repo = ref.watch(consentRepositoryProvider);
    if (repo == null) return ConsentRecord.none;
    return repo.load();
  }

  Future<void> accept({required bool healthData}) async {
    await ref.read(consentRepositoryProvider)?.accept(healthData: healthData);
    ref.invalidateSelf();
    await future;
  }

  /// Withdrawing health-data consent also deletes stored measurements.
  Future<void> withdrawHealthData() async {
    await ref.read(measurementRepositoryProvider)?.deleteAll();
    await ref.read(consentRepositoryProvider)?.withdrawHealthData();
    ref.invalidate(measurementsProvider);
    ref.invalidateSelf();
    await future;
  }
}

final consentProvider = AsyncNotifierProvider<ConsentController, ConsentRecord>(
  ConsentController.new,
);

final measurementsProvider = FutureProvider.family<List<Measurement>, String>((
  ref,
  personId,
) async {
  final repo = ref.watch(measurementRepositoryProvider);
  if (repo == null) return const [];
  return repo.listFor(personId);
});

/// Add, correct or delete a record and refresh that person's history.
class MeasurementActions {
  MeasurementActions(this._ref);

  final Ref _ref;

  Future<void> save(Measurement measurement) async {
    await _ref.read(measurementRepositoryProvider)?.save(measurement);
    _ref.invalidate(measurementsProvider(measurement.personId));
  }

  Future<void> delete(Measurement measurement) async {
    await _ref.read(measurementRepositoryProvider)?.delete(measurement.id);
    _ref.invalidate(measurementsProvider(measurement.personId));
  }
}

final measurementActionsProvider = Provider<MeasurementActions>(
  MeasurementActions.new,
);
