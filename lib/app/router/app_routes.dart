abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const googleIdentity = '/google-identity';
  static const studentPreview = '/debug/student';
  static const adminPreview = '/debug/admin';
  static const designGallery = '/debug/figma';
  static const adminFigmaGallery = '/debug/figma/admin';
  static const designFrame = '/debug/frames/:frame';
  static const adminFigmaFrame = '/debug/admin-frames/:frame';

  static String frame(String name) =>
      '/debug/frames/${Uri.encodeComponent(name)}';

  static String adminFrame(String key, {required bool light}) =>
      '/debug/admin-frames/$key?theme=${light ? 'light' : 'dark'}';
}
