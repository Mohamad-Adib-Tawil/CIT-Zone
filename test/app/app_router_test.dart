import 'dart:async';

import 'package:cit_zone/app/app_environment.dart';
import 'package:cit_zone/app/cit_zone_app.dart';
import 'package:cit_zone/app/config/app_configuration.dart';
import 'package:cit_zone/app/di/app_dependencies.dart';
import 'package:cit_zone/app/router/app_routes.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/presentation/pages/google_identity_page.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';
import 'package:cit_zone/features/student/presentation/pages/student_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/fake_google_identity_gateway.dart';
import '../support/hasobjy_test_app.dart';

AppDependencies dependencies({
  AppStage stage = AppStage.development,
  bool debugBuild = true,
  FakeGoogleIdentityGateway? gateway,
}) => AppDependencies(
  configuration: AppConfiguration.parse(
    environment: AppEnvironment.parse(stageName: stage.name, apiBaseUrl: ''),
    debugBuild: debugBuild,
  ),
  googleIdentityGatewayFactory: () => gateway ?? FakeGoogleIdentityGateway(),
);

GoRouter routerOf(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
        as GoRouter;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCairoForTests);

  test(
    'containers are isolated, dispose is terminal and previews are guarded',
    () async {
      var firstCreations = 0;
      final first = AppDependencies(
        configuration: dependenciesConfiguration(),
        googleIdentityGatewayFactory: () {
          firstCreations++;
          return FakeGoogleIdentityGateway();
        },
      );
      final second = dependencies(stage: AppStage.production);
      final secondCubit = second.createGoogleIdentityCubit();
      expect(firstCreations, 0);
      await secondCubit.signIn();
      expect(() => second.createStudentPreviewCubit(), throwsStateError);
      expect(() => second.createAdminPreviewCubit(), throwsStateError);
      await first.dispose();
      expect(firstCreations, 0);
      expect(() => first.createGoogleIdentityCubit(), throwsStateError);
      await secondCubit.signOut();
      await secondCubit.close();
      await second.dispose();
      await first.dispose();
    },
  );

  for (final route in [
    AppRoutes.studentPreview,
    AppRoutes.adminPreview,
    AppRoutes.frame('B-S06'),
  ]) {
    for (final debugBuild in [true, false]) {
      testWidgets('production blocks direct link $route (debug=$debugBuild)', (
        tester,
      ) async {
        final deps = dependencies(
          stage: AppStage.production,
          debugBuild: debugBuild,
        );
        addTearDown(deps.dispose);
        await tester.pumpWidget(
          CitZoneApp(dependencies: deps, initialLocation: route),
        );
        await tester.pumpAndSettle();
        expect(
          routerOf(tester).routeInformationProvider.value.uri.path,
          AppRoutes.signIn,
        );
        expect(
          tester
              .widget<HasobjyDesignPage>(find.byType(HasobjyDesignPage))
              .frameId,
          HasobjyFrameId.aS01,
        );
        expect(find.byType(StudentPreviewPage), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('identity link waits for restoration without issuing a session', (
    tester,
  ) async {
    final restore = Completer<GoogleIdentity?>();
    final deps = dependencies(
      stage: AppStage.production,
      gateway: FakeGoogleIdentityGateway(restore: () => restore.future),
    );
    addTearDown(deps.dispose);
    await tester.pumpWidget(
      CitZoneApp(dependencies: deps, initialLocation: AppRoutes.googleIdentity),
    );
    await tester.pump();
    expect(
      routerOf(tester).routeInformationProvider.value.uri.path,
      AppRoutes.signIn,
    );
    restore.complete(FakeGoogleIdentityGateway.identity);
    await tester.pumpAndSettle();
    expect(
      routerOf(tester).routeInformationProvider.value.uri.path,
      AppRoutes.googleIdentity,
    );
    expect(find.text('بانتظار ربط حساب التطبيق'), findsOneWidget);
    expect(find.text('معاينة واجهة الطالب'), findsNothing);
  });

  testWidgets('unknown and invalid frame links recover without exception UI', (
    tester,
  ) async {
    final deps = dependencies();
    addTearDown(deps.dispose);
    await tester.pumpWidget(
      CitZoneApp(dependencies: deps, initialLocation: '/unknown'),
    );
    await tester.pumpAndSettle();
    final router = routerOf(tester);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
    router.go(AppRoutes.frame('missing-frame'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'sign-in redirects, preview push/back restores identity, logout clears history',
    (tester) async {
      final gateway = FakeGoogleIdentityGateway();
      final deps = dependencies(gateway: gateway);
      addTearDown(deps.dispose);
      await tester.pumpWidget(CitZoneApp(dependencies: deps));
      await tester.pumpAndSettle();
      await tester.tap(find.text('المتابعة عبر Google'));
      await tester.pumpAndSettle();
      final router = routerOf(tester);
      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.googleIdentity,
      );
      await tester.tap(find.text('معاينة واجهة الطالب'));
      await tester.pumpAndSettle();
      expect(find.byType(StudentPreviewPage), findsOneWidget);
      expect(router.canPop(), isTrue);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(GoogleIdentityPage), findsOneWidget);
      await tester.tap(find.text('الخروج من Google'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
      expect(router.canPop(), isFalse);
      router.go(AppRoutes.googleIdentity);
      await tester.pumpAndSettle();
      expect(find.byType(GoogleIdentityPage), findsNothing);
      expect(gateway.signOutCalls, 1);
    },
  );

  testWidgets(
    'failed logout stays on identity route while request is pending',
    (tester) async {
      final logout = Completer<void>();
      final deps = dependencies(
        gateway: FakeGoogleIdentityGateway(
          restore: () async => FakeGoogleIdentityGateway.identity,
          logout: () => logout.future,
        ),
      );
      addTearDown(deps.dispose);
      await tester.pumpWidget(CitZoneApp(dependencies: deps));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الخروج من Google'));
      await tester.pump();
      expect(
        routerOf(tester).routeInformationProvider.value.uri.path,
        AppRoutes.googleIdentity,
      );
      logout.completeError(StateError('private-token'));
      await tester.pumpAndSettle();
      expect(find.byType(GoogleIdentityPage), findsOneWidget);
      expect(
        find.text('تعذر تسجيل الخروج من Google. حاول مجدداً.'),
        findsOneWidget,
      );
      expect(find.textContaining('private-token'), findsNothing);
    },
  );

  testWidgets('design preview navigation uses router stack and platform back', (
    tester,
  ) async {
    final deps = dependencies();
    addTearDown(deps.dispose);
    await tester.pumpWidget(
      CitZoneApp(dependencies: deps, initialLocation: AppRoutes.frame('A-S03')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();
    final router = routerOf(tester);
    expect(router.state.uri.path, AppRoutes.frame('A-S04'));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRoutes.frame('A-S03'),
    );
    expect(tester.takeException(), isNull);
  });
}

AppConfiguration dependenciesConfiguration() => AppConfiguration.parse(
  environment: AppEnvironment.parse(stageName: 'development', apiBaseUrl: ''),
  debugBuild: true,
);
