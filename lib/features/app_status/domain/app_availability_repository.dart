import '../../../core/errors/either.dart';
import 'app_availability.dart';

abstract interface class AppAvailabilityRepository {
  Future<Either<AppAvailabilityFailure, AppAvailability>> check();
  Future<bool> openStore(Uri url);
  void cancel();
}

abstract interface class MobileAppGateway {
  Future<MobileAppInfo> readInfo();
  Future<bool> openStore(Uri url);
}
