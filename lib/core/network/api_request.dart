import 'dart:typed_data';

class ApiRequest {
  const ApiRequest({
    required this.method,
    required this.path,
    this.query = const {},
    this.jsonBody,
    this.headers = const {},
    this.acceptImage = false,
  });

  final String method;
  final String path;
  final Map<String, String> query;
  final Object? jsonBody;
  final bool acceptImage;
  final Map<String, String> headers;
}

class ApiResponse {
  const ApiResponse({
    required this.statusCode,
    required this.json,
    required this.requestId,
    this.imageBytes,
    this.totalPages,
  });

  final Uint8List? imageBytes;
  final int? totalPages;
  final int statusCode;
  final Map<String, dynamic> json;
  final String requestId;
}
