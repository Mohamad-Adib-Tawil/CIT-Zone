import '../../../core/errors/either.dart';
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
  Future<Either<MediaFailure, PlaybackSession>> open(PlaybackRequest request);
}

/// Opaque native resources, never a plaintext file, key, URL or vendor type.
abstract interface class PlaybackSession {
  Future<Either<MediaFailure, void>> play();
  Future<Either<MediaFailure, void>> pause();
  Future<Either<MediaFailure, void>> seek(Duration position);
  Future<Either<MediaFailure, void>> close();
}
