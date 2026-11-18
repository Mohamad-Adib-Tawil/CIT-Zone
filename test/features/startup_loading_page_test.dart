import 'package:cit_zone/features/app_status/presentation/pages/startup_loading_page.dart';
import 'package:flutter/material.dart';
import 'package:cit_zone/core/localization/generated/app_localizations_ar.dart';
import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_auth_screens.dart';
import 'package:cit_zone/features/onboarding/presentation/theme/hasobjy_visual_scope.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/hasobjy_test_app.dart';

void main() {
  for (final light in [false, true]) {
    testWidgets('startup reuses welcome layout and background light=$light', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final frame = light ? 'A-S01-LIGHT' : 'A-S01';
      final strings = AppLocalizationsAr();
      await tester.pumpWidget(
        arabicTestApp(
          HasobjyVisualScope(
            frameName: frame,
            child: const HasobjyWelcomeScreen(
              onGoogleSignIn: null,
              working: false,
            ),
          ),
        ),
      );
      final titleRect = tester.getRect(find.text(strings.designWelcomeTitle));
      final descriptionRect = tester.getRect(
        find.text(strings.designWelcomeDescription),
      );
      await tester.pumpWidget(
        arabicTestApp(
          Theme(
            data: light ? ThemeData.light() : ThemeData.dark(),
            child: const StartupLoadingPage(),
          ),
        ),
      );
      expect(tester.getRect(find.text(strings.designWelcomeTitle)), titleRect);
      expect(
        tester.getRect(find.text(strings.designWelcomeDescription)),
        descriptionRect,
      );
      expect(find.text(strings.continueViaGoogle).hitTestable(), findsNothing);
      final scope = tester.widget<HasobjyVisualScope>(
        find.descendant(
          of: find.byType(StartupLoadingPage),
          matching: find.byType(HasobjyVisualScope),
        ),
      );
      expect(scope.frameName, frame);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('startup fades branding and respects reduced motion', (
    tester,
  ) async {
    Widget page(bool reducedMotion) => arabicTestApp(
      MediaQuery(
        data: MediaQueryData(disableAnimations: reducedMotion),
        child: const StartupLoadingPage(),
      ),
    );

    await tester.pumpWidget(page(false));
    final fade = find.descendant(
      of: find.byType(StartupLoadingPage),
      matching: find.byType(FadeTransition),
    );
    double opacity() => tester.widget<FadeTransition>(fade).opacity.value;
    expect(opacity(), 1);
    await tester.pump(const Duration(milliseconds: 550));
    expect(opacity(), lessThan(1));
    expect(opacity(), greaterThanOrEqualTo(0.45));

    await tester.pumpWidget(page(true));
    await tester.pump();
    expect(opacity(), 1);
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
