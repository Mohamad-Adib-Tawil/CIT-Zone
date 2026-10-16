import 'package:cit_zone/core/localization/generated/app_localizations.dart';
import 'package:cit_zone/core/localization/generated/app_localizations_ar.dart';
import 'package:cit_zone/features/auth/data/google_identity_repository_impl.dart';
import 'package:cit_zone/features/auth/domain/google_identity_failure.dart';
import 'package:cit_zone/features/auth/presentation/cubit/google_identity_cubit.dart';
import 'package:cit_zone/features/auth/presentation/google_identity_messages.dart';
import 'package:cit_zone/features/auth/presentation/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_google_identity_gateway.dart';
import '../../support/hasobjy_test_app.dart';

void main() {
  testWidgets('generated delegate keeps Arabic, RTL and existing line breaks', (
    tester,
  ) async {
    await tester.pumpWidget(
      arabicTestApp(
        WelcomePage(
          googleConfigured: true,
          working: false,
          onGoogleSignIn: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(WelcomePage));
    expect(AppLocalizations.supportedLocales, const [Locale('ar')]);
    expect(
      AppLocalizations.of(context).welcomeHeadline,
      'تعلم مواد المعهد\nفي مكان واحد',
    );
    expect(Directionality.of(context), TextDirection.rtl);
    expect(find.text('تعلم مواد المعهد\nفي مكان واحد'), findsOneWidget);
  });

  test(
    'failure mapper uses approved safe copy and cancellation stays silent',
    () {
      final strings = AppLocalizationsAr();
      expect(
        googleIdentityFailureMessage(
          GoogleIdentityFailure.unavailable,
          strings,
        ),
        strings.googleUnavailable,
      );
      expect(
        googleIdentityFailureMessage(
          GoogleIdentityFailure.missingToken,
          strings,
        ),
        strings.googleMissingToken,
      );
      expect(
        googleIdentityFailureMessage(GoogleIdentityFailure.unexpected, strings),
        strings.googleUnexpected,
      );
      expect(
        googleIdentityFailureMessage(GoogleIdentityFailure.canceled, strings),
        isEmpty,
      );
    },
  );

  test('Cubit receives its message catalog through its constructor', () async {
    final messages = _TestMessages();
    final cubit = GoogleIdentityCubit(
      GoogleIdentityRepositoryImpl(
        FakeGoogleIdentityGateway(
          logout: () async => throw StateError('secret-provider-detail'),
        ),
      ),
      messages: messages,
    );
    addTearDown(cubit.close);
    await cubit.signIn();
    await cubit.signOut();
    expect(
      (cubit.state as GoogleIdentityReady).error,
      messages.googleSignOutFailed,
    );
  });
}

class _TestMessages extends AppLocalizationsAr {
  @override
  String get googleSignOutFailed => 'injected-safe-message';
}
