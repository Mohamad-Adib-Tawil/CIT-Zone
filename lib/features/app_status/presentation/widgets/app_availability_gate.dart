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
  });
  final AppAvailabilityCubit cubit;
  final Widget child;

  @override
  State<AppAvailabilityGate> createState() => _AppAvailabilityGateState();
}

class _AppAvailabilityGateState extends State<AppAvailabilityGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(widget.cubit.check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(widget.cubit.check());
  }

  Future<void> _update() async {
    final opened = await widget.cubit.openStore();
    if (!opened && mounted) {
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
                onRetry: widget.cubit.check,
                onUpdate: _update,
              ),
      );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
