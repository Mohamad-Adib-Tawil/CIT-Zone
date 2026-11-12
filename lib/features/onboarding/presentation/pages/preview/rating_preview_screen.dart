import 'package:flutter/material.dart';

import '../../widgets/hasobjy_figma_components.dart';

import '../../../../lesson_ratings/presentation/cubit/rating_selection_cubit.dart';
import '../../../../lesson_ratings/presentation/widgets/lesson_rating_sheet.dart';
import 'learning_preview_screens.dart';
import 'preview_widgets.dart';

class RatingPreviewScreen extends StatefulWidget {
  const RatingPreviewScreen({super.key, required this.actions});
  final PreviewActions actions;
  @override
  State<RatingPreviewScreen> createState() => _RatingPreviewScreenState();
}

class _RatingPreviewScreenState extends State<RatingPreviewScreen> {
  // Four stars reproduce the source frame; this is not a student's saved value.
  final selection = RatingSelectionCubit(initial: 4);
  @override
  void dispose() {
    selection.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          LearningPreviewScreen(frame: 'C-04', actions: widget.actions),
          const Positioned.fill(child: ColoredBox(color: Color(0xB8010712))),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              bottom: !HasobjyReferenceViewport.isActive(context),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      HasobjyReferenceViewport.isActive(context) ? 16 : 0,
                    ),
                    child: SingleChildScrollView(
                      child: LessonRatingSheet(
                        cubit: selection,
                        heading: 'قيّم الدرس 4',
                        prompt: 'ما رأيك في «لغة SQL الأساسية»؟',
                        onSubmit: (_) => widget.actions.notice(),
                        onDismiss: () => widget.actions.open('C-04'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
