package com.vyshu.ai

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.GradientDrawable
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.AlarmClock
import android.provider.ContactsContract
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

/**
 * VyshuAccessibilityService — Autonomous On-Device Observation, Gesture & Action Engine.
 * Tag: VYSHU_AGENT
 */
class VyshuAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "VYSHU_AGENT"
        var instance: VyshuAccessibilityService? = null
        var onEmergencyStopPressed: (() -> Unit)? = null

        private val BLOCKED_PACKAGES = setOf(
            "com.google.android.apps.nbu.paisa.user",
            "com.phonepe.app",
            "net.one97.paytm",
            "in.org.npci.upiapp",
            "com.sbi.lotusintouch",
            "com.snapwork.hdfc",
            "com.csam.icici.bank.imobile",
            "com.axis.mobile"
        )
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var overlayView: LinearLayout? = null
    private var overlayTitleView: TextView? = null
    private var overlayStepView: TextView? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.i(TAG, "[AccessibilityService] Connected and ready.")
    }

    override fun onDestroy() {
        hideOverlayHud()
        instance = null
        Log.i(TAG, "[AccessibilityService] Destroyed.")
        super.onDestroy()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {}
    override fun onInterrupt() {}

    // ---------- 1. COMPACT SCREEN OBSERVATION (WITH PASSWORD & BANKING SCRUB) ----------

    fun dumpScreenCompact(): Map<String, Any> {
        val root = rootInActiveWindow
        if (root == null) {
            Log.w(TAG, "[Observe] rootInActiveWindow is null")
            return mapOf("package" to "unknown", "nodes" to emptyList<Map<String, Any>>())
        }

        val pkgName = root.packageName?.toString() ?: "unknown"
        if (BLOCKED_PACKAGES.any { pkgName.contains(it, ignoreCase = true) }) {
            Log.w(TAG, "[Observe] Blocked package detected: $pkgName")
            return mapOf(
                "package" to pkgName,
                "blocked" to true,
                "nodes" to emptyList<Map<String, Any>>()
            )
        }

        val nodes = mutableListOf<Map<String, Any>>()
        collectCompactNodes(root, nodes, maxNodes = 45)
        Log.d(TAG, "[Observe] Dumped package=$pkgName with ${nodes.size} interactive/text nodes")
        return mapOf(
            "package" to pkgName,
            "nodes" to nodes
        )
    }

    private fun collectCompactNodes(
        node: AccessibilityNodeInfo?,
        out: MutableList<Map<String, Any>>,
        maxNodes: Int
    ) {
        if (node == null || out.size >= maxNodes) return

        val isPassword = node.isPassword
        val text = if (isPassword) "[REDACTED_PASSWORD]" else (node.text?.toString()?.trim() ?: "")
        val desc = if (isPassword) "[REDACTED_PASSWORD]" else (node.contentDescription?.toString()?.trim() ?: "")
        val viewId = node.viewIdResourceName?.substringAfterLast("/") ?: ""
        val clickable = node.isClickable
        val editable = node.isEditable
        val scrollable = node.isScrollable

        if (text.isNotEmpty() || desc.isNotEmpty() || clickable || editable) {
            val rect = Rect()
            node.getBoundsInScreen(rect)
            if (rect.width() > 0 && rect.height() > 0) {
                out.add(
                    mapOf(
                        "id" to viewId,
                        "text" to text.take(80),
                        "desc" to desc.take(80),
                        "bounds" to "${rect.left},${rect.top},${rect.right},${rect.bottom}",
                        "cx" to rect.centerX(),
                        "cy" to rect.centerY(),
                        "clickable" to clickable,
                        "editable" to editable,
                        "scrollable" to scrollable,
                        "password" to isPassword
                    )
                )
            }
        }

        for (i in 0 until node.childCount) {
            if (out.size >= maxNodes) break
            collectCompactNodes(node.getChild(i), out, maxNodes)
        }
    }

    // ---------- 2. NODE & GESTURE EXECUTION ----------

    fun tapNodeByText(text: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val target = findNodeByText(root, text)
        if (target != null) {
            if (target.isClickable && target.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                Log.i(TAG, "[Act] Clicked node by text: $text")
                return true
            }
            var parent = target.parent
            while (parent != null) {
                if (parent.isClickable && parent.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                    Log.i(TAG, "[Act] Clicked clickable parent of text: $text")
                    return true
                }
                parent = parent.parent
            }
            val rect = Rect()
            target.getBoundsInScreen(rect)
            if (rect.width() > 0 && rect.height() > 0) {
                return tapCoordinates(rect.centerX(), rect.centerY())
            }
        }
        Log.w(TAG, "[Act] tapNodeByText could not find: $text")
        return false
    }

    fun tapNodeById(viewId: String): Boolean {
        val root = rootInActiveWindow ?: return false
        val target = findNodeByViewId(root, viewId)
        if (target != null) {
            if (target.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
                Log.i(TAG, "[Act] Clicked node by id: $viewId")
                return true
            }
            val rect = Rect()
            target.getBoundsInScreen(rect)
            return tapCoordinates(rect.centerX(), rect.centerY())
        }
        return false
    }

    fun tapCoordinates(x: Int, y: Int): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        return try {
            val path = Path().apply { moveTo(x.toFloat(), y.toFloat()) }
            val stroke = GestureDescription.StrokeDescription(path, 0, 80)
            val gesture = GestureDescription.Builder().addStroke(stroke).build()
            val dispatched = dispatchGesture(gesture, null, null)
            Log.i(TAG, "[Act] tapCoordinates($x, $y) -> $dispatched")
            dispatched
        } catch (e: Exception) {
            Log.e(TAG, "[Act] tapCoordinates error: ${e.message}")
            false
        }
    }

    fun typeText(text: String, targetHint: String = "", submit: Boolean = false): Boolean {
        val root = rootInActiveWindow ?: return false
        var target: AccessibilityNodeInfo? = null

        if (targetHint.isNotEmpty()) {
            target = findEditableByHint(root, targetHint)
        }
        if (target == null) {
            target = root.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
        }
        if (target == null) {
            target = findFirstEditableNode(root)
        }

        if (target == null || target.isPassword) {
            Log.w(TAG, "[Act] typeText found no safe editable node")
            return false
        }

        target.performAction(AccessibilityNodeInfo.ACTION_FOCUS)
        target.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        val args = Bundle().apply {
            putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        }
        val ok = target.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
        if (submit && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            target.performAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_IME_ENTER.id)
        }
        Log.i(TAG, "[Act] typeText('$text', submit=$submit) -> $ok")
        return ok
    }

    fun scrollScreen(direction: String): Boolean {
        val d = direction.lowercase()
        return when (d) {
            "up" -> swipeCoordinates(540, 500, 540, 1500, 350)
            "left" -> swipeCoordinates(900, 1000, 180, 1000, 350)
            "right" -> swipeCoordinates(180, 1000, 900, 1000, 350)
            else -> swipeCoordinates(540, 1500, 540, 450, 350) // "down" scrolls content down
        }
    }

    fun swipeCoordinates(
        startX: Int,
        startY: Int,
        endX: Int,
        endY: Int,
        durationMs: Int = 350
    ): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        return try {
            val path = Path().apply {
                moveTo(startX.toFloat(), startY.toFloat())
                lineTo(endX.toFloat(), endY.toFloat())
            }
            val dur = durationMs.coerceIn(100, 2000).toLong()
            val stroke = GestureDescription.StrokeDescription(path, 0, dur)
            val gesture = GestureDescription.Builder().addStroke(stroke).build()
            dispatchGesture(gesture, null, null)
        } catch (e: Exception) {
            Log.e(TAG, "[Act] swipeCoordinates error: ${e.message}")
            false
        }
    }

    fun performGlobalNavigation(actionName: String): Boolean {
        return when (actionName.lowercase()) {
            "back" -> performGlobalAction(GLOBAL_ACTION_BACK)
            "home" -> performGlobalAction(GLOBAL_ACTION_HOME)
            "recents" -> performGlobalAction(GLOBAL_ACTION_RECENTS)
            else -> false
        }
    }

    // ---------- 3. SYSTEM OVERLAY HUD (VISIBLE OVER EXTERNAL APPS + EMERGENCY STOP) ----------

    fun showOrUpdateOverlayHud(goal: String, stepText: String) {
        mainHandler.post {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                    return@post
                }
                val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                if (overlayView == null) {
                    val container = LinearLayout(this).apply {
                        orientation = LinearLayout.HORIZONTAL
                        gravity = Gravity.CENTER_VERTICAL
                        setPadding(28, 18, 28, 18)
                        background = GradientDrawable().apply {
                            setColor(0xEE0A0F24.toInt())
                            cornerRadius = 32f
                            setStroke(3, 0xFF00CCFF.toInt())
                        }
                    }

                    val textCol = LinearLayout(this).apply {
                        orientation = LinearLayout.VERTICAL
                        layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
                    }

                    val titleTv = TextView(this).apply {
                        text = "VYSHU: $goal"
                        textSize = 12f
                        setTextColor(0xFF00CCFF.toInt())
                        maxLines = 1
                    }

                    val stepTv = TextView(this).apply {
                        text = stepText
                        textSize = 11f
                        setTextColor(0xFFFFFFFF.toInt())
                        maxLines = 1
                    }

                    textCol.addView(titleTv)
                    textCol.addView(stepTv)

                    val stopBtn = Button(this).apply {
                        text = "STOP"
                        textSize = 11f
                        setTextColor(0xFFFFFFFF.toInt())
                        background = GradientDrawable().apply {
                            setColor(0xFFFF2A4B.toInt())
                            cornerRadius = 20f
                        }
                        setOnClickListener {
                            Log.w(TAG, "[OverlayHUD] User tapped hardware STOP button!")
                            onEmergencyStopPressed?.invoke()
                            hideOverlayHud()
                        }
                    }

                    container.addView(textCol)
                    container.addView(stopBtn)

                    val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    } else {
                        @Suppress("DEPRECATION")
                        WindowManager.LayoutParams.TYPE_PHONE
                    }

                    val params = WindowManager.LayoutParams(
                        WindowManager.LayoutParams.MATCH_PARENT,
                        WindowManager.LayoutParams.WRAP_CONTENT,
                        type,
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
                        PixelFormat.TRANSLUCENT
                    ).apply {
                        gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                        y = 80
                    }

                    wm.addView(container, params)
                    overlayView = container
                    overlayTitleView = titleTv
                    overlayStepView = stepTv
                } else {
                    overlayTitleView?.text = "VYSHU: $goal"
                    overlayStepView?.text = stepText
                }
            } catch (e: Exception) {
                Log.e(TAG, "[OverlayHUD] Error displaying overlay: ${e.message}")
            }
        }
    }

    fun hideOverlayHud() {
        mainHandler.post {
            try {
                val view = overlayView ?: return@post
                val wm = getSystemService(Context.WINDOW_SERVICE) as WindowManager
                wm.removeView(view)
            } catch (_: Exception) {
            } finally {
                overlayView = null
                overlayTitleView = null
                overlayStepView = null
            }
        }
    }

    // ---------- 4. EXISTING HARDWARE & INTENT ACTIONS (PRESERVED) ----------

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

    fun openWriteSettingsPermission() {
        val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    fun openHotspotPanel() {
        val intent = Intent(Settings.ACTION_WIRELESS_SETTINGS).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

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
        }, 450)
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

    private fun findNodeByViewId(node: AccessibilityNodeInfo, idPart: String): AccessibilityNodeInfo? {
        if (node.viewIdResourceName?.contains(idPart, ignoreCase = true) == true) {
            return node
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val res = findNodeByViewId(child, idPart)
            if (res != null) return res
        }
        return null
    }

    private fun findEditableByHint(node: AccessibilityNodeInfo, hint: String): AccessibilityNodeInfo? {
        if (node.isEditable && (node.text?.contains(hint, ignoreCase = true) == true ||
                    node.contentDescription?.contains(hint, ignoreCase = true) == true)
        ) {
            return node
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val res = findEditableByHint(child, hint)
            if (res != null) return res
        }
        return null
    }

    private fun findFirstEditableNode(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        if (node.isEditable && !node.isPassword) return node
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            val res = findFirstEditableNode(child)
            if (res != null) return res
        }
        return null
    }

    fun launchAppByName(appName: String): Boolean {
        return try {
            val pm = packageManager
            val apps = pm.getInstalledApplications(android.content.pm.PackageManager.GET_META_DATA)
            val match = apps.firstOrNull { appInfo ->
                pm.getApplicationLabel(appInfo).toString().contains(appName, ignoreCase = true)
            } ?: return false
            if (BLOCKED_PACKAGES.any { match.packageName.contains(it, ignoreCase = true) }) {
                Log.w(TAG, "[Safety] Refused to launch blocked banking package: ${match.packageName}")
                return false
            }
            val launchIntent = pm.getLaunchIntentForPackage(match.packageName) ?: return false
            launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(launchIntent)
            true
        } catch (e: Exception) {
            false
        }
    }

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
