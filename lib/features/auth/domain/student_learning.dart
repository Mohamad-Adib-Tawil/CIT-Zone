import 'dart:typed_data';

import '../../../core/errors/either.dart';

typedef StudentSubjectItem = ({
  String id,
  String name,
  int completed,
  int total,
  int percent,
});

typedef StudentCourseItem = ({
  String id,
  String name,
  String? description,
  String priceUsd,
  int durationDays,
  bool subscribed,
});

typedef StudentCoursePageData = ({
  List<StudentCourseItem> courses,
  bool hasMore,
});

typedef StudentResumeLesson = ({
  String lessonId,
  String lessonTitle,
  String subjectId,
  String subjectName,
  int positionSeconds,
  int? durationSeconds,
});

typedef StudentHomeData = ({
  StudentResumeLesson? resumeLesson,
  String name,
  List<StudentSubjectItem> subjects,
  List<({String id, String name})> courses,
});

typedef StudentLessonSummary = ({
  String? id,
  String title,
  bool locked,
  bool completed,
  int? position,
  int? durationSeconds,
});

typedef StudentSubjectDetails = ({StudentSubjectItem subject, bool subscribed});

typedef StudentProfileData = ({
  String name,
  String email,
  String? phone,
  String? department,
  int? year,
});

enum StudentDeviceStatus {
  notApplicable,
  unregistered,
  authorized,
  unauthorized,
}

typedef StudentDeviceData = ({
  StudentDeviceStatus status,
  String? name,
  String? platform,
  DateTime? registeredAt,
});

typedef StudentSubjectFile = ({
  String id,
  String title,
  int? pages,
  bool downloadable,
});
typedef StudentFilePage = ({Uint8List bytes, int? totalPages});

enum StudentFileViewFailure {
  network,
  unavailable,
  accountSuspended,
  deviceUnauthorized,
}

abstract interface class StudentFileViewer {
  Future<Either<StudentFileViewFailure, StudentFilePage>> page(int number);
  void close();
}

enum StudentExerciseState { notAttempted, attempted, grading, solved }

typedef StudentSubjectExercise = ({
  String id,
  String title,
  StudentExerciseState state,
  num? bestScore,
});

typedef StudentLessonDetail = ({
  String title,
  String? description,
  bool locked,
  bool videoReady,
  int? durationSeconds,
  int positionSeconds,
  int? myRating,
  String? nextId,
});

enum StudentSubscriptionState { active, upcoming, expired, revoked }

typedef StudentSubscription = ({
  String? name,
  String scope,
  StudentSubscriptionState state,
  DateTime startsAt,
  DateTime expiresAt,
  int daysLeft,
});

typedef StudentTicket = ({
  String id,
  String subject,
  String status,
  DateTime updatedAt,
});
typedef StudentTicketPage = ({List<StudentTicket> tickets, bool hasMore});
typedef StudentTicketMessage = ({
  bool fromSupport,
  String body,
  DateTime sentAt,
});
typedef StudentTicketThread = ({
  StudentTicket ticket,
  List<StudentTicketMessage> messages,
});

typedef StudentTicketReply = ({
  StudentTicket ticket,
  StudentTicketMessage message,
});

sealed class StudentExercisePrompt {
  const StudentExercisePrompt(this.title, this.statement);
  final String title;
  final String statement;
}

final class StudentCodingPrompt extends StudentExercisePrompt {
  const StudentCodingPrompt(
    super.title,
    super.statement,
    this.language,
    this.starterCode,
  );
  final String language;
  final String starterCode;
}

final class StudentChoicePrompt extends StudentExercisePrompt {
  const StudentChoicePrompt(super.title, super.statement, this.choices);
  final List<({String id, String text})> choices;
}

enum StudentAttemptStatus { grading, graded, failed }

typedef StudentAttempt = ({
  String id,
  StudentAttemptStatus status,
  num? score,
  bool? passed,
  String? explanation,
  String? suggestedFix,
});

enum StudentCourseContentType { lesson, file, exercise }

typedef StudentCourseContent = ({
  String id,
  String title,
  StudentCourseContentType type,
  bool locked,
  bool isFree,
});

typedef StudentGrade = ({
  String id,
  String name,
  num? theory,
  num? practical,
  num? total,
  String? result,
});
typedef StudentGradeTerm = ({String name, List<StudentGrade> subjects});
typedef StudentGrades = ({num? average, List<StudentGradeTerm> terms});

typedef StudentGradeAttempt = ({
  String term,
  String session,
  num? theory,
  num? practical,
  num? total,
  String? result,
});
typedef StudentGradeDetail = ({
  num? passMark,
  List<StudentGradeAttempt> attempts,
});

enum StudentExamSession { regular, supplementary }

typedef StudentExam = ({
  String id,
  String subjectId,
  bool practical,
  DateTime startsAt,
  String? room,
});

typedef StudentStudyDay = ({DateTime date, int seconds});
typedef StudentStudyTime = ({int totalSeconds, List<StudentStudyDay> days});

sealed class StudentNotificationDestination {
  const StudentNotificationDestination();

  static StudentNotificationDestination? parse(String? raw) {
    final uri = raw == null ? null : Uri.tryParse(raw);
    if (uri == null || uri.hasScheme || uri.hasAuthority || uri.hasFragment) {
      return null;
    }
    if (uri.path == 'me/device' && !uri.hasQuery) {
      return const StudentDeviceNotificationDestination();
    }
    if (uri.path.startsWith('exams/') && !uri.hasQuery) {
      final id = uri.path.substring('exams/'.length);
      return _notificationUuid.hasMatch(id)
          ? StudentExamNotificationDestination(id)
          : null;
    }
    if (uri.path != 'grades') return null;
    final Map<String, List<String>> query;
    try {
      query = uri.queryParametersAll;
    } on FormatException {
      return null;
    }
    if (query.length != 1) return null;
    final ids = query['termId'];
    if (ids == null ||
        ids.length != 1 ||
        !_notificationUuid.hasMatch(ids.single)) {
      return null;
    }
    return StudentGradesNotificationDestination(ids.single);
  }
}

final _notificationUuid = RegExp(
  r'^[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
);

final class StudentExamNotificationDestination
    extends StudentNotificationDestination {
  const StudentExamNotificationDestination(this.id);
  final String id;
}

final class StudentDeviceNotificationDestination
    extends StudentNotificationDestination {
  const StudentDeviceNotificationDestination();
}

final class StudentGradesNotificationDestination
    extends StudentNotificationDestination {
  const StudentGradesNotificationDestination(this.termId);
  final String termId;
}

typedef StudentNotification = ({
  String id,
  String title,
  String body,
  DateTime createdAt,
  bool read,
  StudentNotificationDestination? destination,
});
typedef StudentNotificationPage = ({
  List<StudentNotification> items,
  String? nextCursor,
});
