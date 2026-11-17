import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/generated/app_localizations.dart';
import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import '../widgets/hasobjy_figma_components.dart';

typedef StudentExamRow = ({StudentExam exam, String? subjectName});

class StudentExamSchedule extends StatelessWidget {
  const StudentExamSchedule({
    super.key,
    required this.session,
    required this.onBack,
    required this.onSelect,
    required this.content,
  });

  final StudentExamSession session;
  final VoidCallback onBack;
  final ValueChanged<StudentExamSession> onSelect;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return HasobjyFigmaFrame(
      appBarTitle: strings.examSchedule,
      onBack: onBack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in StudentExamSession.values)
                    Semantics(
                      selected: session == option,
                      child: HasobjyBadge(
                        label: option == StudentExamSession.regular
                            ? strings.regularExams
                            : strings.supplementaryExams,
                        background: session == option
                            ? context.design.selectedSurface
                            : context.design.surfaceSubtle,
                        foreground: session == option
                            ? context.design.brand
                            : context.design.textSecondary,
                        onTap: session == option
                            ? null
                            : () => onSelect(option),
                      ),
                    ),
                ],
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

class StudentExamRows extends StatelessWidget {
  const StudentExamRows({
    super.key,
    required this.rows,
    this.selectedId,
    this.missing = false,
  });

  final List<StudentExamRow> rows;
  final String? selectedId;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    if (missing) return const Text('موعد الامتحان غير متاح في جدولك الحالي.');
    if (rows.isEmpty) {
      return const Text('لا توجد امتحانات مجدولة لهذه الدورة.');
    }
    final strings = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final date = DateFormat('EEEE d MMMM', locale);
    final time = DateFormat.Hm(locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        for (final (:exam, :subjectName) in rows)
          HasobjySurface(
            cornerLine: '8c8a2',
            height: 88,
            selected: exam.id == selectedId,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        subjectName ?? 'امتحان',
                        style: context.design.labelSemiBold,
                      ),
                    ),
                    HasobjyBadge(
                      label: exam.practical
                          ? strings.practicalExam
                          : strings.theoreticalExam,
                      background: exam.practical
                          ? context.design.success
                          : context.design.selectedSurface,
                      foreground: exam.practical
                          ? context.design.successText
                          : context.design.brand,
                    ),
                  ],
                ),
                Text(
                  [
                    date.format(exam.startsAt.toLocal()),
                    time.format(exam.startsAt.toLocal()),
                    exam.room ?? 'القاعة غير معيّنة',
                  ].join(' · '),
                  style: context.design.bodyMedium,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
