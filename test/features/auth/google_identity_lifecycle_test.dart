import 'dart:async';

import 'package:cit_zone/core/localization/generated/app_localizations_ar.dart';
import 'package:cit_zone/features/auth/data/google_identity_repository_impl.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/presentation/cubit/google_identity_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_google_identity_gateway.dart';

void main() {
  test(
    'a disposed idle cubit cannot restore or start Google sign-in',
    () async {
      var calls = 0;
      final cubit = GoogleIdentityCubit(
        GoogleIdentityRepositoryImpl(
          FakeGoogleIdentityGateway(
            restore: () async {
              calls++;
              return null;
            },
            authenticateIdentity: () async {
              calls++;
              return FakeGoogleIdentityGateway.identity;
            },
          ),
        ),
        messages: AppLocalizationsAr(),
      );
      await cubit.close();
      await cubit.restore();
      await cubit.signIn();
      expect(calls, 0);
    },
  );

  test(
    'late Google completion cannot navigate or log out after disposal',
    () async {
      final pending = Completer<GoogleIdentity>();
      final gateway = FakeGoogleIdentityGateway(
        authenticateIdentity: () => pending.future,
      );
      final cubit = GoogleIdentityCubit(
        GoogleIdentityRepositoryImpl(gateway),
        messages: AppLocalizationsAr(),
      );
      final login = cubit.signIn();
      await cubit.signIn();
      expect(gateway.signInCalls, 1);
      await cubit.close();
      pending.complete(FakeGoogleIdentityGateway.identity);
      await login;
      await cubit.signOut();
      expect(cubit.state, isA<GoogleIdentityWorking>());
      expect(gateway.signOutCalls, 0);
    },
  );

  test('a disposed ready cubit does not issue native sign-out', () async {
    final gateway = FakeGoogleIdentityGateway();
    final cubit = GoogleIdentityCubit(
      GoogleIdentityRepositoryImpl(gateway),
      messages: AppLocalizationsAr(),
    );
    await cubit.signIn();
    await cubit.close();
    await cubit.signOut();
    expect(gateway.signOutCalls, 0);
    expect(cubit.state, isA<GoogleIdentityReady>());
  });
}
