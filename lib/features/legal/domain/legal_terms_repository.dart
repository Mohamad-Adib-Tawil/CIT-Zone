import '../../../core/errors/either.dart';

typedef LegalTerms = ({int version, String body, DateTime publishedAt});

enum LegalTermsFailure { unavailable, invalidResponse }

abstract interface class LegalTermsRepository {
  LegalTerms? get cachedPublished;
  Future<Either<LegalTermsFailure, LegalTerms?>> load();
}
