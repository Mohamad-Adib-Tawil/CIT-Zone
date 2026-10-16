import 'dart:async';
import 'dart:typed_data';

import 'api_cancellation_token.dart';
import 'api_failure.dart';

/// One deadline for connect, headers and body, with detachable cancel listeners.
class ApiRequestScope {
  ApiRequestScope({
    required Duration timeout,
    required this.requestId,
    ApiCancellationToken? cancellationToken,
  }) {
    _timer = Timer(timeout, () => stop(ApiFailureKind.timeout));
    _removeCancellation = cancellationToken?.addListener(
      () => stop(ApiFailureKind.canceled),
    );
  }

  final String requestId;
  final _interrupted = Completer<Never>();
  final _aborters = <void Function()>{};
  late final Timer _timer;
  void Function()? _removeCancellation;
  ApiFailureKind? _stopped;

  void throwIfStopped() {
    if (_stopped case final kind?) {
      throw ApiFailure(kind, requestId: requestId);
    }
  }

  void Function() onAbort(void Function() abort) {
    if (_stopped != null) {
      abort();
      return () {};
    }
    _aborters.add(abort);
    return () => _aborters.remove(abort);
  }

  void stop(ApiFailureKind kind) {
    if (_stopped != null) return;
    _stopped = kind;
    for (final abort in List.of(_aborters)) {
      abort();
    }
    _aborters.clear();
    _interrupted.completeError(ApiFailure(kind, requestId: requestId));
  }

  Future<T> run<T>(Future<T> Function() operation) async {
    // Attach interruption handling before starting a potentially synchronous I/O.
    final interrupted = _interrupted.future;
    try {
      return await Future.any<T>([interrupted, Future.sync(operation)]);
    } finally {
      _timer.cancel();
      _removeCancellation?.call();
      _aborters.clear();
    }
  }

  Future<Uint8List> readLimited(Stream<List<int>> stream, int limit) async {
    final iterator = StreamIterator(stream);
    final removeAbort = onAbort(() => unawaited(iterator.cancel()));
    final bytes = BytesBuilder(copy: false);
    try {
      while (await iterator.moveNext()) {
        throwIfStopped();
        final chunk = iterator.current;
        if (chunk.length > limit - bytes.length) {
          throw ApiFailure(
            ApiFailureKind.invalidResponse,
            requestId: requestId,
          );
        }
        bytes.add(chunk);
      }
      throwIfStopped();
      return bytes.takeBytes();
    } finally {
      removeAbort();
      await iterator.cancel();
    }
  }
}
