import 'package:flutter/material.dart';

import '../../theme/hasobjy_visual_scope.dart';
import '../../widgets/hasobjy_figma_components.dart';
import 'preview_widgets.dart';
import 'student_update_scaffold.dart';

class GradeReportPreviewScreen extends StatelessWidget {
  const GradeReportPreviewScreen({super.key, required this.actions});
  final PreviewActions actions;
  static const ink = Color(0xFF02112C);
  static const muted = Color(0xFF3D5A78);
  static const line = Color(0xFFC5DFF0);

  @override
  Widget build(BuildContext context) => StudentUpdateScaffold(
    title: 'كشف علاماتي',
    actions: actions,
    children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _text(
              context,
              'المعهد التقني للحاسوب · حلب',
              color: muted,
              medium: true,
            ),
            const SizedBox(height: 10),
            _text(context, 'كشف علامات الطالب', heading: true),
            const SizedBox(height: 10),
            Container(height: 1, color: line),
            const SizedBox(height: 10),
            _text(context, 'أحمد محمد الحلبي', label: true),
            const SizedBox(height: 10),
            _text(
              context,
              'برمجيات · السنة الثانية · الفصل الثالث 2026/2027',
              color: muted,
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(border: Border.all(color: line)),
              child: Column(
                children: [
                  _row(context, const [
                    'المادة',
                    'نظري /60',
                    'عملي /40',
                    'المجموع',
                  ], header: true),
                  _row(context, const ['قواعد البيانات', '52', '33', '85']),
                  _row(context, const ['برمجة كائنية', '44', '28', '72']),
                  _row(context, const [
                    'هندسة البرمجيات',
                    '34',
                    '24',
                    '58 · راسب',
                  ], failed: true),
                  _row(context, const ['تطوير الويب', '46', '31', '77']),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _text(context, 'المعدل العام', label: true)),
                Text(
                  '73 / 100',
                  textDirection: TextDirection.ltr,
                  style: context.design.labelSemiBold.copyWith(color: ink),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _text(
              context,
              'تاريخ الإصدار: 2 فبراير 2027',
              color: const Color(0xFF587A9C),
            ),
          ],
        ),
      ),
      const Spacer(),
      HasobjyButton(
        label: 'حفظ كملف PDF',
        onPressed: actions.notice,
        icon: HasobjySvg(
          context.designFrame!.assets['imgGlyph']!,
          width: 24,
          height: 24,
        ),
      ),
      HasobjyButton(
        label: 'مشاركة الكشف',
        primary: false,
        onPressed: actions.notice,
      ),
    ],
  );

  Widget _text(
    BuildContext context,
    String value, {
    Color color = ink,
    bool heading = false,
    bool label = false,
    bool medium = false,
  }) => Text(
    value,
    textAlign: TextAlign.right,
    textDirection: TextDirection.rtl,
    style:
        (heading
                ? context.design.labelSemiBold
                : label
                ? context.design.label
                : medium
                ? context.design.badge
                : context.design.bodySmall)
            .copyWith(color: color),
  );

  Widget _row(
    BuildContext context,
    List<String> cells, {
    bool header = false,
    bool failed = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: header ? const Color(0xFFD9F1FD) : Colors.white,
      border: const Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _text(context, cells[0], medium: header)),
        for (var i = 1; i < cells.length; i++)
          SizedBox(
            width: 56,
            child: Text(
              cells[i],
              textAlign: TextAlign.center,
              style:
                  (header || i == 3
                          ? context.design.badge
                          : context.design.bodySmall)
                      .copyWith(
                        color: failed && i == 3 ? const Color(0xFFA32A2E) : ink,
                      ),
            ),
          ),
      ],
    ),
  );
}
