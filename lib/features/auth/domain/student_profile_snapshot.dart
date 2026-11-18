import 'google_identity.dart';
import 'student_learning.dart';

typedef StudentProfileSnapshot = ({StudentProfileData data, DateTime storedAt});

/// Optional cached presentation data; never establishes a student session.
abstract interface class StudentProfileSnapshotSource {
  Future<StudentProfileSnapshot?> profileSnapshot(GoogleIdentity identity);
}
