import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';

import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_figma_components.dart';
import 'package:cit_zone/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/hasobjy_test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final captures = <Map<String, Object>>[];
  binding.reportData = {'captures': captures};

  testWidgets(
    'capture student Figma additions and updated links on simulator',
    (tester) async {
      const cases = [
        HasobjyFrameId.c09,
        HasobjyFrameId.s05,
        HasobjyFrameId.g03,
        HasobjyFrameId.f07,
        HasobjyFrameId.c04,
        HasobjyFrameId.s01,
        HasobjyFrameId.g01,
      ];
      await tester.binding.setSurfaceSize(const Size(700, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final width in [390.0, 320.0, 600.0]) {
        for (final light in [false, true]) {
          for (final entry in cases) {
            final key = GlobalKey();
            await tester.pumpWidget(
              arabicTestApp(
                Theme(
                  data: light ? AppTheme.light : AppTheme.dark,
                  child: Center(
                    child: SizedBox(
                      width: width,
                      height: 844,
                      child: MediaQuery(
                        data: MediaQueryData(
                          size: Size(width, 844),
                          textScaler: TextScaler.linear(width == 320 ? 1.5 : 1),
                        ),
                        child: RepaintBoundary(
                          key: key,
                          child: HasobjyReferenceViewport(
                            child: HasobjyDesignPage(
                              frameId: entry.withLight(light),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.frameName} $width light=$light',
            );
            final boundary =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 1);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            captures.add({
              'frame': '${entry.frameName}${light ? '-LIGHT' : ''}',
              'width': width.toInt(),
              'height': 844,
              'png': base64Encode(png!.buffer.asUint8List()),
            });
            image.dispose();
          }
        }
      }
    },
  );
}
