import 'package:cit_zone/app/cit_zone_app.dart';
import 'package:cit_zone/features/admin/domain/admin_models.dart';
import 'package:cit_zone/features/admin/domain/admin_repository.dart';
import 'package:cit_zone/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('لوحة الإدارة تعرض المحتوى وتنتقل على شاشة هاتف', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CitZoneApp());
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('معاينة لوحة الإدارة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('عرض تجريبي للتصميم'), findsOneWidget);
    expect(find.text('الدورات المنشورة'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('المحتوى'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إدارة المحتوى'), findsOneWidget);
    expect(find.text('الدورات'), findsOneWidget);
  });

  testWidgets('محرر الدورة يعرض تحقق الحقول على هاتف صغير', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CitZoneApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('معاينة لوحة الإدارة'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('معاينة لوحة الإدارة'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('المحتوى'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('معاينة إنشاء دورة'));
    await tester.pumpAndSettle();

    expect(find.text('دورة جديدة'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('معاينة المسودة'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('معاينة المسودة'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل اسم المادة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('لوحة الإدارة تستخدم التنقل الجانبي على شاشة عريضة', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CitZoneApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('معاينة لوحة الإدارة'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('معاينة لوحة الإدارة'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('فشل تحميل لوحة الإدارة ينتج حالة خطأ واضحة', () async {
    final cubit = AdminDashboardCubit(_FailingAdminRepository());
    await cubit.load();
    expect(cubit.state, isA<AdminDashboardFailure>());
    await cubit.close();
  });
}

class _FailingAdminRepository implements AdminRepository {
  @override
  Future<AdminDashboardData> loadDashboard() {
    throw StateError('Backend unavailable');
  }
}
