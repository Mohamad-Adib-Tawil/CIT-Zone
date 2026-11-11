/// Google credential stays in data and is exchanged for Firebase identity.
final class GoogleOAuthCredential {
  const GoogleOAuthCredential({required this.idToken, required this.idGoogle});

  final String idToken;
  final String idGoogle;

  @override
  String toString() => 'GoogleOAuthCredential(redacted)';
}

abstract interface class GoogleOAuthClient {
  bool get isConfigured;
  Future<GoogleOAuthCredential> authenticate();
  Future<void> signOut();
}
