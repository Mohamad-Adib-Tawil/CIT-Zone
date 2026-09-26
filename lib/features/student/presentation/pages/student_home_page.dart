import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/student_models.dart';
import '../widgets/student_components.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({
    super.key,
    required this.courses,
    required this.onOpenCatalog,
    required this.onOpenCourse,
  });

  final List<StudentCourse> courses;
  final VoidCallback onOpenCatalog;
  final ValueChanged<StudentCourse> onOpenCourse;

  @override
  Widget build(BuildContext context) {
    return StudentPageFrame(
      title: 'مرحباً بك في CIT Zone',
      subtitle: 'ابدأ من مسارك الدراسي وتعرّف إلى المواد المتاحة',
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppPalette.primary, const Color(0xFF132A70)],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.school_rounded, color: Colors.white, size: 36),
              const SizedBox(height: 18),
              Text(
                'تعلم بخطوات واضحة',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر القسم والسنة والفصل، ثم استعرض الدرس التعريفي لكل مادة.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onOpenCatalog,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppPalette.primary,
                ),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('استعرض المواد'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const StudentNotice(
          'هذه معاينة تصميم بمواد نموذجية، وليست المنهج الرسمي.',
        ),
        const SizedBox(height: 25),
        const StudentSectionHeading(
          'مواد نموذجية',
          subtitle: 'لرؤية شكل الدورة والدروس قبل وصول بيانات المعهد',
        ),
        const SizedBox(height: 14),
        if (courses.isEmpty)
          const StudentEmptyPanel(
            icon: Icons.menu_book_outlined,
            title: 'لا توجد مواد للعرض',
            message: 'ستظهر المواد بعد تحميل المنهج المعتمد.',
          )
        else
          for (final course in courses.take(3)) ...[
            StudentCourseCard(
              course: course,
              onTap: () => onOpenCourse(course),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}
