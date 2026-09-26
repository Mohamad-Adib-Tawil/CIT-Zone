import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' hide GoogleIdentity;

import '../domain/google_identity.dart';
import '../domain/google_identity_gateway.dart';

class GoogleSignInConfiguration {
  const GoogleSignInConfiguration({
    this.serverClientId = const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '637124336690-ckb8c62mu855i8219nfjv5l4pnu9ob4i.apps.googleusercontent.com',
    ),
    this.iosClientId = const String.fromEnvironment(
      'GOOGLE_IOS_CLIENT_ID',
      defaultValue: '637124336690-q31nv9rdo829dilk6n9d785kvafplhtp.apps.googleusercontent.com',
    ),
  });

  final String serverClientId;
  final String iosClientId;

  bool get isConfigured {
    if (kIsWeb || serverClientId.isEmpty) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => iosClientId.isNotEmpty,
      _ => false,
    };
  }

  String? get clientId =>
      defaultTargetPlatform == TargetPlatform.iOS ? iosClientId : null;
}

class GoogleSignInGateway implements GoogleIdentityGateway {
  GoogleSignInGateway({GoogleSignInConfiguration? configuration})
    : _configuration = configuration ?? const GoogleSignInConfiguration();

  final GoogleSignInConfiguration _configuration;
  Future<void>? _initialization;

  @override
  bool get isConfigured => _configuration.isConfigured;

  Future<void> _initialize() async {
    _initialization ??= GoogleSignIn.instance.initialize(
      clientId: _configuration.clientId,
      serverClientId: _configuration.serverClientId,
    );
    try {
      await _initialization;
    } catch (_) {
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<GoogleIdentity?> restoreIdentity() async {
    if (!isConfigured) return null;
    try {
      await _initialize();
      final attempt = GoogleSignIn.instance.attemptLightweightAuthentication();
      final account = await attempt;
      if (account == null) return null;
      if (account.authentication.idToken?.isNotEmpty != true) return null;
      return _identityFor(account);
    } catch (_) {
      // Restoring a Google account is optional. The user can sign in manually.
      return null;
    }
  }

  GoogleIdentity _identityFor(GoogleSignInAccount account) => GoogleIdentity(
    displayName: account.displayName,
    email: account.email,
    photoUrl: account.photoUrl == null ? null : Uri.tryParse(account.photoUrl!),
  );

  @override
  Future<GoogleIdentity> authenticate() async {
    if (!isConfigured) {
      throw const GoogleIdentityException(GoogleIdentityFailure.unavailable);
    }

    try {
      await _initialize();
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        throw const GoogleIdentityException(GoogleIdentityFailure.unavailable);
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        await GoogleSignIn.instance.signOut();
        throw const GoogleIdentityException(GoogleIdentityFailure.missingToken);
      }
      return _identityFor(account);
    } on GoogleIdentityException {
      rethrow;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleIdentityException(GoogleIdentityFailure.canceled);
      }
      if (error.code == GoogleSignInExceptionCode.clientConfigurationError ||
          error.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw const GoogleIdentityException(GoogleIdentityFailure.unavailable);
      }
      throw const GoogleIdentityException(GoogleIdentityFailure.unexpected);
    } catch (_) {
      throw const GoogleIdentityException(GoogleIdentityFailure.unexpected);
    }
  }

  @override
  Future<void> signOut() async {
    if (_initialization == null) return;
    await _initialize();
    await GoogleSignIn.instance.signOut();
  }
}
