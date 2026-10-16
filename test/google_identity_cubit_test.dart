import 'package:cit_zone/core/localization/generated/app_localizations_ar.dart';
import 'package:cit_zone/features/auth/data/google_identity_repository_impl.dart';
import 'package:cit_zone/app/bootstrap/app_bootstrap.dart';
import 'package:cit_zone/features/auth/domain/google_identity.dart';
import 'package:cit_zone/features/auth/domain/google_identity_gateway.dart';
import 'package:cit_zone/features/auth/presentation/cubit/google_identity_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:cit_zone/features/onboarding/presentation/widgets/hasobjy_figma_components.dart';

void main() {
  testWidgets('زر Google معطل دون إعداد OAuth', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await tester.pumpWidget(const AppBootstrap());
      await tester.pumpAndSettle();
      final button = tester.widget<HasobjyButton>(
        find.widgetWithText(HasobjyButton, 'المتابعة عبر Google'),
      );
      expect(button.onPressed, isNull);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('هوية Google لا تتحول إلى دور أو جلسة تطبيق', () async {
    final gateway = _FakeGoogleGateway();
    final cubit = GoogleIdentityCubit(
      GoogleIdentityRepositoryImpl(gateway),
      messages: AppLocalizationsAr(),
    );
    await cubit.signIn();
    final state = cubit.state;
    expect(state, isA<GoogleIdentityReady>());
    expect(
      (state as GoogleIdentityReady).identity.email,
      'student@example.com',
    );
    await cubit.signOut();
    expect(cubit.state, isA<GoogleIdentityIdle>());
    expect(gateway.signedOut, isTrue);
    await cubit.close();
  });

  test('استعادة حساب Google تظهر الهوية دون جلسة تطبيق', () async {
    final cubit = GoogleIdentityCubit(
      GoogleIdentityRepositoryImpl(_FakeGoogleGateway(restoreAccount: true)),
      messages: AppLocalizationsAr(),
    );
    await cubit.restore();
    expect(cubit.state, isA<GoogleIdentityReady>());
    expect(
      (cubit.state as GoogleIdentityReady).identity.email,
      'student@example.com',
    );
    await cubit.close();
  });

  test('غياب حساب Google سابق يعيد شاشة البداية', () async {
    final cubit = GoogleIdentityCubit(
      GoogleIdentityRepositoryImpl(_FakeGoogleGateway()),
      messages: AppLocalizationsAr(),
    );
    await cubit.restore();
    expect(cubit.state, isA<GoogleIdentityIdle>());
    await cubit.close();
  });

  test('فشل الاستعادة لا يمنع محاولة الدخول اليدوي', () async {
    final cubit = GoogleIdentityCubit(
      GoogleIdentityRepositoryImpl(_FakeGoogleGateway(failRestore: true)),
      messages: AppLocalizationsAr(),
    );
    await cubit.restore();
    expect(cubit.state, isA<GoogleIdentityIdle>());
    await cubit.signIn();
    expect(cubit.state, isA<GoogleIdentityReady>());
    await cubit.close();
  });

  test('إلغاء Google يعيد الشاشة للبداية دون خطأ', () async {
    final cubit = GoogleIdentityCubit(
      GoogleIdentityRepositoryImpl(_FakeGoogleGateway(cancel: true)),
      messages: AppLocalizationsAr(),
    );
    await cubit.signIn();
    expect(cubit.state, isA<GoogleIdentityIdle>());
    await cubit.close();
  });
}

class _FakeGoogleGateway implements GoogleIdentityGateway {
  _FakeGoogleGateway({
    this.cancel = false,
    this.restoreAccount = false,
    this.failRestore = false,
  });

  final bool cancel;
  final bool restoreAccount;
  final bool failRestore;
  bool signedOut = false;

  @override
  bool get isConfigured => true;

  @override
  Future<GoogleIdentity?> restoreIdentity() async {
    if (failRestore) throw StateError('restore unavailable');
    return restoreAccount ? _identity : null;
  }

  @override
  Future<GoogleIdentity> authenticate() async {
    if (cancel) {
      throw const GoogleIdentityException(GoogleIdentityFailure.canceled);
    }
    return _identity;
  }

  @override
  Future<void> signOut() async => signedOut = true;

  static const _identity = GoogleIdentity(
    email: 'student@example.com',
    displayName: 'طالب',
  );
}
