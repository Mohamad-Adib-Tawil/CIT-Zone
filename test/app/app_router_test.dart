import 'dart:async';

import 'package:cit_zone/app/app_environment.dart';
import 'package:cit_zone/app/cit_zone_app.dart';
import 'package:cit_zone/app/config/app_configuration.dart';
import 'package:cit_zone/app/di/app_dependencies.dart';
import 'package:cit_zone/app/router/app_routes.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/presentation/pages/google_identity_page.dart';
import 'package:cit_zone/features/admin/presentation/admin_figma_preview_page.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_frame_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../support/fake_google_identity_gateway.dart';
import '../support/hasobjy_test_app.dart';
import '../support/fake_app_availability.dart';

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
  apiClientFactory: FakeAvailableApiClient.new,
  mobileAppGateway: FakeMobileAppGateway(),
);

GoRouter routerOf(WidgetTester tester) =>
    tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
        as GoRouter;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCairoForTests);

  testWidgets('welcome opens the public privacy tab and returns to sign-in', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final deps = dependencies();
    addTearDown(deps.dispose);
    await tester.pumpWidget(CitZoneApp(dependencies: deps));
    await tester.pumpAndSettle();

    const label = 'سياسة الخصوصية';
    final notice = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.textSpan?.toPlainText().contains(label) == true,
    );
    await tester.ensureVisible(notice);
    final paragraph = tester.renderObject<RenderParagraph>(notice);
    final start = paragraph.text.toPlainText().indexOf(label);
    final box = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: start + label.length),
        )
        .first;
    await tester.tapAt(paragraph.localToGlobal(box.toRect().center));
    await tester.pumpAndSettle();

    expect(find.text('سياسة الخصوصية غير متاحة حالياً.'), findsOneWidget);
    await tester.tap(find.text('فهمت'));
    await tester.pumpAndSettle();
    expect(find.byType(HasobjyDesignPage), findsOneWidget);
    expect(find.text('سياسة الخصوصية غير متاحة حالياً.'), findsNothing);
    expect(
      routerOf(tester).routeInformationProvider.value.uri.path,
      AppRoutes.signIn,
    );
  });

  testWidgets(
    'production cannot skip availability when API configuration is missing',
    (tester) async {
      final deps = AppDependencies(
        configuration: AppConfiguration.parse(
          environment: AppEnvironment.parse(
            stageName: 'production',
            apiBaseUrl: '',
          ),
          debugBuild: false,
        ),
        googleIdentityGatewayFactory: FakeGoogleIdentityGateway.new,
        mobileAppGateway: FakeMobileAppGateway(),
      );
      addTearDown(deps.dispose);
      await tester.pumpWidget(CitZoneApp(dependencies: deps));
      await tester.pumpAndSettle();
      expect(find.byType(HasobjyDesignPage), findsNothing);
      expect(find.byType(GoogleIdentityPage), findsNothing);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    },
  );

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
    AppRoutes.designGallery,
    AppRoutes.adminPreview,
    AppRoutes.adminFigmaGallery,
    AppRoutes.adminFrame('M-A03', light: false),
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
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('gallery build starts in the Figma inspector', (tester) async {
    final deps = AppDependencies(
      configuration: AppConfiguration.parse(
        environment: AppEnvironment.parse(
          stageName: 'development',
          apiBaseUrl: '',
        ),
        debugBuild: true,
        previewFrameName: 'FIGMA_GALLERY',
      ),
      googleIdentityGatewayFactory: () => FakeGoogleIdentityGateway(),
    );
    addTearDown(deps.dispose);
    await tester.pumpWidget(CitZoneApp(dependencies: deps));
    await tester.pumpAndSettle();
    expect(
      routerOf(tester).routeInformationProvider.value.uri.path,
      AppRoutes.designGallery,
    );
    expect(find.byType(HasobjyFrameGalleryPage), findsOneWidget);
  });

  testWidgets('admin Figma gallery opens a debug-only frame without backend', (
    tester,
  ) async {
    final deps = dependencies();
    addTearDown(deps.dispose);
    await tester.pumpWidget(
      CitZoneApp(dependencies: deps, initialLocation: AppRoutes.designGallery),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('شاشات الإدارة من Figma — 30 شاشة'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminFigmaGalleryPage), findsOneWidget);
    final frameButton = find.text('داكن · 96:199');
    await tester.ensureVisible(frameButton);
    await tester.pumpAndSettle();
    await tester.tap(frameButton);
    await tester.pumpAndSettle();
    expect(find.byType(AdminFigmaPreviewPage), findsOneWidget);
    expect(find.text('إدارة حسابات طلاب المعهد'), findsOneWidget);
    expect(
      routerOf(tester).state.uri.path,
      AppRoutes.adminFigmaFrame.replaceAll(':frame', 'M-A03'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Figma gallery opens actual frames without server verification', (
    tester,
  ) async {
    final deps = dependencies();
    addTearDown(deps.dispose);
    await tester.pumpWidget(
      CitZoneApp(dependencies: deps, initialLocation: AppRoutes.designGallery),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HasobjyFrameGalleryPage), findsOneWidget);
    await tester.tap(find.text('افتح الرئيسية من Figma — C-01'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<HasobjyDesignPage>(find.byType(HasobjyDesignPage)).frameId,
      HasobjyFrameId.c01,
    );
    expect(find.text('مرحباً أحمد'), findsOneWidget);
    routerOf(tester).pop();
    await tester.pumpAndSettle();
    expect(find.byType(HasobjyFrameGalleryPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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
    for (final invalid in [
      AppRoutes.frame('missing-frame'),
      AppRoutes.frame('M-A03'),
      AppRoutes.adminFrame('C-01', light: false),
      AppRoutes.adminFrame('missing-frame', light: true),
    ]) {
      router.go(invalid);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'sign-in opens Figma preview, platform back and logout clear history',
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
      await tester.tap(find.text('عرض شاشات Figma — دون خادم'));
      await tester.pumpAndSettle();
      expect(find.byType(HasobjyFrameGalleryPage), findsOneWidget);
      expect(router.canPop(), isTrue);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(GoogleIdentityPage), findsOneWidget);
      await tester.ensureVisible(find.text('الخروج من Google'));
      await tester.pumpAndSettle();
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
      await tester.ensureVisible(find.text('الخروج من Google'));
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
