import 'package:cit_zone/app/cit_zone_app.dart';
import 'package:cit_zone/features/student/domain/student_models.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/student/presentation/pages/student_preview_page.dart';
import 'package:cit_zone/features/student/domain/student_repository.dart';
import 'package:cit_zone/features/student/presentation/cubit/student_catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('معاينة الطالب تتنقل بين الأقسام على هاتف صغير', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CitZoneApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('معاينة واجهة الطالب'),
      220,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text('معاينة واجهة الطالب'));
    await tester.pumpAndSettle();
    expect(find.text('مرحباً بك في CIT Zone'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('المواد'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('المواد الدراسية'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('حسابي'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ملفي الشخصي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('المادة المشتركة تظهر بدورة واحدة في المعاينة', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CitZoneApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('معاينة واجهة الطالب'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('معاينة واجهة الطالب'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('المواد'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('مقدمة البرمجة'));
    await tester.pumpAndSettle();

    expect(find.text('تفاصيل المادة'), findsOneWidget);
    expect(find.textContaining('البرمجيات · السنة الأولى'), findsOneWidget);
    expect(find.textContaining('الشبكات · السنة الأولى'), findsOneWidget);
    expect(find.text('تعرف على المادة'), findsOneWidget);
    expect(find.text('مجاني'), findsOneWidget);
  });

  test('فشل تحميل بيانات المعاينة ينتج حالة خطأ', () async {
    final cubit = StudentCatalogCubit(_FailingStudentRepository());
    await cubit.load();
    expect(cubit.state, isA<StudentCatalogFailure>());
    await cubit.close();
  });

  testWidgets('معاينة الملف تعرض هوية Google الفعلية عند توفرها', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StudentPreviewPage(
          identity: GoogleIdentity(
            displayName: 'طالبة تجريبية',
            email: 'student@example.com',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('حسابي'));
    await tester.pumpAndSettle();
    expect(find.text('طالبة تجريبية'), findsOneWidget);
    expect(find.text('student@example.com'), findsOneWidget);
    expect(find.textContaining('هذه معاينة فقط'), findsOneWidget);
  });
}

class _FailingStudentRepository implements StudentRepository {
  @override
  Future<List<StudentCourse>> loadCatalog() {
    throw StateError('unavailable');
  }
}
