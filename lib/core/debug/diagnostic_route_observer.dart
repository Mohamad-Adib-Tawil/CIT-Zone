import 'package:flutter/widgets.dart';

import 'safe_debug_log.dart';

/// Logs route changes while discarding query strings and dynamic path values.
class DiagnosticRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _record('push', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _record('pop', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _record('replace', newRoute, oldRoute);
  }

  void _record(String action, Route<dynamic> route, Route<dynamic>? previous) {
    SafeDebugLog.event('Navigation', action, {
      'screen': _safeRouteName(route),
      if (previous != null) 'previous_screen': _safeRouteName(previous),
    });
  }

  String _safeRouteName(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return route.runtimeType.toString();
    final path = Uri.tryParse(name)?.path ?? name.split('?').first;
    return path
        .split('/')
        .map((segment) => _looksDynamic(segment) ? '[PARAM]' : segment)
        .join('/');
  }

  bool _looksDynamic(String segment) =>
      RegExp(r'^\d+$').hasMatch(segment) ||
      RegExp(r'^[0-9a-fA-F-]{24,}$').hasMatch(segment) ||
      segment.contains('@');
}
