import '../../../core/errors/result.dart';
import '../../../core/media/media_failure.dart';

enum DownloadFileState {
  absent,
  queued,
  downloading,
  paused,
  present,
  deleting,
  failed,
}

enum OfflineLicenseState { unknown, valid, expiring, expired, denied }

/// Presence is not a license or entitlement. License state comes from DRM.
final class ProtectedDownloadStatus {
  const ProtectedDownloadStatus({
    required this.file,
    required this.license,
    required this.receivedBytes,
    this.totalBytes,
  });
  final DownloadFileState file;
  final OfflineLicenseState license;
  final int receivedBytes;
  final int? totalBytes;
}

final class ProtectedVideoDownloadRequest {
  const ProtectedVideoDownloadRequest({
    required this.assetId,
    required this.representationId,
  });
  final String assetId;

  /// Opaque approved quality identifier; no default quality/limit before D09.
  final String representationId;
}

/// Provider-owned encrypted media and offline licenses, no plaintext export.
/// Implement only after D08/D09/D28 real-device streaming/offline/expiry proof.
abstract interface class ProtectedVideoDownloads {
  Future<Result<void, MediaFailure>> enqueue(
    ProtectedVideoDownloadRequest request,
  );
  Future<Result<void, MediaFailure>> pause(String assetId);
  Future<Result<void, MediaFailure>> resume(String assetId);
  Future<Result<void, MediaFailure>> delete(String assetId);
  Future<Result<void, MediaFailure>> renewLicense(String assetId);
  Future<Result<ProtectedDownloadStatus, MediaFailure>> status(String assetId);
}
