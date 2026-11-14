import 'package:flutter/material.dart';

import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import '../widgets/hasobjy_figma_components.dart';
import 'preview/preview_widgets.dart';

class StudentSubjectProgress extends StatelessWidget {
  const StudentSubjectProgress({super.key, required this.subject});

  final StudentSubjectItem subject;

  @override
  Widget build(BuildContext context) => PreviewPanel(
    height: 98,
    children: [
      PreviewText(
        'تقدّمك في المادة: ${subject.percent}٪',
        style: context.design.labelSemiBold,
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: PreviewProgress(subject.percent / 100, height: 6, width: 100),
      ),
      PreviewText(
        '${subject.completed} من ${subject.total} درساً مكتملة',
        style: context.design.bodySmall,
      ),
    ],
  );
}

class StudentLessonCard extends StatelessWidget {
  const StudentLessonCard({super.key, required this.lesson, this.onTap});

  final StudentLessonSummary lesson;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final light = context.design.isLight;
    final (icon, status) = switch ((lesson.locked, lesson.completed)) {
      (true, _) => (light ? '0bdf1' : 'f969e', 'مقفل'),
      (false, true) => (light ? '96bd9' : '46019', 'مكتمل'),
      _ => (light ? 'c18cf' : 'd589e', null),
    };
    final position = lesson.position;
    final seconds = lesson.durationSeconds;
    return Semantics(
      label: status,
      child: InkWell(
        onTap: onTap,
        child: PreviewPanel(
          height: 100,
          center: true,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PreviewText(
                        position == null
                            ? lesson.title
                            : '$position. ${lesson.title}',
                        style: context.design.bodyMedium,
                        muted: lesson.locked,
                      ),
                      if (seconds != null)
                        PreviewText(
                          seconds < 60
                              ? '$seconds ثانية'
                              : '${(seconds / 60).ceil()} دقيقة',
                          style: context.design.bodySmall,
                          muted: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                HasobjySvg(icon, width: 24, height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
