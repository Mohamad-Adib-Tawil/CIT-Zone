import 'package:cit_zone/features/lesson_ratings/presentation/cubit/rating_selection_cubit.dart';
import 'package:cit_zone/features/lesson_ratings/presentation/widgets/lesson_rating_sheet.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/preview/student_update_scaffold.dart';
import 'package:cit_zone/features/onboarding/presentation/theme/hasobjy_visual_scope.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_figma_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hasobjy_test_app.dart';

void main() {
  setUpAll(loadCairoForTests);
  for (final sample in const [
    (HasobjyFrameId.s05, [(116.0, 118.0), (250.0, 196.0), (462.0, 230.0)]),
    (HasobjyFrameId.g03, [(116.0, 380.0)]),
    (
      HasobjyFrameId.f07,
      [(116.0, 24.0), (152.0, 155.0), (319.0, 24.0), (355.0, 155.0)],
    ),
  ]) {
    testWidgets(
      '${sample.$1.frameName} matches current Figma content geometry at 390',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          arabicTestApp(
            HasobjyDesignPage(frameId: sample.$1, referenceViewport: true),
          ),
        );
        await tester.pumpAndSettle();
        final scaffold = tester.widget<StudentUpdateScaffold>(
          find.byType(StudentUpdateScaffold),
        );
        for (var i = 0; i < sample.$2.length; i++) {
          final rect = tester.getRect(find.byWidget(scaffold.children[i]));
          expect(rect.top, closeTo(sample.$2[i].$1, 1));
          expect(rect.height, closeTo(sample.$2[i].$2, 1));
          expect(rect.left, 24);
          expect(rect.width, 342);
        }
      },
    );
  }
  test(
    'rating selection accepts only 1–5 without inventing a saved rating',
    () {
      final cubit = RatingSelectionCubit();
      addTearDown(cubit.close);
      expect(cubit.state, isNull);
      expect(() => cubit.select(0), throwsRangeError);
      expect(() => cubit.select(6), throwsRangeError);
      cubit.select(5);
      expect(cubit.state, 5);
    },
  );

  testWidgets('rating sheet requires selection and delegates saving to owner', (
    tester,
  ) async {
    final cubit = RatingSelectionCubit();
    addTearDown(cubit.close);
    int? submitted;
    await tester.pumpWidget(
      arabicTestApp(
        HasobjyVisualScope(
          frameName: 'C-09',
          child: Scaffold(
            body: LessonRatingSheet(
              cubit: cubit,
              heading: 'التقييم',
              prompt: 'اختر',
              onSubmit: (value) => submitted = value,
              onDismiss: () {},
            ),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<HasobjyButton>(
            find.widgetWithText(HasobjyButton, 'إرسال التقييم'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.bySemanticsLabel('5 من 5'));
    await tester.pump();
    expect(find.text('ممتاز'), findsOneWidget);
    await tester.tap(find.text('إرسال التقييم'));
    await tester.pump();
    expect(submitted, 5);
    expect(find.byType(LessonRatingSheet), findsOneWidget);
  });

  testWidgets(
    'pending rating prevents changing stars or duplicate submission',
    (tester) async {
      final cubit = RatingSelectionCubit(initial: 4);
      addTearDown(cubit.close);
      await tester.pumpWidget(
        arabicTestApp(
          HasobjyVisualScope(
            frameName: 'C-09',
            child: Scaffold(
              body: LessonRatingSheet(
                cubit: cubit,
                heading: 'التقييم',
                prompt: 'اختر',
                busy: true,
                onSubmit: (_) => fail('duplicate submit'),
                onDismiss: () => fail('dismiss during submit'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('1 من 5'));
      await tester.pump();
      expect(cubit.state, 4);
      for (final button in tester.widgetList<HasobjyButton>(
        find.byType(HasobjyButton),
      )) {
        expect(button.onPressed, isNull);
      }
    },
  );

  testWidgets('updated lesson opens rating in the same theme', (tester) async {
    HasobjyFrameId? opened;
    await tester.pumpWidget(
      arabicTestApp(
        HasobjyDesignPage(
          frameId: HasobjyFrameId.c04Light,
          referenceViewport: true,
          onOpenFrame: (value) => opened = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('قيّم هذا الدرس'));
    expect(opened, HasobjyFrameId.c09Light);
    expect(tester.getTopLeft(find.text('قيّم هذا الدرس')).dy, greaterThan(400));
  });

  testWidgets(
    'subscriptions navigate to catalog without fabricating activation',
    (tester) async {
      HasobjyFrameId? opened;
      await tester.pumpWidget(
        arabicTestApp(
          HasobjyDesignPage(
            frameId: HasobjyFrameId.f07,
            onOpenFrame: (value) => opened = value,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('تصفّح الكورسات'));
      expect(opened, HasobjyFrameId.f01);
    },
  );

  testWidgets('unpublished grade prevents report action in reference state', (
    tester,
  ) async {
    await tester.pumpWidget(
      arabicTestApp(const HasobjyDesignPage(frameId: HasobjyFrameId.g01)),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<HasobjyButton>(
            find.widgetWithText(HasobjyButton, 'طباعة كشف علاماتي'),
          )
          .onPressed,
      isNull,
    );
  });
}
