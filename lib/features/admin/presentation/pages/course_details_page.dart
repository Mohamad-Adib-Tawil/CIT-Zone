import 'package:flutter/material.dart';

import '../../domain/admin_models.dart';
import '../widgets/admin_components.dart';
import 'lesson_editor_preview_page.dart';

class CourseDetailsPage extends StatelessWidget {
  const CourseDetailsPage({super.key, required this.course});

  final AdminCourse course;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الدورة')),
      body: AdminPageFrame(
        title: course.subject,
        subtitle: '${course.code} · ${course.instructor}',
        action: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LessonEditorPreviewPage(
                course: course,
                position: course.lessons.length + 1,
              ),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
          label: const Text('معاينة إضافة درس'),
        ),
        children: [
          AdminPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AdminStatusChip.course(course.status),
                    Text(
                      'آخر تعديل ${adminDateTime(course.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  course.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                Text('تظهر في: ${course.departments.join('، ')}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AdminSectionTitle('الدروس'),
          if (course.lessons.isEmpty)
            const AdminEmptyState(message: 'لم تُضف دروس إلى هذه المسودة بعد.')
          else
            for (var index = 0; index < course.lessons.length; index++) ...[
              AdminPanel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(child: Text('${index + 1}')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.lessons[index].title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${course.lessons[index].durationMinutes} دقيقة · ${course.lessons[index].attachmentCount} مرفقات',
                          ),
                          if (course.lessons[index].isPreview) ...[
                            const SizedBox(height: 4),
                            Text(
                              'الدرس التعريفي المجاني',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AdminStatusChip.media(course.lessons[index].mediaStatus),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          const AdminDemoActionNote(
            text: 'تحرير الدروس والمعاينة والنشر تحتاج API وخدمة وسائط معتمدة؛ هذه بيانات عرض فقط.',
          ),
        ],
      ),
    );
  }
}
