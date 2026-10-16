import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/domain/google_identity_gateway.dart';

class FakeGoogleIdentityGateway implements GoogleIdentityGateway {
  FakeGoogleIdentityGateway({
    this.configured = true,
    this.restore,
    this.authenticateIdentity,
    this.logout,
  });

  final bool configured;
  final Future<GoogleIdentity?> Function()? restore;
  final Future<GoogleIdentity> Function()? authenticateIdentity;
  final Future<void> Function()? logout;
  int restoreCalls = 0;
  int signInCalls = 0;
  int signOutCalls = 0;

  static const identity = GoogleIdentity(
    displayName: 'طالب اختبار',
    email: 'student@example.com',
  );

  @override
  bool get isConfigured => configured;

  @override
  Future<GoogleIdentity?> restoreIdentity() async {
    restoreCalls++;
    return restore == null ? null : await restore!();
  }

  @override
  Future<GoogleIdentity> authenticate() async {
    signInCalls++;
    return authenticateIdentity == null
        ? identity
        : await authenticateIdentity!();
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await logout?.call();
  }
}
