import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Bounded, debug-only diagnostics. Never pass raw credentials or user objects.
abstract final class SafeDebugLog {
  static const int _maxDepth = 16;
  static const int _maxEntries = 100;
  static const int _maxStringLength = 1200;
  static final RegExp _sensitiveKey = RegExp(
    r'(authorization|cookie|token|secret|password|credential|email|phone|full.?name|official.?name|display.?name|description|^name$|photo|profile|uid|id_google|^id$|device.?id|session|license|student|grade|score|transcript|answer|playback.?url|manifest.?url|stream.?url|signed.?url|download.?url)',
    caseSensitive: false,
  );
  static final RegExp _email = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );
  static final RegExp _bearer = RegExp(
    r'\bBearer\s+[^\s,;]+',
    caseSensitive: false,
  );
  static final RegExp _jwt = RegExp(
    r'\beyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b',
  );
  static final RegExp _phone = RegExp(
    r'(?<!\w)\+?[0-9][0-9 ()-]{7,}[0-9](?!\w)',
  );

  // Keep chunks below Android logcat's byte limit, including non-ASCII text.
  static final RegExp _logChunk = RegExp(r'.{1,800}', unicode: true);

  static void event(
    String scope,
    String message, [
    Map<String, Object?> fields = const {},
  ]) {
    if (!kDebugMode) return;
    try {
      final prefix = '[Hasobjy][$scope][${DateTime.now().toIso8601String()}]';
      final json = jsonEncode(_sanitize(fields, 0));
      if (json.length <= 800) {
        debugPrint('$prefix $message $json');
        return;
      }
      var part = 0;
      for (final chunk in _logChunk.allMatches(json)) {
        debugPrint('$prefix $message [${++part}] ${chunk.group(0)}');
      }
    } on Object {
      debugPrint(
        '[Hasobjy][$scope][${DateTime.now().toIso8601String()}] '
        '$message {"details":"unavailable"}',
      );
    }
  }

  static void error(
    String scope,
    Object error, [
    StackTrace? stackTrace,
    Map<String, Object?> fields = const {},
  ]) {
    if (!kDebugMode) return;
    event(scope, 'error', {
      ...fields,
      'error_type': error.runtimeType.toString(),
      'error': error.toString(),
      if (stackTrace != null) 'stack': stackTrace.toString(),
    });
  }

  static Object? _sanitize(Object? value, int depth) {
    if (depth >= _maxDepth) return '[MAX_DEPTH]';
    if (value is Map) {
      final entries = value.entries.take(_maxEntries);
      return {
        for (final entry in entries)
          entry.key.toString():
              _sensitiveKey.hasMatch(entry.key.toString()) &&
                  !(entry.key == 'profileComplete' && entry.value is bool)
              ? '[REDACTED]'
              : _sanitize(entry.value, depth + 1),
        if (value.length > _maxEntries) 'truncated_entries': true,
      };
    }
    if (value is Iterable) {
      final items = value.take(_maxEntries).toList();
      return [
        for (final item in items) _sanitize(item, depth + 1),
        if (value.length > _maxEntries) '[TRUNCATED]',
      ];
    }
    if (value is String) {
      var safe = value
          .replaceAll(_bearer, 'Bearer [REDACTED]')
          .replaceAll(_jwt, '[REDACTED_TOKEN]')
          .replaceAll(_email, '[REDACTED_EMAIL]')
          .replaceAll(_phone, '[REDACTED_PHONE]');
      if (safe.length > _maxStringLength) {
        safe = '${safe.substring(0, _maxStringLength)}…[TRUNCATED]';
      }
      return safe;
    }
    if (value == null || value is num || value is bool) return value;
    return value.runtimeType.toString();
  }
}
