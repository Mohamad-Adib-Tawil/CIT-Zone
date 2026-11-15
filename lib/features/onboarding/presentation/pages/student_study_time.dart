import 'package:flutter/material.dart';

import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentStudyTimeView extends StatelessWidget {
  const StudentStudyTimeView({super.key, required this.data});
  final StudentStudyTime data;

  String _duration(int seconds) {
    if (seconds == 0) return '0 د';
    if (seconds < 60) return 'أقل من دقيقة';
    final minutes = seconds ~/ 60;
    return minutes < 60 ? '$minutes د' : '${minutes ~/ 60} س ${minutes % 60} د';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = MaterialLocalizations.of(context);
    final peak = data.days.fold(
      0,
      (max, day) => day.seconds > max ? day.seconds : max,
    );
    final dateRange =
        '${l10n.formatShortDate(data.days.first.date)} – ${l10n.formatShortDate(data.days.last.date)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        PreviewPanel(
          center: true,
          children: [
            PreviewText('هذا الأسبوع', style: context.design.bodySmall),
            PreviewText(
              _duration(data.totalSeconds),
              style: context.design.display.copyWith(
                color: context.design.brand,
              ),
            ),
            PreviewText(
              dateRange,
              style: context.design.bodySmall,
              align: TextAlign.center,
            ),
          ],
        ),
        PreviewPanel(
          children: [
            PreviewText('نشاطك اليومي', style: context.design.label),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in data.days)
                  Expanded(
                    child: Semantics(
                      label:
                          '${l10n.formatFullDate(day.date)}، ${_duration(day.seconds)}',
                      excludeSemantics: true,
                      child: Column(
                        spacing: 4,
                        children: [
                          PreviewText(
                            day.seconds == 0
                                ? '—'
                                : '${(day.seconds / 60).ceil()}د',
                            style: context.design.badge,
                            align: TextAlign.center,
                          ),
                          SizedBox(
                            width: 20,
                            height: day.seconds == 0
                                ? 3
                                : 84 * day.seconds / peak,
                            child: ColoredBox(
                              color: day.seconds > 0 && day.seconds == peak
                                  ? context.design.brand
                                  : context.design.selectedSurface,
                            ),
                          ),
                          PreviewText(
                            l10n.narrowWeekdays[day.date.weekday % 7],
                            style: context.design.bodySmall,
                            align: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
