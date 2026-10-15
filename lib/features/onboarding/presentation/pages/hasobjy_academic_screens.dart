import 'package:flutter/material.dart';

import '../theme/hasobjy_design_tokens.dart';
import '../widgets/hasobjy_figma_components.dart';

class HasobjyAcademicInfoScreen extends StatefulWidget {
  const HasobjyAcademicInfoScreen({
    super.key,
    required this.onContinue,
    this.onBack,
  });

  final VoidCallback onContinue;
  final VoidCallback? onBack;

  @override
  State<HasobjyAcademicInfoScreen> createState() =>
      _HasobjyAcademicInfoScreenState();
}

class _HasobjyAcademicInfoScreenState extends State<HasobjyAcademicInfoScreen> {
  String _department = 'برمجيات';
  int _year = 2;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      appBarTitle: 'معلوماتك الأكاديمية',
      onBack: widget.onBack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const HasobjyStepper(activeBars: 3),
            const SizedBox(height: 16),
            const _SectionLabel('القسم'),
            const SizedBox(height: 16),
            _AcademicOption(
              title: 'برمجيات',
              subtitle: 'مواد البرمجة وتطوير التطبيقات',
              iconAsset: 'dbeae',
              selected: _department == 'برمجيات',
              onTap: () => setState(() => _department = 'برمجيات'),
            ),
            const SizedBox(height: 16),
            _AcademicOption(
              title: 'شبكات',
              subtitle: 'مواد الشبكات والأنظمة',
              iconAsset: 'f52de',
              selected: _department == 'شبكات',
              onTap: () => setState(() => _department = 'شبكات'),
            ),
            const SizedBox(height: 16),
            const _SectionLabel('السنة الدراسية'),
            const SizedBox(height: 16),
            _AcademicOption(
              title: 'السنة الأولى',
              subtitle: 'الفصل الأول والثاني',
              iconAsset: '1ee59',
              selected: _year == 1,
              onTap: () => setState(() => _year = 1),
            ),
            const SizedBox(height: 16),
            _AcademicOption(
              title: 'السنة الثانية',
              subtitle: 'الفصل الثالث والرابع',
              iconAsset: '1ee59',
              selected: _year == 2,
              onTap: () => setState(() => _year = 2),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(label: 'متابعة', onPressed: widget.onContinue),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    textAlign: TextAlign.end,
    style: HasobjyDesignTokens.labelLarge,
  );
}

