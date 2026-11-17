import 'package:flutter/material.dart';

import '../localization/generated/app_localizations.dart';

/// Marks a group of decorative placeholders as one accessible loading state.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).loadingContent,
      liveRegion: true,
      excludeSemantics: true,
      child: IgnorePointer(child: child),
    );
  }
}

/// A static placeholder sized by the feature's loading layout.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = colors.brightness == Brightness.dark ? 0.20 : 0.14;
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.lerp(colors.surface, colors.primary, tint),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
