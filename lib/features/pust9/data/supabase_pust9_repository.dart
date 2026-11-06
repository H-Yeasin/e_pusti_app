import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/pust9_subscription.dart';

/// Talks to the `pust9-subscribe` Edge Function, which calls bdapps.
class SupabasePust9Repository implements Pust9Repository {
  SupabasePust9Repository(this._client);

  final SupabaseClient _client;

  Future<Map<String, Object?>> _call(Map<String, Object?> body) async {
    final Object? data;
    try {
      final res = await _client.functions
          .invoke('pust9-subscribe', body: body)
          .timeout(const Duration(seconds: 20));
      data = res.data;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] != null) {
        throw Pust9Failure.fromCode(details['error']);
      }
      throw const Pust9ServiceFailure();
    } on SocketException {
      throw const Pust9NetworkFailure();
    } on TimeoutException {
      throw const Pust9NetworkFailure();
    }
    if (data is! Map) throw const Pust9ServiceFailure();
    final json = data.cast<String, Object?>();
    if (json['error'] != null) throw Pust9Failure.fromCode(json['error']);
    return json;
  }

  @override
  Future<Pust9Status> status() async =>
      Pust9Status.fromJson(await _call({'action': 'status'}));

  @override
  Future<void> requestOtp(String phone) async {
    await _call({
      'action': 'request_otp',
      'phone': phone,
      'os': Platform.operatingSystem,
    });
  }

  @override
  Future<Pust9Status> verifyOtp(String code) async =>
      Pust9Status.fromJson(await _call({'action': 'verify_otp', 'code': code}));

  @override
  Future<Pust9Status> unsubscribe() async =>
      Pust9Status.fromJson(await _call({'action': 'unsubscribe'}));
}
