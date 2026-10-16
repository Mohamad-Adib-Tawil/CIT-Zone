import 'package:flutter/material.dart';

import '../../theme/hasobjy_visual_scope.dart';
import 'preview_widgets.dart';

class GradesSupportPreviewScreen extends StatelessWidget {
  const GradesSupportPreviewScreen({
    super.key,
    required this.frame,
    required this.actions,
  });
  final String frame;
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => switch (frame) {
    'G-01' => _grades(context),
    'G-02' => _grade(context),
    'H-01' => _notifications(context),
    'H-02' => _tickets(context),
    'H-03' => _newTicket(context),
    _ => _ticket(context),
  };
  Widget _grades(BuildContext context) => PreviewScaffold(
    title: 'كشف العلامات',
    actions: actions,
    gap: 12,
    children: [
      PreviewPanel(
        height: 118,
        center: true,
        gap: 4,
        children: [
          PreviewText(
            'المعدّل العام',
            style: context.design.bodySmall,
            color: context.design.textMuted,
          ),
          PreviewText(
            '78.5',
            style: context.design.display,
            color: context.design.brand,
          ),
          PreviewText(
            'من 100 · 4 مواد مُنجزة',
            style: context.design.bodySmall,
          ),
        ],
      ),
      for (final row in const [
        ('قواعد البيانات', '85', 'ناجح', 'success'),
        ('برمجة كائنية', '72', 'ناجح', 'success'),
        ('هندسة البرمجيات', '58', 'راسب · الحدّ 60', 'danger'),
        ('تطوير الويب', '—', 'قيد الإعلان', 'neutral'),
      ])
        InkWell(
          onTap: () => actions.open('G-02'),
          child: PreviewPanel(
            height: 62,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  PreviewText(row.$2, style: context.design.headingMedium),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: Align(
                      alignment: Alignment.center,
                      child: previewBadge(context, row.$3, tone: row.$4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PreviewText(
                      row.$1,
                      style: context.design.labelSemiBold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    ],
  );
  Widget _grade(BuildContext context) => PreviewScaffold(
    title: 'قواعد البيانات',
    actions: actions,
    children: [
      PreviewPanel(
        height: 104,
        center: true,
        gap: 6,
        children: [
          PreviewText(
            '85/100',
            style: context.design.display,
            color: context.design.brand,
          ),
          previewBadge(context, 'ناجح', tone: 'success'),
        ],
      ),
      PreviewPanel(
        height: 150,
        gap: 10,
        children: [
          PreviewText(
            'التفصيل',
            style: context.design.label,
            color: context.design.textMuted,
          ),
          const PreviewKeyValue('الامتحان النظري', '52/60', body: true),
          const PreviewKeyValue('الامتحان العملي', '25/30', body: true),
          const PreviewKeyValue('التمارين', '8/10', body: true),
        ],
      ),
      PreviewPanel(
        height: 78,
        children: [
          PreviewText(
            'الدورة العادية · الفصل الثالث',
            style: context.design.bodySmall,
          ),
          PreviewText(
            'أُعلنت العلامة بتاريخ 2 فبراير 2027',
            muted: true,
            style: context.design.bodySmall,
          ),
        ],
      ),
    ],
  );
  Widget _notifications(BuildContext context) => PreviewScaffold(
    actions: actions,
    navigation: true,
    gap: 10,
    children: [
      PreviewText('الإشعارات', style: context.design.title),
      for (final row in const [
        (
          'أُعلنت علامة قواعد البيانات',
          'اطّلع على نتيجتك في كشف العلامات.',
          'منذ ساعة',
          'b15c8',
          'G-01',
        ),
        (
          'تفعّل كورس Flutter',
          'يمكنك البدء بالمشاهدة الآن.',
          'أمس',
          'b15c8',
          'F-02',
        ),
        (
          'تمت الموافقة على تغيير جهازك',
          'سجّل الدخول من جهازك الجديد.',
          'قبل يومين',
          'f2880',
          'S-04',
        ),
        (
          'إعلان: جدول امتحانات الدورة العادية',
          'تم نشر الجدول، تحقّق من مواعيدك.',
          'قبل 3 أيام',
          'f2880',
          'B-S06',
        ),
      ])
        InkWell(
          onTap: () => actions.open(row.$5),
          child: PreviewPanel(
            height: 98,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PreviewText(
                          row.$1,
                          style: context.design.labelSemiBold,
                        ),
                        const SizedBox(height: 2),
                        PreviewText(row.$2, style: context.design.bodySmall),
                        const SizedBox(height: 2),
                        PreviewText(
                          row.$3,
                          style: context.design.bodySmall,
                          color: context.design.textMuted,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  PreviewIconTile(
                    asset: row.$4,
                    size: 44,
                    fill: context.design.selectedSurface,
                  ),
                ],
              ),
            ],
          ),
        ),
    ],
  );
  Widget _tickets(BuildContext context) => PreviewScaffold(
    title: 'الدعم والتواصل',
    actions: actions,
    gap: 12,
    children: [
      PreviewButton('تذكرة جديدة', onTap: () => actions.open('H-03')),
      PreviewText(
        'تذاكري',
        style: context.design.label,
        color: context.design.textMuted,
      ),
      for (final row in const [
        ('لا أستطيع تشغيل الدرس 4', 'قيد المعالجة', 'اليوم', 'warning'),
        ('سؤال عن موعد الامتحان العملي', 'تم الرد', 'أمس', 'success'),
        ('طلب تصحيح الاسم الرسمي', 'مغلقة', 'قبل أسبوع', 'neutral'),
      ])
        InkWell(
          onTap: () => actions.open('H-04'),
          child: PreviewPanel(
            children: [
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  SizedBox(
                    width: 100,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: previewBadge(context, row.$2, tone: row.$4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PreviewText(
                          row.$1,
                          style: context.design.labelSemiBold,
                        ),
                        const SizedBox(height: 2),
                        PreviewText(
                          row.$3,
                          style: context.design.bodySmall,
                          muted: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    ],
  );
  Widget _newTicket(BuildContext context) => PreviewScaffold(
    title: 'تذكرة جديدة',
    actions: actions,
    children: [
      const PreviewField(
        label: 'الموضوع',
        hint: 'عنوان مختصر لمشكلتك',
        helper: 'مثال: مشكلة في تشغيل الفيديو',
      ),
      const PreviewField(
        label: 'التفاصيل',
        hint: 'اشرح المشكلة بالتفصيل',
        helper: 'نرد خلال 24 ساعة في أيام العمل',
      ),
      const Spacer(),
      PreviewButton('إرسال التذكرة', onTap: actions.notice),
    ],
  );
  Widget _ticket(BuildContext context) => PreviewScaffold(
    title: 'لا أستطيع تشغيل الدرس 4',
    actions: actions,
    gap: 12,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: previewBadge(context, 'قيد المعالجة', tone: 'warning'),
      ),
      PreviewPanel(
        gap: 6,
        children: [
          PreviewText(
            'أنت · اليوم 10:20',
            style: context.design.bodySmall,
            color: context.design.textMuted,
          ),
          const PreviewText(
            'عند الضغط على الدرس 4 يظهر خطأ ولا يبدأ الفيديو.',
            primary: true,
          ),
        ],
      ),
      PreviewPanel(
        gap: 6,
        fill: context.design.selectedSurface,
        children: [
          PreviewText(
            'الدعم · اليوم 11:05',
            style: context.design.bodySmall,
            color: context.design.textMuted,
          ),
          const PreviewText(
            'شكراً لك. جرّب تحديث التطبيق، وإن استمرت المشكلة أرسل لنا موديل جهازك.',
            primary: true,
          ),
        ],
      ),
      const Spacer(),
      const PreviewField(
        label: 'ردّك',
        hint: 'اكتب ردّك هنا',
        helper: 'تُغلق التذكرة تلقائياً بعد 7 أيام من آخر رد',
      ),
      PreviewButton('إرسال الرد', onTap: actions.notice),
    ],
  );
}
