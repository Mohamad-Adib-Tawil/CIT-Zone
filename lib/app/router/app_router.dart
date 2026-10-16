import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/domain/google_identity.dart';
import '../../features/auth/presentation/cubit/google_identity_cubit.dart';
import '../../features/auth/presentation/pages/google_identity_page.dart';
import '../../features/onboarding/presentation/pages/hasobjy_design_page.dart';
import '../../features/student/presentation/pages/student_preview_page.dart';
import '../di/app_dependencies.dart';
import 'app_routes.dart';

/// Owns route refresh subscription and router. Google readiness is NOT a session.
class AppRouter {
  AppRouter({
    required AppDependencies dependencies,
    required GoogleIdentityCubit identityCubit,
    String? initialLocation,
  }) : _dependencies = dependencies,
       _identityCubit = identityCubit {
    _subscription = identityCubit.stream.listen((_) => _refresh.notify());
    router = GoRouter(
      initialLocation: initialLocation ?? _initialLocation,
      refreshListenable: _refresh,
      redirect: (_, state) => _redirect(state),
      onException: (_, state, router) => router.go(_identityLocation),
      routes: [
        GoRoute(path: '/', redirect: (_, state) => _identityLocation),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, state) => _identityBuilder(
            (context, identityState) => HasobjyDesignPage(
              frameId: HasobjyFrameId.aS01,
              onGoogleSignIn: identityCubit.isConfigured
                  ? identityCubit.signIn
                  : null,
              working: identityState is GoogleIdentityWorking,
              error: identityState is GoogleIdentityError
                  ? identityState.message
                  : null,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.googleIdentity,
          builder: (_, state) => _identityBuilder((context, identityState) {
            final identity = _identityOf(identityState);
            // A redirect follows on the next refresh when sign-out completes.
            if (identity == null) return const SizedBox.shrink();
            return GoogleIdentityPage(
              identity: identity,
              error: identityState is GoogleIdentityReady
                  ? identityState.error
                  : null,
              onSignOut: identityCubit.signOut,
              onStudentPreview: _previewsEnabled
                  ? () => context.push(AppRoutes.studentPreview)
                  : null,
            );
          }),
        ),
        GoRoute(
          path: AppRoutes.studentPreview,
          builder: (_, state) => _identityBuilder(
            (_, identityState) => StudentPreviewPage(
              identity: _identityOf(identityState),
              createCatalogCubit: dependencies.createStudentPreviewCubit,
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.adminPreview,
          builder: (_, state) => BlocProvider<AdminDashboardCubit>(
            create: (_) => dependencies.createAdminPreviewCubit()..load(),
            child: const AdminDashboardPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.designFrame,
          builder: (_, state) => _identityBuilder(
            (context, identityState) => HasobjyDesignPage(
              frameId: HasobjyFrameId.fromFrameName(
                state.pathParameters['frame']!,
              )!,
              identity: _identityOf(identityState),
              onGoogleSignIn: identityCubit.isConfigured
                  ? identityCubit.signIn
                  : null,
              onSignOut: identityCubit.signOut,
              working: identityState is GoogleIdentityWorking,
              error: identityState is GoogleIdentityError
                  ? identityState.message
                  : null,
              onOpenFrame: (frame) =>
                  context.push(AppRoutes.frame(frame.frameName)),
            ),
          ),
        ),
      ],
    );
  }

  final AppDependencies _dependencies;
  final GoogleIdentityCubit _identityCubit;
  final _RouterRefresh _refresh = _RouterRefresh();
  late final StreamSubscription<GoogleIdentityState> _subscription;
  late final GoRouter router;

  bool get _previewsEnabled =>
      kDebugMode && _dependencies.configuration.previewsEnabled;

  static GoogleIdentity? _identityOf(GoogleIdentityState state) =>
      switch (state) {
        GoogleIdentityReady(:final identity) => identity,
        GoogleIdentityWorking(:final identity) => identity,
        _ => null,
      };

  String get _identityLocation => _identityOf(_identityCubit.state) == null
      ? AppRoutes.signIn
      : AppRoutes.googleIdentity;

  String get _initialLocation {
    if (!_previewsEnabled) return AppRoutes.signIn;
    final frameName = _dependencies.configuration.previewFrameName;
    return switch (frameName) {
      'STUDENT_PREVIEW' => AppRoutes.studentPreview,
      'ADMIN_PREVIEW' => AppRoutes.adminPreview,
      _ when HasobjyFrameId.fromFrameName(frameName) != null => AppRoutes.frame(
        frameName,
      ),
      _ => AppRoutes.signIn,
    };
  }

  String? _redirect(GoRouterState state) {
    final path = state.uri.path;
    if (path == AppRoutes.signIn || path == AppRoutes.googleIdentity) {
      return path == _identityLocation ? null : _identityLocation;
    }
    if (path.startsWith('/debug/')) {
      if (!_previewsEnabled) return _identityLocation;
      final frame = state.pathParameters['frame'];
      if (frame != null && HasobjyFrameId.fromFrameName(frame) == null) {
        return _identityLocation;
      }
    }
    return null;
  }

  Widget _identityBuilder(
    Widget Function(BuildContext, GoogleIdentityState) builder,
  ) => BlocBuilder<GoogleIdentityCubit, GoogleIdentityState>(builder: builder);

  void dispose() {
    unawaited(_subscription.cancel());
    router.dispose();
    _refresh.dispose();
  }
}

class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}
