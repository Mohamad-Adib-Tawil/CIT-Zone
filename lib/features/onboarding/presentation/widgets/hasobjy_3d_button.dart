import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/hasobjy_visual_scope.dart';

/// Native interactive content over the original Figma vector shell layers.
class Hasobjy3DButton extends StatelessWidget {
  const Hasobjy3DButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.google = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool google;

  @override
  Widget build(BuildContext context) {
    final light = context.design.isLight;
    final height = light ? (google ? 66.0 : 60.0) : 52.0;
    Widget svg(String name) =>
        SvgPicture.asset('assets/hasobjy/$name.svg', fit: BoxFit.fill);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          boxShadow: [
            light
                ? BoxShadow(
                    color: google
                        ? const Color(0x4D0578B8)
                        : const Color(0x4D000000),
                    offset: Offset(0, google ? 10 : 8),
                    blurRadius: google ? 28 : 12,
                  )
                : const BoxShadow(color: Color(0xA62E9CE5), blurRadius: 22),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!light) ...[
              Positioned.fill(child: svg('75ce9')),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 20,
                child: svg('80870'),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 52,
                child: svg('07489'),
              ),
            ] else ...[
              if (google)
                Positioned(
                  top: 56,
                  left: 6,
                  right: 6,
                  height: 12,
                  child: svg('d5276'),
                ),
              Positioned(
                top: 8,
                left: 0,
                right: 0,
                height: 52,
                child: svg('0ac5c'),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 52,
                child: svg('b926f'),
              ),
              Positioned(
                top: 2,
                left: 2,
                right: 2,
                height: 20,
                child: svg('7d772'),
              ),
              Positioned(
                top: 0,
                left: 10,
                right: .5,
                height: 1,
                child: svg('2592c'),
              ),
              if (google)
                Positioned(
                  top: 10,
                  left: 0,
                  right: 10,
                  height: 42,
                  child: svg('605ac'),
                ),
            ],
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 52,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        textDirection: TextDirection.ltr,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (google && icon != null) ...[
                            icon!,
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.center,
                              style: context.design.label.copyWith(
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x80000D33),
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!google && icon != null) ...[
                            const SizedBox(width: 10),
                            ColorFiltered(
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              child: icon!,
                            ),
                          ],
                        ],
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
}
