import '../../../core/errors/either.dart';
import 'google_identity.dart';
import 'student_registration.dart';
import 'student_learning.dart';

enum StudentNextStep {
  suspended,
  deviceUnauthorized,
  chooseUsageType,
  completeBasicInfo,
  completeRegistration,
  confirmNewTerm,
  home,
}

enum StudentUsageType { institute, courses }

enum StudentSessionFailure {
  expired,
  unavailable,
  invalidResponse,
  invalidBasicInfo,
  phoneTaken,
}

final class StudentSession {
  const StudentSession({required this.next, required this.usageType});

  final StudentNextStep next;
  final StudentUsageType? usageType;
}

abstract interface class StudentSessionRepository {
  Future<Either<StudentSessionFailure, StudentSession>> start(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, StudentSession?>> restore(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, StudentSession>> read(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, StudentSession>> setUsageType(
    GoogleIdentity identity,
    StudentUsageType usageType,
  );
  Future<Either<StudentSessionFailure, StudentSession>> setBasicInfo(
    GoogleIdentity identity, {
    required String officialName,
    required String phone,
  });
  Future<Either<StudentSessionFailure, List<StudentDepartment>>> departments(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, StudentRegistrationSummary?>>
  registrationSummary(GoogleIdentity identity);
  Future<Either<StudentSessionFailure, StudentRegistrationSummary>>
  saveAcademicInfo(GoogleIdentity identity, String departmentId, int year);
  Future<Either<StudentSessionFailure, StudentSession>> confirmRegistration(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, StudentTermRegistration>>
  termRegistration(GoogleIdentity identity);
  Future<Either<StudentSessionFailure, StudentSession>> confirmNewTerm(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, StudentTermRegistration>>
  requestTermChange(GoogleIdentity identity, String description);
  Future<Either<StudentSessionFailure, StudentHomeData>> home(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, List<StudentSubjectItem>>> subjects(
    GoogleIdentity identity, {
    required bool previous,
  });
  Future<Either<StudentSessionFailure, StudentCoursePageData>> courses(
    GoogleIdentity identity, {
    required bool mine,
    required int page,
  });
  Future<Either<StudentSessionFailure, StudentCourseItem>> course(
    GoogleIdentity identity,
    String id,
  );
  Future<Either<StudentSessionFailure, StudentSubjectDetails>> subject(
    GoogleIdentity identity,
    String id,
  );
  Future<Either<StudentSessionFailure, StudentProfileData>> profile(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, void>> end(GoogleIdentity identity);
}
