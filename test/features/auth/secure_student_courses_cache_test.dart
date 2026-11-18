import 'dart:convert';

import 'package:cit_zone/features/auth/data/secure_student_courses_cache.dart';
import 'package:cit_zone/features/auth/domain/student_learning.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  StudentCourseItem decode(Object? value) {
    if (value case {
      'id': String id,
      'name': String name,
      'description': String? description,
      'priceUsd': String price,
      'durationDays': int days,
      'subscribed': bool subscribed,
    }) {
      return (
        id: id,
        name: name,
        description: description,
        priceUsd: price,
        durationDays: days,
        subscribed: subscribed,
      );
    }
    throw const FormatException();
  }

  StudentCoursePageData data(String id, {String? description}) => (
    hasMore: true,
    courses: [
      (
        id: id,
        name: 'Course',
        description: description,
        priceUsd: '15.00',
        durationDays: 30,
        subscribed: false,
      ),
    ],
  );
  SecureStudentCoursesCache cache([String environment = 'production']) =>
      SecureStudentCoursesCache(storage, environment, decode);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'filter, page, account and environment snapshots remain separate',
    () async {
      final store = cache();
      for (final mine in [false, true]) {
        for (final page in [1, 2]) {
          await store.write('a', data('$mine-$page'), mine: mine, page: page);
        }
      }
      await store.write('b', data('other'), mine: false, page: 1);
      final restored = cache();
      for (final mine in [false, true]) {
        for (final page in [1, 2]) {
          final entry = await restored.read('a', mine: mine, page: page);
          expect(entry?.data.courses.single.id, '$mine-$page');
          expect(entry?.data.hasMore, isTrue);
          expect(() => entry!.data.courses.clear(), throwsUnsupportedError);
          expect(
            (await restored.read('a', mine: mine, page: page))?.storedAt,
            entry?.storedAt,
          );
        }
      }
      expect(await cache('staging').read('a', mine: false, page: 1), isNull);
      await restored.clear('a');
      expect(await restored.read('a', mine: true, page: 2), isNull);
      expect(
        (await restored.read(
          'b',
          mine: false,
          page: 1,
        ))?.data.courses.single.id,
        'other',
      );
    },
  );

  test(
    'concurrent page saves retain the most recent 24 without lost updates',
    () async {
      final store = cache();
      await Future.wait([
        for (var page = 1; page <= 25; page++)
          store.write('a', data('$page'), mine: false, page: page),
      ]);
      expect(await store.read('a', mine: false, page: 1), isNull);
      for (var page = 2; page <= 25; page++) {
        expect(
          (await store.read(
            'a',
            mine: false,
            page: page,
          ))?.data.courses.single.id,
          '$page',
        );
      }
    },
  );

  test(
    'byte budget evicts old pages and oversized updates preserve other pages',
    () async {
      final store = cache();
      await store.write(
        'a',
        data('first', description: 'x' * 70000),
        mine: false,
        page: 1,
      );
      await store.write(
        'a',
        data('second', description: 'x' * 70000),
        mine: false,
        page: 2,
      );
      expect(await store.read('a', mine: false, page: 1), isNull);
      expect(
        (await store.read('a', mine: false, page: 2))?.data.courses.single.id,
        'second',
      );
      await store.write(
        'a',
        data('huge', description: 'x' * 150000),
        mine: false,
        page: 3,
      );
      expect(await store.read('a', mine: false, page: 3), isNull);
      expect(
        (await store.read('a', mine: false, page: 2))?.data.courses.single.id,
        'second',
      );
      final values = await storage.readAll();
      expect(
        values.values.every((value) => utf8.encode(value).length <= 131072),
        isTrue,
      );
    },
  );

  test('a corrupt course makes its entire page a cache miss', () async {
    final key =
        'courses_snapshot_v1_production_${base64Url.encode(utf8.encode('a'))}';
    FlutterSecureStorage.setMockInitialValues({
      key: jsonEncode({
        'version': 1,
        'pages': [
          {
            'mine': false,
            'page': 1,
            'storedAt': 1,
            'hasMore': false,
            'courses': [
              {'id': 42},
            ],
          },
        ],
      }),
    });
    expect(await cache().read('a', mine: false, page: 1), isNull);
  });
}
