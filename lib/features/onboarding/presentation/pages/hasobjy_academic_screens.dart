import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../auth/domain/student_registration.dart';
import '../theme/hasobjy_visual_scope.dart';
import '../widgets/hasobjy_figma_components.dart';

class HasobjyAcademicInfoScreen extends StatefulWidget {
  const HasobjyAcademicInfoScreen({
    super.key,
    this.onContinue,
    this.onBack,
    this.departments,
    this.onSave,
    this.working = false,
    this.error,
  });

  final VoidCallback? onContinue;
  final List<StudentDepartment>? departments;
  final void Function(String departmentId, int year)? onSave;
  final bool working;
  final String? error;
  final VoidCallback? onBack;

  @override
  State<HasobjyAcademicInfoScreen> createState() =>
      _HasobjyAcademicInfoScreenState();
}

class _HasobjyAcademicInfoScreenState extends State<HasobjyAcademicInfoScreen> {
  bool _software = true;
  int _year = 2;
  StudentDepartment? _department;
  int? _selectedYear;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      appBarTitle: AppLocalizations.of(context).academicInfo,
      onBack: widget.onBack,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HasobjyStepper(activeBars: 3),
            SizedBox(height: 16),
            _SectionLabel(AppLocalizations.of(context).department),
            SizedBox(height: 16),
            if (widget.departments case final departments?) ...[
              for (final department in departments) ...[
                HasobjySelectionOption(
                  title: department.name,
                  subtitle: switch (department.name) {
                    'برمجيات' => AppLocalizations.of(
                      context,
                    ).softwareDescription,
                    'شبكات' => AppLocalizations.of(context).networksDescription,
                    _ => '',
                  },
                  iconAsset: department.name == 'شبكات' ? 'f52de' : 'dbeae',
                  selected: _department?.id == department.id,
                  onTap: () {
                    if (widget.working) return;
                    setState(() {
                      _department = department;
                      if (!department.years.contains(_selectedYear)) {
                        _selectedYear = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              ...[
                _SectionLabel(AppLocalizations.of(context).academicYear),
                const SizedBox(height: 16),
                for (final year
                    in _department?.years ?? studentProgramYears) ...[
                  HasobjySelectionOption(
                    title: _yearLabel(context, year),
                    subtitle: year == 1
                        ? AppLocalizations.of(context).firstYearTerms
                        : AppLocalizations.of(context).secondYearTerms,
                    iconAsset: '1ee59',
                    selected: year == _selectedYear,
                    onTap: () {
                      if (!widget.working) setState(() => _selectedYear = year);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ] else ...[
              HasobjySelectionOption(
                title: AppLocalizations.of(context).departmentSoftware,
                subtitle: AppLocalizations.of(context).softwareDescription,
                iconAsset: 'dbeae',
                selected: _software,
                onTap: () => setState(() => _software = true),
              ),
              SizedBox(height: 16),
              HasobjySelectionOption(
                title: AppLocalizations.of(context).departmentNetworks,
                subtitle: AppLocalizations.of(context).networksDescription,
                iconAsset: 'f52de',
                selected: !_software,
                onTap: () => setState(() => _software = false),
              ),
              SizedBox(height: 16),
              _SectionLabel(AppLocalizations.of(context).academicYear),
              SizedBox(height: 16),
              HasobjySelectionOption(
                title: AppLocalizations.of(context).firstYear,
                subtitle: AppLocalizations.of(context).firstYearTerms,
                iconAsset: '1ee59',
                selected: _year == 1,
                onTap: () => setState(() => _year = 1),
              ),
              SizedBox(height: 16),
              HasobjySelectionOption(
                title: AppLocalizations.of(context).secondYear,
                subtitle: AppLocalizations.of(context).secondYearTerms,
                iconAsset: '1ee59',
                selected: _year == 2,
                onTap: () => setState(() => _year = 2),
              ),
            ],
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            if (widget.working) const LinearProgressIndicator(),
            if (widget.error case final error?)
              Semantics(
                liveRegion: true,
                child: Text(error, style: context.design.label),
              ),
            HasobjyButton(
              label: AppLocalizations.of(context).continueAction,
              light3D: true,
              onPressed: widget.working
                  ? null
                  : widget.departments == null
                  ? widget.onContinue
                  : _department != null && _selectedYear != null
                  ? () => widget.onSave?.call(_department!.id, _selectedYear!)
                  : null,
            ),
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
    textAlign: TextAlign.right,
    style: context.design.labelLarge.copyWith(fontWeight: FontWeight.w600),
  );
}

class HasobjyRegistrationSummaryScreen extends StatelessWidget {
  const HasobjyRegistrationSummaryScreen({
    super.key,
    required this.onConfirm,
    required this.onEdit,
    this.onBack,
    this.summary,
    this.working = false,
  });

  final StudentRegistrationSummary? summary;
  final bool working;
  final VoidCallback? onConfirm;
  final VoidCallback? onEdit;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      appBarTitle: AppLocalizations.of(context).confirmEnrollment,
      onBack: onBack,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).reviewBeforeSaving,
              textAlign: TextAlign.right,
              style: context.design.titleBold,
            ),
            SizedBox(height: 16),
            HasobjySurface(
              height: summary == null ? 158 : null,
              padding: EdgeInsets.all(16),
              cornerLine: '8c8a2',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  HasobjyKeyValue(
                    AppLocalizations.of(context).officialName,
                    summary?.officialName ??
                        AppLocalizations.of(context).previewStudentName,
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).department,
                    summary?.departmentName ??
                        AppLocalizations.of(context).departmentSoftware,
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).academicYear,
                    summary == null
                        ? AppLocalizations.of(context).secondYear
                        : _yearLabel(context, summary!.year),
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).currentTerm,
                    summary == null
                        ? AppLocalizations.of(context).previewCurrentTerm
                        : summary!.semesterName ?? 'لا يوجد فصل مفتوح',
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              summary != null && summary!.semesterName == null
                  ? 'يمكنك تأكيد التسجيل الآن. ستُضاف المواد عند فتح الفصل.'
                  : AppLocalizations.of(context).enrollmentExplanation,
              textAlign: TextAlign.right,
              style: context.design.bodyMedium.copyWith(
                color: context.design.textMuted,
              ),
            ),
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            if (working) const LinearProgressIndicator(),
            HasobjyButton(
              label: AppLocalizations.of(context).confirmAndStart,
              light3D: true,
              icon: HasobjySvg(
                context.design.isLight ? '2cd43' : 'f17a9',
                width: 24,
                height: 24,
              ),
              onPressed: onConfirm,
            ),
            SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).editDetails,
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
    this.term,
    this.working = false,
    this.error,
  });

  final VoidCallback? onConfirm;
  final VoidCallback? onChangeDetails;
  final StudentTermRegistration? term;
  final bool working;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return HasobjyFigmaFrame(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: HasobjyBadge(
                label: AppLocalizations.of(context).newTerm,
                background: context.design.selectedSurface,
                foreground: context.design.brand,
              ),
            ),
            SizedBox(height: 16),
            Text(
              term?.semesterName ??
                  AppLocalizations.of(context).previewNewTermTitle,
              textAlign: TextAlign.right,
              style: context.design.titleBold,
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).confirmAcademicDetails,
              textAlign: TextAlign.right,
              style: context.design.bodyLarge,
            ),
            SizedBox(height: 16),
            HasobjySurface(
              height: term == null ? 124 : null,
              padding: EdgeInsets.all(16),
              cornerLine: '8c8a2',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  HasobjyKeyValue(
                    AppLocalizations.of(context).department,
                    term?.departmentName ??
                        AppLocalizations.of(context).departmentSoftware,
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).academicYear,
                    term == null
                        ? AppLocalizations.of(context).secondYear
                        : _yearLabel(context, term!.year),
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).termDuration,
                    term == null
                        ? AppLocalizations.of(context).previewTermDates
                        : '${MaterialLocalizations.of(context).formatCompactDate(term!.startDate)} – ${MaterialLocalizations.of(context).formatCompactDate(term!.endDate)}',
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            if (working) const LinearProgressIndicator(),
            if (error case final message?)
              Semantics(
                liveRegion: true,
                child: Text(message, style: context.design.label),
              ),
            if (term?.changePending == true)
              Text(
                'طلب تعديل بيانات الفصل قيد المراجعة.',
                style: context.design.label,
              ),
            HasobjyButton(
              label: AppLocalizations.of(context).confirmEnrollmentYes,
              light3D: true,
              icon: HasobjySvg(
                context.design.isLight ? '2cd43' : 'f17a9',
                width: 24,
                height: 24,
              ),
              onPressed: onConfirm,
            ),
            SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).detailsChanged,
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).academicHeaderStates,
              textAlign: TextAlign.right,
              style: context.design.headingMedium,
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
  Widget build(BuildContext context) => HasobjySurface(
    height: 108,
    fill: context.design.brand,
    border: null,
    cornerTopLeft: '21288',
    cornerBottomRight: 'c95e6',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).previewCurrentTerm,
          textAlign: TextAlign.right,
          style: context.design.labelSemiBold.copyWith(
            color: context.design.textOnBrand,
          ),
        ),
        SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).previewTermCountdown,
          textAlign: TextAlign.right,
          style: context.design.bodyMediumOnBrand,
        ),
        SizedBox(height: 12),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.centerRight,
          child: FractionallySizedBox(
            widthFactor: 190 / 310,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BetweenTermsCard extends StatelessWidget {
  const _BetweenTermsCard();
  @override
  Widget build(BuildContext context) => HasobjySurface(
    height: 108,
    fill: context.design.warning,
    border: null,
    cornerTopLeft: '21288',
    cornerBottomRight: 'c95e6',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).noCurrentTerm,
          textAlign: TextAlign.right,
          style: context.design.labelSemiBold.copyWith(
            color: context.design.warningText,
          ),
        ),
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).previewNextTermExplanation,
          textAlign: TextAlign.right,
          style: context.design.bodyMedium.copyWith(
            color: context.design.warningText,
          ),
        ),
      ],
    ),
  );
}

