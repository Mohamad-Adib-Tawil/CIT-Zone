import 'package:cit_zone/app/app_environment.dart';
import 'package:cit_zone/app/config/app_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final stage in AppStage.values) {
    for (final debugBuild in [true, false]) {
      test('preview policy: ${stage.name}, debug=$debugBuild', () {
        final configuration = AppConfiguration.parse(
          environment: AppEnvironment.parse(
            stageName: stage.name,
            apiBaseUrl: '',
          ),
          debugBuild: debugBuild,
          previewFrameName: 'ADMIN_PREVIEW',
        );
        final allowed = debugBuild && stage == AppStage.development;
        expect(configuration.previewsEnabled, allowed);
        expect(configuration.previewFrameName, allowed ? 'ADMIN_PREVIEW' : '');
        expect(configuration.environment.hasApi, isFalse);
      });
    }
  }

  test('privacy policy accepts only a credential-free HTTPS URL', () {
    final environment = AppEnvironment.parse(
      stageName: 'production',
      apiBaseUrl: '',
    );
    Uri? policy(String value) => AppConfiguration.parse(
      environment: environment,
      debugBuild: false,
      privacyPolicyUrl: value,
    ).privacyPolicyUrl;

    expect(
      policy(' https://example.org/privacy '),
      Uri.parse('https://example.org/privacy'),
    );
    for (final invalid in [
      '',
      '/privacy',
      'http://example.org',
      'https://user@example.org/privacy',
      'javascript:alert(1)',
      'https:///privacy',
    ]) {
      expect(policy(invalid), isNull, reason: invalid);
    }
  });

  test('build configuration uses the validated environment', () {
    final configuration = AppConfiguration.fromBuild();
    expect(configuration.environment.stage, AppStage.development);
    expect(
      configuration.environment.apiBaseUrl,
      Uri.parse('https://hasobjy-system-api.vercel.app/api/v1/'),
    );
    expect(configuration.previewFrameName, isEmpty);
  });
}
