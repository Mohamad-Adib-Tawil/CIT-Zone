import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/hasobjy_visual_scope.dart';
import '../../widgets/hasobjy_figma_components.dart';
import 'preview_widgets.dart';

/// Composition for the verified 2026-10-22 student frames, not an API screen.
class StudentUpdateScaffold extends StatelessWidget {
  const StudentUpdateScaffold({
    super.key,
    required this.title,
    required this.actions,
    required this.children,
    this.gap = 16,
  });
  final String title;
  final PreviewActions actions;
  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => HasobjyFigmaFrame(
    appBarTitle: title,
    onBack: actions.back,
    backgroundLayer: const StudentUpdateBackground(),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    ),
  );
}

class StudentUpdateBackground extends StatelessWidget {
  const StudentUpdateBackground({super.key});
  @override
  Widget build(BuildContext context) {
    final assets = context.designFrame!.assets;
    final left = assets['imgFloatSph'] == 'a12f7';
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SvgPicture.asset(
              'assets/hasobjy/${assets['img3DBackground']}.svg',
              fit: BoxFit.fill,
            ),
            Positioned(
              left: left ? -26.4 : null,
              right: left ? null : -29.2,
              top: left ? 227.6 : 240.8,
              width: left ? 44.8 : 38.4,
              height: left ? 44.8 : 38.4,
              child: SvgPicture.asset(
                'assets/hasobjy/${assets['imgFloatSph']}.svg',
              ),
            ),
            Positioned(
              left: left ? null : -42.67,
              right: left ? -37.337 : null,
              top: left ? 180.67 : 155.33,
              width: left ? 58.667 : 69.333,
              height: left ? 58.667 : 69.333,
              child: SvgPicture.asset(
                'assets/hasobjy/${assets['imgFloatCube']}.svg',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
