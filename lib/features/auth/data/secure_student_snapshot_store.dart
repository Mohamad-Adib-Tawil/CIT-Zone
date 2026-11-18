import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serializes bounded metadata operations; never receives raw API responses.
final class SecureStudentSnapshotStore {
  SecureStudentSnapshotStore(
    this._storage,
    this._environment,
    this._kind,
    this._maxBytes,
  );

  final FlutterSecureStorage _storage;
  final String _environment;
  final String _kind;
  final int _maxBytes;
  Future<void> _operations = Future.value();

  String _key(String owner) =>
      '${_kind}_snapshot_v1_${_environment}_${base64Url.encode(utf8.encode(owner))}';

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = _operations.then((_) => operation());
    _operations = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Object?> read(String owner) => _serialize(() async {
    try {
      final value = await _storage.read(key: _key(owner));
      if (value == null ||
          value.length > _maxBytes ||
          utf8.encode(value).length > _maxBytes) {
        return null;
      }
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  });

  Future<void> write(String owner, Map<String, Object?> data) => _serialize(
    () async {
      try {
        final value = jsonEncode(data);
        if (value.length > _maxBytes || utf8.encode(value).length > _maxBytes) {
          await _storage.delete(key: _key(owner));
          return;
        }
        await _storage.write(key: _key(owner), value: value);
      } catch (_) {
        // A confirmed server result must survive a cache storage failure.
      }
    },
  );

  Future<void> clear(String owner) => _serialize(() async {
    try {
      await _storage.delete(key: _key(owner));
    } catch (_) {
      // Snapshot use is independently gated by a validated student session.
    }
  });
}
