import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/debug/diagnostic_route_observer.dart';
import '../../features/admin/presentation/cubit/admin_dashboard_cubit.dart';
import '../../features/admin/presentation/admin_figma_frame.dart';
import '../../features/admin/presentation/admin_figma_preview_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/domain/google_identity.dart';
import '../../features/auth/presentation/cubit/google_identity_cubit.dart';
import '../../features/auth/presentation/pages/google_identity_page.dart';
import '../../features/onboarding/presentation/pages/hasobjy_design_page.dart';
import '../../features/onboarding/presentation/pages/hasobjy_frame_gallery_page.dart';
import '../di/app_dependencies.dart';
import 'app_routes.dart';
import 'preview_route_policy.dart';

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
      observers: [DiagnosticRouteObserver()],
      redirect: (_, state) => _redirect(state),
      onException: (_, state, router) => router.go(_identityLocation),
      routes: [
        GoRoute(path: '/', redirect: (_, state) => _identityLocation),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, state) => _identityBuilder(
            (context, identityState) => HasobjyDesignPage(
              frameId: HasobjyFrameId.aS01,
              followSystemTheme: true,
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
              onFigmaPreview: _previewsEnabled
                  ? () => context.push(AppRoutes.designGallery)
                  : null,
            );
          }),
        ),
        GoRoute(
          path: AppRoutes.adminPreview,
          builder: (_, state) => BlocProvider<AdminDashboardCubit>(
            create: (_) => dependencies.createAdminPreviewCubit()..load(),
            child: const AdminDashboardPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.designGallery,
          builder: (context, state) => HasobjyFrameGalleryPage(
            onOpenFrame: (frame) =>
                context.push(AppRoutes.frame(frame.frameName)),
            onOpenAdminGallery: () => context.push(AppRoutes.adminFigmaGallery),
          ),
        ),
        GoRoute(
          path: AppRoutes.adminFigmaGallery,
          builder: (context, state) => AdminFigmaGalleryPage(
            onOpenFrame: (frame, light) =>
                context.push(AppRoutes.adminFrame(frame.key, light: light)),
          ),
        ),
        GoRoute(
          path: AppRoutes.adminFigmaFrame,
          builder: (context, state) {
            final frame = AdminFigmaFrame.fromKey(
              state.pathParameters['frame']!,
            );
            if (frame == null) return const SizedBox.shrink();
            final light = state.uri.queryParameters['theme'] == 'light';
            return AdminFigmaPreviewPage(
              frame: frame,
              light: light,
              onOpenFrame: (target, targetLight) => context.push(
                AppRoutes.adminFrame(target.key, light: targetLight),
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.designFrame,
          builder: (_, state) => _identityBuilder(
            (context, identityState) => HasobjyDesignPage(
              frameId: HasobjyFrameId.fromFrameName(
                state.pathParameters['frame']!,
              )!,
              selectedAppearance: state.uri.queryParameters['appearance'],
              followSystemTheme:
                  state.uri.queryParameters['appearance'] == 'تلقائي',
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
              onOpenAppearance: (frame, appearance) => context.push(
                AppRoutes.frame(frame.frameName, appearance: appearance),
              ),
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
  bool _disposed = false;

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
    return PreviewRoutePolicy.initialLocation(
      _dependencies.configuration.previewFrameName,
    );
  }

  String? _redirect(GoRouterState state) {
    final path = state.uri.path;
    if (path == AppRoutes.signIn || path == AppRoutes.googleIdentity) {
      return path == _identityLocation ? null : _identityLocation;
    }
    if (path.startsWith('/debug/')) {
      if (!_previewsEnabled) return _identityLocation;
      if (!PreviewRoutePolicy.acceptsFrame(
        route: state.fullPath,
        frame: state.pathParameters['frame'],
      )) {
        return _identityLocation;
      }
    }
    return null;
  }

  Widget _identityBuilder(
    Widget Function(BuildContext, GoogleIdentityState) builder,
  ) => BlocBuilder<GoogleIdentityCubit, GoogleIdentityState>(builder: builder);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription.cancel());
    router.dispose();
    _refresh.dispose();
  }
}

class _RouterRefresh extends ChangeNotifier {
  void notify() => notifyListeners();
}
