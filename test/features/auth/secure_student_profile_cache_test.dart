import 'dart:convert';

import 'package:cit_zone/features/auth/data/secure_student_profile_cache.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  const profile = (
    name: 'Student',
    email: 'student@example.test',
    phone: null,
    department: null,
    year: 1,
  );
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test(
    'new store restores metadata with account and environment isolation',
    () async {
      await SecureStudentProfileCache(
        storage,
        'production',
      ).write('one', profile);
      final restored = SecureStudentProfileCache(storage, 'production');
      expect((await restored.read('one'))?.data, profile);
      expect(await restored.read('two'), isNull);
      expect(
        await SecureStudentProfileCache(storage, 'staging').read('one'),
        isNull,
      );
      await restored.clear('one');
      expect(await restored.read('one'), isNull);
    },
  );

  test('corrupt and unsupported metadata are cache misses', () async {
    final key =
        'profile_snapshot_v1_production_${base64Url.encode(utf8.encode('one'))}';
    for (final value in ['broken', '{"version":2}', 'x' * 8193]) {
      FlutterSecureStorage.setMockInitialValues({key: value});
      expect(
        await SecureStudentProfileCache(storage, 'production').read('one'),
        isNull,
      );
    }
  });

  test('oversized update removes the older snapshot', () async {
    final cache = SecureStudentProfileCache(storage, 'production');
    await cache.write('one', profile);
    await cache.write('one', (
      name: 'x' * 9000,
      email: profile.email,
      phone: null,
      department: null,
      year: 1,
    ));
    expect(await cache.read('one'), isNull);
  });
}
