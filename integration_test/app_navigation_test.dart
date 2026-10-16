import 'package:cit_zone/app/app_environment.dart';
import 'package:cit_zone/app/cit_zone_app.dart';
import 'package:cit_zone/app/config/app_configuration.dart';
import 'package:cit_zone/app/di/app_dependencies.dart';
import 'package:cit_zone/app/router/app_routes.dart';
import 'package:cit_zone/features/auth/presentation/pages/google_identity_page.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';
import 'package:cit_zone/features/student/presentation/pages/student_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/fake_google_identity_gateway.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native router sign-in, preview, platform back and sign-out', (
    tester,
  ) async {
    final deps = AppDependencies(
      configuration: AppConfiguration.parse(
        environment: AppEnvironment.parse(
          stageName: 'development',
          apiBaseUrl: '',
        ),
        debugBuild: true,
      ),
      googleIdentityGatewayFactory: FakeGoogleIdentityGateway.new,
    );
    addTearDown(deps.dispose);
    await tester.pumpWidget(CitZoneApp(dependencies: deps));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المتابعة عبر Google'));
    await tester.pumpAndSettle();
    expect(find.byType(GoogleIdentityPage), findsOneWidget);
    expect(find.text('بانتظار ربط حساب التطبيق'), findsOneWidget);
    await tester.ensureVisible(find.text('معاينة واجهة الطالب'));
    await tester.tap(find.text('معاينة واجهة الطالب'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentPreviewPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(GoogleIdentityPage), findsOneWidget);
    await tester.ensureVisible(find.text('الخروج من Google'));
    await tester.tap(find.text('الخروج من Google'));
    await tester.pumpAndSettle();
    final router =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
            as GoRouter;
    expect(router.state.uri.path, AppRoutes.signIn);
    expect(router.canPop(), isFalse);
    expect(find.byType(HasobjyDesignPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('native route parser blocks production preview deep link', (
    tester,
  ) async {
    final deps = AppDependencies(
      configuration: AppConfiguration.parse(
        environment: AppEnvironment.parse(
          stageName: 'production',
          apiBaseUrl: '',
        ),
        debugBuild: true,
      ),
      googleIdentityGatewayFactory: FakeGoogleIdentityGateway.new,
    );
    addTearDown(deps.dispose);
    await tester.pumpWidget(
      CitZoneApp(dependencies: deps, initialLocation: AppRoutes.adminPreview),
    );
    await tester.pumpAndSettle();
    final router =
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
            as GoRouter;
    expect(router.state.uri.path, AppRoutes.signIn);
    expect(find.byType(HasobjyDesignPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
