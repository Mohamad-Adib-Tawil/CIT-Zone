import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_figma_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hasobjy_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCairoForTests);

  for (final size in [
    const Size(390, 844),
    const Size(320, 844),
    const Size(600, 1024),
  ]) {
    for (final frame in HasobjyFrameId.values) {
      testWidgets('${frame.frameName} Cairo RTL layout at ${size.width}', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          arabicTestApp(
            RepaintBoundary(
              key: boundaryKey,
              child: HasobjyDesignPage(frameId: frame, referenceViewport: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          Directionality.of(tester.element(find.byType(HasobjyFigmaFrame))),
          TextDirection.rtl,
        );

        if (size.width == 390) {
          final expectedButtons = switch (frame) {
            HasobjyFrameId.aS01 => [734.0],
            HasobjyFrameId.aS05 ||
            HasobjyFrameId.aS07 ||
            HasobjyFrameId.bS03 ||
            HasobjyFrameId.bS04 => [700.0, 768.0],
            HasobjyFrameId.bS05 || HasobjyFrameId.bS06 => <double>[],
            _ => [768.0],
          };
          final buttons = find.byType(HasobjyButton);
          expect(buttons, findsNWidgets(expectedButtons.length));
          for (var index = 0; index < expectedButtons.length; index++) {
            expect(
              tester.getRect(buttons.at(index)),
              Rect.fromLTWH(24, expectedButtons[index], 342, 52),
            );
          }
          final expectedCards = switch (frame) {
            HasobjyFrameId.aS03 => [(146.0, 100.0), (262.0, 100.0)],
            HasobjyFrameId.aS06 => [(116.0, 86.0)],
            HasobjyFrameId.aS07 => [(116.0, 216.0), (348.0, 88.0)],
            HasobjyFrameId.bS01 => [
              (178.0, 100.0),
              (294.0, 100.0),
              (450.0, 100.0),
              (566.0, 100.0),
            ],
            HasobjyFrameId.bS03 => [(164.0, 158.0)],
            HasobjyFrameId.bS04 => [(216.0, 124.0)],
            HasobjyFrameId.bS05 => [
              (104.0, 108.0),
              (228.0, 108.0),
              (352.0, 108.0),
              (476.0, 120.0),
            ],
            HasobjyFrameId.bS06 => [
              (156.0, 88.0),
              (260.0, 88.0),
              (364.0, 88.0),
              (468.0, 88.0),
            ],
            _ => <(double, double)>[],
          };
          final cards = find.byType(HasobjySurface);
          expect(cards, findsNWidgets(expectedCards.length));
          for (var index = 0; index < expectedCards.length; index++) {
            expect(
              tester.getRect(cards.at(index)),
              Rect.fromLTWH(
                24,
                expectedCards[index].$1,
                342,
                expectedCards[index].$2,
              ),
            );
          }
        }
        if (size.width == 390 && frame == HasobjyFrameId.bS01) {
          final option = find.byType(HasobjySelectionOption).first;
          final rect = tester.getRect(option);
          expect(rect.width, 342);
          expect(rect.height, 100);
          final radio = find.descendant(
            of: option,
            matching: find.byWidgetPredicate(
              (widget) => widget is HasobjySvg && widget.name == '0fd39',
            ),
          );
          final icon = find.descendant(
            of: option,
            matching: find.byWidgetPredicate(
              (widget) => widget is HasobjySvg && widget.name == 'dbeae',
            ),
          );
          expect(
            tester.getCenter(radio).dx,
            lessThan(tester.getCenter(icon).dx),
          );
        }
        if (size.width <= 390) {
          await tester.runAsync(() async {
            final boundary =
                boundaryKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final rendered = await boundary.toImage(pixelRatio: 1);
            final png = await rendered.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final folder = Directory(
              '${Platform.environment['HASOBJY_WIDGET_OUTPUT'] ?? 'reports/figma-design/audit'}/widget-${size.width.toInt()}',
            );
            folder.createSync(recursive: true);
            File('${folder.path}/${frame.frameName}.png')
                .writeAsBytesSync(png!.buffer.asUint8List());
            rendered.dispose();
          });
        }
      });
    }
  }

  testWidgets('academic selection keeps one department and one year', (
    tester,
  ) async {
    await tester.pumpWidget(
      arabicTestApp(const HasobjyDesignPage(frameId: HasobjyFrameId.bS01)),
    );
    await tester.pumpAndSettle();
    final options = find.byType(HasobjySelectionOption);
    await tester.tap(options.at(1));
    await tester.tap(options.at(2));
    await tester.pumpAndSettle();
    expect(
      tester.widget<HasobjySelectionOption>(options.at(0)).selected,
      isFalse,
    );
    expect(
      tester.widget<HasobjySelectionOption>(options.at(1)).selected,
      isTrue,
    );
    expect(
      tester.widget<HasobjySelectionOption>(options.at(2)).selected,
      isTrue,
    );
    expect(
      tester.widget<HasobjySelectionOption>(options.at(3)).selected,
      isFalse,
    );
  });

  testWidgets('unsupported supplementary filter cannot invent exam dates', (
    tester,
  ) async {
    await tester.pumpWidget(
      arabicTestApp(const HasobjyDesignPage(frameId: HasobjyFrameId.bS06)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدورة التكميلية'));
    await tester.pump();
    expect(find.textContaining('هذه معاينة تصميم'), findsOneWidget);
    expect(find.text('الأحد 7 يونيو · 09:00 · القاعة 3'), findsOneWidget);
    expect(find.textContaining('21 يونيو'), findsNothing);
  });

  testWidgets(
    'basic fields keep RTL, disabled email, and keyboard access at 320',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        arabicTestApp(
          const HasobjyDesignPage(
            frameId: HasobjyFrameId.aS04,
            referenceViewport: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      expect(tester.widget<TextField>(fields.last).enabled, isFalse);
      await tester.enterText(fields.first, 'أحمد محمد الحلبي');
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('متابعة'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      expect(find.text('أحمد محمد الحلبي'), findsOneWidget);
    },
  );
}
