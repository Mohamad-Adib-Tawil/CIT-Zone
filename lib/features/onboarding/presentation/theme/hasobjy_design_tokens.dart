import 'package:flutter/material.dart';

abstract final class HasobjyDesignTokens {
  static const background = Color(0xFF02112C);
  static const surface = Color(0xFF06224D);
  static const surfaceSubtle = Color(0xFF011755);
  static const selectedSurface = Color(0xFF1B3F73);
  static const brand = Color(0xFF67A8DC);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFD9F1FD);
  static const textMuted = Color(0xFF9FC4E6);
  static const border = Color(0xFF1B3F73);
  static const borderStrong = Color(0xFF3D5A78);
  static const warning = Color(0xFF8C5E10);
  static const success = Color(0xFF087C52);

  static const fontFamily = 'Cairo';

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 16 / 10,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );
  static const bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  static const bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );
  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  static const labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 32 / 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static const titleBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 32 / 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );
  static const labelSemiBold = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );
  static const labelLargeOnBrand = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
    color: background,
  );
  static const bodyMediumOnBrand = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    color: background,
  );
  static const bodySmallOnBrand = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    height: 16 / 10,
    fontWeight: FontWeight.w400,
    color: background,
  );
  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 34 / 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );
}
