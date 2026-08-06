package com.vyshu.ai // TODO: change to match your actual applicationId in build.gradle

import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * NOTE: if you already have a MainActivity.kt with other setup in it
 * (plugins, other channels, etc.), merge the configureFlutterEngine()
 * body below into it rather than replacing the whole file — this is
 * only the accessibility-channel wiring.
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.vyshu.ai/accessibility"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val service = VyshuAccessibilityService.instance
            if (service == null) {
                // Accessibility service not enabled yet — every action needs it.
                result.success(false)
                return@setMethodCallHandler
            }

            when (call.method) {
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
                "requestWriteSettingsPermission" -> {
                    service.openWriteSettingsPermission()
                    result.success(true)
                }
                "openQuickSettingsAndTapTile" -> {
                    val tileLabel = call.argument<String>("tileLabel") ?: ""
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
}
