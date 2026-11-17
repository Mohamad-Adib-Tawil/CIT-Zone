import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/errors/either.dart';
import '../../../auth/domain/student_learning.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../theme/hasobjy_visual_scope.dart';
import 'preview/preview_widgets.dart';

class StudentExercisePromptView extends StatefulWidget {
  const StudentExercisePromptView({
    super.key,
    required this.prompt,
    required this.submit,
    required this.readAttempt,
    required this.latestAttempt,
    required this.onBack,
  });

  final StudentExercisePrompt prompt;
  final Future<Either<StudentSessionFailure, StudentAttempt>> Function(
    String key, {
    String? code,
    String? language,
    String? choiceId,
  })
  submit;
  final Future<Either<StudentSessionFailure, StudentAttempt>> Function(
    String,
    Future<void>,
  )
  readAttempt;
  final Future<Either<StudentSessionFailure, StudentAttempt?>> Function(
    Future<void>,
  )
  latestAttempt;
  final VoidCallback onBack;

  @override
  State<StudentExercisePromptView> createState() =>
      _StudentExercisePromptViewState();
}

class _StudentExercisePromptViewState extends State<StudentExercisePromptView> {
  late final _code = TextEditingController(
    text: switch (widget.prompt) {
      StudentCodingPrompt(:final starterCode) => starterCode,
      _ => '',
    },
  );
  String? _choice;
  String? _lastAnswer;
  String? _key;
  StudentAttempt? _attempt;
  bool _working = false;
  String? _error;

  bool _historyLoaded = false;
  final _readsEnded = Completer<void>();

  @override
  void initState() {
    super.initState();
    _restoreAttempt();
  }

  Future<void> _restoreAttempt() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    final result = await widget.latestAttempt(_readsEnded.future);
    if (!mounted) return;
    setState(() {
      _working = false;
      _historyLoaded = result.isRight();
      _attempt = result.getRight().toNullable();
      if (!_historyLoaded) _error = 'تعذّر تحميل آخر محاولة.';
    });
    if (_attempt?.status == StudentAttemptStatus.grading) await _refresh();
  }

  Future<void> _send() async {
    if (_working) return;
    final coding = widget.prompt is StudentCodingPrompt
        ? widget.prompt as StudentCodingPrompt
        : null;
    final answer = coding != null ? _code.text : _choice;
    if (answer == null || answer.trim().isEmpty || answer.length > 8000) {
      setState(() => _error = 'أدخل إجابة صالحة قبل الإرسال.');
      return;
    }
    if (_lastAnswer != answer || _key == null) {
      final random = Random.secure();
      _key = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      _lastAnswer = answer;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _working = true;
      _error = null;
    });
    final result = await widget.submit(
      _key!,
      code: coding == null ? null : answer,
      language: coding?.language,
      choiceId: coding == null ? answer : null,
    );
    if (!mounted) return;
    _apply(result);
    if (_attempt?.status == StudentAttemptStatus.grading) await _refresh();
  }

  Future<void> _refresh() async {
    final id = _attempt?.id;
    if (id == null || _working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    final result = await widget.readAttempt(id, _readsEnded.future);
    if (mounted) _apply(result);
  }

  void _apply(Either<StudentSessionFailure, StudentAttempt> result) {
    setState(() {
      _working = false;
      if (result case Right(:final value)) {
        _attempt = value;
      } else {
        _error = _attempt == null
            ? 'تعذّر تأكيد إرسال الحل. أعد المحاولة.'
            : 'تعذّر تحديث النتيجة.';
      }
    });
  }

  @override
  void dispose() {
    _readsEnded.complete();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        if (!_historyLoaded) ...[
          if (!_working)
            PreviewButton('إعادة تحميل المحاولة', onTap: _restoreAttempt),
        ] else if (attempt == null) ...[
          PreviewPanel(
            children: [
              PreviewText('المطلوب', style: context.design.label, muted: true),
              PreviewText(widget.prompt.statement),
            ],
          ),
          ...switch (widget.prompt) {
            StudentCodingPrompt(:final language) => [
              Text(language, textDirection: TextDirection.ltr),
              TextField(
                controller: _code,
                enabled: !_working,
                minLines: 6,
                maxLines: 18,
                maxLength: 8000,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: context.design.bodyMedium.copyWith(
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب الحل هنا',
                  filled: true,
                  fillColor: context.design.surfaceSubtle,
                ),
              ),
            ],
            StudentChoicePrompt(:final choices) => [
              for (final choice in choices)
                OutlinedButton(
                  onPressed: _working
                      ? null
                      : () => setState(() => _choice = choice.id),
                  style: _choice == choice.id
                      ? OutlinedButton.styleFrom(
                          backgroundColor: context.design.selectedSurface,
                        )
                      : null,
                  child: PreviewText(choice.text),
                ),
            ],
          },
          if (!_working) PreviewButton('إرسال للتصحيح', onTap: _send),
        ] else ...[
          PreviewPanel(
            height: 128,
            center: true,
            children: [
              if (attempt.score case final score?)
                PreviewText('$score/100', style: context.design.display),
              previewBadge(context, switch (attempt.status) {
                StudentAttemptStatus.grading => 'قيد التصحيح',
                StudentAttemptStatus.failed => 'تعذّر التصحيح',
                StudentAttemptStatus.graded =>
                  attempt.passed == true ? 'ناجح' : 'غير ناجح',
              }),
            ],
          ),
          if (attempt.explanation case final explanation?)
            PreviewPanel(children: [PreviewText(explanation)]),
          if (attempt.suggestedFix case final fix?)
            PreviewPanel(children: [PreviewText(fix)]),
          if (!_working) ...[
            if (attempt.status == StudentAttemptStatus.grading ||
                _error != null)
              PreviewButton('تحديث النتيجة', onTap: _refresh)
            else
              PreviewButton(
                'إعادة المحاولة',
                onTap: () => setState(() {
                  _attempt = null;
                  _key = null;
                  _error = null;
                }),
              ),
            PreviewButton(
              'العودة إلى التمارين',
              primary: false,
              onTap: widget.onBack,
            ),
          ],
        ],
        if (_working) const LinearProgressIndicator(),
        if (_error case final error?)
          Semantics(liveRegion: true, child: PreviewText(error)),
      ],
    );
  }
}
