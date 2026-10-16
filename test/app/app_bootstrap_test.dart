import 'dart:async';

import 'package:cit_zone/app/app_environment.dart';
import 'package:cit_zone/app/bootstrap/app_bootstrap.dart';
import 'package:cit_zone/app/config/app_configuration.dart';
import 'package:cit_zone/app/di/app_dependencies.dart';
import 'package:cit_zone/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/domain/google_identity_gateway.dart';
import 'package:cit_zone/features/auth/presentation/cubit/google_identity_cubit.dart';
import 'package:cit_zone/features/auth/presentation/pages/google_identity_page.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';
import 'package:cit_zone/features/student/presentation/pages/student_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/hasobjy_test_app.dart';

AppConfiguration configuration({
  AppStage stage = AppStage.development,
  bool debugBuild = true,
  String frame = '',
}) => AppConfiguration.parse(
  environment: AppEnvironment.parse(stageName: stage.name, apiBaseUrl: ''),
  debugBuild: debugBuild,
  previewFrameName: frame,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCairoForTests);

  test(
    'composition is lazy and shares only gateway, never Cubit state',
    () async {
      var creations = 0;
      final dependencies = AppDependencies(
        configuration: configuration(),
        googleIdentityGatewayFactory: () {
          creations++;
          return TestIdentityGateway();
        },
      );
      expect(creations, 0);
      final first = dependencies.createGoogleIdentityCubit();
      final second = dependencies.createGoogleIdentityCubit();
      expect(creations, 1);
      expect(identical(first, second), isFalse);
      await first.signIn();
      expect(first.state, isA<GoogleIdentityReady>());
      expect(second.state, isA<GoogleIdentityIdle>());
      await first.close();
      await second.close();
      await dependencies.dispose();
    },
  );

  testWidgets('rebuild retains dependencies; unmount closes pending Cubit', (
    tester,
  ) async {
    final restored = Completer<GoogleIdentity?>();
    final gateway = TestIdentityGateway(restore: () => restored.future);
    var creations = 0;
    Widget app() => AppBootstrap(
      configuration: configuration(),
      googleIdentityGatewayFactory: () {
        creations++;
        return gateway;
      },
    );
    await tester.pumpWidget(app());
    final cubit = tester
        .element(find.byType(HasobjyDesignPage))
        .read<GoogleIdentityCubit>();
    expect(cubit.state, isA<GoogleIdentityWorking>());
    await tester.pumpWidget(app());
    expect(creations, 1);
    expect(gateway.restoreCalls, 1);
    expect(
      tester
          .element(find.byType(HasobjyDesignPage))
          .read<GoogleIdentityCubit>(),
      same(cubit),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(cubit.isClosed, isTrue);
    restored.complete(TestIdentityGateway.identity);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Google identity restores and signs out without server session', (
    tester,
  ) async {
    final gateway = TestIdentityGateway(
      restore: () async => TestIdentityGateway.identity,
    );
    await tester.pumpWidget(
      AppBootstrap(
        configuration: configuration(stage: AppStage.production),
        googleIdentityGatewayFactory: () => gateway,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GoogleIdentityPage), findsOneWidget);
    expect(find.text('بانتظار ربط حساب التطبيق'), findsOneWidget);
    expect(find.text('معاينة واجهة الطالب'), findsNothing);
    expect(find.byType(StudentPreviewPage), findsNothing);
    await tester.tap(find.text('الخروج من Google'));
    await tester.pumpAndSettle();
    expect(gateway.signOutCalls, 1);
    expect(find.byType(GoogleIdentityPage), findsNothing);
    expect(find.byType(HasobjyDesignPage), findsOneWidget);
  });

  for (final frame in ['ADMIN_PREVIEW', 'STUDENT_PREVIEW', 'B-S06']) {
    for (final config in [
      configuration(stage: AppStage.production, frame: frame),
      configuration(debugBuild: false, frame: frame),
    ]) {
      testWidgets('blocked preview $frame: ${config.environment.stage.name}', (
        tester,
      ) async {
        await tester.pumpWidget(
          AppBootstrap(
            configuration: config,
            googleIdentityGatewayFactory: () => TestIdentityGateway(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(StudentPreviewPage), findsNothing);
        expect(find.byType(AdminDashboardPage), findsNothing);
        expect(
          tester
              .widget<HasobjyDesignPage>(find.byType(HasobjyDesignPage))
              .frameId,
          HasobjyFrameId.aS01,
        );
      });
    }
  }

  for (final frame in ['ADMIN_PREVIEW', 'STUDENT_PREVIEW', 'B-S06']) {
    testWidgets('development keeps explicit preview $frame', (tester) async {
      await tester.pumpWidget(
        AppBootstrap(
          configuration: configuration(frame: frame),
          googleIdentityGatewayFactory: () => TestIdentityGateway(),
        ),
      );
      await tester.pumpAndSettle();
      switch (frame) {
        case 'ADMIN_PREVIEW':
          expect(find.byType(AdminDashboardPage), findsOneWidget);
        case 'STUDENT_PREVIEW':
          expect(find.byType(StudentPreviewPage), findsOneWidget);
        default:
          expect(
            tester
                .widget<HasobjyDesignPage>(find.byType(HasobjyDesignPage))
                .frameId,
            HasobjyFrameId.bS06,
          );
      }
      expect(tester.takeException(), isNull);
    });
  }
}

class TestIdentityGateway implements GoogleIdentityGateway {
  TestIdentityGateway({this.restore});

  final Future<GoogleIdentity?> Function()? restore;
  int restoreCalls = 0;
  int signOutCalls = 0;
  static const identity = GoogleIdentity(
    displayName: 'طالب',
    email: 'student@example.com',
  );

  @override
  bool get isConfigured => true;

  @override
  Future<GoogleIdentity?> restoreIdentity() async {
    restoreCalls++;
    return restore == null ? null : await restore!();
  }

  @override
  Future<GoogleIdentity> authenticate() async => identity;

  @override
  Future<void> signOut() async => signOutCalls++;
}
