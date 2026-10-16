import 'package:flutter/material.dart';

import '../../theme/hasobjy_frame_slots.dart';
import '../../theme/hasobjy_visual_scope.dart';
import '../../widgets/hasobjy_figma_components.dart';

/// Actions stay within debug preview routes. Server operations are never faked.
class PreviewActions {
  const PreviewActions({
    required this.open,
    required this.notice,
    required this.back,
  });
  final ValueChanged<String> open;
  final VoidCallback notice;
  final VoidCallback back;
}

String? previewIcon(BuildContext context, String label) =>
    hasobjyFrameIconSlots[context.designFrame?.frameName]?[label] ??
    hasobjyFrameIconSlots[context.designFrame?.baseName]?[label];

class PreviewScaffold extends StatelessWidget {
  const PreviewScaffold({
    super.key,
    this.title,
    required this.actions,
    required this.children,
    this.navigation = false,
    this.header,
    this.gap = 14,
    this.bottomPadding = 24,
  });
  final String? title;
  final PreviewActions actions;
  final List<Widget> children;
  final bool navigation;
  final Widget? header;
  final double gap;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => HasobjyFigmaFrame(
    appBarTitle: title,
    onBack: actions.back,
    header: header,
    bottomNavigation: navigation ? PreviewNavigation(actions: actions) : null,
    child: Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding),
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

class PreviewNavigation extends StatelessWidget {
  const PreviewNavigation({super.key, required this.actions});
  final PreviewActions actions;
  static const destinations = {
    'الرئيسية': 'C-01',
    'المواد': 'C-02',
    'الكورسات': 'F-01',
    'الإعدادات': 'S-01',
  };
  @override
  Widget build(BuildContext context) {
    final entries =
        hasobjyFrameNavigation[context.designFrame?.frameName] ??
        const <(String, String)>[];
    final reference = HasobjyReferenceViewport.isActive(context);
    return ColoredBox(
      color: context.design.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.design.border)),
            ),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [
                for (final item in entries)
                  Expanded(
                    child: Semantics(
                      button: true,
                      child: InkWell(
                        onTap: () => actions.open(destinations[item.$1]!),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HasobjySvg(item.$2, width: 24, height: 24),
                            const SizedBox(height: 4),
                            Text(
                              item.$1,
                              style: context.design.badge.copyWith(
                                color:
                                    destinations[item.$1] ==
                                        (switch (context
                                            .designFrame
                                            ?.baseName) {
                                          'C-03' => 'C-02',
                                          'H-01' => 'C-01',
                                          final name => name,
                                        })
                                    ? context.design.brand
                                    : context.design.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (reference)
            SizedBox(
              height: 34,
              child: Center(
                child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.design.textPrimary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            )
          else
            SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
        ],
      ),
    );
  }
}

class PreviewText extends StatelessWidget {
  const PreviewText(
    this.text, {
    super.key,
    this.style,
    this.align = TextAlign.right,
    this.color,
    this.primary = false,
    this.muted = false,
  });
  final String text;
  final TextStyle? style;
  final TextAlign align;
  final Color? color;
  final bool primary;
  final bool muted;
  @override
  Widget build(BuildContext context) => Text(
    text,
    textDirection: RegExp(r'^[^A-Za-z\u0600-\u06ff]*[A-Za-z]').hasMatch(text)
        ? TextDirection.ltr
        : TextDirection.rtl,
    textAlign: align,
    style: (style ?? context.design.bodyMedium).copyWith(
      color:
          color ??
          (primary
              ? context.design.textPrimary
              : muted
              ? context.design.textMuted
              : style == context.design.bodySmall
              ? context.design.textSecondary
              : null),
    ),
  );
}

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    required this.children,
    this.gap = 8,
    this.padding = 16,
    this.fill,
    this.height,
    this.center = false,
    this.border = true,
  });
  final List<Widget> children;
  final double gap;
  final double padding;
  final Color? fill;
  final double? height;
  final bool center;
  final bool border;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    constraints: BoxConstraints(minHeight: height ?? 0),
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: fill ?? context.design.surface,
      border: border ? Border.all(color: context.design.border) : null,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.stretch,
      mainAxisAlignment: center
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          children[i],
        ],
      ],
    ),
  );
}

class PreviewProgress extends StatelessWidget {
  const PreviewProgress(
    this.value, {
    super.key,
    this.width,
    this.height = 4,
    this.fill,
  });
  final double value;
  final double? width;
  final double height;
  final Color? fill;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ColoredBox(
      color: context.design.surfaceSubtle,
      child: Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          child: ColoredBox(color: fill ?? context.design.brand),
        ),
      ),
    ),
  );
}

