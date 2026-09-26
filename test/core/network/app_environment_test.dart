import 'package:cit_zone/app/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('بيئة التطوير تقبل عنوان الاختبار المحلي فقط عبر HTTP', () {
    final environment = AppEnvironment.parse(
      stageName: 'development',
      apiBaseUrl: 'http://127.0.0.1:8080/api/v1',
    );
    expect(environment.stage, AppStage.development);
    expect(environment.apiBaseUrl.toString(), 'http://127.0.0.1:8080/api/v1/');
    expect(
      () => AppEnvironment.parse(
        stageName: 'development',
        apiBaseUrl: 'http://example.com/api/v1',
      ),
      throwsFormatException,
    );
  });

  test('الإنتاج لا يقبل HTTP أو وضع التطوير أو عنواناً ذا بيانات اعتماد', () {
    expect(
      () => AppEnvironment.parse(
        stageName: 'development',
        apiBaseUrl: 'https://api.example.com',
        releaseBuild: true,
      ),
      throwsFormatException,
    );
    expect(
      () => AppEnvironment.parse(
        stageName: 'production',
        apiBaseUrl: 'http://localhost:8080',
      ),
      throwsFormatException,
    );
    expect(
      () => AppEnvironment.parse(
        stageName: 'production',
        apiBaseUrl: 'https://user:password@api.example.com',
      ),
      throwsFormatException,
    );
    expect(
      AppEnvironment.parse(
        stageName: 'production',
        apiBaseUrl: 'https://api.example.com/v1',
      ).apiBaseUrl.toString(),
      'https://api.example.com/v1/',
    );
  });

  test('عنوان API غير المحدد يبقى غير مفعل دون قيمة Demo', () {
    final environment = AppEnvironment.parse(
      stageName: 'staging',
      apiBaseUrl: '',
    );
    expect(environment.hasApi, isFalse);
    expect(environment.apiBaseUrl, isNull);
  });
}
