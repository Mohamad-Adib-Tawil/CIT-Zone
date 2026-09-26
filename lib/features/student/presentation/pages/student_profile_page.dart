import 'package:flutter/material.dart';

import '../../../auth/domain/google_identity.dart';
import '../widgets/student_components.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key, this.identity});

  final GoogleIdentity? identity;

  @override
  Widget build(BuildContext context) {
    final name = identity?.displayName?.trim();
    return StudentPageFrame(
      title: 'ملفي الشخصي',
      subtitle: identity == null
          ? 'تصور واجهة الملف قبل ربط حساب التطبيق بالخادم'
          : 'هوية Google المعروضة في معاينة الطالب',
      children: [
        const StudentNotice(
          'هذه معاينة فقط. هوية Google لا تعني إنشاء حساب CIT Zone أو ربط هذا الجهاز.',
        ),
        const SizedBox(height: 18),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: Text(
                  name == null || name.isEmpty ? 'الاسم والبريد' : name,
                ),
                subtitle: identity == null
                    ? const Text(
                        'اختيار Google يعرض بيانات الهوية هنا في وضع التطوير',
                      )
                    : Text(identity!.email, textDirection: TextDirection.ltr),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.smartphone_outlined),
                title: Text('جهازي'),
                subtitle: Text('حالة الربط وطلبات النقل بعد تفعيل الخادم'),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.verified_user_outlined),
                title: Text('استحقاقاتي'),
                subtitle: Text('تُقرأ من الخادم ولا تُستنتج من بيانات محلية'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const StudentEmptyPanel(
          icon: Icons.support_agent_rounded,
          title: 'المساعدة ونقل الجهاز',
          message: 'يحتاج إرسال طلب النقل إلى سياسة تحقق وخادم يسجل القرار.',
        ),
      ],
    );
  }
}
