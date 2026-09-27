import 'package:cit_zone/features/admin/data/demo_admin_repository.dart';
import 'package:cit_zone/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:cit_zone/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:cit_zone/features/auth/presentation/pages/welcome_page.dart';
import 'package:cit_zone/features/student/presentation/pages/student_preview_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('شاشة الترحيب تحقق تسميات وأحجام لمس Android', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomePage(
          googleConfigured: true,
          working: false,
          onGoogleSignIn: () {},
          onStudentPreview: () {},
          onAdminPreview: () {},
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('واجهة الطالب لا تنهار مع تكبير النص والتنقل الأساسي', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const MaterialApp(home: StudentPreviewPage()));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('لوحة الإدارة تحقق إرشادات تسميات وأحجام اللمس', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AdminDashboardCubit(DemoAdminRepository())..load(),
        child: const MaterialApp(home: AdminDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
