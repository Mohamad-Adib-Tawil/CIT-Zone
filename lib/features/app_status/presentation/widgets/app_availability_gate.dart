import 'package:cit_zone/core/localization/generated/app_localizations.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/app_availability.dart';
import '../cubit/app_availability_cubit.dart';
import '../pages/app_status_page.dart';

class AppAvailabilityGate extends StatefulWidget {
  const AppAvailabilityGate({
    super.key,
    required this.cubit,
    required this.child,
    this.onFirstAvailable,
    this.onAvailableAfterResume,
  });
  final AppAvailabilityCubit cubit;
  final Widget child;
  final Future<void> Function()? onFirstAvailable;
  final Future<void> Function()? onAvailableAfterResume;

  @override
  State<AppAvailabilityGate> createState() => _AppAvailabilityGateState();
}

class _AppAvailabilityGateState extends State<AppAvailabilityGate>
    with WidgetsBindingObserver {
  bool _storeOpenFailed = false;
  bool _openingStore = false;
  bool _checking = false;
  bool _wasAvailable = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_retry());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_retry(background: true));
    }
  }

  Future<void> _retry({bool background = false}) async {
    if (_checking) return;
    _checking = true;
    if (_storeOpenFailed) setState(() => _storeOpenFailed = false);
    try {
      await widget.cubit.check(background: background);
    } finally {
      _checking = false;
    }
    if (!mounted) return;
    if (widget.cubit.state case AppAvailabilityLoaded(
      availability: AppAvailability(kind: AppAvailabilityKind.available),
    )) {
      final callback = _wasAvailable
          ? widget.onAvailableAfterResume
          : widget.onFirstAvailable;
      _wasAvailable = true;
      await callback?.call();
    }
  }

  Future<void> _update() async {
    if (_openingStore) return;
    _openingStore = true;
    final state = widget.cubit.state;
    final opened = await widget.cubit.openStore().whenComplete(() {
      _openingStore = false;
    });
    if (!opened && mounted && identical(state, widget.cubit.state)) {
      setState(() => _storeOpenFailed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).appStatusStoreUnavailable),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AppAvailabilityCubit, AppAvailabilityState>(
        bloc: widget.cubit,
        builder: (context, state) =>
            state is AppAvailabilityLoaded &&
                state.availability.kind == AppAvailabilityKind.available
            ? widget.child
            : AppStatusPage(
                state: state,
                onRetry: () => _retry(),
                storeOpenFailed: _storeOpenFailed,
                onUpdate: _update,
              ),
      );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
