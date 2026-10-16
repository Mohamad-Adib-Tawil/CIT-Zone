import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/hasobjy_design_tokens.dart';

/// Uses the design's status bar only for deterministic visual audit captures.
/// Normal app routes retain the device's native safe areas and system chrome.
class HasobjyReferenceViewport extends InheritedWidget {
  const HasobjyReferenceViewport({super.key, required super.child});

  static bool isActive(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HasobjyReferenceViewport>() !=
      null;

  @override
  bool updateShouldNotify(HasobjyReferenceViewport oldWidget) => false;
}

class HasobjyFigmaFrame extends StatelessWidget {
  const HasobjyFigmaFrame({
    super.key,
    required this.child,
    this.appBarTitle,
    this.onBack,
  });

  final Widget child;
  final String? appBarTitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final reference = HasobjyReferenceViewport.isActive(context);
    final content = Column(
      children: [
        if (reference) const HasobjyStatusBar(),
        if (appBarTitle != null)
          HasobjyAppBar(title: appBarTitle!, onBack: onBack),
        Expanded(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [SliverFillRemaining(hasScrollBody: false, child: child)],
          ),
        ),
      ],
    );
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: HasobjyDesignTokens.background,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: reference ? content : SafeArea(child: content),
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
  Widget build(BuildContext context) => const SizedBox(
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

class HasobjyAppBar extends StatelessWidget {
  const HasobjyAppBar({super.key, required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: ColoredBox(
      color: HasobjyDesignTokens.surface,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(title, style: HasobjyDesignTokens.labelSemiBold),
          Positioned(
            right: 4,
            child: IconButton(
              tooltip: AppLocalizations.of(context).backAction,
              onPressed: onBack,
              icon: const HasobjySvg('e82f9', width: 24, height: 24),
            ),
          ),
        ],
      ),
    ),
  );
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

/// The original SVG corner masks and diagonal strokes are separate Figma layers.
/// Paint them over the rectangular surface once, without a second drawn chamfer.
class _HasobjyCorners extends StatelessWidget {
  const _HasobjyCorners({
    required this.size,
    required this.inset,
    required this.topLeft,
    required this.bottomRight,
    this.line,
  });
  final double size;
  final double inset;
  final String topLeft;
  final String bottomRight;
  final String? line;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -inset,
          top: -inset,
          child: HasobjySvg(topLeft, width: size, height: size),
        ),
        Positioned(
          right: -inset,
          bottom: -inset,
          child: HasobjySvg(bottomRight, width: size, height: size),
        ),
        if (line != null) ...[
          Positioned(
            left: -inset - inset / 1.4142,
            top: -inset - inset / 1.4142,
            child: HasobjySvg(
              line!,
              width: size + inset * 1.4142,
              height: size + inset * 1.4142,
            ),
          ),
          Positioned(
            right: -inset - inset / 1.4142,
            bottom: -inset - inset / 1.4142,
            child: HasobjySvg(
              line!,
              width: size + inset * 1.4142,
              height: size + inset * 1.4142,
            ),
          ),
        ],
      ],
    ),
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
    final outlined = !primary && backgroundColor == null;
    final borderWidth = outlined ? 1.0 : 0.0;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: background,
          border: outlined
              ? Border.all(color: HasobjyDesignTokens.borderStrong)
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              textDirection: TextDirection.rtl,
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
                ),
              ),
            ),
            _HasobjyCorners(
              size: 10,
              inset: borderWidth,
              topLeft: 'b043f',
              bottomRight: '03567',
              line: outlined ? (cornerLine ?? '84987') : null,
            ),
          ],
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
    this.alignment = Alignment.topLeft,
    this.fill = HasobjyDesignTokens.surface,
    this.border = HasobjyDesignTokens.border,
    this.selected = false,
    this.cornerSize = 12,
    this.cornerTopLeft = '21288',
    this.cornerBottomRight = 'c95e6',
    this.cornerLine,
  });
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry alignment;
  final Color fill;
  final Color? border;
  final bool selected;
  final double cornerSize;
  final String cornerTopLeft;
  final String cornerBottomRight;
  final String? cornerLine;

  @override
  Widget build(BuildContext context) {
    final borderWidth = selected ? 2.0 : (border == null ? 0.0 : 1.0);
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: height ?? 0),
      decoration: BoxDecoration(
        color: selected ? HasobjyDesignTokens.selectedSurface : fill,
        border: borderWidth == 0
            ? null
            : Border.all(
                color: selected ? HasobjyDesignTokens.brand : border!,
                width: borderWidth,
              ),
      ),
      child: Stack(
        alignment: alignment,
        clipBehavior: Clip.none,
        children: [
          Padding(padding: padding, child: child),
          Positioned.fill(
            child: _HasobjyCorners(
              size: cornerSize,
              inset: borderWidth,
              topLeft: cornerTopLeft,
              bottomRight: cornerBottomRight,
              line: cornerLine,
            ),
          ),
        ],
      ),
    );
  }
}

