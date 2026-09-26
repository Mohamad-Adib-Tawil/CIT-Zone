import 'dart:async';

class ApiCancellationToken {
  final Completer<void> _completer = Completer<void>();

  bool get isCanceled => _completer.isCompleted;
  Future<void> get whenCanceled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}
