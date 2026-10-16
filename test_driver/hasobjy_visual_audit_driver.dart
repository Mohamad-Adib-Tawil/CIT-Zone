import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final root = Directory('reports/figma-design/update-2026-10-16');
    for (final capture in data?['captures'] as List<dynamic>? ?? []) {
      final folder = Directory('${root.path}/device-${capture['width']}');
      await folder.create(recursive: true);
      await File('${folder.path}/${capture['frame']}.png')
          .writeAsBytes(base64Decode(capture['png'] as String));
    }
    for (final screenshot in data?['screenshots'] as List<dynamic>? ?? []) {
      await File('${root.path}/${screenshot['screenshotName']}.png')
          .writeAsBytes((screenshot['bytes'] as List<dynamic>).cast<int>());
    }
    await File('${root.path}/device-run.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'platform': 'iOS simulator, iPhone 18 Pro, iOS 27.0',
        'frames': [
          for (final capture in data?['captures'] as List<dynamic>? ?? [])
            {
              'frame': capture['frame'],
              'width': capture['width'],
              'height': capture['height'],
            },
        ],
        'textInputAndScroll': 'passed',
        'nativeKeyboardInset': data?['nativeKeyboardInset'],
      }),
    );
  },
);
