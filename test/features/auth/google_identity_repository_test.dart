import 'package:cit_zone/core/errors/result.dart';
import 'package:cit_zone/features/auth/data/google_identity_repository_impl.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/domain/google_identity_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_google_identity_gateway.dart';

void main() {
  test(
    'identity, missing identity and sign-out are distinct successful results',
    () async {
      final repository = GoogleIdentityRepositoryImpl(
        FakeGoogleIdentityGateway(),
      );
      final restore = await repository.restoreIdentity();
      expect(restore, isA<Success<GoogleIdentity?, GoogleIdentityFailure>>());
      expect(
        restore.fold(
          onSuccess: (value) => value,
          onFailure: (_) => throw StateError('unexpected failure'),
        ),
        isNull,
      );
      final login = await repository.signIn();
      expect(
        login.fold(
          onSuccess: (value) => value,
          onFailure: (_) => throw StateError('unexpected failure'),
        ),
        same(FakeGoogleIdentityGateway.identity),
      );
      expect(
        await repository.signOut(),
        isA<Success<void, GoogleIdentityFailure>>(),
      );
    },
  );

  for (final failure in GoogleIdentityFailure.values) {
    test(
      'typed failure $failure is preserved for all repository operations',
      () async {
        Never fail() => throw GoogleIdentityException(failure);
        final repository = GoogleIdentityRepositoryImpl(
          FakeGoogleIdentityGateway(
            restore: () async => fail(),
            authenticateIdentity: () async => fail(),
            logout: () async => fail(),
          ),
        );
        final results = [
          await repository.restoreIdentity(),
          await repository.signIn(),
          await repository.signOut(),
        ];
        for (final result in results) {
          expect(
            result.fold(onSuccess: (_) => null, onFailure: (error) => error),
            failure,
          );
        }
      },
    );
  }

  test(
    'raw SDK errors and sensitive messages cannot cross repository boundary',
    () async {
      Never fail() =>
          throw StateError('secret-token and private-provider-details');
      final repository = GoogleIdentityRepositoryImpl(
        FakeGoogleIdentityGateway(
          restore: () async => fail(),
          authenticateIdentity: () async => fail(),
          logout: () async => fail(),
        ),
      );
      for (final result in [
        await repository.restoreIdentity(),
        await repository.signIn(),
        await repository.signOut(),
      ]) {
        expect(
          result.fold(onSuccess: (_) => null, onFailure: (error) => error),
          GoogleIdentityFailure.unexpected,
        );
      }
    },
  );
}
