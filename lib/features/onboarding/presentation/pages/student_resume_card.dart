import 'package:flutter/material.dart';

import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentResumeCard extends StatelessWidget {
  const StudentResumeCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  final StudentResumeLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final design = context.design;
    final duration = lesson.durationSeconds;
    final remaining = duration == null
        ? null
        : duration - lesson.positionSeconds;
    final subtitle = remaining != null && remaining > 0
        ? '${lesson.subjectName} · متبقٍ ${(remaining / 60).ceil()} دقيقة'
        : lesson.subjectName;
    return InkWell(
      onTap: onTap,
      child: PreviewPanel(
        padding: 0,
        gap: 0,
        children: [
          SizedBox(
            height: 150,
            child: ColoredBox(
              color: design.surfaceSubtle,
              child: Center(
                child: PreviewIconTile(
                  asset: design.isLight ? '0a1db' : 'e3eac',
                  size: 56,
                  fill: design.brand,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                PreviewText(lesson.lessonTitle, style: design.labelSemiBold),
                PreviewText(subtitle, style: design.bodySmall),
                if (duration != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PreviewProgress(
                      lesson.positionSeconds / duration,
                      width: 100,
                      height: 6,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
