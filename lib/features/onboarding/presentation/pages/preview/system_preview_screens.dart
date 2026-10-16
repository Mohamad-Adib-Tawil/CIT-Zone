import 'package:flutter/material.dart';

import '../../theme/hasobjy_visual_scope.dart';
import '../../widgets/hasobjy_figma_components.dart';
import 'preview_widgets.dart';

class SystemPreviewScreen extends StatelessWidget {
  const SystemPreviewScreen({
    super.key,
    required this.frame,
    required this.actions,
  });
  final String frame;
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) {
    if (frame == 'I-01') {
      return HasobjyFigmaFrame(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: HasobjySvg(
                      context.designFrame!.assets['imgH']!,
                      width: 96,
                      height: 96,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PreviewText(
                  'حاسوبجي سيستم',
                  style: context.design.title,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 16),
                PreviewText(
                  'المعهد التقني للحاسوب',
                  style: context.design.bodySmall,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (frame == 'E-01') return _Downloads(actions: actions);
    final (title, description) = switch (frame) {
      'I-02' => (
        'لا يوجد اتصال بالإنترنت',
        'يمكنك متابعة الدروس التي نزّلتها مسبقاً. ستُحفظ تقدّمك وتتزامن عند عودة الاتصال.',
      ),
      'I-03' => (
        'التطبيق قيد الصيانة',
        'نُجري تحديثات لتحسين الخدمة. سنعود قريباً، شكراً لصبرك.',
      ),
      'I-04' => (
        'يتوفر تحديث جديد',
        'لمتابعة الاستخدام يجب تحديث التطبيق إلى أحدث إصدار.',
      ),
      _ => (
        'حدث خطأ غير متوقع',
        'لم نتمكن من إكمال العملية. حاول مجدداً، وإن تكرر الخطأ تواصل مع الدعم.',
      ),
    };
    return PreviewScaffold(
      actions: actions,
      children: [
        Center(
          child: PreviewIconTile(
            asset: context.designFrame!.assets['imgGlyph'],
            size: 112,
            fill: context.design.selectedSurface,
          ),
        ),
        PreviewText(
          title,
          style: context.design.title,
          align: TextAlign.center,
        ),
        PreviewText(description, align: TextAlign.center),
        const Spacer(),
        if (frame == 'I-04') PreviewButton('تحديث الآن', onTap: actions.notice),
        if (frame == 'I-02' || frame == 'I-05') ...[
          PreviewButton('إعادة المحاولة', onTap: actions.notice),
          PreviewButton(
            frame == 'I-02' ? 'الانتقال إلى التنزيلات' : 'التواصل مع الدعم',
            onTap: () => actions.open(frame == 'I-02' ? 'E-01' : 'H-02'),
            primary: false,
          ),
        ],
      ],
    );
  }
}

class _Downloads extends StatelessWidget {
  const _Downloads({required this.actions});
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => PreviewScaffold(
    title: 'التنزيلات',
    actions: actions,
    gap: 12,
    children: [
      PreviewPanel(
        height: 94,
        gap: 6,
        children: [
          PreviewText(
            'المساحة المستخدمة',
            style: context.design.bodySmall,
            muted: true,
          ),
          PreviewText('420 MB من 2 GB', style: context.design.labelSemiBold),
          const Align(
            alignment: Alignment.centerLeft,
            child: PreviewProgress(.21, width: 300, height: 6),
          ),
        ],
      ),
      for (final item in const [
        (
          'الدرس 4: لغة SQL الأساسية',
          'قواعد البيانات · 86 MB',
          'جاهز دون إنترنت',
          'success',
        ),
        (
          'الدرس 5: العلاقات بين الجداول',
          'قواعد البيانات · 74 MB',
          'جارٍ التنزيل 40%',
          'brand',
        ),
        (
          'الدرس 2: الأصناف والكائنات',
          'برمجة كائنية · 92 MB',
          'ينتهي خلال 3 أيام',
          'warning',
        ),
      ])
        PreviewListCard(
          title: item.$1,
          subtitle: item.$2,
          height: 108,
          badge: previewBadge(context, item.$3, tone: item.$4),
          onTap: actions.notice,
        ),
    ],
  );
}
