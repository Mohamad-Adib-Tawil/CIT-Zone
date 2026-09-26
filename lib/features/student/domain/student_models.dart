class StudentPlacement {
  const StudentPlacement({
    required this.department,
    required this.year,
    required this.term,
  });

  final String department;
  final String year;
  final String term;
}

class StudentLesson {
  const StudentLesson({
    required this.title,
    required this.durationMinutes,
    required this.isPreview,
    required this.attachmentCount,
  });

  final String title;
  final int durationMinutes;
  final bool isPreview;
  final int attachmentCount;
}

class StudentCourse {
  const StudentCourse({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.instructor,
    required this.placements,
    required this.lessons,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String instructor;
  final List<StudentPlacement> placements;
  final List<StudentLesson> lessons;
}
