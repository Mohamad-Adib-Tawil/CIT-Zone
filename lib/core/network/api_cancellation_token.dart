import 'dart:async';

class ApiCancellationToken {
  final Completer<void> _completer = Completer<void>();
  final _listeners = <void Function()>{};

  bool get isCanceled => _completer.isCompleted;
  Future<void> get whenCanceled => _completer.future;

  /// Returns an unsubscribe function so completed requests do not retain I/O.
  void Function() addListener(void Function() listener) {
    if (isCanceled) {
      listener();
      return () {};
    }
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void cancel() {
    if (isCanceled) return;
    _completer.complete();
    final listeners = List.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }
}
