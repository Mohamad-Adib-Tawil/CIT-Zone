import '../../../core/errors/either.dart';
import '../../../core/media/media_failure.dart';

sealed class PdfReference {
  const PdfReference({required this.documentId, required this.versionId});
  final String documentId;
  final String versionId;
}

/// Free after server-verified sign-in/publication, independently of video rights.
final class AcademicPdf extends PdfReference {
  const AcademicPdf({required super.documentId, required super.versionId});
}

sealed class CoursePdf extends PdfReference {
  const CoursePdf({required super.documentId, required super.versionId});
}

final class ViewOnlyCoursePdf extends CoursePdf {
  const ViewOnlyCoursePdf({
    required super.documentId,
    required super.versionId,
  });
}

final class EncryptedCoursePdf extends CoursePdf {
  const EncryptedCoursePdf({
    required super.documentId,
    required super.versionId,
  });
}

/// A future viewer must render only visible pages plus bounded neighbors and
/// release its buffers on close/memory pressure. PDF protection is not video DRM.
abstract interface class DocumentSession {
  int get pageCount;
  Future<Either<MediaFailure, void>> close();
}

abstract interface class DocumentRepository {
  Future<Either<MediaFailure, DocumentSession>> open(PdfReference document);

  /// Only academic PDFs may enter an exportable download path.
  Future<Either<MediaFailure, void>> downloadAcademic(AcademicPdf document);

  /// Private encrypted storage only, after a separate protection/expiry proof.
  Future<Either<MediaFailure, void>> cacheProtectedCourse(
    EncryptedCoursePdf document,
  );
}
