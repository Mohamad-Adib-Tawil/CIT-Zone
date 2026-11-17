import 'dart:io';
import 'dart:ui' as ui;

import 'package:cit_zone/core/theme/app_theme.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/student_content_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/hasobjy_test_app.dart';

void main() {
  for (final (width, brightness) in [
    (320.0, Brightness.light),
    (320.0, Brightness.dark),
    (430.0, Brightness.light),
    (430.0, Brightness.dark),
  ]) {
    testWidgets('all loading layouts fit RTL at $width in $brightness', (
      tester,
    ) async {
      const captureKey = ValueKey('student-skeleton-samples');
      const sampleHeight = 368.0;
      await tester.binding.setSurfaceSize(Size(width * 2, sampleHeight * 4));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final theme = brightness == Brightness.light
          ? AppTheme.light
          : AppTheme.dark;
      await tester.pumpWidget(
        arabicTestApp(
          Theme(
            data: theme,
            child: RepaintBoundary(
              key: captureKey,
              child: ColoredBox(
                color: theme.scaffoldBackgroundColor,
                child: Wrap(
                  children: [
                    for (final layout in StudentLoadingLayout.values)
                      SizedBox(
                        width: width,
                        height: sampleHeight,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: StudentContentSkeleton(layout: layout),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final layouts = find.byType(StudentContentSkeleton);
      expect(layouts, findsNWidgets(StudentLoadingLayout.values.length));
      for (final element in layouts.evaluate()) {
        expect(Directionality.of(element), TextDirection.rtl);
        final box = element.renderObject! as RenderBox;
        expect(box.size.width, width - 48);
        expect(box.size.height, lessThanOrEqualTo(sampleHeight - 48));
      }
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);

      final output = Platform.environment['HASOBJY_SKELETON_OUTPUT'];
      if (output != null) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(captureKey),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final png = (await image.toByteData(
              format: ui.ImageByteFormat.png,
            ))!;
            Directory(output).createSync(recursive: true);
            File('$output/student-${width.toInt()}-${brightness.name}.png')
                .writeAsBytesSync(png.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
    });
  }
}
