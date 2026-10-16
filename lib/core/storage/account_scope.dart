import 'dart:convert';

/// A backend account identifier, never an email, role or local authorization.
final class AccountScope {
  AccountScope(this.id) {
    if (id.isEmpty ||
        id.length > 256 ||
        id.trim() != id ||
        RegExp(r'[\x00-\x1f\x7f]').hasMatch(id)) {
      throw ArgumentError('A non-empty bounded account identifier is required');
    }
  }

  final String id;
  String get storageKey => base64Url.encode(utf8.encode(id));
}
