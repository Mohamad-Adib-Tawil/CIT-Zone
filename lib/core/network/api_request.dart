class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.path,
    this.query = const {},
    this.jsonBody,
  });

  final String method;
  final String path;
  final Map<String, String> query;
  final Object? jsonBody;
}

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.json,
    required this.requestId,
  });

  final int statusCode;
  final Map<String, dynamic> json;
  final String requestId;
}
