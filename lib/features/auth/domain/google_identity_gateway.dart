import 'google_identity.dart';
import 'google_identity_failure.dart';

export 'google_identity_failure.dart';

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
