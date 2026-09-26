enum AdminCourseStatus { draft, published }

enum AdminMediaStatus { processing, ready, failed }

enum AdminRequestStatus { pending, completed, rejected }

enum AdminAttentionTarget { course, media, deviceRequests }

class AdminLesson {
  const AdminLesson({
    required this.title,
    required this.durationMinutes,
    required this.isPreview,
    required this.mediaStatus,
    required this.attachmentCount,
  });

  final String title;
  final int durationMinutes;
  final bool isPreview;
  final AdminMediaStatus mediaStatus;
  final int attachmentCount;
}

class AdminCourse {
  const AdminCourse({
    required this.id,
    required this.subject,
    required this.code,
    required this.instructor,
    required this.description,
    required this.status,
    required this.departments,
    required this.lessons,
    required this.updatedAt,
  });

  final String id;
  final String subject;
  final String code;
  final String instructor;
  final String description;
  final AdminCourseStatus status;
  final List<String> departments;
  final List<AdminLesson> lessons;
  final DateTime updatedAt;
}

class AdminPlacement {
  const AdminPlacement({
    required this.id,
    required this.subject,
    required this.department,
    required this.year,
    required this.term,
    required this.courseId,
  });

  final String id;
  final String subject;
  final String department;
  final String year;
  final String term;
  final String courseId;
}

class AdminMedia {
  const AdminMedia({
    required this.id,
    required this.title,
    required this.courseTitle,
    required this.status,
    required this.sizeLabel,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String courseTitle;
  final AdminMediaStatus status;
  final String sizeLabel;
  final DateTime createdAt;
}

class AdminEntitlement {
  const AdminEntitlement({
    required this.courseTitle,
    required this.expiresAt,
    required this.source,
  });

  final String courseTitle;
  final DateTime expiresAt;
  final String source;
}

class AdminStudent {
  const AdminStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.deviceLabel,
    required this.entitlements,
  });

  final String id;
  final String name;
  final String email;
  final String deviceLabel;
  final List<AdminEntitlement> entitlements;
}

class AdminDeviceRequest {
  const AdminDeviceRequest({
    required this.id,
    required this.studentName,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String studentName;
  final String reason;
  final AdminRequestStatus status;
  final DateTime createdAt;
}

class AdminActivity {
  const AdminActivity({
    required this.title,
    required this.details,
    required this.actor,
    required this.occurredAt,
  });

  final String title;
  final String details;
  final String actor;
  final DateTime occurredAt;
}

class AdminAttentionItem {
  const AdminAttentionItem({
    required this.title,
    required this.details,
    required this.target,
    this.targetId,
  });

  final String title;
  final String details;
  final AdminAttentionTarget target;
  final String? targetId;
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.asOf,
    required this.courses,
    required this.placements,
    required this.media,
    required this.students,
    required this.deviceRequests,
    required this.activities,
    required this.attention,
  });

  final DateTime asOf;
  final List<AdminCourse> courses;
  final List<AdminPlacement> placements;
  final List<AdminMedia> media;
  final List<AdminStudent> students;
  final List<AdminDeviceRequest> deviceRequests;
  final List<AdminActivity> activities;
  final List<AdminAttentionItem> attention;

  int get publishedCourseCount => courses
      .where((item) => item.status == AdminCourseStatus.published)
      .length;

  int get draftCourseCount =>
      courses.where((item) => item.status == AdminCourseStatus.draft).length;

  int get processingMediaCount =>
      media.where((item) => item.status == AdminMediaStatus.processing).length;

  int get pendingRequestCount => deviceRequests
      .where((item) => item.status == AdminRequestStatus.pending)
      .length;
}
