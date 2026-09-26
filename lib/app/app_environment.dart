enum AppStage { development, staging, production }

class AppEnvironment {
  AppEnvironment._({required this.stage, required this.apiBaseUrl});

  final AppStage stage;
  final Uri? apiBaseUrl;

  bool get hasApi => apiBaseUrl != null;

  factory AppEnvironment.fromBuild() => AppEnvironment.parse(
    stageName: const String.fromEnvironment(
      'APP_ENV',
      defaultValue: bool.fromEnvironment('dart.vm.product')
          ? 'production'
          : 'development',
    ),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    releaseBuild: const bool.fromEnvironment('dart.vm.product'),
  );

  factory AppEnvironment.parse({
    required String stageName,
    required String apiBaseUrl,
    bool releaseBuild = false,
  }) {
    final stage = switch (stageName) {
      'development' => AppStage.development,
      'staging' => AppStage.staging,
      'production' => AppStage.production,
      _ => throw const FormatException('Invalid APP_ENV'),
    };
    if (releaseBuild && stage == AppStage.development) {
      throw const FormatException(
        'Release build requires staging or production',
      );
    }
    if (apiBaseUrl.trim().isEmpty) {
      return AppEnvironment._(stage: stage, apiBaseUrl: null);
    }

    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Invalid API_BASE_URL');
    }

    final localDevelopment =
        stage == AppStage.development &&
        uri.scheme == 'http' &&
        const {'localhost', '127.0.0.1', '::1'}.contains(uri.host);
    if (uri.scheme != 'https' && !localDevelopment) {
      throw const FormatException('API_BASE_URL must use HTTPS');
    }

    final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return AppEnvironment._(
      stage: stage,
      apiBaseUrl: uri.replace(path: path),
    );
  }
}
