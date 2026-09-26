import 'google_identity.dart';

enum GoogleIdentityFailure { unavailable, missingToken, canceled, unexpected }

class GoogleIdentityException implements Exception {
  const GoogleIdentityException(this.failure);

  final GoogleIdentityFailure failure;
}

abstract class GoogleIdentityGateway {
  bool get isConfigured;

  Future<GoogleIdentity?> restoreIdentity();

  Future<GoogleIdentity> authenticate();

  Future<void> signOut();
}
