import 'google_identity.dart';
import 'student_learning.dart';

typedef StudentCoursesSnapshot = ({
  StudentCoursePageData data,
  DateTime storedAt,
});

abstract interface class StudentCoursesSnapshotSource {
  Future<StudentCoursesSnapshot?> coursesSnapshot(
    GoogleIdentity identity, {
    required bool mine,
    required int page,
  });
}
