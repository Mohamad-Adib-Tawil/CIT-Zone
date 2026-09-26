import 'package:cit_zone/features/admin/domain/admin_models.dart';
import 'package:cit_zone/features/admin/presentation/pages/course_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('معاينة إضافة درس تُظهر تحقق الحقول والمجانية للأول', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final course = AdminCourse(
      id: 'demo-course',
      subject: 'مادة تجريبية',
      code: 'DEMO',
      instructor: 'أستاذ تجريبي',
      description: 'للاختبار',
      status: AdminCourseStatus.draft,
      departments: const ['البرمجيات'],
      lessons: const [],
      updatedAt: DateTime.utc(2026, 9, 26),
    );

    await tester.pumpWidget(
      MaterialApp(home: CourseDetailsPage(course: course)),
    );
    await tester.tap(find.text('معاينة إضافة درس'));
    await tester.pumpAndSettle();
    expect(find.text('درس جديد'), findsOneWidget);
    expect(
      find.text('الدرس الأول فقط مجاني في خطة النسخة الأولى'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('معاينة بيانات الدرس'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('معاينة بيانات الدرس'));
    await tester.pumpAndSettle();
    expect(find.text('أدخل عنوان الدرس'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
