enum MobilePlatform { android, ios }

final class AppVersion implements Comparable<AppVersion> {
  AppVersion._(this.major, this.minor, this.patch);

  factory AppVersion.parse(String value) {
    final match = RegExp(
      r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:\+[0-9A-Za-z.-]+)?$',
    ).firstMatch(value);
    if (match == null || match.end != value.length) {
      throw const FormatException('Invalid app version');
    }
    return AppVersion._(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  final int major;
  final int minor;
  final int patch;

  @override
  int compareTo(AppVersion other) {
    for (final pair in [
      (major, other.major),
      (minor, other.minor),
      (patch, other.patch),
    ]) {
      final comparison = pair.$1.compareTo(pair.$2);
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}

final class MobileAppInfo {
  const MobileAppInfo({required this.platform, required this.version});
  final MobilePlatform platform;
  final String version;
}

enum AppAvailabilityKind { available, maintenance, updateRequired }

final class AppAvailability {
  const AppAvailability(this.kind, {this.message = '', this.storeUrl});
  final AppAvailabilityKind kind;
  final String message;
  final Uri? storeUrl;
}

enum AppAvailabilityFailure { network, unavailable, invalidResponse }

/// Only known HTTPS app stores may be opened from remotely supplied config.
bool isAppStoreUrl(Uri url) =>
    url.scheme == 'https' &&
    url.userInfo.isEmpty &&
    !url.hasFragment &&
    (!url.hasPort || url.port == 443) &&
    const {'play.google.com', 'apps.apple.com'}.contains(url.host);
