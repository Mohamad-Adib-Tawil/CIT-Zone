class GoogleIdentity {
  const GoogleIdentity({
    required this.idGoogle,
    required this.firebaseUid,
    required this.emailVerified,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.givenName,
    this.familyName,
    this.googleLocale,
  });

  final String idGoogle;
  final String firebaseUid;
  final bool emailVerified;
  final String? displayName;
  final String email;
  final Uri? photoUrl;
  final String? givenName;
  final String? familyName;
  final String? googleLocale;
}