class _ClosedTermCard extends StatelessWidget {
  const _ClosedTermCard();
  @override
  Widget build(BuildContext context) => HasobjySurface(
    height: 108,
    fill: context.design.surfaceSubtle,
    border: null,
    cornerTopLeft: '21288',
    cornerBottomRight: 'c95e6',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).previewClosedTermTitle,
          textAlign: TextAlign.right,
          style: context.design.labelSemiBold,
        ),
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).closedTermExplanation,
          textAlign: TextAlign.right,
          style: context.design.bodyMedium,
        ),
      ],
    ),
  );
}

class _EnrollmentPostponedCard extends StatelessWidget {
  const _EnrollmentPostponedCard();
  @override
  Widget build(BuildContext context) => HasobjySurface(
    height: 120,
    cornerTopLeft: '21288',
    cornerBottomRight: 'c95e6',
    cornerLine: '8c8a2',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: HasobjyBadge(label: AppLocalizations.of(context).postponed),
        ),
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).enrollmentPostponed,
          textAlign: TextAlign.right,
          style: context.design.labelSemiBold,
        ),
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).reactivateEnrollment,
          textAlign: TextAlign.right,
          style: context.design.bodyMedium,
        ),
      ],
    ),
  );
}

class HasobjyExamScheduleScreen extends StatelessWidget {
  const HasobjyExamScheduleScreen({
    super.key,
    this.onBack,
    required this.onUnsupportedSupplementary,
  });

