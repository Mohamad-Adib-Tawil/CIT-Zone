import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/errors/either.dart';
import '../../../auth/domain/student_session_repository.dart';
import '../../../onboarding/presentation/pages/preview/preview_widgets.dart';
import '../../../onboarding/presentation/theme/hasobjy_visual_scope.dart';
import '../../../onboarding/presentation/widgets/hasobjy_figma_components.dart';
import '../cubit/rating_selection_cubit.dart';
import 'lesson_rating_sheet.dart';

class StudentLessonRating extends StatefulWidget {
  const StudentLessonRating({
    super.key,
    required this.title,
    required this.initial,
    required this.onRate,
  });

  final String title;
  final int? initial;
  final Future<Either<StudentSessionFailure, int>> Function(int) onRate;

  @override
  State<StudentLessonRating> createState() => _StudentLessonRatingState();
}

class _StudentLessonRatingState extends State<StudentLessonRating> {
  int? _saved;
  bool _sheetOpen = false;

  Future<void> _open() async {
    if (_sheetOpen) return;
    _sheetOpen = true;
    final light = Theme.of(context).brightness == Brightness.light;
    final selection = RatingSelectionCubit(initial: _saved ?? widget.initial);
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => HasobjyVisualScope(
          frameName: light ? 'C-09-LIGHT' : 'C-09',
          child: _RatingDialog(
            title: widget.title,
            selection: selection,
            onRate: widget.onRate,
            onSaved: (stars) {
              if (mounted) setState(() => _saved = stars);
            },
          ),
        ),
      );
    } finally {
      _sheetOpen = false;
      unawaited(selection.close());
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: InkWell(
      onTap: _open,
      child: PreviewPanel(
        height: 70,
        children: [
          Row(
            textDirection: TextDirection.ltr,
            spacing: 12,
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: List.generate(
                      5,
                      (_) => HasobjySvg(
                        context.design.isLight ? '65432' : 'b8cdb',
                        width: 26,
                        height: 26,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PreviewText('قيّم هذا الدرس', style: context.design.label),
                    PreviewText(
                      switch (_saved ?? widget.initial) {
                        final stars? => 'تقييمك: $stars من 5',
                        null => 'اضغط على النجوم',
                      },
                      muted: true,
                      style: context.design.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog({
    required this.title,
    required this.selection,
    required this.onRate,
    required this.onSaved,
  });

  final String title;
  final RatingSelectionCubit selection;
  final Future<Either<StudentSessionFailure, int>> Function(int) onRate;
  final ValueChanged<int> onSaved;

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  bool _busy = false;
  String? _error;

  Future<void> _submit(int stars) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.onRate(stars);
    if (!mounted) return;
    if (result case Right(:final value)) {
      widget.onSaved(value);
      Navigator.of(context).pop();
      return;
    }
    final failure = result.getLeft().toNullable();
    if (failure == StudentSessionFailure.accountSuspended ||
        failure == StudentSessionFailure.deviceUnauthorized) {
      if (ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).pop();
      }
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (failure) {
        StudentSessionFailure.lessonNotWatched =>
          'شاهد الدرس أولاً قبل تقييمه.',
        StudentSessionFailure.learningDataDenied => 'لا يمكنك تقييم هذا الدرس.',
        _ => 'تعذّر حفظ التقييم. أعد المحاولة.',
      };
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: LessonRatingSheet(
          cubit: widget.selection,
          heading: 'قيّم الدرس',
          prompt: 'ما رأيك في «${widget.title}»؟',
          onSubmit: _submit,
          onDismiss: () => Navigator.of(context).pop(),
          busy: _busy,
          error: _error,
        ),
      ),
    ),
  );
}