class PreviewTabs extends StatefulWidget {
  const PreviewTabs({
    super.key,
    required this.labels,
    this.selected = 0,
    this.onSelected,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int>? onSelected;
  @override
  State<PreviewTabs> createState() => _PreviewTabsState();
}

class _PreviewTabsState extends State<PreviewTabs> {
  late int selected = widget.selected;
  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.ltr,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < widget.labels.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () {
              if (widget.onSelected != null) {
                widget.onSelected!(i);
              } else {
                setState(() => selected = i);
              }
            },
            child: Container(
              constraints: BoxConstraints(minHeight: i == selected ? 40 : 42),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: i == selected ? context.design.brand : null,
                border: i == selected
                    ? null
                    : Border.all(color: context.design.border),
              ),
              child: PreviewText(
                widget.labels[i],
                align: TextAlign.center,
                style: context.design.label,
                color: i == selected
                    ? context.design.textOnBrand
                    : context.design.textSecondary,
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class PreviewButton extends StatelessWidget {
  const PreviewButton(
    this.label, {
    super.key,
    required this.onTap,
    this.primary = true,
    this.icon = true,
    this.subtle = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool icon;
  final bool subtle;
  @override
  Widget build(BuildContext context) {
    final asset = icon ? previewIcon(context, label) : null;
    return HasobjyButton(
      label: label,
      onPressed: onTap,
      primary: primary,
      backgroundColor: subtle ? context.design.selectedSurface : null,
      textColor: subtle ? context.design.brand : null,
      icon: asset == null ? null : HasobjySvg(asset, width: 24, height: 24),
    );
  }
}

class PreviewIconTile extends StatelessWidget {
  const PreviewIconTile({
    super.key,
    this.asset,
    this.label,
    this.size = 44,
    this.glyphSize = 24,
    this.fill,
  });
  final String? asset;
  final String? label;
  final double size;
  final double glyphSize;
  final Color? fill;
  @override
  Widget build(BuildContext context) {
    final value = asset ?? previewIcon(context, label ?? '');
    return Container(
      width: size,
      height: size,
      color: fill ?? context.design.surfaceSubtle,
      alignment: Alignment.center,
      child: value == null
          ? null
          : HasobjySvg(value, width: glyphSize, height: glyphSize),
    );
  }
}

class PreviewListCard extends StatelessWidget {
  const PreviewListCard({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.progress,
    this.height = 100,
    this.onTap,
    this.asset,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? badge;
  final double? progress;
  final double height;
  final VoidCallback? onTap;
  final String? asset;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: PreviewPanel(
      height: height,
      center: true,
      children: [
        Row(
          textDirection: TextDirection.ltr,
          children: [
            if (trailing != null) ...[trailing!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  PreviewText(title, style: context.design.labelSemiBold),
                  if (subtitle != null) ...[
                    SizedBox(height: badge == null ? 6 : 4),
                    PreviewText(subtitle!, style: context.design.bodySmall),
                  ],
                  if (badge != null) ...[
                    SizedBox(height: subtitle == null ? 6 : 4),
                    Align(alignment: Alignment.centerRight, child: badge),
                  ],
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PreviewProgress(progress!, width: 100),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            PreviewIconTile(asset: asset, label: title),
          ],
        ),
      ],
    ),
  );
}

class PreviewField extends StatelessWidget {
  const PreviewField({
    super.key,
    required this.label,
    required this.hint,
    this.helper,
    this.controller,
    this.direction,
  });
  final String label;
  final String hint;
  final String? helper;
  final TextEditingController? controller;
  final TextDirection? direction;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PreviewText(label, style: context.design.label),
      const SizedBox(height: 4),
      Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.design.surface,
          border: Border.all(color: context.design.border),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          style: context.design.bodyLarge.copyWith(
            color: context.design.textMuted,
          ),
          textDirection: direction ?? TextDirection.rtl,
          textAlign: direction == TextDirection.ltr
              ? TextAlign.left
              : TextAlign.right,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.design.bodyLarge.copyWith(
              color: context.design.textMuted,
            ),
            filled: false,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
      if (helper != null) ...[
        const SizedBox(height: 4),
        PreviewText(
          helper!,
          style: context.design.bodySmall,
          color: context.design.textMuted,
        ),
      ],
    ],
  );
}

Widget previewBadge(
  BuildContext context,
  String text, {
  String tone = 'brand',
}) => HasobjyBadge(
  label: text,
  background: tone == 'neutral'
      ? context.design.surfaceSubtle
      : tone == 'danger'
      ? (context.design.isLight
            ? const Color(0xFFFDECEC)
            : const Color(0xFFA32A2E))
      : tone == 'success'
      ? context.design.success
      : tone == 'warning'
      ? context.design.warning
      : context.design.selectedSurface,
  foreground: tone == 'neutral'
      ? context.design.textSecondary
      : tone == 'danger'
      ? (context.design.isLight
            ? const Color(0xFFA32A2E)
            : const Color(0xFFFDECEC))
      : tone == 'success'
      ? context.design.successText
      : tone == 'warning'
      ? context.design.warningText
      : context.design.brand,
);

class PreviewKeyValue extends StatelessWidget {
  const PreviewKeyValue(
    this.label,
    this.value, {
    super.key,
    this.body = false,
    this.emphasis = false,
  });
  final String label;
  final String value;
  final bool body;
  final bool emphasis;
  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.ltr,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: PreviewText(
          value,
          align: TextAlign.left,
          style: emphasis
              ? context.design.labelSemiBold
              : context.design.bodyMedium.copyWith(
                  color: context.design.textPrimary,
                ),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: PreviewText(
          label,
          style: body ? context.design.bodyMedium : context.design.bodySmall,
          color: body ? context.design.textSecondary : context.design.textMuted,
        ),
      ),
    ],
  );
}
