import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cit_zone/features/onboarding/presentation/pages/hasobjy_design_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/hasobjy_test_app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture every Figma frame on the device', (tester) async {
    final captures = <Map<String, Object>>[];
    binding.reportData = {'captures': captures};
    for (final width in [390.0, 320.0]) {
      for (final frame in HasobjyFrameId.values) {
        final key = GlobalKey();
        await tester.pumpWidget(
          arabicTestApp(
            ColoredBox(
              color: Colors.black,
              child: Center(
                child: SizedBox(
                  width: width,
                  height: 844,
                  child: MediaQuery(
                    data: MediaQueryData(size: Size(width, 844)),
                    child: RepaintBoundary(
                      key: key,
                      child: HasobjyDesignPage(
                        key: ValueKey('$width-${frame.frameName}'),
                        frameId: frame,
                        referenceViewport: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        captures.add({
          'frame': frame.frameName,
          'width': width.toInt(),
          'height': 844,
          'png': base64Encode(png!.buffer.asUint8List()),
        });
        image.dispose();
      }
    }
    // Exercise real platform text input and keyboard with native safe areas.
    await tester.pumpWidget(
      arabicTestApp(const HasobjyDesignPage(frameId: HasobjyFrameId.aS04)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, 'أحمد محمد الحلبي');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('متابعة'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('أحمد محمد الحلبي'), findsOneWidget);
    expect(find.text('متابعة').hitTestable(), findsOneWidget);
    final keyboardTop =
        (tester.view.physicalSize.height - tester.view.viewInsets.bottom) /
        tester.view.devicePixelRatio;
    expect(
      tester.getRect(find.text('متابعة')).bottom,
      lessThanOrEqualTo(keyboardTop),
    );
    expect(
      tester.view.viewInsets.bottom,
      greaterThan(0),
      reason:
          'Enable Device > Keyboard > Toggle Software Keyboard in Device Hub.',
    );
    binding.reportData!['nativeKeyboardInset'] =
        tester.view.viewInsets.bottom / tester.view.devicePixelRatio;
    await binding.takeScreenshot('device-input-focused');
    debugPrint('HASOBJY_NATIVE_KEYBOARD_READY');
    await Future<void>.delayed(const Duration(seconds: 5));
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
  });
}
