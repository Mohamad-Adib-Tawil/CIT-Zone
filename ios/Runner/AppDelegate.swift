import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HasobjyApp") else { return }
    let channel = FlutterMethodChannel(
      name: "com.devmind.cit.learn/app", binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "appInfo":
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
          result(FlutterError(code: "APP_INFO_UNAVAILABLE", message: "Cannot read installed version", details: nil))
          return
        }
        result(["platform": "ios", "version": version])
      case "openStore":
        guard let raw = call.arguments as? String,
              let url = URL(string: raw), url.scheme == "https", url.host == "apps.apple.com",
              url.user == nil, url.password == nil, url.fragment == nil,
              url.port == nil || url.port == 443 else {
          result(false)
          return
        }
        UIApplication.shared.open(url, options: [:]) { opened in result(opened) }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
