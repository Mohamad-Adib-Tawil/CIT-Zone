import '../domain/google_identity.dart';

/// Ephemeral data-layer input for the future API exchange; never UI state.
final class FirebaseIdentityProof {
  const FirebaseIdentityProof(this._idToken, {required this.identity});

  final String _idToken;
  String get idToken => _idToken;
  final GoogleIdentity identity;

  /// Proposed payload, awaiting BE-AUTH-FIREBASE contract confirmation.
  /// No endpoint or response/session format is assumed by this DTO.
  Map<String, Object?> toJson() => {
    'firebase_id_token': _idToken,
    'google_profile': {
      'id_google': identity.idGoogle,
      'firebase_uid': identity.firebaseUid,
      'email': identity.email,
      'email_verified': identity.emailVerified,
      'display_name': identity.displayName,
      'photo_url': identity.photoUrl?.toString(),
      if (identity.givenName != null) 'given_name': identity.givenName,
      if (identity.familyName != null) 'family_name': identity.familyName,
      if (identity.googleLocale != null) 'locale': identity.googleLocale,
    },
  };

  @override
  String toString() => 'FirebaseIdentityProof(redacted)';
}

abstract interface class FirebaseIdentityProofSource {
  /// Refuses stale callers after logout or account switching.
  Future<FirebaseIdentityProof> prepareForBackend({
    required String expectedFirebaseUid,
  });
}
