class GoogleIdentity {
  const GoogleIdentity({
    required this.displayName,
    required this.email,
    this.photoUrl,
  });

  final String? displayName;
  final String email;
  final Uri? photoUrl;
}
