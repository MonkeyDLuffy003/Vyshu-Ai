package com.vyshu.ai // TODO: change to match your actual applicationId in build.gradle

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Handles "phone accessibility control" features from the V1.0 plan (section 1.10).
 *
 * IMPORTANT: Since Android 10, third-party apps cannot directly toggle WiFi,
 * Bluetooth, Hotspot, or Airplane Mode via their APIs anymore (they're
 * silent no-ops for non-system apps). The only working approaches are:
 *   (a) open the matching Settings panel and let the user tap it, or
 *   (b) use this AccessibilityService to open Quick Settings and tap the
 *       tile programmatically (gesture automation) — see
 *       openQuickSettingsAndTapTile() below.
 *
 * Torch, brightness, and volume DON'T need any of this — they use normal
 * APIs that still work for regular apps, see the direct methods below.
 */
class VyshuAccessibilityService : AccessibilityService() {

    companion object {
        var instance: VyshuAccessibilityService? = null
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        // Not needed for toggles. Only required if Vyshu later reads screen
        // content for other features.
    }

    override fun onInterrupt() {}

    // ---------- Toggles with normal, still-working APIs ----------

    fun setTorch(on: Boolean): Boolean {
        return try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            } ?: return false
            cameraManager.setTorchMode(cameraId, on)
            true
        } catch (e: Exception) {
            false
        }
    }

    fun setBrightness(value: Int): Boolean {
        // value 0-255. Requires WRITE_SETTINGS to already be granted
        // (special permission — see openWriteSettingsPermission()).
        return try {
            if (!Settings.System.canWrite(this)) return false
            Settings.System.putInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                value.coerceIn(0, 255)
            )
            true
        } catch (e: Exception) {
            false
        }
    }

    fun setVolume(streamType: Int, level: Int): Boolean {
        return try {
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.setStreamVolume(streamType, level, 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    // ---------- Toggles that need gesture automation ----------

    /** Opens the system WiFi quick-settings panel for the user to tap themselves. */
    fun openWifiPanel() {
        val intent = Intent(Settings.Panel.ACTION_WIFI).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    /**
     * Opens Quick Settings and searches visible nodes for a tile whose label
     * matches tileLabel (e.g. "Wi-Fi", "Bluetooth", "Hotspot", "Airplane mode"),
     * then taps it.
     *
     * Caveat: tile labels/layout vary by OEM and device language (Samsung's
     * One UI vs stock Pixel vs MIUI all differ), so this is inherently a bit
     * brittle. Test on every device family you plan to support.
     */
    fun openQuickSettingsAndTapTile(tileLabel: String): Boolean {
        performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
        val root = rootInActiveWindow ?: return false
        val target = findNodeByText(root, tileLabel)
        return if (target != null) {
            target.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            true
        } else {
            false
        }
    }

    private fun findNodeByText(node: AccessibilityNodeInfo, text: String): AccessibilityNodeInfo? {
        if (node.text?.contains(text, ignoreCase = true) == true ||
            node.contentDescription?.contains(text, ignoreCase = true) == true
        ) {
            return node
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val result = findNodeByText(child, text)
            if (result != null) return result
        }
        return null
    }
}
