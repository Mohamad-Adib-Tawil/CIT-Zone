import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/architecture_rules.dart';

void main() {
  test(
    'shared domain-safe helpers cannot import transport or platform SDKs',
    () {
      for (final path in [
        'lib/core/errors/error.dart',
        'lib/core/media/media.dart',
      ]) {
        final violations = architectureViolations({
          path: "import 'package:dio/dio.dart';",
        });
        expect(violations.single, contains('domain imports'));
      }
    },
  );

  test(
    'Either is approved in pure domain and service location stays in DI',
    () {
      expect(
        architectureViolations({
          'lib/core/errors/either.dart':
              "export 'package:fpdart/fpdart.dart' show Either, Left, Right;",
          'lib/features/course/domain/repository.dart':
              "import '../../../core/errors/either.dart';",
          'lib/app/di/dependencies.dart':
              "import 'package:get_it/get_it.dart';",
          'lib/app/router/router.dart':
              "import 'package:go_router/go_router.dart';",
        }),
        isEmpty,
      );
    },
  );

  test('cross-feature data dependencies cannot bypass domain contracts', () {
    final violations = architectureViolations({
      'lib/features/course/data/source.dart':
          "import '../../auth/data/source.dart';",
      'lib/features/auth/data/source.dart': '',
    });
    expect(violations.single, contains('another feature data layer'));
  });

  test('feature UI cannot import composition or construct routing', () {
    final violations = architectureViolations({
      'lib/features/course/presentation/page.dart':
          "import '../../../app/config/config.dart';\n"
          "import 'package:go_router/go_router.dart';",
      'lib/app/config/config.dart': '',
    });
    expect(violations.any((v) => v.contains('composition layer')), isTrue);
    expect(violations.any((v) => v.contains('app/router')), isTrue);
  });

  test('repository preserves domain, data, presentation and composition boundaries', () {
    expect(
      architectureViolations(readArchitectureSources(Directory('lib'))),
      isEmpty,
    );
  });

  test('barrel exports cannot hide a platform dependency from domain', () {
    final result = architectureViolations({
      'lib/features/course/domain/course.dart':
          "import '../../../core/errors/either.dart';",
      'lib/core/errors/either.dart': "export '../media/barrel.dart';",
      'lib/core/media/barrel.dart': "export 'package:flutter/material.dart';",
    });
    expect(
      result.any(
        (value) => value.contains(
          'course.dart -> lib/core/errors/either.dart -> lib/core/media/barrel.dart -> package:flutter/',
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
import 'package:cit_zone/core/errors/either.dart';
part 'course_part.dart';
""",
        'lib/features/course/domain/course_part.dart': "part of 'course.dart';",
        'lib/core/errors/either.dart': "export '../media/value.dart';",
        'lib/core/media/value.dart': "export '../errors/either.dart';",
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
