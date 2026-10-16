import 'package:cit_zone/core/localization/generated/app_localizations_ar.dart';

import 'dart:async';

import 'package:cit_zone/features/auth/data/google_identity_repository_impl.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/domain/google_identity_gateway.dart';
import 'package:cit_zone/features/auth/presentation/cubit/google_identity_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_google_identity_gateway.dart';

void main() {
  test(
    'one in-flight sign-in; failed sign-out retains identity and safe error',
    () async {
      final pending = Completer<GoogleIdentity>();
      final gateway = FakeGoogleIdentityGateway(
        authenticateIdentity: () => pending.future,
        logout: () async => throw StateError('private-sdk-message'),
      );
      final cubit = GoogleIdentityCubit(
        GoogleIdentityRepositoryImpl(gateway),
        messages: AppLocalizationsAr(),
      );
      addTearDown(cubit.close);
      final signIn = cubit.signIn();
      await cubit.signIn();
      expect(gateway.signInCalls, 1);
      pending.complete(FakeGoogleIdentityGateway.identity);
      await signIn;
      await cubit.signOut();
      final state = cubit.state as GoogleIdentityReady;
      expect(state.identity, same(FakeGoogleIdentityGateway.identity));
      expect(state.error, 'تعذر تسجيل الخروج من Google. حاول مجدداً.');
    },
  );

  for (final failure in [
    GoogleIdentityFailure.unavailable,
    GoogleIdentityFailure.missingToken,
    GoogleIdentityFailure.unexpected,
  ]) {
    test('$failure produces a safe presentation error', () async {
      final cubit = GoogleIdentityCubit(
        GoogleIdentityRepositoryImpl(
          FakeGoogleIdentityGateway(
            authenticateIdentity: () async =>
                throw GoogleIdentityException(failure),
          ),
        ),
        messages: AppLocalizationsAr(),
      );
      addTearDown(cubit.close);
      await cubit.signIn();
      expect(cubit.state, isA<GoogleIdentityError>());
      expect((cubit.state as GoogleIdentityError).message, isNotEmpty);
    });
  }
}
