package com.devmind.cit.learn

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.content.pm.PackageManager

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.devmind.cit.learn/app")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "appInfo" -> {
                        try {
                            val info = if (Build.VERSION.SDK_INT >= 33) {
                                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
                            } else {
                                @Suppress("DEPRECATION")
                                packageManager.getPackageInfo(packageName, 0)
                            }
                            result.success(mapOf("platform" to "android", "version" to info.versionName))
                        } catch (_: Exception) {
                            result.error("APP_INFO_UNAVAILABLE", "Cannot read installed version", null)
                        }
                    }
                    "openStore" -> {
                        val uri = (call.arguments as? String)?.let { Uri.parse(it) }
                        if (uri == null || uri.scheme != "https" || uri.host != "play.google.com" ||
                            uri.userInfo != null || uri.fragment != null || (uri.port != -1 && uri.port != 443)) {
                            result.success(false)
                        } else {
                            try {
                                startActivity(Intent(Intent.ACTION_VIEW, uri).addCategory(Intent.CATEGORY_BROWSABLE))
                                result.success(true)
                            } catch (_: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
