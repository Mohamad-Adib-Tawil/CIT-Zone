import 'package:flutter/material.dart';

import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';
import 'preview/student_update_scaffold.dart';
import 'preview/subscriptions_preview_screen.dart';

class StudentSubscriptions extends StatelessWidget {
  const StudentSubscriptions({
    super.key,
    required this.actions,
    this.subscriptions = const [],
    this.placeholder,
    required this.onBrowseCourses,
  });

  final PreviewActions actions;
  final List<StudentSubscription> subscriptions;
  final Widget? placeholder;
  final VoidCallback onBrowseCourses;

  @override
  Widget build(BuildContext context) {
    final academic = <(String, String, String, String)>[];
    final courses = <(String, String, String, String)>[];
    for (final subscription in subscriptions) {
      final isCourse = subscription.scope == 'course';
      final date = MaterialLocalizations.of(context).formatMediumDate(
        (subscription.state == StudentSubscriptionState.upcoming
                ? subscription.startsAt
                : subscription.expiresAt)
            .toLocal(),
      );
      final (status, tone, detail) = switch (subscription.state) {
        StudentSubscriptionState.active when subscription.daysLeft <= 7 => (
          'ينتهي قريباً',
          'warning',
          'ينتهي الوصول في $date',
        ),
        StudentSubscriptionState.active => (
          'نشط',
          'success',
          'ينتهي الوصول في $date',
        ),
        StudentSubscriptionState.upcoming => (
          'قادم',
          'neutral',
          'يبدأ الوصول في $date',
        ),
        StudentSubscriptionState.expired => (
          'منتهٍ',
          'neutral',
          'انتهى الوصول في $date',
        ),
        StudentSubscriptionState.revoked => ('ملغى', 'neutral', ''),
      };
      (isCourse ? courses : academic).add((
        subscription.name ?? (isCourse ? 'اشتراك كورس' : 'اشتراك أكاديمي'),
        detail,
        status,
        tone,
      ));
    }
    return StudentUpdateScaffold(
      title: 'اشتراكاتي',
      actions: actions,
      gap: 12,
      children: [
        if (placeholder case final content?)
          content
        else if (subscriptions.isEmpty)
          const PreviewText('لا توجد اشتراكات لهذا الحساب.'),
        if (academic.isNotEmpty) ...[
          PreviewText('المواد الدراسية', style: context.design.labelSemiBold),
          SubscriptionRows(academic),
        ],
        if (courses.isNotEmpty) ...[
          PreviewText('الكورسات', style: context.design.labelSemiBold),
          SubscriptionRows(courses),
        ],
        const Spacer(),
        PreviewButton('تصفّح الكورسات', primary: false, onTap: onBrowseCourses),
      ],
    );
  }
}
