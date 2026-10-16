import 'package:flutter/material.dart';

import '../../theme/hasobjy_visual_scope.dart';
import '../../widgets/hasobjy_figma_components.dart';
import 'preview_widgets.dart';

class LearningPreviewScreen extends StatelessWidget {
  const LearningPreviewScreen({
    super.key,
    required this.frame,
    required this.actions,
  });
  final String frame;
  final PreviewActions actions;

  @override
  Widget build(BuildContext context) => switch (frame) {
    'C-01' => _home(context),
    'C-02' => _materials(context),
    'C-03' => _subject(context),
    'C-04' => _player(context),
    'C-05' => _document(context),
    'C-06' => _exercises(context),
    'C-07' => _CodeExercise(actions: actions),
    _ => _result(context),
  };

  Widget _home(BuildContext context) => PreviewScaffold(
    actions: actions,
    navigation: true,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PreviewText('مرحباً أحمد', style: context.design.title),
          const SizedBox(height: 2),
          PreviewText(
            'متابع تعلّمك من حيث توقفت',
            style: context.design.bodySmall,
          ),
        ],
      ),
      _section(context, 'متابعة المشاهدة'),
      GestureDetector(
        onTap: () => actions.open('C-04'),
        child: PreviewPanel(
          padding: 0,
          gap: 0,
          children: [
            Container(
              height: 150,
              color: context.design.surfaceSubtle,
              alignment: Alignment.center,
              child: PreviewIconTile(
                asset: 'e3eac',
                size: 56,
                fill: context.design.brand,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PreviewText(
                    'الدرس 5: العلاقات بين الجداول',
                    style: context.design.labelSemiBold,
                  ),
                  const SizedBox(height: 6),
                  PreviewText(
                    'قواعد البيانات · متبقٍ 12 دقيقة',
                    style: context.design.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: PreviewProgress(.62, width: 100, height: 6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      _section(context, 'موادي'),
      PreviewListCard(
        title: 'برمجة كائنية',
        subtitle: '8 دروس · 3 تمارين',
        progress: .4,
        asset: '38165',
        onTap: () => actions.open('C-03'),
      ),
      PreviewListCard(
        title: 'هندسة البرمجيات',
        subtitle: '10 دروس · 2 تمارين',
        progress: .15,
        asset: '38165',
        onTap: () => actions.open('C-03'),
      ),
    ],
  );

  Widget _materials(BuildContext context) => PreviewScaffold(
    actions: actions,
    navigation: true,
    gap: 12,
    children: [
      PreviewText('المواد', style: context.design.title),
      PreviewTabs(
        labels: const ['الفصول السابقة', 'الفصل الحالي'],
        selected: 1,
        onSelected: (_) => actions.notice(),
      ),
      for (final row in const [
        ('قواعد البيانات', '12 درساً · 4 تمارين', .62),
        ('برمجة كائنية', '8 درساً · 3 تمارين', .4),
        ('هندسة البرمجيات', '10 دروس · 2 تمارين', .15),
        ('تطوير الويب', '14 درساً · 5 تمارين', .01),
        ('شبكات الحاسوب', '9 دروس · 2 تمارين', .01),
      ])
        PreviewListCard(
          title: row.$1,
          subtitle: row.$2,
          progress: row.$3,
          asset: '38165',
          onTap: () => actions.open('C-03'),
        ),
    ],
  );

  Widget _subject(BuildContext context) => PreviewScaffold(
    title: 'قواعد البيانات',
    actions: actions,
    navigation: true,
    gap: 12,
    children: [
      PreviewPanel(
        height: 98,
        gap: 8,
        children: [
          PreviewText(
            'تقدّمك في المادة: 62%',
            style: context.design.labelSemiBold,
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: PreviewProgress(.62, height: 6, width: 100),
          ),
          PreviewText('8 من 12 درساً مكتملة', style: context.design.bodySmall),
        ],
      ),
      PreviewTabs(
        labels: const ['التمارين', 'الملفات', 'الدروس'],
        selected: 2,
        onSelected: (i) {
          if (i == 0) actions.open('C-06');
          if (i == 1) actions.open('C-05');
        },
      ),
      for (final row in const [
        ('1. مقدمة في قواعد البيانات', '18 دقيقة', '46019'),
        ('2. النمذجة الكيانية', '24 دقيقة', '46019'),
        ('3. الجداول والمفاتيح', '21 دقيقة', '46019'),
        ('4. لغة SQL الأساسية', '32 دقيقة', 'd589e'),
        ('5. العلاقات بين الجداول', '27 دقيقة', 'f969e'),
      ])
        InkWell(
          onTap: () =>
              row.$3 == 'f969e' ? actions.notice() : actions.open('C-04'),
          child: PreviewPanel(
            height: 100,
            center: true,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  HasobjySvg(row.$3, width: 24, height: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PreviewText(
                          row.$1,
                          style: context.design.bodyMedium.copyWith(
                            color: row.$3 == 'f969e'
                                ? context.design.textMuted
                                : context.design.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        PreviewText(
                          row.$2,
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

  Widget _player(BuildContext context) => PreviewScaffold(
    actions: actions,
    header: _PlayerPoster(actions: actions),
    bottomPadding: 16,
    gap: 12,
    children: [
      PreviewText(
        'الدرس 4: لغة SQL الأساسية',
        style: context.design.headingMedium,
      ),
      PreviewText(
        'قواعد البيانات · الفصل الثالث',
        style: context.design.bodySmall,
      ),
      const PreviewText(
        'تعرّف على أوامر الاستعلام الأساسية: SELECT وWHERE وORDER BY مع أمثلة تطبيقية على جداول المعهد.',
      ),
      const Spacer(),
      PreviewButton('الدرس التالي', onTap: actions.notice),
      PreviewButton(
        'تنزيل للمشاهدة دون إنترنت',
        onTap: actions.notice,
        primary: false,
      ),
    ],
  );

  Widget _document(BuildContext context) => PreviewScaffold(
    title: 'ملخص الفصل الأول',
    actions: actions,
    gap: 12,
    children: [
      PreviewPanel(
        height: 100,
        padding: 0,
        fill: Colors.transparent,
        border: false,
        center: true,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              previewBadge(context, 'عرض فقط'),
              PreviewText('صفحة 3 من 24', style: context.design.bodySmall),
            ],
          ),
        ],
      ),
      SizedBox(
        height: 528,
        child: Stack(
          children: [
            PreviewPanel(
              padding: 20,
              gap: 10,
              height: 528,
              children: [
                PreviewText(
                  'مبادئ قواعد البيانات',
                  style: context.design.headingMedium,
                ),
                for (var i = 0; i < 10; i++)
                  Container(height: 8, color: context.design.surfaceSubtle),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 260,
              height: 20,
              child: Opacity(
                opacity: .3,
                child: PreviewText(
                  'أحمد محمد · 0991 234 567',
                  muted: true,
                  style: context.design.bodySmall,
                  align: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
      Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(
            child: PreviewButton(
              'السابقة',
              onTap: actions.notice,
              primary: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: PreviewButton('التالية', onTap: actions.notice)),
        ],
      ),
    ],
  );

  Widget _exercises(BuildContext context) => PreviewScaffold(
    title: 'تمارين قواعد البيانات',
    actions: actions,
    gap: 12,
    children: [
      for (final row in const [
        ('تمرين 1: إنشاء جدول الطلاب', 'تم الحل · 90/100', 'success'),
        ('تمرين 2: استعلامات SELECT', 'تم الحل · 75/100', 'success'),
        ('تمرين 3: ربط الجداول JOIN', 'قيد التصحيح', 'warning'),
        ('تمرين 4: التجميع GROUP BY', 'لم يُحلّ', 'neutral'),
      ])
        PreviewListCard(
          title: row.$1,
          badge: previewBadge(context, row.$2, tone: row.$3),
          height: 88,
          asset: '5c3d1',
          onTap: () => actions.open('C-07'),
        ),
    ],
  );

  Widget _result(BuildContext context) => PreviewScaffold(
    title: 'نتيجة التمرين',
    actions: actions,
    children: [
      PreviewPanel(
        height: 128,
        center: true,
        gap: 6,
        children: [
          PreviewText(
            '85/100',
            style: context.design.display.copyWith(color: context.design.brand),
          ),
          previewBadge(context, 'ناجح · حدّ النجاح 60', tone: 'success'),
          PreviewText('صُحّح بواسطة Gemini', style: context.design.bodySmall),
        ],
      ),
      _section(context, 'ما أصبت فيه'),
      const PreviewPanel(
        height: 78,
        children: [
          PreviewText(
            'استخدمتَ JOIN بشكل صحيح بين الجداول الثلاثة، والترتيب مطابق للمطلوب.',
            primary: true,
          ),
        ],
      ),
      _section(context, 'ملاحظات للتحسين'),
      const PreviewPanel(
        height: 78,
        children: [
          PreviewText(
            'يُفضّل استخدام أسماء مستعارة أوضح للجداول، وإضافة LEFT JOIN لعرض الطلاب غير المسجّلين.',
            primary: true,
          ),
        ],
      ),
      const Spacer(),
      PreviewButton('إعادة المحاولة', onTap: () => actions.open('C-07')),
      PreviewButton(
        'العودة إلى التمارين',
        onTap: () => actions.open('C-06'),
        primary: false,
      ),
    ],
  );
  Widget _section(BuildContext context, String text) => PreviewText(
    text,
    style: context.design.label,
    color: context.design.textMuted,
  );
}

class _PlayerPoster extends StatelessWidget {
  const _PlayerPoster({required this.actions});
  final PreviewActions actions;
  @override
  Widget build(BuildContext context) => Container(
    height: 220,
    color: context.design.surfaceSubtle,
    child: Stack(
      children: [
        Positioned(
          top: 24,
          height: 20,
          left: 60,
          right: 60,
          child: Opacity(
            opacity: .35,
            child: PreviewText(
              'أحمد محمد · 0991 234 567',
              muted: true,
              style: context.design.bodySmall,
              align: TextAlign.center,
            ),
          ),
        ),
        Center(
          child: InkWell(
            onTap: actions.notice,
            child: PreviewIconTile(
              asset: 'e3eac',
              size: 64,
              fill: context.design.brand,
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          top: 176,
          height: 32,
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              Container(
                width: 38,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: context.design.surface,
                child: PreviewText(
                  '1.0x',
                  style: context.design.badge.copyWith(
                    color: context.design.textPrimary,
                  ),
                  align: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              PreviewText('12:40 / 27:00', style: context.design.bodySmall),
              const SizedBox(width: 10),
              const Expanded(child: PreviewProgress(.47)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CodeExercise extends StatefulWidget {
  const _CodeExercise({required this.actions});
  final PreviewActions actions;
  @override
  State<_CodeExercise> createState() => _CodeExerciseState();
}

class _CodeExerciseState extends State<_CodeExercise> {
  final controller = TextEditingController(
    text: 'SELECT s.name, c.title\nFROM students s\nJOIN enrollments e\n  ON e.student_id = s.id\nJOIN courses c\n  ON c.id = e.course_id\nORDER BY s.name;',
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PreviewScaffold(
    title: 'تمرين 3: ربط الجداول',
    actions: widget.actions,
    gap: 12,
    children: [
      PreviewPanel(
        height: 104,
        gap: 6,
        children: [
          PreviewText(
            'المطلوب',
            style: context.design.label,
            color: context.design.textMuted,
          ),
          const PreviewText(
            'اكتب استعلام SQL يعرض اسم كل طالب مع اسم المادة المسجّل بها، مرتّباً حسب اسم الطالب.',
            primary: true,
          ),
        ],
      ),
      Container(
        height: 524,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: context.design.surfaceSubtle,
          border: Border.all(color: context.design.border),
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '1\n2\n3\n4\n5\n6\n7',
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 13,
                  height: 22 / 13,
                  color: context.design.textMuted,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 13,
                  height: 22 / 13,
                  color: context.design.textPrimary,
                ),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
      PreviewButton('إرسال للتصحيح', onTap: widget.actions.notice),
    ],
  );
}
