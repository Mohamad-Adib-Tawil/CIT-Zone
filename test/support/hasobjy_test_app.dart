import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cit_zone/core/localization/generated/app_localizations.dart';

import 'package:cit_zone/core/theme/app_theme.dart';

Future<void> loadCairoForTests() async {
  final loader = FontLoader('Cairo');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(rootBundle.load('assets/hasobjy/fonts/Cairo-$weight.ttf'));
  }
  await loader.load();
  await (FontLoader('RobotoMono')..addFont(
        rootBundle.load('assets/hasobjy/fonts/RobotoMono-Variable.ttf'),
      ))
      .load();
}

Widget arabicTestApp(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: const Locale('ar'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: AppTheme.light,
  home: child,
);
