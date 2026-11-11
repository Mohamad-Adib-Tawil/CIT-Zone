import '../../features/admin/presentation/admin_figma_frame.dart';
import '../../features/onboarding/presentation/pages/hasobjy_design_page.dart';
import 'app_routes.dart';

/// Validates debug destinations against their own frame registry.
abstract final class PreviewRoutePolicy {
  static String initialLocation(String frameName) => switch (frameName) {
    'FIGMA_GALLERY' => AppRoutes.designGallery,
    'ADMIN_FIGMA_GALLERY' => AppRoutes.adminFigmaGallery,
    'STUDENT_PREVIEW' => AppRoutes.studentPreview,
    'ADMIN_PREVIEW' => AppRoutes.adminPreview,
    _ when HasobjyFrameId.fromFrameName(frameName) != null => AppRoutes.frame(
      frameName,
    ),
    _ => AppRoutes.signIn,
  };

  static bool acceptsFrame({required String? route, required String? frame}) =>
      switch (route) {
        AppRoutes.designFrame =>
          frame != null && HasobjyFrameId.fromFrameName(frame) != null,
        AppRoutes.adminFigmaFrame =>
          frame != null && AdminFigmaFrame.fromKey(frame) != null,
        _ => true,
      };
}
