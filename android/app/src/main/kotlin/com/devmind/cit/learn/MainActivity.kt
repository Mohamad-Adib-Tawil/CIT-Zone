package com.devmind.cit.learn

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.content.pm.PackageManager
import android.provider.Settings
import android.util.Base64
import java.security.MessageDigest

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
                    "readDeviceBindingId" -> {
                        val androidId = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                        if (androidId.isNullOrBlank() || androidId == "9774d56d682e549c" ||
                            androidId.all { it == '0' }) {
                            result.error("DEVICE_ID_UNAVAILABLE", "Cannot read Android ID", null)
                        } else {
                            val input = "hasobjy:android:v1:$packageName:$androidId"
                            val hash = MessageDigest.getInstance("SHA-256").digest(input.toByteArray(Charsets.UTF_8))
                            val flags = Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP
                            result.success("android_v1_${Base64.encodeToString(hash, flags)}")
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
