import '../../../core/errors/either.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/api_request.dart';
import '../domain/legal_terms_repository.dart';

final class ApiLegalTermsRepository implements LegalTermsRepository {
  ApiLegalTermsRepository(this._api, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ApiClient _api;
  final DateTime Function() _now;
  ({LegalTerms document, DateTime expiresAt})? _published;
  Future<Either<LegalTermsFailure, LegalTerms?>>? _pending;

  @override
  LegalTerms? get cachedPublished {
    final cached = _published;
    return cached != null && _now().isBefore(cached.expiresAt)
        ? cached.document
        : null;
  }

  @override
  Future<Either<LegalTermsFailure, LegalTerms?>> load() {
    if (cachedPublished case final document?) {
      return Future.value(Right(document));
    }
    _published = null;
    return _pending ??= _fetch().whenComplete(() => _pending = null);
  }

  Future<Either<LegalTermsFailure, LegalTerms?>> _fetch() async {
    try {
      final response = await _api.send(
        const ApiRequest(method: 'GET', path: 'legal/terms'),
      );
      final data = response.json['data'];
      if (data case {'version': 0, 'body': '', 'publishedAt': null}) {
        return const Right(null);
      }
      if (data
          case {
            'version': int version,
            'body': String body,
            'publishedAt': String published,
          }
          when version > 0 && body.trim().isNotEmpty) {
        final date = DateTime.tryParse(published);
        if (date != null && date.isUtc) {
          final document = (version: version, body: body, publishedAt: date);
          _published = (
            document: document,
            expiresAt: _now().add(const Duration(minutes: 1)),
          );
          return Right(document);
        }
      }
      return const Left(LegalTermsFailure.invalidResponse);
    } on ApiFailure catch (failure) {
      return Left(
        failure.kind == ApiFailureKind.invalidResponse
            ? LegalTermsFailure.invalidResponse
            : LegalTermsFailure.unavailable,
      );
    }
  }
}
