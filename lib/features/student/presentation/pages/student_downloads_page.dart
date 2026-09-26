import 'package:flutter/material.dart';

import '../widgets/student_components.dart';

class StudentDownloadsPage extends StatelessWidget {
  const StudentDownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StudentPageFrame(
      title: 'التنزيلات',
      subtitle: 'دروسك المتاحة للتشغيل داخل التطبيق دون إنترنت',
      children: [
        StudentEmptyPanel(
          icon: Icons.download_for_offline_outlined,
          title: 'لا توجد تنزيلات بعد',
          message: 'سيُفعّل التنزيل بعد اعتماد مزود DRM واختبار الرخص على الأجهزة الحقيقية.',
        ),
        SizedBox(height: 16),
        StudentNotice(
          'لا يُحمّل التطبيق ملفات فيديو واضحة أو يحفظها في المعرض.',
          icon: Icons.shield_outlined,
        ),
      ],
    );
  }
}