class HasobjySelectionOption extends StatelessWidget {
  const HasobjySelectionOption({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: GestureDetector(
      onTap: onTap,
      child: HasobjySurface(
        height: 100,
        alignment: Alignment.center,
        selected: selected,
        cornerTopLeft: '21288',
        cornerBottomRight: 'c95e6',
        cornerLine: selected ? '416c4' : '8c8a2',
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              HasobjySvg(selected ? '0fd39' : 'cb103', width: 22, height: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: HasobjyDesignTokens.labelSemiBold,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: HasobjyDesignTokens.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 44,
                height: 44,
                color: HasobjyDesignTokens.surfaceSubtle,
                alignment: Alignment.center,
                child: HasobjySvg(iconAsset, width: 24, height: 24),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HasobjyStepper extends StatelessWidget {
  const HasobjyStepper({super.key, required this.activeBars});
  final int activeBars;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Row(
      children: [
        for (var index = 0; index < 3; index++) ...[
          if (index > 0) const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: index < activeBars
                    ? HasobjyDesignTokens.brand
                    : HasobjyDesignTokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class HasobjyBadge extends StatelessWidget {
  const HasobjyBadge({
    super.key,
    required this.label,
    this.background = HasobjyDesignTokens.surfaceSubtle,
    this.foreground = HasobjyDesignTokens.textSecondary,
    this.onTap,
  });
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: HasobjyDesignTokens.badge.copyWith(color: foreground),
      ),
    ),
  );
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
    this.mirrorIcon = false,
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
  final bool mirrorIcon;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : .6,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.right,
          style: HasobjyDesignTokens.label,
        ),
        const SizedBox(height: 4),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: enabled
                ? HasobjyDesignTokens.surface
                : HasobjyDesignTokens.surfaceSubtle,
            border: Border.all(color: HasobjyDesignTokens.border),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: enabled,
                    maxLines: maxLines,
                    keyboardType: keyboardType,
                    textDirection: textDirection ?? TextDirection.rtl,
                    textAlign: textDirection == TextDirection.ltr
                        ? TextAlign.left
                        : TextAlign.right,
                    style: HasobjyDesignTokens.bodyLarge.copyWith(
                      color: HasobjyDesignTokens.textMuted,
                    ),
                    cursorColor: HasobjyDesignTokens.brand,
                    decoration: InputDecoration(
                      hintText: hint,
                      filled: false,
                      hintStyle: HasobjyDesignTokens.bodyLarge.copyWith(
                        color: HasobjyDesignTokens.textMuted,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isCollapsed: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: Transform.flip(
                      flipX: mirrorIcon,
                      child: HasobjySvg(
                        iconAsset,
                        width: mirrorIcon ? 21.414 : 24,
                        height: mirrorIcon ? 21.414 : 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper!,
            textAlign: TextAlign.right,
            style: HasobjyDesignTokens.bodySmall,
          ),
        ],
      ],
    ),
  );
}

class HasobjyKeyValue extends StatelessWidget {
  const HasobjyKeyValue(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            value,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.left,
            style: HasobjyDesignTokens.label,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: HasobjyDesignTokens.bodyMedium,
        ),
      ],
    ),
  );
}
