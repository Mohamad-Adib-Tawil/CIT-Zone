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

typedef StudentHomeData = ({
  String name,
  List<StudentSubjectItem> subjects,
  List<({String id, String name})> courses,
});

typedef StudentLessonSummary = ({
  String title,
  bool locked,
  bool completed,
  int? position,
  int? durationSeconds,
});

typedef StudentSubjectDetails = ({
  StudentSubjectItem subject,
  bool subscribed,
  List<StudentLessonSummary> lessons,
});

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
