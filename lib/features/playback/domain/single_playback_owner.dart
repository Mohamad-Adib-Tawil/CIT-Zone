import '../../../core/errors/either.dart';
import '../../../core/media/media_failure.dart';
import 'playback_repository.dart';

/// One owner per app playback scope. No new resource before old close succeeds.
final class SinglePlaybackOwner {
  SinglePlaybackOwner(this._repository);
  final PlaybackRepository _repository;
  PlaybackSession? _active;
  Future<void> _tail = Future.value();
  bool _disposed = false;

  Future<Either<MediaFailure, PlaybackSession>> open(PlaybackRequest request) =>
      _serialize(() async {
        if (_disposed) return const Left(MediaFailure.canceled);
        final closed = await _closeActive();
        if (closed case Left(value: final failure)) return Left(failure);
        final opened = await _repository.open(request);
        if (opened case Right(:final value)) {
          _active = value;
          if (_disposed) {
            final cleanup = await _closeActive();
            return switch (cleanup) {
              Left(value: final failure) => Left(failure),
              Right() => const Left(MediaFailure.canceled),
            };
          }
        }
        return opened;
      });

  Future<Either<MediaFailure, void>> close() => _serialize(_closeActive);

  Future<Either<MediaFailure, void>> dispose() {
    _disposed = true;
    return _serialize(_closeActive);
  }

  Future<Either<MediaFailure, void>> _closeActive() async {
    final current = _active;
    if (current == null) return const Right(null);
    final closed = await current.close();
    if (closed is Right<MediaFailure, void>) _active = null;
    return closed;
  }

  Future<Either<MediaFailure, T>> _serialize<T>(
    Future<Either<MediaFailure, T>> Function() operation,
  ) {
    final result = _tail.then((_) async {
      try {
        return await operation();
      } catch (_) {
        return Left<MediaFailure, T>(MediaFailure.unexpected);
      }
    });
    _tail = result.then((_) {});
    return result;
  }
}
