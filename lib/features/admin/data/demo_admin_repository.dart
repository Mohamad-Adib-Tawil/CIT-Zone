import '../domain/admin_models.dart';
import '../domain/admin_repository.dart';

/// Development-only sample data. Never use this repository for authorization.
class DemoAdminRepository implements AdminRepository {
  @override
  Future<AdminDashboardData> loadDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return AdminDashboardData(
      asOf: DateTime.now().toUtc(),
      courses: [
        AdminCourse(
          id: 'course-1',
          subject: 'مقدمة البرمجة',
          code: 'CIT-101',
          instructor: 'أ. أحمد',
          description: 'أساسيات التفكير البرمجي وبناء البرامج الأولى.',
          status: AdminCourseStatus.published,
          departments: const ['البرمجيات', 'الشبكات'],
          lessons: const [
            AdminLesson(
              title: 'تعرف على المادة وخطة الدراسة',
              durationMinutes: 8,
              isPreview: true,
              mediaStatus: AdminMediaStatus.ready,
              attachmentCount: 0,
            ),
            AdminLesson(
              title: 'المتغيرات وأنواع البيانات',
              durationMinutes: 24,
              isPreview: false,
              mediaStatus: AdminMediaStatus.ready,
              attachmentCount: 2,
            ),
            AdminLesson(
              title: 'التحكم بتدفق البرنامج',
              durationMinutes: 31,
              isPreview: false,
              mediaStatus: AdminMediaStatus.ready,
              attachmentCount: 1,
            ),
          ],
          updatedAt: DateTime.utc(2026, 9, 25, 11, 20),
        ),
        AdminCourse(
          id: 'course-2',
          subject: 'قواعد البيانات',
          code: 'CIT-204',
          instructor: 'أ. ليلى',
          description: 'نمذجة البيانات والاستعلامات والعلاقات.',
          status: AdminCourseStatus.published,
          departments: const ['البرمجيات', 'الشبكات'],
          lessons: const [
            AdminLesson(
              title: 'ماذا ستتعلم في هذه المادة؟',
              durationMinutes: 7,
              isPreview: true,
              mediaStatus: AdminMediaStatus.ready,
              attachmentCount: 0,
            ),
            AdminLesson(
              title: 'الجداول والعلاقات',
              durationMinutes: 28,
              isPreview: false,
              mediaStatus: AdminMediaStatus.ready,
              attachmentCount: 1,
            ),
          ],
          updatedAt: DateTime.utc(2026, 9, 24, 15, 10),
        ),
        AdminCourse(
          id: 'course-3',
          subject: 'أساسيات الشبكات',
          code: 'NET-110',
          instructor: 'أ. خالد',
          description: 'مدخل إلى الشبكات والبروتوكولات الأساسية.',
          status: AdminCourseStatus.draft,
          departments: const ['الشبكات'],
          lessons: const [
            AdminLesson(
              title: 'نظرة عامة على المادة',
              durationMinutes: 9,
              isPreview: true,
              mediaStatus: AdminMediaStatus.processing,
              attachmentCount: 0,
            ),
          ],
          updatedAt: DateTime.utc(2026, 9, 26, 9, 5),
        ),
        AdminCourse(
          id: 'course-4',
          subject: 'الخوارزميات',
          code: 'CIT-210',
          instructor: 'أ. سارة',
          description: 'تصميم الحلول وتحليلها بصورة منهجية.',
          status: AdminCourseStatus.draft,
          departments: const ['البرمجيات'],
          lessons: const [],
          updatedAt: DateTime.utc(2026, 9, 23, 12, 40),
        ),
      ],
      placements: const [
        AdminPlacement(
          id: 'p1',
          subject: 'مقدمة البرمجة',
          department: 'البرمجيات',
          year: 'الأولى',
          term: 'الأول',
          courseId: 'course-1',
        ),
        AdminPlacement(
          id: 'p2',
          subject: 'مقدمة البرمجة',
          department: 'الشبكات',
          year: 'الأولى',
          term: 'الأول',
          courseId: 'course-1',
        ),
        AdminPlacement(
          id: 'p3',
          subject: 'قواعد البيانات',
          department: 'البرمجيات',
          year: 'الثانية',
          term: 'الأول',
          courseId: 'course-2',
        ),
        AdminPlacement(
          id: 'p4',
          subject: 'قواعد البيانات',
          department: 'الشبكات',
          year: 'الثانية',
          term: 'الثاني',
          courseId: 'course-2',
        ),
        AdminPlacement(
          id: 'p5',
          subject: 'أساسيات الشبكات',
          department: 'الشبكات',
          year: 'الأولى',
          term: 'الثاني',
          courseId: 'course-3',
        ),
        AdminPlacement(
          id: 'p6',
          subject: 'الخوارزميات',
          department: 'البرمجيات',
          year: 'الثانية',
          term: 'الأول',
          courseId: 'course-4',
        ),
      ],
      media: [
        AdminMedia(
          id: 'm1',
          title: 'مقدمة المادة.mp4',
          courseTitle: 'أساسيات الشبكات',
          status: AdminMediaStatus.processing,
          sizeLabel: '420 MB',
          createdAt: DateTime.utc(2026, 9, 26, 8, 45),
        ),
        AdminMedia(
          id: 'm2',
          title: 'الجداول والعلاقات.mp4',
          courseTitle: 'قواعد البيانات',
          status: AdminMediaStatus.ready,
          sizeLabel: '860 MB',
          createdAt: DateTime.utc(2026, 9, 24, 13, 10),
        ),
        AdminMedia(
          id: 'm3',
          title: 'مقدمة الخوارزميات.mp4',
          courseTitle: 'الخوارزميات',
          status: AdminMediaStatus.failed,
          sizeLabel: '310 MB',
          createdAt: DateTime.utc(2026, 9, 25, 17, 30),
        ),
      ],
      students: [
        AdminStudent(
          id: 'student-1',
          name: 'علي محمود',
          email: 'a***@example.com',
          deviceLabel: 'جهاز مرتبط',
          entitlements: [
            AdminEntitlement(
              courseTitle: 'مقدمة البرمجة',
              expiresAt: DateTime.utc(2027, 1, 31),
              source: 'منح إداري',
            ),
          ],
        ),
        AdminStudent(
          id: 'student-2',
          name: 'هبة أحمد',
          email: 'h***@example.com',
          deviceLabel: 'جهاز مرتبط',
          entitlements: [
            AdminEntitlement(
              courseTitle: 'قواعد البيانات',
              expiresAt: DateTime.utc(2027, 2, 28),
              source: 'منح إداري',
            ),
          ],
        ),
        const AdminStudent(
          id: 'student-3',
          name: 'محمد خالد',
          email: 'm***@example.com',
          deviceLabel: 'طلب نقل جهاز',
          entitlements: [],
        ),
        const AdminStudent(
          id: 'student-4',
          name: 'نور علي',
          email: 'n***@example.com',
          deviceLabel: 'لا يوجد جهاز',
          entitlements: [],
        ),
      ],
      deviceRequests: [
        AdminDeviceRequest(
          id: 'request-1',
          studentName: 'محمد خالد',
          reason: 'تغيير الهاتف',
          status: AdminRequestStatus.pending,
          createdAt: DateTime.utc(2026, 9, 26, 7, 20),
        ),
        AdminDeviceRequest(
          id: 'request-2',
          studentName: 'علي محمود',
          reason: 'الهاتف السابق لم يعد متاحاً',
          status: AdminRequestStatus.completed,
          createdAt: DateTime.utc(2026, 9, 22, 14, 0),
        ),
      ],
      activities: [
        AdminActivity(
          title: 'تحديث دورة قواعد البيانات',
          details: 'تعديل وصف الدرس الثاني',
          actor: 'الإدارة',
          occurredAt: DateTime.utc(2026, 9, 25, 11, 45),
        ),
        AdminActivity(
          title: 'منح وصول لمقدمة البرمجة',
          details: 'الطالب: علي محمود',
          actor: 'الإدارة',
          occurredAt: DateTime.utc(2026, 9, 24, 9, 10),
        ),
        AdminActivity(
          title: 'نشر دورة مقدمة البرمجة',
          details: '3 دروس منشورة',
          actor: 'الإدارة',
          occurredAt: DateTime.utc(2026, 9, 23, 16, 30),
        ),
      ],
      attention: const [
        AdminAttentionItem(
          title: 'فشل معالجة فيديو',
          details: 'مقدمة الخوارزميات · تحقق من الملف',
          target: AdminAttentionTarget.media,
          targetId: 'm3',
        ),
        AdminAttentionItem(
          title: 'طلب نقل جهاز بانتظار المراجعة',
          details: 'محمد خالد · تغيير الهاتف',
          target: AdminAttentionTarget.deviceRequests,
          targetId: 'request-1',
        ),
        AdminAttentionItem(
          title: 'دورة تنتظر إكمال الفيديو',
          details: 'أساسيات الشبكات · درس تعريفي',
          target: AdminAttentionTarget.course,
          targetId: 'course-3',
        ),
      ],
    );
  }
}
