import 'package:flutter/material.dart';

import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentLessonVideoStatus extends StatelessWidget {
  const StudentLessonVideoStatus({super.key, required this.lesson});

  final StudentLessonDetail lesson;

  @override
  Widget build(BuildContext context) {
    final duration = lesson.durationSeconds;
    final status = switch ((lesson.locked, lesson.videoReady)) {
      (true, _) => 'هذا الدرس يتطلب اشتراكاً سارياً.',
      (false, false) => 'الفيديو قيد المعالجة.',
      (false, true) => 'تشغيل الفيديو غير متاح حالياً.',
    };

    return PreviewPanel(
      fill: context.design.surfaceSubtle,
      gap: 12,
      children: [
        PreviewText(status, align: TextAlign.center),
        if (!lesson.locked && duration != null && duration > 0)
          _savedPosition(context, duration),
      ],
    );
  }

  Widget _savedPosition(BuildContext context, int duration) {
    final position = lesson.positionSeconds.clamp(0, duration);
    return Semantics(
      label: position == 0
          ? 'مدة الفيديو'
          : 'موضع المشاهدة المحفوظ ومدة الفيديو',
      child: Row(
        textDirection: TextDirection.ltr,
        spacing: 12,
        children: [
          Text(
            position > 0
                ? '${_time(position)} / ${_time(duration)}'
                : _time(duration),
            textDirection: TextDirection.ltr,
            style: context.design.bodySmall,
          ),
          if (position > 0)
            Expanded(child: PreviewProgress(position / duration, height: 4)),
        ],
      ),
    );
  }

  static String _time(int seconds) {
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '$minutes:$remainder';
    final middle = (minutes % 60).toString().padLeft(2, '0');
    return '${minutes ~/ 60}:$middle:$remainder';
  }
}
