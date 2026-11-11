import 'dart:async';

import 'package:cit_zone/features/auth/data/firebase_google_identity_gateway.dart';
import 'package:cit_zone/features/auth/data/google_oauth_client.dart';
import 'package:cit_zone/features/auth/data/google_identity_repository_impl.dart';
import 'package:cit_zone/features/auth/domain/google_identity_gateway.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _UserInfo extends Mock implements UserInfo {}

UserInfo googleInfo(String uid) {
  final info = _UserInfo();
  when(() => info.providerId).thenReturn('google.com');
  when(() => info.uid).thenReturn(uid);
  return info;
}

class _Credential extends Mock implements UserCredential {}

class _AdditionalInfo extends Mock implements AdditionalUserInfo {}

class _Token extends Mock implements IdTokenResult {}

class _Google extends Mock implements GoogleOAuthClient {}

class _AuthCredential extends Fake implements AuthCredential {}

void main() {
  late _Auth auth;
  late _User user;
  late _Token token;
  late _Google google;
  late FirebaseGoogleIdentityGateway gateway;

  setUpAll(() => registerFallbackValue(_AuthCredential()));
  setUp(() {
    auth = _Auth();
    user = _User();
    token = _Token();
    google = _Google();
    when(() => google.isConfigured).thenReturn(true);
    when(() => google.authenticate()).thenAnswer(
      (_) async => const GoogleOAuthCredential(
        idToken: 'google-secret',
        idGoogle: 'google-123',
      ),
    );
    when(() => google.signOut()).thenAnswer((_) async {});
    when(() => auth.currentUser).thenReturn(user);
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => user.uid).thenReturn('firebase-456');
    final info = googleInfo('google-123');
    when(() => user.providerData).thenReturn([info]);
    when(() => user.email).thenReturn('student@example.test');
    when(() => user.emailVerified).thenReturn(true);
    when(() => user.displayName).thenReturn('Student');
    when(() => user.photoURL).thenReturn(null);
    when(() => user.reload()).thenAnswer((_) async {});
    when(() => token.token).thenReturn('firebase-secret');
    when(() => token.signInProvider).thenReturn('google.com');
    when(() => user.getIdTokenResult(any())).thenAnswer((_) async => token);
    final additional = _AdditionalInfo();
    when(() => additional.profile).thenReturn({
      'given_name': 'Given',
      'family_name': 'Family',
      'locale': 'ar',
      'unexpected_secret': 'never-copy',
    });
    final credential = _Credential();
    when(() => credential.additionalUserInfo).thenReturn(additional);
    when(() => credential.user).thenReturn(user);
    when(() => auth.signInWithCredential(any()))
        .thenAnswer((_) async => credential);
    gateway = FirebaseGoogleIdentityGateway(
      google: google,
      initializeAuth: () async => auth,
    );
  });

  test(
    'Google is exchanged through Firebase and IDs remain distinct',
    () async {
      final identity = await gateway.authenticate();
      expect(identity.idGoogle, 'google-123');
      expect(identity.firebaseUid, 'firebase-456');
      expect(identity.emailVerified, isTrue);
      expect(identity.givenName, 'Given');
      expect(identity.familyName, 'Family');
      expect(identity.googleLocale, 'ar');
      expect(identity.photoUrl, isNull);
      final captured =
          verify(() => auth.signInWithCredential(captureAny())).captured.single
              as OAuthCredential;
      expect(captured.providerId, 'google.com');
      expect(captured.idToken, 'google-secret');
      final proof = await gateway.prepareForBackend(
        expectedFirebaseUid: identity.firebaseUid,
      );
      expect(proof.toJson()['firebase_id_token'], 'firebase-secret');
      expect(
        (proof.toJson()['google_profile'] as Map)['id_google'],
        'google-123',
      );
      expect(proof.toString(), isNot(contains('secret')));
      expect(proof.toJson().toString(), isNot(contains('never-copy')));
      expect((proof.toJson()['google_profile'] as Map)['given_name'], 'Given');
      verify(() => user.getIdTokenResult(true)).called(1);
    },
  );

  test(
    'restore reloads Firebase without opening Google account chooser',
    () async {
      expect((await gateway.restoreIdentity())?.firebaseUid, 'firebase-456');
      verify(() => user.reload()).called(1);
      verifyNever(() => google.authenticate());
      verifyNever(() => auth.signInWithCredential(any()));
    },
  );

  test('restore without Firebase account returns empty', () async {
    when(() => auth.currentUser).thenReturn(null);
    expect(await gateway.restoreIdentity(), isNull);
  });

  test(
    'disabled/deleted account restore is a safe repository failure',
    () async {
      when(() => user.reload()).thenThrow(
        FirebaseAuthException(
          code: 'user-disabled',
          message: 'private SDK data',
        ),
      );
      final result = await GoogleIdentityRepositoryImpl(gateway)
          .restoreIdentity();
      expect(
        result.match((failure) => failure, (_) => null),
        GoogleIdentityFailure.unexpected,
      );
    },
  );

  for (final invalid in [
    'missing-token',
    'wrong-provider',
    'wrong-google-id',
    'missing-provider',
  ]) {
    test(
      '$invalid rejects partial login and signs both providers out',
      () async {
        switch (invalid) {
          case 'missing-token':
            when(() => token.token).thenReturn(null);
          case 'wrong-provider':
            when(() => token.signInProvider).thenReturn('password');
          case 'wrong-google-id':
            final other = googleInfo('other');
            when(() => user.providerData).thenReturn([other]);
          case 'missing-provider':
            when(() => user.providerData).thenReturn([]);
        }
        await expectLater(
          gateway.authenticate(),
          throwsA(isA<GoogleIdentityException>()),
        );
        verify(() => auth.signOut()).called(1);
        verify(() => google.signOut()).called(1);
      },
    );
  }

  test('Google cancellation does not start Firebase', () async {
    when(
      () => google.authenticate(),
    ).thenThrow(const GoogleIdentityException(GoogleIdentityFailure.canceled));
    var initialized = false;
    final canceled = FirebaseGoogleIdentityGateway(
      google: google,
      initializeAuth: () async {
        initialized = true;
        return auth;
      },
    );
    await expectLater(
      canceled.authenticate(),
      throwsA(isA<GoogleIdentityException>()),
    );
    expect(initialized, isFalse);
  });

  test('initialization failure can be retried', () async {
    var calls = 0;
    final retry = FirebaseGoogleIdentityGateway(
      google: google,
      initializeAuth: () async {
        if (++calls == 1) throw StateError('native initialization failed');
        return auth;
      },
    );
    await expectLater(retry.restoreIdentity(), throwsStateError);
    expect((await retry.restoreIdentity())?.firebaseUid, 'firebase-456');
    expect(calls, 2);
  });

  test('proof refuses wrong expected user before reading token', () async {
    await expectLater(
      gateway.prepareForBackend(expectedFirebaseUid: 'other'),
      throwsA(isA<GoogleIdentityException>()),
    );
    verifyNever(() => user.getIdTokenResult(any()));
  });

  test(
    'account switch/logout while token refresh is pending is rejected',
    () async {
      final pending = Completer<IdTokenResult>();
      when(() => user.getIdTokenResult(true)).thenAnswer((_) => pending.future);
      final request = gateway.prepareForBackend(
        expectedFirebaseUid: 'firebase-456',
      );
      await Future<void>.delayed(Duration.zero);
      when(() => auth.currentUser).thenReturn(null);
      pending.complete(token);
      await expectLater(request, throwsA(isA<GoogleIdentityException>()));
    },
  );

  test('sign-out attempts Google even if Firebase fails', () async {
    when(() => auth.signOut()).thenThrow(StateError('private'));
    await expectLater(
      gateway.signOut(),
      throwsA(isA<GoogleIdentityException>()),
    );
    verify(() => google.signOut()).called(1);
  });

  test('sign-out clears Firebase even if Google fails', () async {
    when(() => google.signOut()).thenThrow(StateError('private'));
    await expectLater(
      gateway.signOut(),
      throwsA(isA<GoogleIdentityException>()),
    );
    verify(() => auth.signOut()).called(1);
  });
}
