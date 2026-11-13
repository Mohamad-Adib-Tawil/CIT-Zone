const studentProgramYears = {1, 2};

final class StudentDepartment {
  const StudentDepartment(this.id, this.name, this.years);

  final String id;
  final String name;
  final List<int> years;
}

final class StudentRegistrationSummary {
  const StudentRegistrationSummary({
    required this.officialName,
    required this.departmentId,
    required this.departmentName,
    required this.year,
    required this.semesterName,
  });

  final String officialName;
  final String departmentId;
  final String departmentName;
  final int year;
  final String? semesterName;
}

final class StudentTermRegistration {
  const StudentTermRegistration({
    required this.departmentName,
    required this.year,
    required this.semesterName,
    required this.startDate,
    required this.endDate,
    required this.changePending,
  });

  final String departmentName;
  final int year;
  final String semesterName;
  final DateTime startDate;
  final DateTime endDate;
  final bool changePending;
}
