import '../../../core/errors/either.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/network/api_request.dart';
import '../domain/legal_terms_repository.dart';

final class ApiLegalTermsRepository implements LegalTermsRepository {
  const ApiLegalTermsRepository(this._api);

  final ApiClient _api;

  @override
  Future<Either<LegalTermsFailure, LegalTerms?>> load() async {
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
          return Right((version: version, body: body, publishedAt: date));
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
