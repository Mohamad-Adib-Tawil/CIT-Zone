import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Decorations read from the ten live I-01..05 Figma contexts, 2026-10-22.
class AppStatusBackground extends StatelessWidget {
  const AppStatusBackground({
    super.key,
    required this.frame,
    required this.light,
  });
  final String frame;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final background = light
        ? '624a4'
        : frame == 'I-02'
        ? 'b335e'
        : 'acb67';
    final decorations = switch ((frame, light)) {
      ('I-01', false) => [
        ('6f3f1', 348.0, 122.67, 74.667),
        ('9af13', 381.0, 99.2, 41.6),
      ],
      ('I-02', false) || ('I-01', true) || ('I-04', true) => [
        ('5df30', 364.0, 118.0, 64.0),
        ('ae3b3', -21.2, 280.8, 38.4),
      ],
      ('I-03', false) || ('I-05', true) => [
        ('ff7c9', 380.8, 240.8, 38.4),
        ('5a19f', -42.67, 155.33, 69.333),
      ],
      ('I-04', false) || ('I-02', true) => [
        ('6f3f1', -43.33, 122.67, 74.667),
        ('9af13', 381.2, 99.2, 41.6),
      ],
      _ => [('a12f7', -26.4, 227.6, 44.8), ('f1409', 368.67, 180.67, 58.667)],
    };
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              left: frame == 'I-01' && !light ? 33 : 0,
              right: frame == 'I-01' && !light ? -33 : 0,
              child: SvgPicture.asset(
                'assets/hasobjy/$background.svg',
                fit: BoxFit.fill,
              ),
            ),
            for (final item in decorations)
              Positioned(
                left: item.$2 < 0 ? item.$2 : null,
                right: item.$2 >= 0 ? 390 - item.$2 - item.$4 : null,
                top: item.$3,
                width: item.$4,
                height: item.$4,
                child: SvgPicture.asset('assets/hasobjy/${item.$1}.svg'),
              ),
          ],
        ),
      ),
    );
  }
}
