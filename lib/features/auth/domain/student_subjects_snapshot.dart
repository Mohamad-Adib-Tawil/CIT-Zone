import 'google_identity.dart';
import 'student_learning.dart';

typedef StudentSubjectsSnapshot = ({
  List<StudentSubjectItem> data,
  DateTime storedAt,
});

abstract interface class StudentSubjectsSnapshotSource {
  Future<StudentSubjectsSnapshot?> subjectsSnapshot(
    GoogleIdentity identity, {
    required bool previous,
  });
}
