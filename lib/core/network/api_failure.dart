enum ApiFailureKind {
  configuration,
  canceled,
  network,
  timeout,
  unauthenticated,
  forbidden,
  conflict,
  rateLimited,
  server,
  invalidResponse,
  unexpected,
}

class ApiFailure implements Exception {
  const ApiFailure(this.kind, {this.statusCode, this.code, this.requestId});

  final ApiFailureKind kind;
  final int? statusCode;
  final String? code;
  final String? requestId;
}
