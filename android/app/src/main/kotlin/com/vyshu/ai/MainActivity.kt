package com.vyshu.ai

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.text.TextUtils
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity — Bridges Flutter's VyshuBrain & ActionLibrary to VyshuAccessibilityService
 * and VyshuAgentForegroundService over `com.vyshu.ai/accessibility`.
 * Tag: VYSHU_AGENT
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vyshu.ai/accessibility"
    private val TAG = "VYSHU_AGENT"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel

        // Bind callbacks from native Overlay STOP and Always-On Wake Word to Dart
        VyshuAccessibilityService.onEmergencyStopPressed = {
            runOnUiThread {
                channel.invokeMethod("onOverlayEmergencyStop", null)
            }
        }

        VyshuAgentForegroundService.onWakeWordGoalCaptured = { goal ->
            runOnUiThread {
                channel.invokeMethod("onWakeWordGoal", goal)
            }
        }

        channel.setMethodCallHandler { call, result ->
            Log.d(TAG, "[MainActivity] MethodChannel call=${call.method}")

            // 1. Methods that work BEFORE AccessibilityService is enabled
            when (call.method) {
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(intent)
                    result.success(true)
                    return@setMethodCallHandler
                }

                "isServiceEnabled" -> {
                    val enabled = isAccessibilityServiceConnected()
                    Log.d(TAG, "[MainActivity] isServiceEnabled -> $enabled")
                    result.success(enabled)
                    return@setMethodCallHandler
                }

                "setAlwaysOnService" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    val prefs = getSharedPreferences(
                        VyshuAgentForegroundService.PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                    prefs.edit().putBoolean(VyshuAgentForegroundService.KEY_ENABLED, enabled).apply()
                    val svcIntent = Intent(this, VyshuAgentForegroundService::class.java)
                    if (enabled) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(svcIntent)
                        } else {
                            startService(svcIntent)
                        }
                    } else {
                        stopService(svcIntent)
                    }
                    result.success(true)
                    return@setMethodCallHandler
                }

                "isAlwaysOnServiceRunning" -> {
                    result.success(VyshuAgentForegroundService.isRunning)
                    return@setMethodCallHandler
                }

                "requestBatteryExemption" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                            }
                            startActivity(intent)
                        }
                    }
                    result.success(true)
                    return@setMethodCallHandler
                }

                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    }
                    result.success(true)
                    return@setMethodCallHandler
                }
            }

            // 2. Methods that require VyshuAccessibilityService instance
            val service = VyshuAccessibilityService.instance
            if (service == null) {
                Log.w(TAG, "[MainActivity] AccessibilityService instance is null for ${call.method}")
                if (call.method == "dumpScreenCompact") {
                    result.success(mapOf("package" to "service_disabled", "nodes" to emptyList<Any>()))
                } else {
                    result.success(false)
                }
                return@setMethodCallHandler
            }

            when (call.method) {
                "dumpScreenCompact" -> {
                    result.success(service.dumpScreenCompact())
                }
                "tapNodeByText" -> {
                    val text = call.argument<String>("text") ?: ""
                    result.success(service.tapNodeByText(text))
                }
                "tapNodeById" -> {
                    val viewId = call.argument<String>("viewId") ?: ""
                    result.success(service.tapNodeById(viewId))
                }
                "tapCoordinates" -> {
                    val x = call.argument<Int>("x") ?: 500
                    val y = call.argument<Int>("y") ?: 500
                    result.success(service.tapCoordinates(x, y))
                }
                "typeText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val targetHint = call.argument<String>("targetHint") ?: ""
                    val submit = call.argument<Boolean>("submit") ?: false
                    result.success(service.typeText(text, targetHint, submit))
                }
                "scrollScreen" -> {
                    val direction = call.argument<String>("direction") ?: "down"
                    result.success(service.scrollScreen(direction))
                }
                "swipeCoordinates" -> {
                    val startX = call.argument<Int>("startX") ?: 500
                    val startY = call.argument<Int>("startY") ?: 1400
                    val endX = call.argument<Int>("endX") ?: 500
                    val endY = call.argument<Int>("endY") ?: 400
                    val durationMs = call.argument<Int>("durationMs") ?: 350
                    result.success(service.swipeCoordinates(startX, startY, endX, endY, durationMs))
                }
                "performGlobal" -> {
                    val action = call.argument<String>("action") ?: "back"
                    result.success(service.performGlobalNavigation(action))
                }
                "showOverlayHud" -> {
                    val goal = call.argument<String>("goal") ?: ""
                    val stepText = call.argument<String>("stepText") ?: ""
                    service.showOrUpdateOverlayHud(goal, stepText)
                    result.success(true)
                }
                "updateOverlayHud" -> {
                    val goal = call.argument<String>("goal") ?: ""
                    val stepText = call.argument<String>("stepText") ?: ""
                    service.showOrUpdateOverlayHud(goal, stepText)
                    result.success(true)
                }
                "hideOverlayHud" -> {
                    service.hideOverlayHud()
                    result.success(true)
                }
                "setTorch" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    result.success(service.setTorch(on))
                }
                "setBrightness" -> {
                    val value = call.argument<Int>("value") ?: 128
                    result.success(service.setBrightness(value))
                }
                "setVolume" -> {
                    val streamType = call.argument<Int>("streamType") ?: AudioManager.STREAM_MUSIC
                    val level = call.argument<Int>("level") ?: 7
                    result.success(service.setVolume(streamType, level))
                }
                "requestWriteSettingsPermission", "openWriteSettingsPermission" -> {
                    service.openWriteSettingsPermission()
                    result.success(true)
                }
                "openQuickSettingsAndTapTile", "toggleQuickSettingsTile" -> {
                    val tileLabel = call.argument<String>("tileLabel")
                        ?: call.argument<String>("tile")
                        ?: ""
                    service.openQuickSettingsAndTapTile(tileLabel) { success ->
                        result.success(success)
                    }
                }
                "openHotspotPanel" -> {
                    service.openHotspotPanel()
                    result.success(true)
                }
                "launchAppByName" -> {
                    val appName = call.argument<String>("appName") ?: ""
                    result.success(service.launchAppByName(appName))
                }
                "sendWhatsAppMessage" -> {
                    val contactName = call.argument<String>("contactName") ?: ""
                    val message = call.argument<String>("message") ?: ""
                    result.success(service.sendWhatsAppMessage(contactName, message))
                }
                "callContact" -> {
                    val contactName = call.argument<String>("contactName") ?: ""
                    result.success(service.callContact(contactName))
                }
                "setAlarm" -> {
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val message = call.argument<String>("message") ?: "Vyshu reminder"
                    result.success(service.setAlarm(hour, minute, message))
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Reliably checks both the live AccessibilityService singleton AND Android Settings.Secure
     * so "Tap to enable" updates immediately when returning to the app.
     */
    private fun isAccessibilityServiceConnected(): Boolean {
        if (VyshuAccessibilityService.instance != null) return true
        val expectedComponent = ComponentName(this, VyshuAccessibilityService::class.java)
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        while (splitter.hasNext()) {
            val componentNameString = splitter.next()
            val enabledComponent = ComponentName.unflattenFromString(componentNameString)
            if (enabledComponent != null && enabledComponent == expectedComponent) {
                return true
            }
        }
        return false
    }
}
