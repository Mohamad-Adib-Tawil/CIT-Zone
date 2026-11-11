import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final root = Directory('reports/student-features-2026-10-22');
    for (final capture in data?['captures'] as List<dynamic>? ?? []) {
      final folder = Directory('${root.path}/device-${capture['width']}');
      await folder.create(recursive: true);
      await File('${folder.path}/${capture['frame']}.png')
          .writeAsBytes(base64Decode(capture['png'] as String));
    }
    await root.create(recursive: true);
    await File('${root.path}/device-run.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'device': 'iPhone Duo simulator, iOS 27.1',
        'captures': [
          for (final capture in data?['captures'] as List<dynamic>? ?? [])
            {
              'frame': capture['frame'],
              'width': capture['width'],
              'height': capture['height'],
            },
        ],
        'limits': 'Design fixtures in debug previews only; no student API, actual PDF export, purchase, usage tracking or persisted rating. No real device performance or DRM validation.',
      }),
    );
  },
);
