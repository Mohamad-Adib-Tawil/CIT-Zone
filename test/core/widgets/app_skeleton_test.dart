import 'package:cit_zone/core/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hasobjy_test_app.dart';

void main() {
  testWidgets('exposes one loading label and schedules no animation frames', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      arabicTestApp(
        Directionality(
          textDirection: TextDirection.rtl,
          child: AppSkeleton(
            child: Column(
              children: [
                const SkeletonBlock(width: 120, height: 24),
                Semantics(label: 'decorative placeholder'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('جارٍ تحميل المحتوى'), findsOneWidget);
    expect(find.bySemanticsLabel('decorative placeholder'), findsNothing);
    expect(tester.getSize(find.byType(SkeletonBlock)), const Size(120, 24));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    semantics.dispose();
  });
}
