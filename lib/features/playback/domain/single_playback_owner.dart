import '../../../core/errors/result.dart';
import '../../../core/media/media_failure.dart';
import 'playback_repository.dart';

/// One owner per app playback scope. No new resource before old close succeeds.
final class SinglePlaybackOwner {
  SinglePlaybackOwner(this._repository);
  final PlaybackRepository _repository;
  PlaybackSession? _active;
  Future<void> _tail = Future.value();
  bool _disposed = false;

  Future<Result<PlaybackSession, MediaFailure>> open(PlaybackRequest request) =>
      _serialize(() async {
        if (_disposed) return const Failure(MediaFailure.canceled);
        final closed = await _closeActive();
        if (closed case Failure(:final failure)) return Failure(failure);
        final opened = await _repository.open(request);
        if (opened case Success(:final value)) {
          _active = value;
          if (_disposed) {
            final cleanup = await _closeActive();
            return switch (cleanup) {
              Failure(:final failure) => Failure(failure),
              Success() => const Failure(MediaFailure.canceled),
            };
          }
        }
        return opened;
      });

  Future<Result<void, MediaFailure>> close() => _serialize(_closeActive);

  Future<Result<void, MediaFailure>> dispose() {
    _disposed = true;
    return _serialize(_closeActive);
  }

  Future<Result<void, MediaFailure>> _closeActive() async {
    final current = _active;
    if (current == null) return const Success(null);
    final closed = await current.close();
    if (closed is Success<void, MediaFailure>) _active = null;
    return closed;
  }

  Future<Result<T, MediaFailure>> _serialize<T>(
    Future<Result<T, MediaFailure>> Function() operation,
  ) {
    final result = _tail.then((_) async {
      try {
        return await operation();
      } catch (_) {
        return Failure<T, MediaFailure>(MediaFailure.unexpected);
      }
    });
    _tail = result.then((_) {});
    return result;
  }
}
