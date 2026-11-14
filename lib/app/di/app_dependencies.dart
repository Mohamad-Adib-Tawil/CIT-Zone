import 'package:cit_zone/core/localization/generated/app_localizations_ar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../core/network/api_client.dart';
import '../../core/network/dio_api_client.dart';
import '../../features/app_status/data/api_app_availability_repository.dart';
import '../../features/app_status/data/app_config_remote_data_source.dart';
import '../../features/app_status/data/native_mobile_app_gateway.dart';
import '../../features/app_status/domain/app_availability_repository.dart';
import '../../features/app_status/presentation/cubit/app_availability_cubit.dart';
import '../../features/admin/data/demo_admin_repository.dart';
import '../../features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import '../../features/auth/data/google_identity_repository_impl.dart';
import '../../features/auth/data/firebase_google_identity_gateway.dart';
import '../../features/auth/data/student_session_gateway.dart';
import '../../features/auth/domain/google_identity_gateway.dart';
import '../../features/auth/domain/google_identity_repository.dart';
import '../../features/auth/domain/student_session_repository.dart';
import '../../features/auth/presentation/cubit/google_identity_cubit.dart';
import '../config/app_configuration.dart';
import '../app_environment.dart';

/// Private container per mounted app; feature code uses constructor injection.
class AppDependencies {
  AppDependencies({
    required this.configuration,
    GoogleIdentityGateway Function()? googleIdentityGatewayFactory,
    ApiClient Function()? apiClientFactory,
    MobileAppGateway? mobileAppGateway,
    this.sessionRepository,
  }) {
    _container.registerLazySingleton<ApiClient>(
      apiClientFactory ??
          () => DioApiClient(
            configuration.environment.apiBaseUrl,
            allowLocalHttp:
                configuration.environment.stage == AppStage.development,
          ),
      dispose: (client) => client.close(),
    );
    _container.registerLazySingleton<GoogleIdentityGateway>(
      googleIdentityGatewayFactory ?? FirebaseGoogleIdentityGateway.new,
    );
    _container.registerFactory<AppAvailabilityCubit>(
      () => AppAvailabilityCubit(
        ApiAppAvailabilityRepository(
          AppConfigRemoteDataSource(apiClient),
          mobileAppGateway ?? const NativeMobileAppGateway(),
        ),
      ),
    );
    _container.registerLazySingleton<GoogleIdentityRepository>(
      () => GoogleIdentityRepositoryImpl(_container<GoogleIdentityGateway>()),
    );
    _container.registerFactory<GoogleIdentityCubit>(
      () => GoogleIdentityCubit(
        _container<GoogleIdentityRepository>(),
        messages: AppLocalizationsAr(),
        sessions: studentSessions,
      ),
    );
  }

  final StudentSessionRepository? sessionRepository;
  late final StudentSessionRepository? studentSessions =
      sessionRepository ?? _createStudentSessions();

  StudentSessionRepository? _createStudentSessions() {
    final gateway = _container<GoogleIdentityGateway>();
    final environment = configuration.environment.apiBaseUrl;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
    if (gateway is! FirebaseGoogleIdentityGateway ||
        environment == null ||
        platform == null ||
        kIsWeb) {
      return null;
    }
    return StudentSessionGateway(
      api: apiClient,
      proofSource: gateway,
      environment: environment,
      platform: platform,
      androidDeviceId: platform == 'android'
          ? () =>
                const MethodChannel('com.devmind.cit.learn/app')
                    .invokeMethod<String>('readDeviceBindingId')
          : null,
    );
  }

  final AppConfiguration configuration;
  final GetIt _container = GetIt.asNewInstance();
  bool _disposed = false;

  ApiClient get apiClient {
    _ensureActive();
    return _container<ApiClient>();
  }

  GoogleIdentityCubit createGoogleIdentityCubit() {
    _ensureActive();
    return _container<GoogleIdentityCubit>();
  }

  AppAvailabilityCubit createAppAvailabilityCubit() {
    _ensureActive();
    return _container<AppAvailabilityCubit>();
  }

  AdminDashboardCubit createAdminPreviewCubit() {
    _ensurePreviewsAllowed();
    return AdminDashboardCubit(DemoAdminRepository());
  }

  void _ensureActive() {
    if (_disposed) throw StateError('App dependencies have been disposed');
  }

  void _ensurePreviewsAllowed() {
    _ensureActive();
    if (!kDebugMode || !configuration.previewsEnabled) {
      throw StateError('Previews are disabled');
    }
  }

  /// Cubit instances are closed by their presentation owners, not by get_it.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _container.reset();
  }
}
