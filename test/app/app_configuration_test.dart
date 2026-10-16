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

  test('build configuration uses the validated environment', () {
    final configuration = AppConfiguration.fromBuild();
    expect(configuration.environment.stage, AppStage.development);
    expect(configuration.environment.apiBaseUrl, isNull);
    expect(configuration.previewFrameName, isEmpty);
  });
}
