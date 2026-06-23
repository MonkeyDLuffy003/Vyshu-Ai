package com.tejaswaroop.vyshu

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

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

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}

    fun setTorch(on: Boolean): Boolean {
        return try {
            val cameraManager = getSystemService(Context.CAMERA_SERVICE) as CameraManager
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            } ?: return false
            cameraManager.setTorchMode(cameraId, on)
            true
        } catch (e: Exception) { false }
    }

    fun setBrightness(value: Int): Boolean {
        return try {
            if (!Settings.System.canWrite(this)) return false
            Settings.System.putInt(contentResolver, Settings.System.SCREEN_BRIGHTNESS, value.coerceIn(0, 255))
            true
        } catch (e: Exception) { false }
    }

    fun setVolume(streamType: Int, level: Int): Boolean {
        return try {
            val am = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            am.setStreamVolume(streamType, level, 0)
            true
        } catch (e: Exception) { false }
    }

    fun openQuickSettingsAndTapTile(tileLabel: String): Boolean {
        performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
        val root = rootInActiveWindow ?: return false
        val target = findNodeByText(root, tileLabel)
        return if (target != null) {
            target.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            true
        } else false
    }

    private fun findNodeByText(node: AccessibilityNodeInfo, text: String): AccessibilityNodeInfo? {
        if (node.text?.contains(text, ignoreCase = true) == true ||
            node.contentDescription?.contains(text, ignoreCase = true) == true) {
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
