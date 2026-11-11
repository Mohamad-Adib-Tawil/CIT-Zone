import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../onboarding/presentation/theme/hasobjy_visual_scope.dart';
import '../../../onboarding/presentation/widgets/hasobjy_figma_components.dart';
import '../cubit/rating_selection_cubit.dart';

/// Controlled UI: the owner supplies persistence, busy and failure state.
/// A successful tap never marks a rating saved without a repository result.
class LessonRatingSheet extends StatelessWidget {
  const LessonRatingSheet({
    super.key,
    required this.cubit,
    required this.onSubmit,
    required this.onDismiss,
    required this.heading,
    required this.prompt,
    this.busy = false,
    this.error,
  });
  final RatingSelectionCubit cubit;
  final ValueChanged<int> onSubmit;
  final VoidCallback onDismiss;
  final String heading;
  final String prompt;
  final bool busy;
  final String? error;

  @override
  Widget build(BuildContext context) => BlocBuilder<RatingSelectionCubit, int?>(
    bloc: cubit,
    builder: (context, rating) {
      final assets = context.designFrame!.assets;
      return Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: BoxDecoration(
          color: context.design.surface,
          border: Border(top: BorderSide(color: context.design.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, color: context.design.borderStrong),
            const SizedBox(height: 12),
            Text(
              heading,
              style: context.design.labelSemiBold,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              prompt,
              style: context.design.bodySmall.copyWith(
                color: context.design.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  Flexible(
                    child: Semantics(
                      label: '$i من 5',
                      selected: rating == i,
                      button: true,
                      enabled: !busy,
                      child: InkWell(
                        onTap: busy ? null : () => cubit.select(i),
                        child: SizedBox(
                          width: 52,
                          height: 40,
                          child: Center(
                            child: HasobjySvg(
                              assets[rating != null && i <= rating
                                  ? 'imgStar'
                                  : 'imgStarEmpty1']!,
                              width: 40,
                              height: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              rating == null
                  ? 'اختر تقييماً'
                  : const ['ضعيف', 'مقبول', 'جيد', 'جيد جداً', 'ممتاز'][rating -
                        1],
              style: context.design.label.copyWith(color: context.design.brand),
            ),
            const SizedBox(height: 28),
            if (error != null) ...[
              Text(
                error!,
                style: context.design.bodySmall.copyWith(
                  color: context.design.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            HasobjyButton(
              label: busy ? 'جارٍ إرسال التقييم…' : 'إرسال التقييم',
              onPressed: busy || rating == null ? null : () => onSubmit(rating),
            ),
            const SizedBox(height: 12),
            HasobjyButton(
              label: 'ليس الآن',
              primary: false,
              onPressed: busy ? null : onDismiss,
            ),
          ],
        ),
      );
    },
  );
}
