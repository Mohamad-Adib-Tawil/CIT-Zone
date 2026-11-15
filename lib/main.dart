import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/debug/diagnostic_bloc_observer.dart';
import 'core/debug/safe_debug_log.dart';
import 'app/bootstrap/app_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    SafeDebugLog.error('Flutter', details.exception, details.stack, {
      'library': details.library,
    });
    previousFlutterErrorHandler?.call(
      FlutterErrorDetails(
        exception: ErrorSummary(
          'Unhandled Flutter error (${details.exception.runtimeType})',
        ),
        stack: details.stack,
        library: details.library,
        silent: details.silent,
      ),
    );
  };

  final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    SafeDebugLog.error('Platform', error, stackTrace);
    return previousPlatformErrorHandler?.call(error, stackTrace) ?? false;
  };
  Bloc.observer = DiagnosticBlocObserver();
  SafeDebugLog.event('App', 'started');
  runApp(const AppBootstrap());
}
