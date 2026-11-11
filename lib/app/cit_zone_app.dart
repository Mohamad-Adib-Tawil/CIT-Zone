import 'package:cit_zone/core/localization/generated/app_localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/theme/app_theme.dart';
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
    this.initialLocation,
  });

  final AppDependencies dependencies;
  final String? initialLocation;

  @override
  State<CitZoneApp> createState() => _CitZoneAppState();
}

class _CitZoneAppState extends State<CitZoneApp> {
  late final GoogleIdentityCubit _identityCubit;
  late final AppRouter _router;
  AppAvailabilityCubit? _availabilityCubit;

  @override
  void initState() {
    super.initState();
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
    );
    unawaited(_identityCubit.restore());
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _identityCubit,
    child: MaterialApp.router(
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
      themeMode: ThemeMode.system,
    ),
  );

  @override
  void dispose() {
    _router.dispose();
    unawaited(_availabilityCubit?.close());
    unawaited(_identityCubit.close());
    super.dispose();
  }
}
