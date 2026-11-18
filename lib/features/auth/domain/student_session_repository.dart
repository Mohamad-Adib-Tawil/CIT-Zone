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
  learningDataDenied,
  accountSuspended,
  deviceUnauthorized,
  lessonNotWatched,
  supportTicketClosed,
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
  Future<Either<StudentSessionFailure, List<StudentCourseContent>>>
  courseContent(GoogleIdentity identity, String id);
  Future<Either<StudentSessionFailure, StudentCourseItem>> course(
    GoogleIdentity identity,
    String id,
  );
  Future<Either<StudentSessionFailure, StudentSubjectDetails>> subject(
    GoogleIdentity identity,
    String id,
  );
  Future<Either<StudentSessionFailure, int>> rateLesson(
    GoogleIdentity identity,
    String id,
    int stars,
  );
  Future<Either<StudentSessionFailure, StudentLessonDetail>> lesson(
    GoogleIdentity identity,
    String id,
  );
  Future<Either<StudentSessionFailure, Uri>> academicFileDownload(
    GoogleIdentity identity,
    String id, {
    Future<void>? whenCanceled,
  });
  StudentFileViewer fileViewer(GoogleIdentity identity, String id);
  Future<Either<StudentSessionFailure, List<StudentSubjectFile>>> subjectFiles(
    GoogleIdentity identity,
    String id,
  );
  Future<Either<StudentSessionFailure, StudentAttempt>> submitExercise(
    GoogleIdentity identity,
    String id,
    String key, {
    String? code,
    String? language,
    String? choiceId,
  });
  Future<Either<StudentSessionFailure, StudentAttempt?>> latestExerciseAttempt(
    GoogleIdentity identity,
    String exerciseId, {
    Future<void>? whenCanceled,
  });
  Future<Either<StudentSessionFailure, StudentAttempt>> exerciseAttempt(
    GoogleIdentity identity,
    String id, {
    Future<void>? whenCanceled,
  });
  Future<Either<StudentSessionFailure, StudentExercisePrompt>> exercise(
    GoogleIdentity identity,
    String id,
  );
  Future<Either<StudentSessionFailure, List<StudentSubjectExercise>>>
  subjectExercises(GoogleIdentity identity, String id);
  Future<Either<StudentSessionFailure, List<StudentSubscription>>>
  subscriptions(GoogleIdentity identity);
  Future<Either<StudentSessionFailure, StudentTicketPage>> supportTickets(
    GoogleIdentity identity,
    int page,
  );
  Future<Either<StudentSessionFailure, StudentTicketThread>> supportTicket(
    GoogleIdentity identity,
    String id, {
    Future<void>? whenCanceled,
  });
  Future<Either<StudentSessionFailure, StudentTicket>> createSupportTicket(
    GoogleIdentity identity,
    String subject,
    String body,
  );
  Future<Either<StudentSessionFailure, StudentTicketReply>>
  replyToSupportTicket(
    GoogleIdentity identity,
    String id,
    String body,
    String idempotencyKey,
  );
  Future<Either<StudentSessionFailure, String?>> currentDeviceRequest(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, String>> requestDeviceChange(
    GoogleIdentity identity,
    String reason,
  );
  Future<Either<StudentSessionFailure, StudentDeviceData>> device(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, List<StudentLessonSummary>>>
  subjectLessons(GoogleIdentity identity, String id);
  Future<Either<StudentSessionFailure, StudentNotificationPage>> notifications(
    GoogleIdentity identity,
    String? cursor,
  );
  Future<Either<StudentSessionFailure, int>> unreadNotificationCount(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, void>> markNotificationRead(
    GoogleIdentity identity,
    String id,
  );
  Future<Either<StudentSessionFailure, List<StudentExam>>> examSchedule(
    GoogleIdentity identity,
    StudentExamSession session,
  );
  Future<Either<StudentSessionFailure, StudentStudyTime>> studyTime(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, StudentGradeDetail>> subjectGrades(
    GoogleIdentity identity,
    String id,
  );
  Future<Either<StudentSessionFailure, StudentGrades>> grades(
    GoogleIdentity identity, {
    String? termId,
  });
  Future<Either<StudentSessionFailure, StudentProfileData>> profile(
    GoogleIdentity identity,
  );
  Future<Either<StudentSessionFailure, StudentProfileData?>> updateProfile(
    GoogleIdentity identity, {
    String? officialName,
    String? phone,
  });
  Future<Either<StudentSessionFailure, void>> end(GoogleIdentity identity);
}
