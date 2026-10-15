import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/hasobjy_design_tokens.dart';

class HasobjyFigmaFrame extends StatelessWidget {
  const HasobjyFigmaFrame({
    super.key,
    required this.child,
    this.appBarTitle,
    this.onBack,
    this.scrollable = false,
  });

  final Widget child;
  final String? appBarTitle;
  final VoidCallback? onBack;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HasobjyDesignTokens.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                children: [
                  if (appBarTitle != null)
                    HasobjyAppBar(title: appBarTitle!, onBack: onBack),
                  Expanded(
                    child: scrollable
                        ? SingleChildScrollView(child: child)
                        : child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HasobjyStatusBar extends StatelessWidget {
  const HasobjyStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Text('9:41', style: HasobjyDesignTokens.label),
              Spacer(),
              HasobjySvg('ec76a', width: 18, height: 12),
              SizedBox(width: 6),
              HasobjySvg('22855', width: 17, height: 12),
              SizedBox(width: 6),
              HasobjySvg('00202', width: 27, height: 13),
            ],
          ),
        ),
      ),
    );
  }
}

class HasobjyAppBar extends StatelessWidget {
  const HasobjyAppBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ColoredBox(
        color: HasobjyDesignTokens.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                const SizedBox(width: 24),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: HasobjyDesignTokens.labelLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: onBack == null
                      ? const SizedBox.shrink()
                      : InkWell(
                          onTap: onBack,
                          child: const HasobjySvg('e82f9'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HasobjySvg extends StatelessWidget {
  const HasobjySvg(
    this.name, {
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String name;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/hasobjy/$name.svg',
    width: width,
    height: height,
    fit: fit,
  );
}

class HasobjyButton extends StatelessWidget {
  const HasobjyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.icon,
    this.height = 52,
    this.backgroundColor,
    this.cornerLine,
    this.textColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final Widget? icon;
  final double height;
  final Color? backgroundColor;
  final String? cornerLine;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final background =
        backgroundColor ??
        (primary ? HasobjyDesignTokens.brand : HasobjyDesignTokens.surface);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: HasobjyCutPainter(
          fill: background,
          border: primary ? null : HasobjyDesignTokens.borderStrong,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [
                  Align(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: HasobjyDesignTokens.labelLarge.copyWith(
                                color:
                                    textColor ??
                                    (primary
                                        ? HasobjyDesignTokens.background
                                        : HasobjyDesignTokens.textPrimary),
                              ),
                            ),
                          ),
                          if (icon != null) ...[
                            const SizedBox(width: 8),
                            icon!,
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (primary) ...[
                    const Positioned(
                      left: 0,
                      top: 0,
                      width: 10,
                      height: 10,
                      child: HasobjySvg('b043f'),
                    ),
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      width: 10,
                      height: 10,
                      child: HasobjySvg('03567'),
                    ),
                  ],
                  if (cornerLine != null) ...[
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 10,
                      height: 10,
                      child: HasobjySvg(cornerLine!),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      width: 10,
                      height: 10,
                      child: HasobjySvg(cornerLine!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HasobjySurface extends StatelessWidget {
  const HasobjySurface({
    super.key,
    required this.child,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.fill = HasobjyDesignTokens.surface,
    this.border = HasobjyDesignTokens.border,
    this.selected = false,
    this.cornerSize = 12,
    this.cornerTopLeft = 'b043f',
    this.cornerBottomRight = '03567',
    this.cornerLine,
  });

  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final Color fill;
  final Color border;
  final bool selected;
  final double cornerSize;
  final String cornerTopLeft;
  final String cornerBottomRight;
  final String? cornerLine;

  @override
  Widget build(BuildContext context) {
    final actualFill = selected ? HasobjyDesignTokens.selectedSurface : fill;
    final actualBorder = selected ? HasobjyDesignTokens.brand : border;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: HasobjyCutPainter(fill: actualFill, border: actualBorder),
        child: ClipPath(
          clipper: HasobjyCutClipper(),
          child: Stack(
            children: [
              Padding(padding: padding, child: child),
              Positioned(
                top: -1,
                left: -1,
                width: cornerSize,
                height: cornerSize,
                child: HasobjySvg(cornerTopLeft),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                width: cornerSize,
                height: cornerSize,
                child: HasobjySvg(cornerBottomRight),
              ),
              if (cornerLine != null) ...[
                Positioned(
                  top: -1,
                  left: -1,
                  width: cornerSize,
                  height: cornerSize,
                  child: HasobjySvg(cornerLine!),
                ),
                Positioned(
                  right: -1,
                  bottom: -1,
                  width: cornerSize,
                  height: cornerSize,
                  child: HasobjySvg(cornerLine!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class HasobjyStepper extends StatelessWidget {
  const HasobjyStepper({super.key, required this.activeBars});

  final int activeBars;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsetsDirectional.only(end: index == 2 ? 0 : 4),
            decoration: BoxDecoration(
              color: index < activeBars
                  ? HasobjyDesignTokens.brand
                  : HasobjyDesignTokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class HasobjyCutPainter extends CustomPainter {
  const HasobjyCutPainter({required this.fill, this.border});

  final Color fill;
  final Color? border;

  @override
  void paint(Canvas canvas, Size size) {
    const cut = 12.0;
    final path = Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    if (border != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = border!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(HasobjyCutPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}

class HasobjyCutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const cut = 12.0;
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  bool shouldReclip(HasobjyCutClipper oldClipper) => false;
}

class HasobjyFormField extends StatelessWidget {
  const HasobjyFormField({
    super.key,
    required this.label,
    required this.hint,
    required this.iconAsset,
    this.helper,
    this.controller,
    this.enabled = true,
    this.textDirection,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final String iconAsset;
  final String? helper;
  final TextEditingController? controller;
  final bool enabled;
  final TextDirection? textDirection;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.label,
          ),
          const SizedBox(height: 4),
          Container(
            height: maxLines == 1 ? 52 : null,
            constraints: maxLines == 1
                ? null
                : const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(
              color: enabled
                  ? HasobjyDesignTokens.surface
                  : HasobjyDesignTokens.surfaceSubtle,
              border: Border.all(color: HasobjyDesignTokens.border),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      enabled: enabled,
                      maxLines: maxLines,
                      keyboardType: keyboardType,
                      textDirection: textDirection,
                      textAlign: textDirection == TextDirection.ltr
                          ? TextAlign.left
                          : TextAlign.right,
                      style: HasobjyDesignTokens.bodyLarge,
                      decoration: InputDecoration(
                        hintText: hint,
                        filled: true,
                        fillColor: enabled
                            ? HasobjyDesignTokens.surface
                            : HasobjyDesignTokens.surfaceSubtle,
                        hintStyle: HasobjyDesignTokens.bodyLarge.copyWith(
                          color: HasobjyDesignTokens.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 8,
                      end: 16,
                    ),
                    child: HasobjySvg(iconAsset, width: 24, height: 24),
                  ),
                ],
              ),
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(
              helper!,
              textAlign: TextAlign.end,
              style: HasobjyDesignTokens.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class HasobjyKeyValue extends StatelessWidget {
  const HasobjyKeyValue(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: HasobjyDesignTokens.bodyMedium,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            textAlign: TextAlign.end,
            style: HasobjyDesignTokens.bodyMedium.copyWith(
              color: HasobjyDesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
