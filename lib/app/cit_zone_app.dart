import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/theme/app_theme.dart';
import '../features/admin/data/demo_admin_repository.dart';
import '../features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import '../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../features/auth/data/google_sign_in_gateway.dart';
import '../features/auth/domain/google_identity.dart';
import '../features/auth/presentation/cubit/google_identity_cubit.dart';
import '../features/auth/presentation/pages/google_identity_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/student/presentation/pages/student_preview_page.dart';

class CitZoneApp extends StatelessWidget {
  const CitZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CIT Zone',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: BlocProvider(
        create: (_) => GoogleIdentityCubit(GoogleSignInGateway())..restore(),
        child: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();

  void _openStudentPreview(BuildContext context, {GoogleIdentity? identity}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StudentPreviewPage(identity: identity),
      ),
    );
  }

  void _openAdminPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => AdminDashboardCubit(DemoAdminRepository())..load(),
          child: const AdminDashboardPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoogleIdentityCubit, GoogleIdentityState>(
      builder: (context, state) {
        final cubit = context.read<GoogleIdentityCubit>();
        if (state is GoogleIdentityReady) {
          return GoogleIdentityPage(
            identity: state.identity,
            error: state.error,
            onSignOut: cubit.signOut,
            onStudentPreview: kDebugMode
                ? () => _openStudentPreview(context, identity: state.identity)
                : null,
          );
        }
        return WelcomePage(
          googleConfigured: cubit.isConfigured,
          working: state is GoogleIdentityWorking,
          error: state is GoogleIdentityError ? state.message : null,
          onGoogleSignIn: cubit.signIn,
          onStudentPreview: kDebugMode
              ? () => _openStudentPreview(context)
              : null,
          onAdminPreview: kDebugMode ? () => _openAdminPreview(context) : null,
        );
      },
    );
  }
}
