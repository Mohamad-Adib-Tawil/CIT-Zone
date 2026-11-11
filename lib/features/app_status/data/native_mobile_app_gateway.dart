import 'package:flutter/services.dart';

import '../domain/app_availability.dart';
import '../domain/app_availability_repository.dart';

final class NativeMobileAppGateway implements MobileAppGateway {
  const NativeMobileAppGateway();
  static const channel = MethodChannel('com.devmind.cit.learn/app');

  @override
  Future<MobileAppInfo> readInfo() async {
    final data = await channel.invokeMapMethod<String, dynamic>('appInfo');
    final version = data?['version'];
    final platform = switch (data?['platform']) {
      'android' => MobilePlatform.android,
      'ios' => MobilePlatform.ios,
      _ => throw const FormatException('Unsupported platform'),
    };
    if (version is! String) throw const FormatException('Missing app version');
    AppVersion.parse(version);
    return MobileAppInfo(platform: platform, version: version);
  }

  @override
  Future<bool> openStore(Uri url) async {
    if (!isAppStoreUrl(url)) return false;
    try {
      return await channel.invokeMethod<bool>('openStore', url.toString()) ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
