import 'package:flutter/material.dart';

import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentGradesView extends StatelessWidget {
  const StudentGradesView({
    super.key,
    required this.grades,
    required this.onOpen,
  });
  final StudentGrades grades;
  final ValueChanged<StudentGrade> onOpen;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      if (grades.average case final average?)
        PreviewPanel(
          height: 118,
          center: true,
          children: [
            PreviewText('المعدل العام', style: context.design.bodySmall),
            PreviewText(
              '$average',
              style: context.design.display.copyWith(
                color: context.design.brand,
              ),
            ),
            const PreviewText('من 100'),
          ],
        ),
      if (grades.terms.every((term) => term.subjects.isEmpty))
        const PreviewText('لا توجد مواد في سجل العلامات.'),
      for (final term in grades.terms)
        if (term.subjects.isNotEmpty) ...[
          if (term.name.isNotEmpty)
            PreviewText(term.name, style: context.design.label),
          for (final grade in term.subjects)
            InkWell(
              onTap: () => onOpen(grade),
              child: _GradeRow(grade: grade),
            ),
        ],
    ],
  );
}

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.grade});
  final StudentGrade grade;

  @override
  Widget build(BuildContext context) {
    final (status, tone) = switch (grade.result) {
      'passed' => ('ناجح', 'success'),
      'failed' => ('راسب', 'danger'),
      _ when grade.total == null => ('قيد الإعلان', 'neutral'),
      _ => ('معلنة', 'neutral'),
    };
    return PreviewPanel(
      children: [
        Row(
          children: [
            Expanded(
              child: PreviewText(
                grade.name,
                style: context.design.labelSemiBold,
              ),
            ),
            const SizedBox(width: 8),
            previewBadge(context, status, tone: tone),
            const SizedBox(width: 8),
            Text(grade.total?.toString() ?? '—'),
          ],
        ),
        if (grade.theory case final theory?)
          PreviewKeyValue('النظري', '$theory', body: true),
        if (grade.practical case final practical?)
          PreviewKeyValue('العملي', '$practical', body: true),
      ],
    );
  }
}

class StudentGradeDetailView extends StatelessWidget {
  const StudentGradeDetailView({super.key, required this.detail});
  final StudentGradeDetail detail;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      if (detail.attempts.isEmpty)
        const PreviewText('علامة هذه المادة قيد الإعلان.'),
      for (final attempt in detail.attempts) ...[
        PreviewPanel(
          height: 104,
          center: true,
          children: [
            if (attempt.total case final total?)
              PreviewText(
                '$total/100',
                style: context.design.display.copyWith(
                  color: context.design.brand,
                ),
              ),
            if (attempt.result == 'passed' || attempt.result == 'failed')
              previewBadge(
                context,
                [
                  attempt.result == 'passed' ? 'ناجح' : 'راسب',
                  if (detail.passMark case final threshold?)
                    'حد النجاح $threshold',
                ].join(' · '),
                tone: attempt.result == 'passed' ? 'success' : 'danger',
              ),
          ],
        ),
        if (attempt.theory != null || attempt.practical != null)
          PreviewPanel(
            children: [
              PreviewText('التفصيل', style: context.design.label),
              if (attempt.theory case final theory?)
                PreviewKeyValue('الامتحان النظري', '$theory', body: true),
              if (attempt.practical case final practical?)
                PreviewKeyValue('الامتحان العملي', '$practical', body: true),
            ],
          ),
        PreviewPanel(
          children: [
            PreviewText(
              [
                attempt.term,
                switch (attempt.session) {
                  'regular' => 'الدورة العادية',
                  'supplementary' => 'الدورة التكميلية',
                  _ => null,
                },
              ].whereType<String>().join(' · '),
              style: context.design.bodySmall,
            ),
          ],
        ),
      ],
    ],
  );
}
