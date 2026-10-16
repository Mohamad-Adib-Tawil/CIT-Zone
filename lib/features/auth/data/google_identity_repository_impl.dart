import '../../../core/errors/result.dart';
import '../domain/google_identity.dart';
import '../domain/google_identity_gateway.dart';
import '../domain/google_identity_repository.dart';

final class GoogleIdentityRepositoryImpl implements GoogleIdentityRepository {
  const GoogleIdentityRepositoryImpl(this._gateway);

  final GoogleIdentityGateway _gateway;

  @override
  bool get isConfigured => _gateway.isConfigured;

  @override
  Future<Result<GoogleIdentity?, GoogleIdentityFailure>> restoreIdentity() =>
      _capture(_gateway.restoreIdentity);

  @override
  Future<Result<GoogleIdentity, GoogleIdentityFailure>> signIn() =>
      _capture(_gateway.authenticate);

  @override
  Future<Result<void, GoogleIdentityFailure>> signOut() =>
      _capture(_gateway.signOut);

  Future<Result<T, GoogleIdentityFailure>> _capture<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return Success(await operation());
    } on GoogleIdentityException catch (error) {
      return Failure(error.failure);
    } catch (_) {
      // Never forward SDK exceptions, tokens or raw messages to presentation.
      return const Failure(GoogleIdentityFailure.unexpected);
    }
  }
}