class _AcademicOption extends StatelessWidget {
  const _AcademicOption({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: HasobjySurface(
        height: 100,
        selected: selected,
        border: selected
            ? HasobjyDesignTokens.brand
            : HasobjyDesignTokens.border,
        cornerTopLeft: selected ? '21288' : 'b043f',
        cornerBottomRight: selected ? 'c95e6' : '03567',
        cornerLine: selected ? '416c4' : '8c8a2',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            HasobjySvg(selected ? '0fd39' : 'cb103', width: 22, height: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.end,
                    style: HasobjyDesignTokens.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    textAlign: TextAlign.end,
                    style: HasobjyDesignTokens.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              color: HasobjyDesignTokens.surfaceSubtle,
              padding: const EdgeInsets.all(10),
              child: HasobjySvg(iconAsset, width: 24, height: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class HasobjyRegistrationSummaryScreen extends StatelessWidget {
  const HasobjyRegistrationSummaryScreen({
    super.key,
    required this.onConfirm,
    required this.onEdit,
    this.onBack,
  });

  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      appBarTitle: 'تأكيد التسجيل',
      onBack: onBack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'راجع بياناتك قبل الحفظ',
              textAlign: TextAlign.end,
              style: HasobjyDesignTokens.titleBold,
            ),
            const SizedBox(height: 16),
            const HasobjySurface(
              height: 158,
              padding: EdgeInsets.all(16),
              cornerLine: '8c8a2',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HasobjyKeyValue('الاسم الرسمي', 'أحمد محمد الحلبي'),
                  HasobjyKeyValue('القسم', 'برمجيات'),
                  HasobjyKeyValue('السنة الدراسية', 'السنة الثانية'),
                  HasobjyKeyValue('الفصل الحالي', 'الفصل الثالث · 2026/2027'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'سيُسجَّل حسابك على الفصل الجاري، ويمكنك طلب تعديل القسم أو السنة من الدعم لاحقاً.',
              textAlign: TextAlign.end,
              style: HasobjyDesignTokens.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'تأكيد وبدء الاستخدام',
              icon: const HasobjySvg('f17a9', width: 24, height: 24),
              onPressed: onConfirm,
            ),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'تعديل البيانات',
              primary: false,
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class HasobjyNewTermScreen extends StatelessWidget {
  const HasobjyNewTermScreen({
    super.key,
    required this.onConfirm,
    required this.onChangeDetails,
  });

  final VoidCallback onConfirm;
  final VoidCallback onChangeDetails;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: HasobjyDesignTokens.selectedSurface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'فصل جديد',
                  style: HasobjyDesignTokens.bodySmall,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'بدأ الفصل الرابع',
              textAlign: TextAlign.end,
              style: HasobjyDesignTokens.titleBold,
            ),
            const SizedBox(height: 16),
            const Text(
              'هل ما زلت في القسم والسنة نفسهما؟ نحتاج تأكيدك لتفعيل مواد هذا الفصل.',
              textAlign: TextAlign.end,
              style: HasobjyDesignTokens.bodyLarge,
            ),
            const SizedBox(height: 16),
            const HasobjySurface(
              height: 124,
              padding: EdgeInsets.all(16),
              cornerLine: '8c8a2',
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  HasobjyKeyValue('القسم', 'برمجيات'),
                  HasobjyKeyValue('السنة الدراسية', 'السنة الثانية'),
                  HasobjyKeyValue('مدة الفصل', '1 فبراير – 15 يونيو 2027'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Spacer(),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'نعم، تأكيد التسجيل',
              icon: const HasobjySvg('f17a9', width: 24, height: 24),
              onPressed: onConfirm,
            ),
            const SizedBox(height: 16),
            HasobjyButton(
              label: 'تغيّرت بياناتي',
              primary: false,
              onPressed: onChangeDetails,
            ),
          ],
        ),
      ),
    );
  }
}

class HasobjyTermStatesScreen extends StatelessWidget {
  const HasobjyTermStatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      scrollable: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'حالات رأس الصفحة الأكاديمي',
              textAlign: TextAlign.end,
              style: HasobjyDesignTokens.labelSemiBold,
            ),
            SizedBox(height: 16),
            _ActiveTermCard(),
            SizedBox(height: 16),
            _BetweenTermsCard(),
            SizedBox(height: 16),
            _ClosedTermCard(),
            SizedBox(height: 16),
            _EnrollmentPostponedCard(),
          ],
        ),
      ),
    );
  }
}

class _ActiveTermCard extends StatelessWidget {
  const _ActiveTermCard();

