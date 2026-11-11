import 'package:flutter/material.dart';

import '../../theme/hasobjy_visual_scope.dart';
import 'preview_widgets.dart';
import 'student_update_scaffold.dart';

/// Figma examples only. No device tracking or client-defined week boundaries.
class ActivityPreviewScreen extends StatelessWidget {
  const ActivityPreviewScreen({super.key, required this.actions});
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => StudentUpdateScaffold(
    title: 'وقتي في التطبيق',
    actions: actions,
    children: [
      PreviewPanel(
        gap: 4,
        center: true,
        children: [
          PreviewText(
            'هذا الأسبوع',
            style: context.design.bodySmall,
            color: context.design.textMuted,
          ),
          PreviewText(
            '4 س 35 د',
            style: context.design.display,
            color: context.design.brand,
            align: TextAlign.center,
          ),
          PreviewText(
            'أكثر بـ 45 دقيقة من الأسبوع الماضي',
            style: context.design.bodySmall,
            color: context.design.successText,
            align: TextAlign.center,
          ),
        ],
      ),
      PreviewPanel(
        gap: 12,
        children: [
          PreviewText('نشاطك اليومي', style: context.design.label),
          Row(
            textDirection: TextDirection.ltr,
            children: [
              for (final day in const [
                ('جمعة', 0),
                ('خميس', 0),
                ('أربعاء', 0),
                ('ثلاثاء', 95),
                ('اثنين', 45),
                ('أحد', 80),
                ('سبت', 55),
              ])
                Expanded(
                  child: Semantics(
                    label: '${day.$1}: ${day.$2} دقيقة',
                    child: ExcludeSemantics(
                      child: SizedBox(
                        height:
                            130 *
                            MediaQuery.textScalerOf(context).scale(12) /
                            12,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            PreviewText(
                              day.$2 == 0 ? '—' : '${day.$2}د',
                              style: context.design.badge,
                              align: TextAlign.center,
                              color: day.$2 == 0
                                  ? context.design.textMuted
                                  : context.design.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 20,
                              height: day.$2 == 0 ? 3 : day.$2 * .905,
                              color: day.$2 == 95
                                  ? context.design.brand
                                  : day.$2 == 0
                                  ? context.design.border
                                  : context.design.selectedSurface,
                            ),
                            const SizedBox(height: 4),
                            PreviewText(
                              day.$1,
                              style: context.design.bodySmall,
                              align: TextAlign.center,
                              color: day.$2 == 95
                                  ? context.design.brand
                                  : context.design.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      PreviewPanel(
        gap: 12,
        children: [
          PreviewText('حسب المادة', style: context.design.label),
          for (final item in const [
            ('قواعد البيانات', '1 س 45 د', 1.0),
            ('برمجة كائنية', '1 س 20 د', 236 / 310),
            ('هندسة البرمجيات', '55 د', 162 / 310),
            ('تطوير الويب', '35 د', 103 / 310),
          ])
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: PreviewText(item.$1, primary: true)),
                    PreviewText(item.$2, style: context.design.badge),
                  ],
                ),
                const SizedBox(height: 6),
                PreviewProgress(item.$3),
              ],
            ),
        ],
      ),
      PreviewText(
        'يُحتسب الوقت أثناء مشاهدة الدروس وحلّ التمارين فقط.',
        style: context.design.bodySmall,
        color: context.design.textMuted,
      ),
    ],
  );
}
