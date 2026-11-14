import 'package:flutter/material.dart';

import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentRegisteredDevice extends StatelessWidget {
  const StudentRegisteredDevice({super.key, required this.device});

  final StudentDeviceData device;

  @override
  Widget build(BuildContext context) {
    final platform = switch (device.platform) {
      'android' => 'Android',
      'ios' => 'iOS',
      _ => device.platform,
    };
    final status = switch (device.status) {
      StudentDeviceStatus.notApplicable => 'حساب الكورسات لا يتطلب تسجيل جهاز.',
      StudentDeviceStatus.unregistered => 'لا يوجد جهاز مسجّل لهذا الحساب.',
      StudentDeviceStatus.authorized => 'نشط',
      StudentDeviceStatus.unauthorized => 'الجهاز الحالي غير مصرّح به',
    };
    if (platform == null) return PreviewPanel(children: [PreviewText(status)]);
    return PreviewPanel(
      gap: 12,
      children: [
        Row(
          children: [
            PreviewIconTile(asset: context.design.isLight ? 'e8da6' : 'dcfca'),
            const SizedBox(width: 12),
            Expanded(
              child: PreviewText(
                device.name ?? platform,
                style: context.design.labelSemiBold,
              ),
            ),
          ],
        ),
        PreviewKeyValue('حالة الجهاز', status, body: true),
        PreviewKeyValue('نظام التشغيل', platform, body: true),
        if (device.registeredAt case final date?)
          PreviewKeyValue(
            'تاريخ التسجيل',
            MaterialLocalizations.of(context).formatMediumDate(date.toLocal()),
            body: true,
          ),
      ],
    );
  }
}
