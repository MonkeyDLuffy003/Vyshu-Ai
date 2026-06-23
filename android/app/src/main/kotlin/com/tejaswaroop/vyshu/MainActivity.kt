package com.tejaswaroop.vyshu

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.provider.Settings

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.vyshu.ai/accessibility")
            .setMethodCallHandler { call, result ->
                val service = VyshuAccessibilityService.instance
                when (call.method) {
                    "isServiceEnabled" -> result.success(service != null)
                    "openAccessibilitySettings" -> {
                        startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        result.success(null)
                    }
                    "openWriteSettingsPermission" -> {
                        startActivity(Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS,
                            Uri.parse("package:$packageName")))
                        result.success(null)
                    }
                    "setTorch" -> result.success(service?.setTorch(call.argument("on") ?: false) ?: false)
                    "setBrightness" -> result.success(service?.setBrightness(call.argument("value") ?: 128) ?: false)
                    "toggleQuickSettingsTile" -> result.success(
                        service?.openQuickSettingsAndTapTile(call.argument("tile") ?: "") ?: false
                    )
                    else -> result.notImplemented()
                }
            }
    }
}
