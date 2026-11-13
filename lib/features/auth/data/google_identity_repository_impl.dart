import '../../../core/errors/either.dart';
import '../domain/google_identity.dart';
import '../domain/google_identity_gateway.dart';
import '../domain/google_identity_repository.dart';

final class GoogleIdentityRepositoryImpl implements GoogleIdentityRepository {
  GoogleIdentityRepositoryImpl(this._gateway);

  final GoogleIdentityGateway _gateway;
  @override
  bool get isConfigured => _gateway.isConfigured;

  @override
  Future<Either<GoogleIdentityFailure, GoogleIdentity?>> restoreIdentity() =>
      _capture(_gateway.restoreIdentity);

  @override
  Future<Either<GoogleIdentityFailure, GoogleIdentity>> signIn() =>
      _capture(_gateway.authenticate);

  @override
  Future<Either<GoogleIdentityFailure, void>> signOut() =>
      _capture(_gateway.signOut);

  Future<Either<GoogleIdentityFailure, T>> _capture<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return Right(await operation());
    } on GoogleIdentityException catch (error) {
      return Left(error.failure);
    } catch (_) {
      // Never forward SDK exceptions, tokens or raw messages to presentation.
      return const Left(GoogleIdentityFailure.unexpected);
    }
  }
}
