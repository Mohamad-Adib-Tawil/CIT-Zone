import 'dart:convert';

import 'package:cit_zone/features/auth/data/secure_student_home_cache.dart';
import 'package:cit_zone/features/auth/domain/student_learning.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  const StudentHomeData home = (
    name: 'Student',
    resumeLesson: null,
    subjects: <StudentSubjectItem>[],
    courses: <({String id, String name})>[],
  );
  SecureStudentHomeCache cache([String environment = 'production']) =>
      SecureStudentHomeCache(storage, environment, (data) {
        if (data case {'name': String name}) {
          return (
            name: name,
            resumeLesson: null,
            subjects: home.subjects,
            courses: home.courses,
          );
        }
        throw const FormatException();
      });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('snapshots are isolated by account and environment', () async {
    await cache().write('one', home);
    expect((await cache().read('one'))?.data.name, 'Student');
    expect(await cache().read('two'), isNull);
    expect(await cache('staging').read('one'), isNull);
    await cache().write('two', home);
    await cache().clear('one');
    expect(await cache().read('one'), isNull);
    expect(await cache().read('two'), isNotNull);
  });

  test('malformed, unsupported and oversized snapshots are misses', () async {
    final key =
        'home_snapshot_v1_production_${base64Url.encode(utf8.encode('one'))}';
    for (final value in [
      'broken',
      '{"version":2,"storedAt":1,"data":{}}',
      '{"version":1,"storedAt":1,"data":{}}',
      'x' * 65537,
    ]) {
      FlutterSecureStorage.setMockInitialValues({key: value});
      expect(await cache().read('one'), isNull);
    }
  });

  test('oversized update discards the old home snapshot', () async {
    final store = cache();
    await store.write('one', home);
    await store.write('one', (
      name: 'x' * 65537,
      resumeLesson: null,
      subjects: home.subjects,
      courses: home.courses,
    ));
    expect(await store.read('one'), isNull);
  });
}
