import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_zone/features/onboarding/presentation/pages/preview/preview_widgets.dart';
import 'package:cit_zone/features/onboarding/presentation/theme/hasobjy_visual_scope.dart';

import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_figma_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hasobjy_test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadCairoForTests);
  final expectedContent = jsonDecode(
    File('test/fixtures/hasobjy_figma_content_rects.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final expectedStyles = jsonDecode(
    File('test/fixtures/hasobjy_figma_text_styles.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final observed = <String, Object>{};
  final observedText = <String, Object>{};
  tearDownAll(() {
    File('reports/figma-design/update-2026-10-16/text-observed.json')
        .writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(observedText),
        );
    File(
      'reports/figma-design/update-2026-10-16/layout-observed.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(observed));
  });

  for (final light in [false, true]) {
    testWidgets(
      'progress fill keeps its full height and RTL fraction (light=$light)',
      (tester) async {
        final scope = HasobjyVisualScope(
          frameName: light ? 'C-01-LIGHT' : 'C-01',
          child: const Center(
            child: PreviewProgress(.4, width: 100, height: 6),
          ),
        );
        await tester.pumpWidget(arabicTestApp(scope));
        await tester.pumpAndSettle();
        final palette = HasobjyPalette(light);
        final fill = find.byWidgetPredicate(
          (widget) => widget is ColoredBox && widget.color == palette.brand,
        );
        final track = find.byType(PreviewProgress);
        expect(tester.getSize(fill), const Size(40, 6));
        expect(tester.getRect(fill).right, tester.getRect(track).right);
      },
    );
  }

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
        await tester.runAsync(() async {
          final images = find
              .byType(Image)
              .evaluate()
              .map((e) => (e.widget as Image).image)
              .toList();
          for (final image in images) {
            await precacheImage(
              image,
              tester.element(find.byType(HasobjyFigmaFrame)),
            );
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (size.width == 390) {
          for (final expected
              in expectedStyles[frame.frameName] as List<dynamic>) {
            final actual = tester.widget<Text>(
              find.byWidgetPredicate(
                (widget) => widget is Text && widget.data == expected['text'],
              ),
            );
            if (expected.containsKey('fontSize')) {
              expect(
                actual.style?.fontSize,
                expected['fontSize'],
                reason: '${frame.frameName}: ${expected['text']} size',
              );
            }
            if (expected.containsKey('fontWeight')) {
              expect(
                actual.style?.fontWeight?.value,
                expected['fontWeight'],
                reason: '${frame.frameName}: ${expected['text']} weight',
              );
            }
            if (expected.containsKey('color')) {
              expect(
                actual.style?.color?.toARGB32(),
                expected['color'],
                reason: '${frame.frameName}: ${expected['text']} color',
              );
            }
          }
          observedText[frame.frameName] = [
            for (final t in tester.widgetList<Text>(find.byType(Text)))
              if (t.data != null)
                {
                  'text': t.data!,
                  'color': t.style?.color?.toARGB32(),
                  'fontSize': t.style?.fontSize,
                  'fontWeight': t.style?.fontWeight?.value,
                  'rect': [
                    tester.getRect(find.byWidget(t)).left,
                    tester.getRect(find.byWidget(t)).top,
                    tester.getRect(find.byWidget(t)).width,
                    tester.getRect(find.byWidget(t)).height,
                  ],
                },
          ];
        }
        if (size.width == 390 &&
            find.byType(PreviewScaffold).evaluate().isNotEmpty) {
          final scaffold = tester.widget<PreviewScaffold>(
            find.byType(PreviewScaffold),
          );
          final measuredChildren = [
            for (final child in scaffold.children)
              if (child is! Spacer) child,
          ];
          final expected = expectedContent[frame.frameName] as List<dynamic>;
          expect(measuredChildren.length, expected.length);
          for (var index = 0; index < expected.length; index++) {
            final child = measuredChildren[index];
            final rect = tester.getRect(
              find.byWidget(child is Center ? child.child! : child),
            );
            final reference = (expected[index]['rect'] as List<dynamic>)
                .cast<num>();
            expect(
              rect.left,
              closeTo(reference[0], .01),
              reason: '${frame.frameName} child $index left',
            );
            expect(
              rect.top,
              closeTo(reference[1], .01),
              reason: '${frame.frameName} child $index top',
            );
            expect(
              rect.width,
              closeTo(reference[2], .01),
              reason: '${frame.frameName} child $index width',
            );
            expect(
              rect.height,
              closeTo(reference[3], .01),
              reason: '${frame.frameName} child $index height',
            );
          }
          observed[frame.frameName] = [
            for (final w in scaffold.children)
              if (find.byWidget(w).evaluate().length == 1)
                {
                  'widget': w.runtimeType.toString(),
                  'rect': [
                    tester.getRect(find.byWidget(w)).left,
                    tester.getRect(find.byWidget(w)).top,
                    tester.getRect(find.byWidget(w)).width,
                    tester.getRect(find.byWidget(w)).height,
                  ],
                },
          ];
        }
        expect(
          Directionality.of(tester.element(find.byType(HasobjyFigmaFrame))),
          TextDirection.rtl,
        );

        if (size.width == 390 &&
            !frame.isLight &&
            const {
              'A-S01',
              'A-S03',
              'A-S04',
              'A-S05',
              'A-S06',
              'A-S07',
              'B-S01',
              'B-S03',
              'B-S04',
              'B-S05',
              'B-S06',
            }.contains(frame.frameName)) {
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
              '${Platform.environment['HASOBJY_WIDGET_OUTPUT'] ?? 'reports/figma-design/update-2026-10-16'}/widget-${size.width.toInt()}',
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

  for (final frame in HasobjyFrameId.values) {
    testWidgets('${frame.frameName} supports enlarged Arabic text at 320', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        arabicTestApp(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 844),
              textScaler: TextScaler.linear(1.3),
            ),
            child: HasobjyDesignPage(frameId: frame, referenceViewport: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'frame registry matches the 88 actual Figma frames and local assets',
    () {
      final frames = jsonDecode(
        File('reports/figma-design/update-2026-10-16/frames.json')
            .readAsStringSync(),
      ) as List<dynamic>;
      expect(frames.length, 88);
      expect(HasobjyFrameId.values.length, frames.length);
      for (final reference in frames) {
        final frame = HasobjyFrameId.fromFrameName(reference['key'] as String)!;
        expect(frame.figmaNodeId, reference['node']);
        for (final asset
            in (reference['assets'] as Map<String, dynamic>).values) {
          expect(
            File('assets/hasobjy/$asset').existsSync(),
            isTrue,
            reason: '${frame.frameName}: $asset',
          );
        }
      }
      expect(HasobjyFrameId.fromFrameName('A-S02'), isNull);
      expect(HasobjyFrameId.fromFrameName('B-S02'), isNull);
    },
  );

  for (final frame in [HasobjyFrameId.f03, HasobjyFrameId.f03Light]) {
    testWidgets(
      '${frame.frameName} coupon selection opens its existing frame',
      (tester) async {
        HasobjyFrameId? opened;
        await tester.pumpWidget(
          arabicTestApp(
            HasobjyDesignPage(
              frameId: frame,
              onOpenFrame: (value) => opened = value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(HasobjySelectionOption).last);
        await tester.pump();
        await tester.tap(find.text('متابعة الدفع'));
        await tester.pump();
        expect(opened, HasobjyFrameId.f05.withLight(frame.isLight));
      },
    );
  }

  testWidgets('payment review cannot fabricate activation or navigation', (
    tester,
  ) async {
    HasobjyFrameId? opened;
    await tester.pumpWidget(
      arabicTestApp(
        HasobjyDesignPage(
          frameId: HasobjyFrameId.f04,
          onOpenFrame: (value) => opened = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إرسال للمراجعة'));
    await tester.pump();
    expect(opened, isNull);
    expect(find.textContaining('هذه معاينة تصميم'), findsOneWidget);
    expect(find.text('تم تفعيل الكورس'), findsNothing);
  });

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
