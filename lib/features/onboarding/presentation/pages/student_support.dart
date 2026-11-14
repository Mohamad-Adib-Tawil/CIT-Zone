import 'package:flutter/material.dart';

import '../../../auth/domain/student_learning.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

Widget _status(BuildContext context, String status) {
  final (label, tone) = switch (status) {
    'closed' => ('مغلقة', 'neutral'),
    'answered' || 'resolved' => ('تم الرد', 'success'),
    'open' || 'pending' || 'in_progress' => ('قيد المعالجة', 'warning'),
    _ => ('الحالة غير متاحة', 'neutral'),
  };
  return previewBadge(context, label, tone: tone);
}

class StudentSupportList extends StatelessWidget {
  const StudentSupportList({
    super.key,
    required this.data,
    required this.onOpen,
    this.onPrevious,
    this.onNext,
  });

  final StudentTicketPage data;
  final ValueChanged<StudentTicket> onOpen;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      PreviewText('تذاكري', style: context.design.label),
      if (data.tickets.isEmpty) const PreviewText('لا توجد تذاكر دعم.'),
      for (final ticket in data.tickets)
        PreviewListCard(
          title: ticket.subject,
          subtitle: MaterialLocalizations.of(context)
              .formatMediumDate(ticket.updatedAt.toLocal()),
          badge: _status(context, ticket.status),
          onTap: () => onOpen(ticket),
        ),
      if (onPrevious != null || onNext != null)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(onPressed: onPrevious, child: const Text('السابق')),
            TextButton(onPressed: onNext, child: const Text('التالي')),
          ],
        ),
    ],
  );
}

class StudentSupportThread extends StatelessWidget {
  const StudentSupportThread({super.key, required this.data});
  final StudentTicketThread data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: _status(context, data.ticket.status),
      ),
      for (final message in data.messages)
        PreviewPanel(
          fill: message.fromSupport ? context.design.selectedSurface : null,
          children: [
            PreviewText(
              message.fromSupport ? 'الدعم' : 'أنت',
              style: context.design.bodySmall,
              muted: true,
            ),
            PreviewText(message.body),
          ],
        ),
    ],
  );
}
