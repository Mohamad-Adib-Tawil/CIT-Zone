import 'package:flutter/foundation.dart';

import '../app_environment.dart';

/// Public build configuration only. Never put session or service secrets here.
class AppConfiguration {
  const AppConfiguration._({
    required this.environment,
    required this.previewsEnabled,
    required this.previewFrameName,
  });

  final AppEnvironment environment;
  final bool previewsEnabled;
  final String previewFrameName;

  factory AppConfiguration.fromBuild() => AppConfiguration.parse(
    environment: AppEnvironment.fromBuild(),
    debugBuild: kDebugMode,
    previewFrameName: const String.fromEnvironment('HASOBJY_FRAME'),
  );

  factory AppConfiguration.parse({
    required AppEnvironment environment,
    required bool debugBuild,
    String previewFrameName = '',
  }) {
    final previewsEnabled =
        debugBuild && environment.stage == AppStage.development;
    return AppConfiguration._(
      environment: environment,
      previewsEnabled: previewsEnabled,
      previewFrameName: previewsEnabled ? previewFrameName : '',
    );
  }
}
