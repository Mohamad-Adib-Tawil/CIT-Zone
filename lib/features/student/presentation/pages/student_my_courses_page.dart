import 'package:flutter/material.dart';

import '../widgets/student_components.dart';

class StudentMyCoursesPage extends StatelessWidget {
  const StudentMyCoursesPage({super.key, required this.onOpenCatalog});

  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    return StudentPageFrame(
      title: 'دوراتي',
      subtitle: 'ستظهر هنا الدورات التي يمنحك الخادم حق الوصول إليها',
      children: [
        StudentEmptyPanel(
          icon: Icons.auto_stories_outlined,
          title: 'لا توجد استحقاقات متصلة',
          message: 'معاينة التطبيق لا تنشئ اشتراكاً أو حقاً في أي دورة.',
          action: OutlinedButton.icon(
            onPressed: onOpenCatalog,
            icon: const Icon(Icons.explore_outlined),
            label: const Text('استعرض المواد النموذجية'),
          ),
        ),
      ],
    );
  }
}
