import 'package:flutter/material.dart';

import '../../../../core/widgets/app_skeleton.dart';
import 'admin_components.dart';

class AdminDashboardSkeleton extends StatelessWidget {
  const AdminDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: AdminPageFrame(
          title: 'لوحة الإدارة',
          subtitle: 'إليك ما يحدث في منصة Hasobjy اليوم',
          children: [
            AppSkeleton(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 18,
                children: [
                  SkeletonBlock(width: 160, height: 14),
                  _MetricsSkeleton(),
                  SkeletonBlock(width: 120, height: 20),
                  SkeletonBlock(width: double.infinity, height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsSkeleton extends StatelessWidget {
  const _MetricsSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1040
            ? 4
            : width >= 340
            ? 2
            : 1;
        const spacing = 12.0;
        final cardWidth = (width - (columns - 1) * spacing) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < 4; index++)
              SkeletonBlock(width: cardWidth, height: 100),
          ],
        );
      },
    );
  }
}
