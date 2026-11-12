import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/debug/safe_debug_log.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/api_request.dart';
import '../../../core/security/secure_session_secret_store.dart';
import '../domain/google_identity.dart';
import 'firebase_identity_proof.dart';

/// Coordinates the session exchange while keeping credentials out of UI state.
final class StudentSessionGateway {
  StudentSessionGateway({
    required this._api,
    required this._proofSource,
    required Uri environment,
    required this._platform,
    this._storage = SecureSessionSecretStore.platformStorage,
  }) : _namespace = base64Url.encode(utf8.encode(environment.toString()));

  final ApiClient _api;
  final FirebaseIdentityProofSource _proofSource;
  final String _namespace;
  final String _platform;
  final FlutterSecureStorage _storage;

  String get _deviceKey => 'device_v1_$_namespace';
  String _sessionKey(GoogleIdentity identity) =>
      'refresh_v1_${_namespace}_${base64Url.encode(utf8.encode(identity.firebaseUid))}';

  Future<void> start(GoogleIdentity identity) async {
    // If a previous exchange failed after rotation, resume the saved session.
    if (await restore(identity)) return;
    final deviceId = await _installationId();
    final proof = await _proofSource.prepareForBackend(
      expectedFirebaseUid: identity.firebaseUid,
    );
    await _accept(
      identity,
      await _api.send(
        ApiRequest(
          method: 'POST',
          path: 'auth/google',
          jsonBody: {
            'idToken': proof.idToken,
            'device': {'id': deviceId, 'platform': _platform},
          },
        ),
      ),
    );
  }

  Future<bool> restore(GoogleIdentity identity) async {
    final key = _sessionKey(identity);
    final refresh = await _storage.read(key: key);
    if (refresh == null) return false;
    try {
      await _accept(
        identity,
        await _api.send(
          ApiRequest(
            method: 'POST',
            path: 'auth/refresh',
            jsonBody: {'refreshToken': refresh},
          ),
        ),
      );
      return true;
    } on ApiFailure catch (failure) {
      if (failure.code != 'INVALID_REFRESH_TOKEN' &&
          failure.code != 'SESSION_REVOKED') {
        rethrow;
      }
      await _storage.delete(key: key);
      return false;
    }
  }

  Future<void> end(GoogleIdentity identity) async {
    final key = _sessionKey(identity);
    final refresh = await _storage.read(key: key);
    if (refresh == null) return;
    // Clear local authority before attempting remote revocation.
    await _storage.delete(key: key);
    try {
      await _revoke(refresh);
    } on ApiFailure catch (failure) {
      SafeDebugLog.event('Auth', 'remote logout failed', {
        'kind': failure.kind.name,
      });
    }
  }

  Future<void> _accept(GoogleIdentity identity, ApiResponse response) async {
    final data = response.json['data'];
    final access = data is Map ? data['accessToken'] : null;
    final refresh = data is Map ? data['refreshToken'] : null;
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.length < 20 ||
        refresh.length > 256) {
      throw const ApiFailure(ApiFailureKind.invalidResponse);
    }
    try {
      // Rotation invalidates the old value, so persist the replacement first.
      await _storage.write(key: _sessionKey(identity), value: refresh);
    } catch (_) {
      await _revoke(refresh);
      rethrow;
    }
    final state = await _api.send(
      ApiRequest(
        method: 'GET',
        path: 'me/session-state',
        headers: {'Authorization': 'Bearer $access'},
      ),
    );
    final stateData = state.json['data'];
    if (stateData is! Map ||
        !const {
          'suspended',
          'device_unauthorized',
          'choose_usage_type',
          'complete_basic_info',
          'complete_registration',
          'confirm_new_term',
          'home',
        }.contains(stateData['next'])) {
      throw const ApiFailure(ApiFailureKind.invalidResponse);
    }
  }

  Future<void> _revoke(String refresh) async {
    await _api.send(
      ApiRequest(
        method: 'POST',
        path: 'auth/logout',
        jsonBody: {'refreshToken': refresh},
      ),
    );
  }

  Future<String> _installationId() async {
    final existing = await _storage.read(key: _deviceKey);
    if (existing != null) return existing;
    final random = Random.secure();
    final value = base64Url.encode(
      List.generate(24, (_) => random.nextInt(256)),
    );
    await _storage.write(key: _deviceKey, value: value);
    return value;
  }
}
