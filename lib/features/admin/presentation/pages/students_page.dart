import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import 'entitlement_preview_page.dart';
import '../widgets/admin_components.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({
    super.key,
    required this.data,
    required this.onOpenStudent,
  });

  final AdminDashboardData data;
  final ValueChanged<AdminStudent> onOpenStudent;

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final students = widget.data.students.where((student) {
      return _query.isEmpty ||
          '${student.name} ${student.email}'.contains(_query);
    }).toList();
    return AdminPageFrame(
      title: 'الطلاب',
      subtitle: 'راجع الحسابات والاستحقاقات وحالات الأجهزة',
      children: [
        AdminSearchField(
          hint: 'ابحث باسم الطالب أو بريده',
          onChanged: (value) => setState(() => _query = value.trim()),
        ),
        const SizedBox(height: 18),
        Text(
          '${students.length} طلاب',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (students.isEmpty)
          const AdminEmptyState(message: 'لا يوجد طلاب يطابقون البحث.')
        else
          for (final student in students) ...[
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => widget.onOpenStudent(student),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primary
                            .withValues(alpha: 0.1),
                        child: Text(
                          student.name.characters.first,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              student.email,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${student.entitlements.length} استحقاقات · ${student.deviceLabel}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
        const AdminDemoActionNote(
          text: 'بيانات الطلاب هنا تجريبية. البحث والإجراءات الفعلية تتطلب API مع صلاحيات وتدقيق.',
        ),
      ],
    );
  }
}

class StudentDetailsPage extends StatelessWidget {
  const StudentDetailsPage({
    super.key,
    required this.student,
    required this.courses,
  });

  final AdminStudent student;
  final List<AdminCourse> courses;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطالب')),
      body: AdminPageFrame(
        title: student.name,
        subtitle: student.email,
        action: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  EntitlementPreviewPage(student: student, courses: courses),
            ),
          ),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('معاينة منح وصول'),
        ),
        children: [
          AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionTitle('الحساب والجهاز'),
                ListTile(
                  leading: const Icon(Icons.perm_identity_rounded),
                  title: const Text('معرف الطالب'),
                  subtitle: Text(student.id),
                ),
                ListTile(
                  leading: const Icon(Icons.smartphone_rounded),
                  title: const Text('حالة الجهاز'),
                  subtitle: Text(student.deviceLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const AdminSectionTitle('الاستحقاقات'),
          if (student.entitlements.isEmpty)
            const AdminEmptyState(message: 'لا توجد دورات متاحة لهذا الطالب.')
          else
            for (final entitlement in student.entitlements) ...[
              AdminPanel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(entitlement.courseTitle),
                  subtitle: Text(
                    '${entitlement.source} · ينتهي ${adminDate(entitlement.expiresAt)}',
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          const AdminDemoActionNote(
            text: 'منح الاستحقاق ونقل الجهاز لا يعملان دون خادم يتحقق من الصلاحيات ويسجل الإجراء.',
          ),
        ],
      ),
    );
  }
}
