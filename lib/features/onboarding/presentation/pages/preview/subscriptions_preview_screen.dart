import 'package:flutter/material.dart';

import '../../theme/hasobjy_visual_scope.dart';
import 'preview_widgets.dart';
import 'student_update_scaffold.dart';

/// Labels/dates are the design fixture; never used to grant content access.
class SubscriptionsPreviewScreen extends StatelessWidget {
  const SubscriptionsPreviewScreen({super.key, required this.actions});
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => StudentUpdateScaffold(
    title: 'اشتراكاتي',
    actions: actions,
    gap: 12,
    children: [
      PreviewText('المواد الدراسية', style: context.design.labelSemiBold),
      _group(context, const [
        (
          'اشتراك الفصل الثالث الكامل',
          '4 مواد · حتى 30 يونيو 2027',
          'نشط',
          'success',
        ),
        (
          'هندسة البرمجيات',
          'مفتوحة للمراجعة فقط بعد انتهاء الفصل',
          'مراجعة',
          'neutral',
        ),
      ]),
      PreviewText('الكورسات', style: context.design.labelSemiBold),
      _group(context, const [
        (
          'تطوير تطبيقات Flutter',
          'ينتهي الوصول في 15 أكتوبر 2027',
          'نشط',
          'success',
        ),
        (
          'أساسيات Python',
          'ينتهي الوصول في 28 أكتوبر 2026',
          'ينتهي قريباً',
          'warning',
        ),
      ]),
      PreviewText(
        'مدة الوصول إلى كل كورس سنة كاملة من تاريخ الشراء.',
        style: context.design.bodySmall,
        color: context.design.textMuted,
      ),
      const Spacer(),
      PreviewButton(
        'تصفّح الكورسات',
        primary: false,
        onTap: () => actions.open('F-01'),
      ),
    ],
  );

  Widget _group(
    BuildContext context,
    List<(String, String, String, String)> rows,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: context.design.surface,
      border: Border.all(color: context.design.border),
    ),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) Container(height: 1, color: context.design.border),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    previewBadge(context, rows[i].$3, tone: rows[i].$4),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PreviewText(
                        rows[i].$1,
                        style: context.design.labelSemiBold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                PreviewText(
                  rows[i].$2,
                  style: context.design.bodySmall,
                  color: context.design.textMuted,
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}