  final VoidCallback? onBack;
  final VoidCallback onUnsupportedSupplementary;

  @override
  Widget build(BuildContext context) {
    final exams = _regularExams(AppLocalizations.of(context));
    return HasobjyFigmaFrame(
      appBarTitle: AppLocalizations.of(context).examSchedule,
      onBack: onBack,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            Row(
              textDirection: TextDirection.ltr,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ExamFilter(
                  title: AppLocalizations.of(context).supplementaryExams,
                  selected: false,
                  onTap: onUnsupportedSupplementary,
                ),
                SizedBox(width: 8),
                _ExamFilter(
                  title: AppLocalizations.of(context).regularExams,
                  selected: true,
                  onTap: null,
                ),
              ],
            ),
            SizedBox(height: 16),
            for (var i = 0; i < exams.length; i++) ...[
              _ExamCard(exam: exams[i]),
              if (i != exams.length - 1) SizedBox(height: 16),
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HasobjyBadge(
      label: title,
      background: selected
          ? context.design.selectedSurface
          : context.design.surfaceSubtle,
      foreground: selected
          ? context.design.brand
          : context.design.textSecondary,
      onTap: onTap,
    );
  }
}

enum _ExamKind { theoretical, practical }

class _ExamData {
  const _ExamData({
    required this.kind,
    required this.subject,
    required this.date,
  });

  final _ExamKind kind;
  final String subject;
  final String date;
}

List<_ExamData> _regularExams(AppLocalizations strings) => [
  _ExamData(
    kind: _ExamKind.theoretical,
    subject: strings.previewOopSubject,
    date: strings.previewOopExamDate,
  ),
  _ExamData(
    kind: _ExamKind.practical,
    subject: strings.previewDatabaseSubject,
    date: strings.previewDatabaseExamDate,
  ),
  _ExamData(
    kind: _ExamKind.theoretical,
    subject: strings.previewEngineeringSubject,
    date: strings.previewEngineeringExamDate,
  ),
  _ExamData(
    kind: _ExamKind.practical,
    subject: strings.previewWebSubject,
    date: strings.previewWebExamDate,
  ),
];

class _ExamCard extends StatelessWidget {
  const _ExamCard({required this.exam});
  final _ExamData exam;
  @override
  Widget build(BuildContext context) {
    final practical = exam.kind == _ExamKind.practical;
    return HasobjySurface(
      height: 88,
      cornerLine: '8c8a2',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                HasobjyBadge(
                  label: practical
                      ? AppLocalizations.of(context).practicalExam
                      : AppLocalizations.of(context).theoreticalExam,
                  background: practical
                      ? context.design.success
                      : context.design.selectedSurface,
                  foreground: practical
                      ? context.design.successText
                      : context.design.brand,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exam.subject,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: context.design.labelSemiBold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            exam.date,
            textAlign: TextAlign.right,
            style: context.design.bodyMedium,
          ),
        ],
      ),
    );
  }
}

String _yearLabel(BuildContext context, int year) => switch (year) {
  1 => AppLocalizations.of(context).firstYear,
  2 => AppLocalizations.of(context).secondYear,
  _ => 'السنة $year',
};
