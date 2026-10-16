import '../../../core/errors/result.dart';
import 'google_identity.dart';
import 'google_identity_failure.dart';

/// Google identity only. No application session, role or entitlement is issued.
abstract interface class GoogleIdentityRepository {
  bool get isConfigured;

  Future<Result<GoogleIdentity?, GoogleIdentityFailure>> restoreIdentity();
  Future<Result<GoogleIdentity, GoogleIdentityFailure>> signIn();
  Future<Result<void, GoogleIdentityFailure>> signOut();
}
