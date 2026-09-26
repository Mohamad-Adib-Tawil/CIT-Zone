import 'package:flutter/material.dart';

import '../../domain/student_models.dart';
import '../widgets/student_components.dart';

class StudentCoursePage extends StatelessWidget {
  const StudentCoursePage({super.key, required this.course});

  final StudentCourse course;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المادة')),
      body: StudentPageFrame(
        title: course.title,
        subtitle: '${course.code} · ${course.instructor}',
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StudentSectionHeading('عن الدورة'),
                  const SizedBox(height: 12),
                  Text(course.description),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const StudentSectionHeading('تظهر في المنهج'),
                  const SizedBox(height: 8),
                  for (final placement in course.placements)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        '${placement.department} · السنة ${placement.year} · الفصل ${placement.term}',
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const StudentSectionHeading('الدروس'),
          const SizedBox(height: 12),
          for (var index = 0; index < course.lessons.length; index++) ...[
            _LessonTile(lesson: course.lessons[index], index: index),
            const SizedBox(height: 9),
          ],
          const SizedBox(height: 14),
          const StudentNotice(
            'هذه معاينة للواجهة. تشغيل الفيديو والمرفقات والاشتراك تحتاج إلى خادم ووسائط مرخصة.',
            icon: Icons.lock_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.index});

  final StudentLesson lesson;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text(lesson.title),
        subtitle: Text(
          '${lesson.durationMinutes} دقيقة · ${lesson.attachmentCount} مرفقات',
        ),
        trailing: lesson.isPreview
            ? const Chip(label: Text('مجاني'))
            : const Icon(Icons.lock_outline_rounded),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              lesson.isPreview ? 'الدرس التعريفي' : 'درس يحتاج وصولاً',
            ),
            content: Text(
              lesson.isPreview
                  ? 'تشغيل المعاينة المجانية سيُفعّل بعد ربط خدمة الفيديو بالخادم.'
                  : 'صلاحية هذا الدرس يحددها الخادم بعد تفعيل الاشتراكات.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('حسناً'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
