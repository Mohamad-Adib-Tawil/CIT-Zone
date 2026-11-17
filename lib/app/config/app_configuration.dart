import 'package:flutter/foundation.dart';

import '../app_environment.dart';

/// Public build configuration only. Never put session or service secrets here.
class AppConfiguration {
  const AppConfiguration._({
    required this.environment,
    required this.previewsEnabled,
    required this.previewFrameName,
    required this.privacyPolicyUrl,
  });

  final AppEnvironment environment;
  final bool previewsEnabled;
  final String previewFrameName;
  final Uri? privacyPolicyUrl;

  factory AppConfiguration.fromBuild() => AppConfiguration.parse(
    environment: AppEnvironment.fromBuild(),
    debugBuild: kDebugMode,
    previewFrameName: const String.fromEnvironment('HASOBJY_FRAME'),
    privacyPolicyUrl: const String.fromEnvironment(
      'HASOBJY_PRIVACY_POLICY_URL',
    ),
  );

  factory AppConfiguration.parse({
    required AppEnvironment environment,
    required bool debugBuild,
    String previewFrameName = '',
    String privacyPolicyUrl = '',
  }) {
    final previewsEnabled =
        debugBuild && environment.stage == AppStage.development;
    return AppConfiguration._(
      environment: environment,
      previewsEnabled: previewsEnabled,
      previewFrameName: previewsEnabled ? previewFrameName : '',
      privacyPolicyUrl: _parsePrivacyPolicyUrl(privacyPolicyUrl),
    );
  }
  static Uri? _parsePrivacyPolicyUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.authority.contains('@')) {
      return null;
    }
    return uri;
  }
}
