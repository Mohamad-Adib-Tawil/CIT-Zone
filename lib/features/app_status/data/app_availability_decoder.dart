import '../domain/app_availability.dart';

AppAvailability decodeAppAvailability(
  Map<String, dynamic> json,
  MobileAppInfo info,
) {
  final data = json['data'];
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Missing data');
  }
  final maintenance = data['maintenance'];
  if (maintenance is! Map<String, dynamic> ||
      maintenance['enabled'] is! bool ||
      maintenance['message'] is! String) {
    throw const FormatException('Invalid maintenance config');
  }
  // Validate the platform policy even while maintenance hides other content.
  final platforms = data['platforms'];
  final policy = platforms is Map<String, dynamic>
      ? platforms[info.platform.name]
      : null;
  if (policy is! Map<String, dynamic> || policy['minVersion'] is! String) {
    throw const FormatException('Missing platform policy');
  }
  final minimum = AppVersion.parse(policy['minVersion'] as String);
  final installed = AppVersion.parse(info.version);
  final rawUrl = policy['storeUrl'];
  if (rawUrl != null && rawUrl is! String) {
    throw const FormatException('Invalid store URL');
  }
  final url = rawUrl is String ? Uri.tryParse(rawUrl) : null;
  if (rawUrl != null && (url == null || !isAppStoreUrl(url))) {
    throw const FormatException('Invalid store URL');
  }
  if (maintenance['enabled'] == true) {
    return AppAvailability(
      AppAvailabilityKind.maintenance,
      message: maintenance['message'] as String,
    );
  }
  return AppAvailability(
    installed.compareTo(minimum) < 0
        ? AppAvailabilityKind.updateRequired
        : AppAvailabilityKind.available,
    storeUrl: url,
  );
}
