import '../../../core/errors/either.dart';
import 'google_identity.dart';
import 'google_identity_failure.dart';

/// Google identity only. No application session, role or entitlement is issued.
abstract interface class GoogleIdentityRepository {
  bool get isConfigured;

  Future<Either<GoogleIdentityFailure, GoogleIdentity?>> restoreIdentity();
  Future<Either<GoogleIdentityFailure, GoogleIdentity>> signIn();
  Future<Either<GoogleIdentityFailure, void>> signOut();
}
