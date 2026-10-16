abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const googleIdentity = '/google-identity';
  static const studentPreview = '/debug/student';
  static const adminPreview = '/debug/admin';
  static const designFrame = '/debug/frames/:frame';

  static String frame(String name) =>
      '/debug/frames/${Uri.encodeComponent(name)}';
}
