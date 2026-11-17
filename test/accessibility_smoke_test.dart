import 'package:cit_zone/features/admin/data/demo_admin_repository.dart';
import 'package:cit_zone/features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:cit_zone/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:cit_zone/features/auth/presentation/pages/welcome_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/hasobjy_test_app.dart';

void main() {
  testWidgets('شاشة الترحيب تحقق تسميات وأحجام لمس Android', (tester) async {
    await tester.pumpWidget(
      arabicTestApp(
        WelcomePage(
          googleConfigured: true,
          working: false,
          onGoogleSignIn: () {},
          onAdminPreview: () {},
        ),
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('لوحة الإدارة تحقق إرشادات تسميات وأحجام اللمس', (tester) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AdminDashboardCubit(DemoAdminRepository())..load(),
        child: arabicTestApp(const AdminDashboardPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
