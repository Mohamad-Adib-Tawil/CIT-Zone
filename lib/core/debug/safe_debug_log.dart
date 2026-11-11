import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Debug-only structured logs with common credential and personal-data fields
/// redacted before they reach the IDE console.
abstract final class SafeDebugLog {
  static const _sensitiveKey =
      r'(token|authorization|cookie|secret|password|credential|email|phone|name|photo|profile|uid|subject|id_google)';

  static void event(
    String scope,
    String message, [
    Map<String, Object?> fields = const {},
  ]) {
    if (!kDebugMode) return;
    debugPrint('[Hasobjy][$scope] $message ${jsonEncode(_redact(fields))}');
  }

  static Map<String, Object?> _redact(Map<String, Object?> values) => {
    for (final entry in values.entries)
      entry.key: RegExp(_sensitiveKey, caseSensitive: false).hasMatch(entry.key)
          ? '[REDACTED]'
          : entry.value is Map<String, Object?>
          ? _redact(entry.value! as Map<String, Object?>)
          : entry.value is List
          ? (entry.value! as List)
                .map(
                  (value) =>
                      value is Map<String, Object?> ? _redact(value) : value,
                )
                .toList()
          : entry.value,
  };
}
