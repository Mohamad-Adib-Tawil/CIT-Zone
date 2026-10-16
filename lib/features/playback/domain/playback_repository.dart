import '../../../core/errors/result.dart';
import '../../../core/media/media_failure.dart';

enum PlaybackMode { streaming, offline }

final class PlaybackRequest {
  const PlaybackRequest({required this.assetId, required this.mode});
  final String assetId;
  final PlaybackMode mode;
}

/// A future provider adapter must authorize on the server and enforce DRM.
/// Offline expiry must be enforced by the DRM trusted clock, not Dart time.
abstract interface class PlaybackRepository {
  Future<Result<PlaybackSession, MediaFailure>> open(PlaybackRequest request);
}

/// Opaque native resources, never a plaintext file, key, URL or vendor type.
abstract interface class PlaybackSession {
  Future<Result<void, MediaFailure>> play();
  Future<Result<void, MediaFailure>> pause();
  Future<Result<void, MediaFailure>> seek(Duration position);
  Future<Result<void, MediaFailure>> close();
}