  @override
  Widget build(BuildContext context) {
    return HasobjySurface(
      height: 126,
      fill: HasobjyDesignTokens.brand,
      border: HasobjyDesignTokens.brand,
      cornerTopLeft: '21288',
      cornerBottomRight: 'c95e6',
      cornerLine: '8c8a2',
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'الفصل الثالث · 2026/2027',
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.labelLargeOnBrand,
          ),
          const SizedBox(height: 8),
          const Text(
            'ينتهي بعد 62 يوماً · الامتحانات تبدأ 1 يونيو',
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.bodySmallOnBrand,
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: .6,
              minHeight: 6,
              backgroundColor: HasobjyDesignTokens.textMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                HasobjyDesignTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BetweenTermsCard extends StatelessWidget {
  const _BetweenTermsCard();

  @override
  Widget build(BuildContext context) {
    return const HasobjySurface(
      height: 132,
      fill: HasobjyDesignTokens.warning,
      border: HasobjyDesignTokens.warning,
      cornerTopLeft: '21288',
      cornerBottomRight: 'c95e6',
      cornerLine: '8c8a2',
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'لا يوجد فصل جارٍ حالياً',
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.labelLarge,
          ),
          SizedBox(height: 4),
          Text(
            'سُجّلت تلقائياً على الفصل القادم الذي يبدأ في 1 فبراير 2027، وسنذكّرك عند بدايته.',
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ClosedTermCard extends StatelessWidget {
  const _ClosedTermCard();

  @override
  Widget build(BuildContext context) {
    return const HasobjySurface(
      height: 114,
      fill: HasobjyDesignTokens.surfaceSubtle,
      border: HasobjyDesignTokens.surfaceSubtle,
      cornerTopLeft: '21288',
      cornerBottomRight: 'c95e6',
      cornerLine: '8c8a2',
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'انتهى الفصل الثالث',
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.labelLarge,
          ),
          SizedBox(height: 4),
          Text(
            'أُغلقت مواد الفصل، وتبقى مفتوحة للمراجعة المواد التي لم تنجح بها فقط.',
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EnrollmentPostponedCard extends StatelessWidget {
  const _EnrollmentPostponedCard();

  @override
  Widget build(BuildContext context) {
    return HasobjySurface(
      height: 124,
      cornerLine: '8c8a2',
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: HasobjyDesignTokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('مؤجَّل', style: HasobjyDesignTokens.bodySmall),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تسجيلك مؤجَّل',
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.labelLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'تواصل مع الدعم لإعادة تفعيل تسجيلك الأكاديمي.',
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.bodySmall,
          ),
        ],
      ),
    );
  }
}

class HasobjyExamScheduleScreen extends StatefulWidget {
  const HasobjyExamScheduleScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<HasobjyExamScheduleScreen> createState() =>
      _HasobjyExamScheduleScreenState();
}

class _HasobjyExamScheduleScreenState extends State<HasobjyExamScheduleScreen> {
  bool _supplementary = false;

  @override
  Widget build(BuildContext context) {
    final exams = _supplementary ? _supplementaryExams : _regularExams;
    return HasobjyFigmaFrame(
      appBarTitle: 'جدول الامتحانات',
      onBack: widget.onBack,
      scrollable: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _ExamFilter(
                    title: 'الدورة التكميلية',
                    selected: _supplementary,
                    onTap: () => setState(() => _supplementary = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ExamFilter(
                    title: 'الدورة العادية',
                    selected: !_supplementary,
                    onTap: () => setState(() => _supplementary = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < exams.length; i++) ...[
              _ExamCard(exam: exams[i]),
              if (i != exams.length - 1) const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExamFilter extends StatelessWidget {
  const _ExamFilter({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? HasobjyDesignTokens.selectedSurface
              : HasobjyDesignTokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(title, style: HasobjyDesignTokens.bodySmall),
      ),
    );
  }
}

class _ExamData {
  const _ExamData({
    required this.kind,
    required this.subject,
    required this.date,
  });

  final String kind;
  final String subject;
  final String date;
}

const _regularExams = [
  _ExamData(
    kind: 'نظري',
    subject: 'البرمجة الكائنية',
    date: 'الأحد 7 يونيو · 09:00 · القاعة 3',
  ),
  _ExamData(
    kind: 'عملي',
    subject: 'قواعد البيانات',
    date: 'الثلاثاء 9 يونيو · 11:00 · المخبر 1',
  ),
  _ExamData(
    kind: 'نظري',
    subject: 'هندسة البرمجيات',
    date: 'الخميس 11 يونيو · 09:00 · القاعة 2',
  ),
  _ExamData(
    kind: 'عملي',
    subject: 'تطوير الويب',
    date: 'الأحد 14 يونيو · 10:00 · المخبر 2',
  ),
];

const _supplementaryExams = [
  _ExamData(
    kind: 'نظري',
    subject: 'البرمجة الكائنية',
    date: 'الأحد 21 يونيو · 09:00 · القاعة 3',
  ),
  _ExamData(
    kind: 'عملي',
    subject: 'قواعد البيانات',
    date: 'الثلاثاء 23 يونيو · 11:00 · المخبر 1',
  ),
  _ExamData(
    kind: 'نظري',
    subject: 'هندسة البرمجيات',
    date: 'الخميس 25 يونيو · 09:00 · القاعة 2',
  ),
  _ExamData(
    kind: 'عملي',
    subject: 'تطوير الويب',
    date: 'الأحد 28 يونيو · 10:00 · المخبر 2',
  ),
];

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});

  final _ExamData exam;

  @override
  Widget build(BuildContext context) {
    final practical = exam.kind == 'عملي';
    return HasobjySurface(
      cornerLine: '8c8a2',
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: practical
                        ? HasobjyDesignTokens.success
                        : HasobjyDesignTokens.selectedSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    exam.kind,
                    style: HasobjyDesignTokens.bodySmall.copyWith(
                      color: practical
                          ? HasobjyDesignTokens.textPrimary
                          : HasobjyDesignTokens.brand,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    exam.subject,
                    textAlign: TextAlign.end,
                    style: HasobjyDesignTokens.labelLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            exam.date,
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.bodySmall,
          ),
        ],
      ),
    );
  }
}
