import 'google_identity.dart';
import 'student_learning.dart';

typedef StudentHomeSnapshot = ({StudentHomeData data, DateTime storedAt});

/// Cached presentation metadata, not an authorization or playback source.
abstract interface class StudentHomeSnapshotSource {
  Future<StudentHomeSnapshot?> homeSnapshot(GoogleIdentity identity);
}
