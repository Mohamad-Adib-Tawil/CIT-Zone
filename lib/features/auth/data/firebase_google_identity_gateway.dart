import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/debug/safe_debug_log.dart';
import '../domain/google_identity.dart';
import '../domain/google_identity_gateway.dart';
import 'firebase_identity_proof.dart';
import 'google_oauth_client.dart';
import 'google_sign_in_gateway.dart';
import 'hasobjy_firebase_configuration.dart';

/// Firebase proves Google identity; only the API can issue Hasobjy access.
final class FirebaseGoogleIdentityGateway
    implements GoogleIdentityGateway, FirebaseIdentityProofSource {
  FirebaseGoogleIdentityGateway({
    GoogleOAuthClient? google,
    Future<FirebaseAuth> Function()? initializeAuth,
  }) : _google = google ?? GoogleSignInGateway(),
       _initializeAuth =
           initializeAuth ?? HasobjyFirebaseConfiguration.initializeAuth;

  final GoogleOAuthClient _google;
  final Future<FirebaseAuth> Function() _initializeAuth;
  Future<FirebaseAuth>? _initialization;
  GoogleIdentity? _lastIdentity;

  @override
  bool get isConfigured => _google.isConfigured;

  Future<FirebaseAuth> _auth() async {
    _initialization ??= _initializeAuth();
    try {
      return await _initialization!;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<GoogleIdentity> authenticate() async {
    SafeDebugLog.event('Google', 'sign-in started');
    if (!isConfigured) {
      throw const GoogleIdentityException(GoogleIdentityFailure.unavailable);
    }
    final credential = await _google.authenticate();
    try {
      if (credential.idToken.isEmpty || credential.idGoogle.isEmpty) {
        throw const GoogleIdentityException(GoogleIdentityFailure.missingToken);
      }
      final auth = await _auth();
      final result = await auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: credential.idToken),
      );
      final user = result.user;
      if (user == null) {
        throw const GoogleIdentityException(GoogleIdentityFailure.missingToken);
      }
      final proof = await _proofFor(
        auth,
        user,
        profile: result.additionalUserInfo?.profile,
      );
      if (proof.identity.idGoogle != credential.idGoogle) {
        throw const GoogleIdentityException(GoogleIdentityFailure.unexpected);
      }
      SafeDebugLog.event('Google/Firebase', 'sign-in succeeded', {
        'provider': 'google.com',
        'firebase_uid': proof.identity.firebaseUid,
        'email': proof.identity.email,
        'email_verified': proof.identity.emailVerified,
        'display_name': proof.identity.displayName,
      });
      _lastIdentity = proof.identity;
      return proof.identity;
    } catch (_) {
      SafeDebugLog.event('Google/Firebase', 'sign-in failed');
      // A partially completed exchange must not leave a restorable identity.
      try {
        await signOut();
      } catch (_) {
        // Preserve the original failure without exposing SDK details.
      }
      rethrow;
    }
  }

  @override
  Future<GoogleIdentity?> restoreIdentity() async {
    if (!isConfigured) return null;
    final auth = await _auth();
    final previous = auth.currentUser;
    if (previous == null) return null;
    // Reload rejects deleted/disabled accounts; never trust a cached profile.
    await previous.reload();
    final user = auth.currentUser;
    if (user == null || previous.uid != user.uid) return null;
    return (await _proofFor(auth, user)).identity;
  }

  @override
  Future<FirebaseIdentityProof> prepareForBackend({
    required String expectedFirebaseUid,
  }) async {
    final auth = await _auth();
    final user = auth.currentUser;
    if (user == null || user.uid != expectedFirebaseUid) {
      throw const GoogleIdentityException(GoogleIdentityFailure.missingToken);
    }
    return _proofFor(auth, user, forceRefresh: true);
  }

  Future<FirebaseIdentityProof> _proofFor(
    FirebaseAuth auth,
    User user, {
    bool forceRefresh = false,
    Map<String, dynamic>? profile,
  }) async {
    final provider = user.providerData
        .where((value) => value.providerId == GoogleAuthProvider.PROVIDER_ID)
        .singleOrNull;
    final googleUid = provider?.uid;
    if (provider == null ||
        googleUid == null ||
        googleUid.isEmpty ||
        user.uid.isEmpty) {
      throw const GoogleIdentityException(GoogleIdentityFailure.unavailable);
    }
    final token = await user.getIdTokenResult(forceRefresh);
    if (token.token?.isNotEmpty != true) {
      throw const GoogleIdentityException(GoogleIdentityFailure.missingToken);
    }
    if (token.signInProvider != GoogleAuthProvider.PROVIDER_ID ||
        auth.currentUser?.uid != user.uid) {
      throw const GoogleIdentityException(GoogleIdentityFailure.unavailable);
    }
    // Runtime validation here protects data consistency, not server authority.
    final email = user.email ?? provider.email;
    if (email == null || email.isEmpty) {
      throw const GoogleIdentityException(GoogleIdentityFailure.unavailable);
    }
    final previous = _lastIdentity;
    final sameUser =
        previous?.firebaseUid == user.uid && previous?.idGoogle == googleUid;
    return FirebaseIdentityProof(
      token.token!,
      identity: GoogleIdentity(
        idGoogle: googleUid,
        firebaseUid: user.uid,
        emailVerified: user.emailVerified,
        displayName: user.displayName ?? provider.displayName,
        email: email,
        photoUrl: _photoUrl(user.photoURL ?? provider.photoURL),
        givenName:
            _optionalText(profile?['given_name'], 150) ??
            (sameUser ? previous?.givenName : null),
        familyName:
            _optionalText(profile?['family_name'], 150) ??
            (sameUser ? previous?.familyName : null),
        googleLocale:
            _optionalText(profile?['locale'], 35) ??
            (sameUser ? previous?.googleLocale : null),
      ),
    );
  }

  String? _optionalText(Object? value, int maxLength) =>
      value is String && value.isNotEmpty && value.length <= maxLength
      ? value
      : null;

  Uri? _photoUrl(String? value) =>
      value == null || value.isEmpty ? null : Uri.tryParse(value);

  @override
  Future<void> signOut() async {
    // Try both providers even when one fails; callers can safely retry.
    _lastIdentity = null;
    Object? failure;
    try {
      final auth = await _auth();
      await auth.signOut();
    } catch (error) {
      failure = error;
    }
    try {
      await _google.signOut();
    } catch (error) {
      failure ??= error;
    }
    if (failure != null) {
      throw const GoogleIdentityException(GoogleIdentityFailure.unexpected);
    }
  }
}
