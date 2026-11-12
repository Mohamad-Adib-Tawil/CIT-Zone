import '../../../core/errors/either.dart';
import '../domain/google_identity.dart';
import '../domain/google_identity_gateway.dart';
import '../domain/google_identity_repository.dart';
import 'student_session_gateway.dart';

final class GoogleIdentityRepositoryImpl implements GoogleIdentityRepository {
  GoogleIdentityRepositoryImpl(this._gateway, {this._session});

  final GoogleIdentityGateway _gateway;
  final StudentSessionGateway? _session;
  GoogleIdentity? _activeIdentity;

  @override
  bool get isConfigured => _gateway.isConfigured;

  @override
  Future<Either<GoogleIdentityFailure, GoogleIdentity?>> restoreIdentity() =>
      _capture(() async {
        final identity = await _gateway.restoreIdentity();
        if (identity == null) return null;
        final session = _session;
        if (session != null && !await session.restore(identity)) return null;
        return _activeIdentity = identity;
      });

  @override
  Future<Either<GoogleIdentityFailure, GoogleIdentity>> signIn() =>
      _capture(() async {
        final identity = await _gateway.authenticate();
        await _session?.start(identity);
        return _activeIdentity = identity;
      });

  @override
  Future<Either<GoogleIdentityFailure, void>> signOut() => _capture(() async {
    final identity = _activeIdentity;
    if (identity != null) await _session?.end(identity);
    await _gateway.signOut();
    _activeIdentity = null;
  });

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
