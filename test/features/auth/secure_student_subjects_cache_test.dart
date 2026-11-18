import 'dart:convert';

import 'package:cit_zone/features/auth/data/secure_student_subjects_cache.dart';
import 'package:cit_zone/features/auth/domain/student_learning.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  const StudentSubjectItem subject = (
    id: 'one',
    name: 'Subject',
    completed: 1,
    total: 2,
    percent: 50,
  );
  StudentSubjectItem decode(Object? item) {
    if (item case {
      'id': String id,
      'name': String name,
      'progress': {
        'completed': int completed,
        'total': int total,
        'percent': int percent,
      },
    }) {
      return (
        id: id,
        name: name,
        completed: completed,
        total: total,
        percent: percent,
      );
    }
    throw const FormatException();
  }

  SecureStudentSubjectsCache cache([String environment = 'production']) =>
      SecureStudentSubjectsCache(storage, environment, decode);
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'filters and accounts are independent and all account filters clear',
    () async {
      await cache().write('a', [subject], previous: false);
      await cache().write('a', [], previous: true);
      await cache().write('b', [subject], previous: false);
      final restored = cache();
      final current = await restored.read('a', previous: false);
      expect(current?.data, [subject]);
      expect(() => current!.data.add(subject), throwsUnsupportedError);
      expect((await restored.read('a', previous: true))?.data, isEmpty);
      expect(await cache('staging').read('a', previous: false), isNull);
      await restored.clear('a');
      expect(await restored.read('a', previous: false), isNull);
      expect(await restored.read('a', previous: true), isNull);
      expect(await restored.read('b', previous: false), isNotNull);
    },
  );

  test('corrupt item invalidates the entire cached list', () async {
    final key =
        'subjects_current_snapshot_v1_production_${base64Url.encode(utf8.encode('a'))}';
    FlutterSecureStorage.setMockInitialValues({
      key: jsonEncode({
        'version': 1,
        'storedAt': 1,
        'data': [
          {'id': 42},
        ],
      }),
    });
    expect(await cache().read('a', previous: false), isNull);
  });
}
