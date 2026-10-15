import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';

void main() {
  const frames = <HasobjyFrameId, String>{
    HasobjyFrameId.aS01: 'مرحباً بك في حاسوبجي سيستم',
    HasobjyFrameId.aS03: 'كيف ستستخدم التطبيق؟',
    HasobjyFrameId.aS04: 'معلوماتك الأساسية',
    HasobjyFrameId.aS05: 'هذا الحساب مرتبط بجهاز آخر',
    HasobjyFrameId.aS06: 'طلب تغيير الجهاز',
    HasobjyFrameId.aS07: 'طلبك قيد المراجعة',
    HasobjyFrameId.bS01: 'معلوماتك الأكاديمية',
    HasobjyFrameId.bS03: 'راجع بياناتك قبل الحفظ',
    HasobjyFrameId.bS04: 'بدأ الفصل الرابع',
    HasobjyFrameId.bS05: 'حالات رأس الصفحة الأكاديمي',
    HasobjyFrameId.bS06: 'جدول الامتحانات',
  };

  for (final entry in frames.entries) {
    testWidgets('${entry.key.frameName} displays its Figma screen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ar'),
          home: HasobjyDesignPage(frameId: entry.key),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
