import '../../../core/errors/either.dart';
import '../../../core/network/api_cancellation_token.dart';
import '../../../core/network/api_failure.dart';
import '../domain/app_availability.dart';
import '../domain/app_availability_repository.dart';
import 'app_config_remote_data_source.dart';

final class ApiAppAvailabilityRepository implements AppAvailabilityRepository {
  ApiAppAvailabilityRepository(this._source, this._gateway);
  final AppConfigRemoteDataSource _source;
  final MobileAppGateway _gateway;
  ApiCancellationToken? _request;

  @override
  Future<Either<AppAvailabilityFailure, AppAvailability>> check() async {
    cancel();
    final request = ApiCancellationToken();
    _request = request;
    try {
      final info = await _gateway.readInfo();
      if (request.isCanceled) {
        return const Left(AppAvailabilityFailure.unavailable);
      }
      return Right(await _source.fetch(info, cancellationToken: request));
    } on ApiFailure catch (error) {
      if (request.isCanceled) {
        return const Left(AppAvailabilityFailure.unavailable);
      }
      if (error.code == 'APP_UPDATE_REQUIRED') {
        return const Right(AppAvailability(AppAvailabilityKind.updateRequired));
      }
      if (error.code == 'MAINTENANCE') {
        return const Right(AppAvailability(AppAvailabilityKind.maintenance));
      }
      return Left(switch (error.kind) {
        ApiFailureKind.network ||
        ApiFailureKind.timeout => AppAvailabilityFailure.network,
        ApiFailureKind.invalidResponse =>
          AppAvailabilityFailure.invalidResponse,
        _ => AppAvailabilityFailure.unavailable,
      });
    } on FormatException {
      return const Left(AppAvailabilityFailure.invalidResponse);
    } catch (_) {
      return const Left(AppAvailabilityFailure.unavailable);
    } finally {
      if (identical(_request, request)) _request = null;
    }
  }

  @override
  Future<bool> openStore(Uri url) async {
    if (!isAppStoreUrl(url)) return false;
    try {
      return await _gateway.openStore(url);
    } catch (_) {
      return false;
    }
  }

  @override
  void cancel() {
    _request?.cancel();
    _request = null;
  }
}
