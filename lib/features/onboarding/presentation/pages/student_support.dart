import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/errors/either.dart';
import '../../../auth/domain/student_learning.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

Widget _status(BuildContext context, String status) {
  final (label, tone) = switch (status) {
    'closed' => ('مغلقة', 'neutral'),
    'waiting_user' || 'resolved' => ('تم الرد', 'success'),
    'open' || 'waiting_support' => ('قيد المعالجة', 'warning'),
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

class StudentSupportThread extends StatefulWidget {
  const StudentSupportThread({
    super.key,
    required this.data,
    required this.onReply,
  });

  final StudentTicketThread data;
  final Future<Either<StudentSessionFailure, StudentTicketReply>> Function(
    String body,
    String key,
  )
  onReply;

  @override
  State<StudentSupportThread> createState() => _StudentSupportThreadState();
}

class _StudentSupportThreadState extends State<StudentSupportThread> {
  final _controller = TextEditingController();
  final _replies = <StudentTicketMessage>[];
  StudentTicket? _updatedTicket;
  String? _attemptBody;
  String? _attemptKey;
  String? _error;
  bool _sending = false;
  bool _closedByServer = false;

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (_sending || body.isEmpty || body.length > 5000) return;
    if (_attemptBody != body) {
      final random = Random.secure();
      _attemptKey = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      _attemptBody = body;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await widget.onReply(body, _attemptKey!);
    if (!mounted) return;
    setState(() {
      _sending = false;
      switch (result) {
        case Right(:final value):
          _updatedTicket = value.ticket;
          _replies.add(value.message);
          _controller.clear();
          _attemptKey = null;
          _attemptBody = null;
        case Left(:final value):
          _closedByServer = value == StudentSessionFailure.supportTicketClosed;
          _error = _closedByServer
              ? 'أُغلقت التذكرة. تعذّر إرسال الرد.'
              : 'تعذّر تأكيد إرسال الرد. أعد المحاولة.';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticket = _updatedTicket ?? widget.data.ticket;
    final canReply =
        !_closedByServer &&
        const {
          'open',
          'waiting_user',
          'waiting_support',
        }.contains(ticket.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _status(context, _closedByServer ? 'closed' : ticket.status),
        ),
        for (final message in [...widget.data.messages, ..._replies])
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
        if (_error case final error?)
          Semantics(liveRegion: true, child: PreviewText(error)),
        if (canReply) ...[
          TextField(
            controller: _controller,
            enabled: !_sending,
            minLines: 1,
            maxLines: 4,
            maxLength: 5000,
            decoration: const InputDecoration(
              labelText: 'ردّك',
              hintText: 'اكتب ردّك هنا',
              counterText: '',
              border: OutlineInputBorder(),
            ),
          ),
          if (_sending)
            const LinearProgressIndicator()
          else
            PreviewButton('إرسال الرد', onTap: _send, light3D: true),
        ],
      ],
    );
  }
}
