import 'package:cit_zone/core/localization/generated/app_localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/debug/safe_debug_log.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import '../features/auth/presentation/cubit/google_identity_cubit.dart';
import '../features/app_status/presentation/cubit/app_availability_cubit.dart';
import '../features/app_status/presentation/widgets/app_availability_gate.dart';
import 'di/app_dependencies.dart';
import 'router/app_router.dart';
import 'app_environment.dart';

class CitZoneApp extends StatefulWidget {
  const CitZoneApp({
    super.key,
    required this.dependencies,
    this.themeModeController,
    this.initialLocation,
  });

  final AppDependencies dependencies;
  final ThemeModeController? themeModeController;
  final String? initialLocation;

  @override
  State<CitZoneApp> createState() => _CitZoneAppState();
}

class _CitZoneAppState extends State<CitZoneApp> with WidgetsBindingObserver {
  late final GoogleIdentityCubit _identityCubit;
  late final AppRouter _router;
  AppAvailabilityCubit? _availabilityCubit;
  late final ThemeModeController _themeModeController;
  bool _ownsThemeModeController = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _themeModeController =
        widget.themeModeController ?? _createDefaultThemeController();
    _ownsThemeModeController = widget.themeModeController == null;
    _identityCubit = widget.dependencies.createGoogleIdentityCubit();
    if (widget.dependencies.configuration.environment.hasApi ||
        widget.dependencies.configuration.environment.stage !=
            AppStage.development) {
      _availabilityCubit = widget.dependencies.createAppAvailabilityCubit();
    }
    _router = AppRouter(
      dependencies: widget.dependencies,
      identityCubit: _identityCubit,
      initialLocation: widget.initialLocation,
      themeModeController: _themeModeController,
    );
    unawaited(_identityCubit.restore());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SafeDebugLog.event('App', 'lifecycle', {'state': state.name});
    if (state == AppLifecycleState.resumed) {
      unawaited(_identityCubit.revalidateSession());
    }
  }

  ThemeModeController _createDefaultThemeController() =>
      ThemeModeController.inMemory();

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _identityCubit,
    child: ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeModeController,
      builder: (context, themeMode, _) => MaterialApp.router(
        routerConfig: _router.router,
        builder: (context, child) => _availabilityCubit == null
            ? child!
            : AppAvailabilityGate(cubit: _availabilityCubit!, child: child!),
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
      ),
    ),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    unawaited(_availabilityCubit?.close());
    unawaited(_identityCubit.close());
    if (_ownsThemeModeController) _themeModeController.dispose();
    super.dispose();
  }
}
