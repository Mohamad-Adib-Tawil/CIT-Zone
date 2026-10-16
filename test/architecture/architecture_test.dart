import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture_rules.dart';

void main() {
  test('repository preserves domain, data, presentation and composition boundaries', () {
    expect(
      architectureViolations(readArchitectureSources(Directory('lib'))),
      isEmpty,
    );
  });

  test('barrel exports cannot hide a platform dependency from domain', () {
    final result = architectureViolations({
      'lib/features/course/domain/course.dart':
          "import '../../../core/errors/result.dart';",
      'lib/core/errors/result.dart': "export '../media/barrel.dart';",
      'lib/core/media/barrel.dart': "export 'package:flutter/material.dart';",
    });
    expect(
      result.any(
        (value) => value.contains(
          'course.dart -> lib/core/errors/result.dart -> lib/core/media/barrel.dart -> package:flutter/',
        ),
      ),
      isTrue,
    );
  });

  test('every conditional branch is checked, not just the VM branch', () {
    final result = architectureViolations({
      'lib/features/course/domain/course.dart':
          "export 'safe.dart' if (dart.library.io) 'package:dio/dio.dart';",
      'lib/features/course/domain/safe.dart': '',
    });
    expect(result.single, contains('package:dio/dio.dart'));
  });

  test('relative/package imports, parts, cycles and comments are parsed', () {
    expect(
      architectureViolations({
        'lib/features/course/domain/course.dart': """
// import 'package:flutter/material.dart';
import 'package:cit_zone/core/errors/result.dart';
part 'course_part.dart';
""",
        'lib/features/course/domain/course_part.dart': "part of 'course.dart';",
        'lib/core/errors/result.dart': "export '../media/value.dart';",
        'lib/core/media/value.dart': "export '../errors/result.dart';",
      }),
      isEmpty,
    );
  });

  test('presentation cannot hide a data implementation behind another feature', () {
    expect(
      architectureViolations({
        'lib/features/course/presentation/page.dart':
            "import 'package:cit_zone/features/other/domain/repository.dart';",
        'lib/features/other/domain/repository.dart':
            "export '../data/repository_impl.dart';",
        'lib/features/other/data/repository_impl.dart': '',
      }).any((value) => value.contains('presentation bypasses')),
      isTrue,
    );
  });

  test('data/core inversion and locator usage outside DI are rejected', () {
    final result = architectureViolations({
      'lib/features/course/data/source.dart':
          "import '../presentation/page.dart';",
      'lib/features/course/presentation/page.dart': '',
      'lib/core/errors/failure.dart':
          "import '../../features/course/domain/course.dart';",
      'lib/features/course/domain/course.dart': '',
      'lib/features/course/data/locator.dart':
          "import 'package:get_it/get_it.dart';",
    });
    expect(result.any((value) => value.startsWith('data depends')), isTrue);
    expect(result.any((value) => value.startsWith('core depends')), isTrue);
    expect(result.any((value) => value.startsWith('service locator')), isTrue);
  });
}
