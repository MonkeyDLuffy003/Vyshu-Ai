package com.vyshu.ai // TODO: change to match your actual applicationId in build.gradle

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.AlarmClock
import android.provider.ContactsContract
import android.provider.Settings
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * Handles "phone accessibility control" + app-launching/messaging/calling
 * features from the V1.0 plan.
 *
 * FIXES applied in this version:
 *  1. openQuickSettingsAndTapTile() had a race condition — it read
 *     rootInActiveWindow immediately after requesting the panel open,
 *     before the panel had actually rendered. Now waits briefly first.
 *     (A fully robust fix would listen for TYPE_WINDOW_STATE_CHANGED
 *     instead of a fixed delay — flagging this as a known simplification,
 *     the delay works reliably in practice but is not bulletproof on
 *     slower devices.)
 *  2. openWriteSettingsPermission() now actually exists (was referenced
 *     in a comment but never implemented).
 *  3. Added openHotspotPanel() — hotspot has no direct System Panel
 *     action like WiFi does, so this opens Wireless & Networks settings.
 *  4. Added launchAppByName(), sendWhatsAppMessage(), callContact(),
 *     setAlarm() — none of these existed before, which is why Vyshu could
 *     only open YouTube/Spotify and never anything else.
 */
class VyshuAccessibilityService : AccessibilityService() {

    companion object {
        var instance: VyshuAccessibilityService? = null
    }

    private val mainHandler = Handler(Looper.getMainLooper())

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

    /** FIX: was missing entirely — setBrightness() silently failed without this. */
    fun openWriteSettingsPermission() {
        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    // ---------- Toggles that need gesture automation ----------

    fun openWifiPanel() {
        val intent = Intent(Settings.Panel.ACTION_WIFI).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    /** FIX: hotspot has no ACTION_*_PANEL equivalent — route to wireless settings instead. */
    fun openHotspotPanel() {
        val intent = Intent(Settings.ACTION_WIRELESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    /**
     * FIX: previously read rootInActiveWindow immediately after requesting
     * Quick Settings to open, before it had rendered. Now waits ~400ms first.
     */
    fun openQuickSettingsAndTapTile(tileLabel: String, callback: (Boolean) -> Unit) {
        performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
        mainHandler.postDelayed({
            val root = rootInActiveWindow
            if (root == null) {
                callback(false)
                return@postDelayed
            }
            val target = findNodeByText(root, tileLabel)
            if (target != null) {
                target.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                callback(true)
            } else {
                callback(false)
            }
        }, 400)
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

    // ---------- NEW: generic app launcher ----------

    /**
     * Launches any installed app by matching its visible label
     * (case-insensitive, partial match — e.g. "insta" matches "Instagram").
     * Requires the <queries> block in AndroidManifest.xml, otherwise the
     * package manager will not show most apps on Android 11+.
     */
    fun launchAppByName(appName: String): Boolean {
        return try {
            val pm = packageManager
            val apps = pm.getInstalledApplications(android.content.pm.PackageManager.GET_META_DATA)
            val match = apps.firstOrNull { appInfo ->
                pm.getApplicationLabel(appInfo).toString().contains(appName, ignoreCase = true)
            } ?: return false
            val launchIntent = pm.getLaunchIntentForPackage(match.packageName) ?: return false
            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(launchIntent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // ---------- NEW: contact lookup ----------

    private fun lookupContactNumber(contactName: String): String? {
        val resolver = contentResolver
        val cursor: Cursor? = resolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            arrayOf(
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER
            ),
            "${ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME} LIKE ?",
            arrayOf("%$contactName%"),
            null
        )
        cursor?.use {
            if (it.moveToFirst()) {
                val numberIndex = it.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)
                if (numberIndex >= 0) return it.getString(numberIndex)
            }
        }
        return null
    }

    // ---------- NEW: WhatsApp messaging ----------

    /**
     * Opens a WhatsApp chat with the contact, pre-filled with `message`.
     * IMPORTANT: WhatsApp does not allow third-party apps to press Send on
     * the user's behalf — this is a WhatsApp/Android privacy restriction,
     * not a bug. Teja still has to tap Send himself once the chat opens.
     */
    fun sendWhatsAppMessage(contactName: String, message: String): Boolean {
        val number = lookupContactNumber(contactName) ?: return false
        val cleanNumber = number.replace(Regex("[^0-9+]"), "")
        return try {
            val uri = Uri.parse("https://wa.me/$cleanNumber?text=${Uri.encode(message)}")
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // ---------- NEW: outbound calling ----------

    /** Places a direct call — requires CALL_PHONE permission (already granted at this point). */
    fun callContact(contactName: String): Boolean {
        val number = lookupContactNumber(contactName) ?: return false
        return try {
            val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number")).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    // ---------- NEW: alarm setting ----------

    /**
     * Opens the clock app's "create alarm" screen pre-filled for hour:minute.
     * EXTRA_SKIP_UI requests a silent set, but many clock apps (especially
     * OEM ones like Samsung/Xiaomi) ignore that and show a confirm screen
     * anyway — that's the clock app's choice, not something Vyshu controls.
     */
    fun setAlarm(hour: Int, minute: Int, message: String): Boolean {
        return try {
            val intent = Intent(AlarmClock.ACTION_SET_ALARM).apply {
                putExtra(AlarmClock.EXTRA_HOUR, hour)
                putExtra(AlarmClock.EXTRA_MINUTES, minute)
                putExtra(AlarmClock.EXTRA_MESSAGE, message)
                putExtra(AlarmClock.EXTRA_SKIP_UI, true)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
