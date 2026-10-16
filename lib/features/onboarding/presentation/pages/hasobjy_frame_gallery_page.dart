import 'package:flutter/material.dart';

import 'hasobjy_design_page.dart';

/// Development inspector for existing Figma frames, not a product screen.
class HasobjyFrameGalleryPage extends StatelessWidget {
  const HasobjyFrameGalleryPage({super.key, required this.onOpenFrame});

  final ValueChanged<HasobjyFrameId> onOpenFrame;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('معرض شاشات Figma')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '44 شاشة · 88 إطاراً بالنمطين الفاتح والداكن\n'
            'هذه واجهات Flutter المنفذة من Figma. البيانات أمثلة؛ '
            'الخادم والدفع والتصحيح غير متصلين.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => onOpenFrame(HasobjyFrameId.c01),
            child: const Text('افتح الرئيسية من Figma — C-01'),
          ),
          const SizedBox(height: 12),
          for (final frame in HasobjyFrameId.values.where((f) => !f.isLight))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${frame.frameName} — ${_names[frame.baseName]}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => onOpenFrame(frame),
                          child: Text('داكن · ${frame.figmaNodeId}'),
                        ),
                        OutlinedButton(
                          onPressed: () => onOpenFrame(frame.withLight(true)),
                          child: Text(
                            'فاتح · ${frame.withLight(true).figmaNodeId}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

const _names = <String, String>{
  "A-S01": "تسجيل الدخول",
  "A-S03": "اختيار نوع الاستخدام",
  "A-S04": "المعلومات الأساسية",
  "A-S05": "الجهاز غير مصرّح",
  "A-S06": "طلب تغيير الجهاز",
  "A-S07": "حالة الطلب",
  "A-S08": "الشروط وسياسة الخصوصية",
  "A-S09": "معلومات الكورسات فقط",
  "A-S10": "الحساب موقوف",
  "B-S01": "المعلومات الأكاديمية",
  "B-S03": "ملخص التأكيد",
  "B-S04": "تأكيد تسجيل الفصل الجديد",
  "B-S05": "حالات الفصل في الرئيسية",
  "B-S06": "جدول الامتحانات",
  "C-01": "الرئيسية",
  "C-02": "المواد",
  "C-03": "تفاصيل المادة",
  "C-04": "مشغّل الدرس",
  "C-05": "عارض PDF (عرض فقط)",
  "C-06": "التمارين",
  "C-07": "حلّ التمرين",
  "C-08": "نتيجة التصحيح",
  "E-01": "التنزيلات",
  "F-01": "الكورسات",
  "F-02": "تفاصيل الكورس",
  "F-03": "الدفع",
  "F-04": "تأكيد الحوالة",
  "F-05": "قسيمة الشحن",
  "F-06": "نجاح العملية",
  "G-01": "كشف العلامات",
  "G-02": "تفاصيل علامة المادة",
  "H-01": "الإشعارات",
  "H-02": "الدعم",
  "H-03": "تذكرة جديدة",
  "H-04": "تفاصيل التذكرة",
  "I-01": "شاشة البداية",
  "I-02": "لا يوجد اتصال",
  "I-03": "الصيانة",
  "I-04": "تحديث إجباري",
  "I-05": "خطأ عام",
  "S-01": "الإعدادات",
  "S-02": "الملف الشخصي",
  "S-03": "تعديل البيانات",
  "S-04": "الجهاز المسجّل",
};
