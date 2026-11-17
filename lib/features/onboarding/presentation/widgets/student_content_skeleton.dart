import 'package:flutter/material.dart';

import '../../../../core/widgets/app_skeleton.dart';

enum StudentLoadingLayout {
  home,
  list,
  details,
  media,
  profile,
  form,
  schedule,
  nextPage,
}

class StudentContentSkeleton extends StatelessWidget {
  const StudentContentSkeleton({super.key, required this.layout});

  final StudentLoadingLayout layout;

  @override
  Widget build(BuildContext context) {
    final blocks = switch (layout) {
      StudentLoadingLayout.home => const [
        _RowBlock(height: 52),
        SkeletonBlock(width: 168, height: 24),
        SkeletonBlock(width: 208, height: 12),
        _PanelBlock(height: 102),
        _RowBlock(height: 70),
      ],
      StudentLoadingLayout.list => const [
        _RowBlock(height: 76),
        _RowBlock(height: 76),
        _RowBlock(height: 76),
      ],
      StudentLoadingLayout.details => const [
        SkeletonBlock(width: 168, height: 22),
        _PanelBlock(height: 84),
        _RowBlock(height: 64),
      ],
      StudentLoadingLayout.media => const [
        _PanelBlock(height: 150),
        SkeletonBlock(width: 180, height: 22),
        SkeletonBlock(width: 240, height: 12),
        _PanelBlock(height: 80),
      ],
      StudentLoadingLayout.profile => const [
        Align(
          child: SkeletonBlock(
            width: 72,
            height: 72,
            borderRadius: BorderRadius.all(Radius.circular(36)),
          ),
        ),
        Align(child: SkeletonBlock(width: 124, height: 20)),
        _RowBlock(height: 60),
        _RowBlock(height: 60),
      ],
      StudentLoadingLayout.form => const [
        SkeletonBlock(width: 108, height: 16),
        _PanelBlock(height: 52),
        SkeletonBlock(width: 92, height: 16),
        _PanelBlock(height: 52),
      ],
      StudentLoadingLayout.schedule => const [
        _PanelBlock(height: 44),
        _PanelBlock(height: 60),
        _PanelBlock(height: 60),
      ],
      StudentLoadingLayout.nextPage => const [_RowBlock(height: 64)],
    };

    return AppSkeleton(
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: blocks,
        ),
      ),
    );
  }
}

class _PanelBlock extends StatelessWidget {
  const _PanelBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => SkeletonBlock(
    width: double.infinity,
    height: height,
    borderRadius: const BorderRadius.all(Radius.circular(18)),
  );
}

class _RowBlock extends StatelessWidget {
  const _RowBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Row(
        spacing: 12,
        children: [
          SkeletonBlock(width: 44, height: 44),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: SkeletonBlock(height: 14),
                ),
                FractionallySizedBox(
                  widthFactor: 0.46,
                  child: SkeletonBlock(height: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
