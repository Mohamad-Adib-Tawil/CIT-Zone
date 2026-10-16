import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';

import '../theme/hasobjy_visual_scope.dart';
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
  bool _software = true;
  int _year = 2;

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
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).continueAction,
              onPressed: widget.onContinue,
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
  });

  final VoidCallback onConfirm;
  final VoidCallback onEdit;
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
              height: 158,
              padding: EdgeInsets.all(16),
              cornerLine: '8c8a2',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  HasobjyKeyValue(
                    AppLocalizations.of(context).officialName,
                    AppLocalizations.of(context).previewStudentName,
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).department,
                    AppLocalizations.of(context).departmentSoftware,
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).academicYear,
                    AppLocalizations.of(context).secondYear,
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).currentTerm,
                    AppLocalizations.of(context).previewCurrentTerm,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).enrollmentExplanation,
              textAlign: TextAlign.right,
              style: context.design.bodyMedium.copyWith(
                color: context.design.textMuted,
              ),
            ),
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).confirmAndStart,
              icon: HasobjySvg('f17a9', width: 24, height: 24),
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
  });

  final VoidCallback onConfirm;
  final VoidCallback onChangeDetails;

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
              height: 124,
              padding: EdgeInsets.all(16),
              cornerLine: '8c8a2',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  HasobjyKeyValue(
                    AppLocalizations.of(context).department,
                    AppLocalizations.of(context).departmentSoftware,
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).academicYear,
                    AppLocalizations.of(context).secondYear,
                  ),
                  HasobjyKeyValue(
                    AppLocalizations.of(context).termDuration,
                    AppLocalizations.of(context).previewTermDates,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Spacer(),
            SizedBox(height: 16),
            HasobjyButton(
              label: AppLocalizations.of(context).confirmEnrollmentYes,
              icon: HasobjySvg('f17a9', width: 24, height: 24),
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
