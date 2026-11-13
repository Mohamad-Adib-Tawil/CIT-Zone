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

typedef StudentSubjectDetails = ({
  StudentSubjectItem subject,
  bool subscribed,
  List<({String title, bool locked, bool completed})> lessons,
});

typedef StudentProfileData = ({
  String name,
  String email,
  String? phone,
  String? department,
  int? year,
});
