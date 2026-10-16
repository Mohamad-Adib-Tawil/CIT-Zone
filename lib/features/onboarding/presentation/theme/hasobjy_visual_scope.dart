import 'package:flutter/material.dart';

import 'hasobjy_design_tokens.dart';
import 'hasobjy_frame_assets.dart';
import 'hasobjy_asset_variants.dart';

final _hasobjyOriginalLightAssets = {
  for (final entry in hasobjyFrameAssets.entries)
    if (entry.key.endsWith('-LIGHT')) ...entry.value.values,
};

/// Figma appearance and original asset variants, scoped to one rendered frame.
/// This carries presentation data only, never account access or product policy.
class HasobjyVisualScope extends InheritedWidget {
  const HasobjyVisualScope({
    super.key,
    required this.frameName,
    required super.child,
  });

  final String frameName;
  bool get isLight => frameName.endsWith('-LIGHT');
  String get baseName => frameName.replaceAll('-LIGHT', '');
  Map<String, String> get assets => hasobjyFrameAssets[frameName] ?? const {};

  static HasobjyVisualScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HasobjyVisualScope>();

  String resolveAsset(String original) {
    if (!isLight) return original;
    // Figma keeps these structural role names stable across theme exports.
    // Glyph numbering changes when shared component definitions are expanded.
    final dark = hasobjyFrameAssets[baseName] ?? const {};
    for (final entry in dark.entries) {
      if (entry.value == original &&
          RegExp(r'^img(Radio|Chamfer|IconCircle|Signal|WiFi|Battery|BackIcon)')
              .hasMatch(entry.key) &&
          assets.containsKey(entry.key)) {
        return assets[entry.key]!;
      }
    }
    if (_hasobjyOriginalLightAssets.contains(original)) return original;
    return hasobjyLightAssetVariants[original] ?? original;
  }

  @override
  bool updateShouldNotify(HasobjyVisualScope oldWidget) =>
      frameName != oldWidget.frameName;
}

extension HasobjyVisualContext on BuildContext {
  HasobjyPalette get design =>
      HasobjyPalette(HasobjyVisualScope.maybeOf(this)?.isLight ?? false);

  HasobjyVisualScope? get designFrame => HasobjyVisualScope.maybeOf(this);
}

class HasobjyPalette {
  const HasobjyPalette(this.isLight);
  final bool isLight;
  Color get background =>
      isLight ? const Color(0xFFF4FBFF) : HasobjyDesignTokens.background;
  Color get surface => isLight ? Colors.white : HasobjyDesignTokens.surface;
  Color get surfaceSubtle =>
      isLight ? const Color(0xFFE4F1F9) : HasobjyDesignTokens.surfaceSubtle;
  Color get selectedSurface =>
      isLight ? const Color(0xFFD9F1FD) : HasobjyDesignTokens.selectedSurface;
  Color get brand =>
      isLight ? const Color(0xFF0578B7) : HasobjyDesignTokens.brand;
  Color get textPrimary => isLight ? const Color(0xFF02112C) : Colors.white;
  Color get textSecondary =>
      isLight ? const Color(0xFF3D5A78) : HasobjyDesignTokens.textSecondary;
  Color get textMuted =>
      isLight ? const Color(0xFF587A9C) : HasobjyDesignTokens.textMuted;
  Color get border =>
      isLight ? const Color(0xFFC5DFF0) : HasobjyDesignTokens.border;
  Color get borderStrong =>
      isLight ? const Color(0xFF9FC4E6) : HasobjyDesignTokens.borderStrong;
  Color get warning =>
      isLight ? const Color(0xFFFDF4E1) : HasobjyDesignTokens.warning;
  Color get warningText =>
      isLight ? const Color(0xFF8C5E10) : HasobjyDesignTokens.warningText;
  Color get success =>
      isLight ? const Color(0xFFE8F8EF) : HasobjyDesignTokens.success;
  Color get successText =>
      isLight ? const Color(0xFF12713F) : HasobjyDesignTokens.successText;
  Color get textOnBrand =>
      isLight ? Colors.white : HasobjyDesignTokens.background;

  TextStyle get bodySmall =>
      HasobjyDesignTokens.bodySmall.copyWith(color: textMuted);
  TextStyle get bodyMedium =>
      HasobjyDesignTokens.bodyMedium.copyWith(color: textSecondary);
  TextStyle get bodyLarge =>
      HasobjyDesignTokens.bodyLarge.copyWith(color: textSecondary);
  TextStyle get label => HasobjyDesignTokens.label.copyWith(color: textPrimary);
  TextStyle get labelLarge =>
      HasobjyDesignTokens.labelLarge.copyWith(color: textPrimary);
  TextStyle get title => HasobjyDesignTokens.title.copyWith(color: textPrimary);
  TextStyle get titleBold => title;
  TextStyle get labelSemiBold =>
      HasobjyDesignTokens.labelSemiBold.copyWith(color: textPrimary);
  TextStyle get labelLargeOnBrand =>
      HasobjyDesignTokens.labelLargeOnBrand.copyWith(color: textOnBrand);
  TextStyle get bodyMediumOnBrand =>
      HasobjyDesignTokens.bodyMediumOnBrand.copyWith(color: textOnBrand);
  TextStyle get bodySmallOnBrand =>
      HasobjyDesignTokens.bodySmallOnBrand.copyWith(color: textOnBrand);
  TextStyle get badge =>
      HasobjyDesignTokens.badge.copyWith(color: textSecondary);
  TextStyle get headingMedium =>
      HasobjyDesignTokens.headingMedium.copyWith(color: textPrimary);
  TextStyle get display =>
      HasobjyDesignTokens.display.copyWith(color: textPrimary);

  /// Resolve existing constructor defaults while keeping null as no border.
  Color resolve(Color color) {
    if (!isLight) return color;
    if (color == HasobjyDesignTokens.background) return background;
    if (color == HasobjyDesignTokens.surface) return surface;
    if (color == HasobjyDesignTokens.surfaceSubtle) return surfaceSubtle;
    if (color == HasobjyDesignTokens.selectedSurface) return selectedSurface;
    if (color == HasobjyDesignTokens.brand) return brand;
    if (color == HasobjyDesignTokens.textPrimary) return textPrimary;
    if (color == HasobjyDesignTokens.textSecondary) return textSecondary;
    if (color == HasobjyDesignTokens.textMuted) return textMuted;
    if (color == HasobjyDesignTokens.borderStrong) return borderStrong;
    if (color == HasobjyDesignTokens.warning) return warning;
    if (color == HasobjyDesignTokens.warningText) return warningText;
    if (color == HasobjyDesignTokens.success) return success;
    if (color == HasobjyDesignTokens.successText) return successText;
    return color;
  }
}
