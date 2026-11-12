import 'package:flutter_bloc/flutter_bloc.dart';

import 'safe_debug_log.dart';

/// Records Cubit/Bloc activity without serializing state or event contents.
class DiagnosticBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    SafeDebugLog.event('State', 'changed', {
      'component': bloc.runtimeType.toString(),
      'from': change.currentState.runtimeType.toString(),
      'to': change.nextState.runtimeType.toString(),
    });
    super.onChange(bloc, change);
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    SafeDebugLog.event('State', 'transition', {
      'component': bloc.runtimeType.toString(),
      'event_type': transition.event.runtimeType.toString(),
      'from': transition.currentState.runtimeType.toString(),
      'to': transition.nextState.runtimeType.toString(),
    });
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    SafeDebugLog.error('State', error, stackTrace, {
      'component': bloc.runtimeType.toString(),
    });
    super.onError(bloc, error, stackTrace);
  }
}
