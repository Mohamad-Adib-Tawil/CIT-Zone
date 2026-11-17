import 'package:flutter/material.dart';

import '../../../../core/errors/either.dart';
import '../../../auth/domain/student_learning.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentNewTicket extends StatefulWidget {
  const StudentNewTicket({
    super.key,
    required this.onBack,
    required this.onCreate,
    required this.onCreated,
  });

  final VoidCallback onBack;
  final Future<Either<StudentSessionFailure, StudentTicket>> Function(
    String subject,
    String body,
  )
  onCreate;
  final ValueChanged<StudentTicket> onCreated;

  @override
  State<StudentNewTicket> createState() => _StudentNewTicketState();
}

class _StudentNewTicketState extends State<StudentNewTicket> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;
  String? _error;

  Future<void> _submit() async {
    if (_sending) return;
    final subject = _subject.text.trim();
    final body = _body.text.trim();
    if (subject.length < 3 ||
        subject.length > 200 ||
        body.isEmpty ||
        body.length > 5000) {
      setState(
        () =>
            _error = 'أدخل عنواناً من 3 إلى 200 حرف وتفاصيل من 1 إلى 5000 حرف.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await widget.onCreate(subject, body);
    if (!mounted) return;
    if (result case Right(:final value)) {
      widget.onCreated(value);
      return;
    }
    setState(() {
      _sending = false;
      _error = 'تعذّر تأكيد إنشاء التذكرة. راجع تذاكرك قبل إعادة الإرسال.';
    });
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController controller, {
    required int maxLength,
    int maxLines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 4,
    children: [
      PreviewText(label, style: context.design.label),
      TextField(
        controller: controller,
        enabled: !_sending,
        minLines: 1,
        maxLines: maxLines,
        maxLength: maxLength,
        style: context.design.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          filled: true,
          fillColor: context.design.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: context.design.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: context.design.border),
          ),
        ),
      ),
    ],
  );

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  void _back() {
    if (!_sending) widget.onBack();
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: PreviewScaffold(
      title: 'تذكرة جديدة',
      actions: PreviewActions(back: _back, open: (_) {}, notice: () {}),
      children: [
        _field('الموضوع', 'عنوان مختصر لمشكلتك', _subject, maxLength: 200),
        _field(
          'التفاصيل',
          'اشرح المشكلة بالتفصيل',
          _body,
          maxLength: 5000,
          maxLines: 5,
        ),
        if (_error case final error?)
          Semantics(liveRegion: true, child: PreviewText(error)),
        const Spacer(),
        if (_sending)
          const LinearProgressIndicator()
        else
          PreviewButton('إرسال التذكرة', onTap: _submit, light3D: true),
      ],
    ),
  );
}
