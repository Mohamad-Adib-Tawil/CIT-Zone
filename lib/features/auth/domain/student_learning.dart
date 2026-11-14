import 'dart:typed_data';

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

abstract interface class StudentFileViewer {
  Future<StudentFilePage?> page(int number);
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
