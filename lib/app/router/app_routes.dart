abstract final class AppRoutes {
  static const signIn = '/sign-in';
  static const studentSession = '/student/session';
  static const studentUsage = '/student/usage-type';
  static const studentHome = '/student/home';
  static const studentNewTerm = '/student/new-term';
  static const studentRegistration = '/student/registration';
  static const studentBasicInfo = '/student/basic-info';
  static const googleIdentity = '/google-identity';
  static const adminPreview = '/debug/admin';
  static const designGallery = '/debug/figma';
  static const adminFigmaGallery = '/debug/figma/admin';
  static const designFrame = '/debug/frames/:frame';
  static const adminFigmaFrame = '/debug/admin-frames/:frame';

  static String frame(String name, {String? appearance}) {
    final path = '/debug/frames/${Uri.encodeComponent(name)}';
    return appearance == null
        ? path
        : '$path?appearance=${Uri.encodeQueryComponent(appearance)}';
  }

  static String adminFrame(String key, {required bool light}) =>
      '/debug/admin-frames/$key?theme=${light ? 'light' : 'dark'}';
}
