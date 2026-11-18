import 'package:cit_zone/core/security/secure_session_secret_store.dart';
import 'package:cit_zone/features/auth/data/secure_student_home_cache.dart';
import 'package:cit_zone/features/auth/data/secure_student_profile_cache.dart';
import 'package:cit_zone/features/auth/domain/student_learning.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Run write and read with --no-uninstall in separate app launches.
// Flutter test otherwise uninstalls the app and removes Android snapshots.
// Default roundtrip is self-cleaning for ordinary integration test runs.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment(
    'HASOBJY_METADATA_RESTART_PHASE',
    defaultValue: 'roundtrip',
  );
  const environment = 'integration_metadata_restart_v1';
  const owner = 'integration_student_a';
  const otherOwner = 'integration_student_b';
  const profile = (
    name: 'Integration Student',
    email: 'synthetic@example.test',
    phone: null,
    department: null,
    year: 1,
  );
  const StudentHomeData home = (
    name: 'Integration Student',
    resumeLesson: null,
    subjects: <StudentSubjectItem>[],
    courses: <({String id, String name})>[],
  );

  testWidgets('native metadata persistence phase: $phase', (tester) async {
    expect(['write', 'read', 'roundtrip'], contains(phase));
    final storage = SecureSessionSecretStore.platformStorage;
    final profiles = SecureStudentProfileCache(storage, environment);
    StudentHomeData decode(Object? value) {
      if (value case {
        'name': String name,
        'subjects': List _,
        'courses': List _,
      }) {
        return (
          name: name,
          resumeLesson: null,
          subjects: home.subjects,
          courses: home.courses,
        );
      }
      throw const FormatException('Invalid integration home snapshot');
    }

    final homes = SecureStudentHomeCache(storage, environment, decode);
    final stopwatch = Stopwatch()..start();

    if (phase != 'read') {
      await profiles.clear(owner);
      await profiles.clear(otherOwner);
      await homes.clear(owner);
      await profiles.write(owner, profile);
      await profiles.write(otherOwner, profile);
      await homes.write(owner, home);
      expect((await profiles.read(owner))?.data, profile);
      expect((await homes.read(owner))?.data.name, home.name);
    }

    if (phase != 'write') {
      addTearDown(() async {
        await profiles.clear(owner);
        await profiles.clear(otherOwner);
        await homes.clear(owner);
      });
      final restoredProfile = await profiles.read(owner);
      final restoredHome = await homes.read(owner);
      expect(restoredProfile?.data, profile);
      expect(restoredHome?.data.name, home.name);
      expect(restoredProfile!.storedAt.isUtc, isTrue);
      expect(restoredHome!.storedAt.isUtc, isTrue);
      expect(await profiles.read('unrelated_integration_account'), isNull);
      expect(await homes.read(otherOwner), isNull);
      expect(
        await SecureStudentProfileCache(
          storage,
          '${environment}_other',
        ).read(owner),
        isNull,
      );
      expect(
        await SecureStudentHomeCache(
          storage,
          '${environment}_other',
          decode,
        ).read(owner),
        isNull,
      );
      await profiles.clear(owner);
      await homes.clear(owner);
      expect(await profiles.read(owner), isNull);
      expect(await homes.read(owner), isNull);
      expect((await profiles.read(otherOwner))?.data, profile);
    }

    binding.reportData = {
      'phase': phase,
      'native_storage': true,
      'elapsed_ms': stopwatch.elapsedMilliseconds,
      'live_student_session_tested': false,
    };
  });
}
