#!/usr/bin/env python3
"""Build a native Vyshu client and a Vaani integration test.

The workflow checks out the reviewed Vaani source at vaani-source/.
API keys are generated on the phone, never inside this script.
"""
from pathlib import Path
import xml.etree.ElementTree as ET

FILES = {
    "native-control/settings.gradle.kts": r"""
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "VyshuBotLink"
include(":app")
""",

    "native-control/build.gradle.kts": r"""
plugins {
    id("com.android.application") version "9.1.1" apply false
}
""",

    "native-control/app/build.gradle.kts": r"""
plugins {
    id("com.android.application")
}
android {
    namespace = "com.vyshu.botlink"
    compileSdk {
        version = release(36) {
            minorApiLevel = 1
        }
    }
    defaultConfig {
        applicationId = "com.vyshu.coretest"
        minSdk = 28
        targetSdk = 35
        versionCode = 1
        versionName = "0.1-link-test"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}
""",

    "native-control/app/src/main/AndroidManifest.xml": r"""
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>

    <queries>
        <package android:name="com.aistudio.vaani.vzqk.vyshutest"/>
    </queries>

    <application
        android:label="Vyshu Link Test"
        android:allowBackup="false"
        android:usesCleartextTraffic="false"
        android:theme="@android:style/Theme.Material.NoActionBar">

        <activity
            android:name=".BotLinkActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
""",

    "native-control/app/src/main/java/com/vyshu/botlink/BotKeyVault.kt": r"""
package com.vyshu.botlink

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class BotKeyVault(context: Context) {
    private val prefs =
        context.getSharedPreferences("bot_keys", Context.MODE_PRIVATE)

    private fun wrappingKey(): SecretKey {
        val store = KeyStore.getInstance("AndroidKeyStore").apply {
            load(null)
        }

        (store.getKey("vyshu_bot_keys_v1", null) as? SecretKey)?.let {
            return it
        }

        return KeyGenerator.getInstance("AES", "AndroidKeyStore").run {
            init(
                KeyGenParameterSpec.Builder(
                    "vyshu_bot_keys_v1",
                    KeyProperties.PURPOSE_ENCRYPT or
                        KeyProperties.PURPOSE_DECRYPT
                )
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setEncryptionPaddings(
                        KeyProperties.ENCRYPTION_PADDING_NONE
                    )
                    .setKeySize(256)
                    .build()
            )
            generateKey()
        }
    }

    // Call on the main thread. Never log this value.
    fun keyFor(botId: String): String {
        require(botId.matches(Regex("[a-z0-9_.-]{1,64}")))

        val saved = prefs.getString(botId, null)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")

        if (saved != null) {
            val parts = saved.split(":")
            require(parts.size == 2) {
                "Invalid vault record"
            }

            cipher.init(
                Cipher.DECRYPT_MODE,
                wrappingKey(),
                GCMParameterSpec(
                    128,
                    Base64.decode(parts[0], Base64.NO_WRAP)
                )
            )
            cipher.updateAAD(botId.toByteArray(Charsets.UTF_8))

            return String(
                cipher.doFinal(
                    Base64.decode(parts[1], Base64.NO_WRAP)
                ),
                Charsets.UTF_8
            )
        }

        val random = ByteArray(32).also {
            SecureRandom().nextBytes(it)
        }

        val token = "vyshu_v1_" + Base64.encodeToString(
            random,
            Base64.URL_SAFE or
                Base64.NO_WRAP or
                Base64.NO_PADDING
        )

        cipher.init(Cipher.ENCRYPT_MODE, wrappingKey())
        cipher.updateAAD(botId.toByteArray(Charsets.UTF_8))

        val encrypted = cipher.doFinal(
            token.toByteArray(Charsets.UTF_8)
        )

        val record =
            Base64.encodeToString(cipher.iv, Base64.NO_WRAP) +
                ":" +
                Base64.encodeToString(encrypted, Base64.NO_WRAP)

        check(prefs.edit().putString(botId, record).commit()) {
            "Key could not be saved"
        }

        return token
    }
}
""",

    "native-control/app/src/main/java/com/vyshu/botlink/BotLinkActivity.kt": r"""
package com.vyshu.botlink

import android.app.Activity
import android.content.*
import android.os.*
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.widget.*
import java.util.UUID

class BotLinkActivity : Activity() {
    private val target = "com.aistudio.vaani.vzqk.vyshutest"
    private val main = Handler(Looper.getMainLooper())

    private lateinit var output: TextView
    private lateinit var input: EditText
    private lateinit var vault: BotKeyVault

    private var connection: ServiceConnection? = null
    private var bound = false
    private var pendingId: String? = null

    private val timeout = Runnable {
        finishRequest(
            "No reply. The result is unknown; check status before retrying."
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        vault = BotKeyVault(this)

        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(24, 24, 24, 24)

            setOnApplyWindowInsetsListener { view, insets ->
                view.setPadding(
                    24,
                    insets.systemWindowInsetTop + 24,
                    24,
                    insets.systemWindowInsetBottom + 24
                )
                insets
            }
        }

        layout.addView(
            TextView(this).apply {
                text = "Vyshu — Vaani connection test"
                textSize = 22f
            }
        )

        output = TextView(this).apply {
            text = "Open the Vaani test app first, then pair it here."
            textSize = 16f
        }
        layout.addView(output)

        fun button(label: String, action: () -> Unit) {
            layout.addView(
                Button(this).apply {
                    text = label
                    setOnClickListener { action() }
                }
            )
        }

        button("Open Vaani test app") {
            try {
                val launch =
                    packageManager.getLaunchIntentForPackage(target)
                        ?: error("Install the Vaani test APK first.")

                startActivity(launch)
            } catch (e: Exception) {
                output.text = e.message
            }
        }

        button("Pair with Vaani") {
            try {
                val intent = Intent()
                    .setComponent(
                        ComponentName(
                            target,
                            "com.example.control.VyshuPairActivity"
                        )
                    )
                    .putExtra("key", vault.keyFor("vaani"))

                startActivityForResult(intent, 10)
            } catch (_: Exception) {
                output.text =
                    "Pairing could not open. Check the test APK installation."
            }
        }

        input = EditText(this).apply {
            hint = "status / pause / resume / next / play title / timer 10"
            isSingleLine = true
            imeOptions = EditorInfo.IME_ACTION_SEND

            setOnEditorActionListener { _, action, _ ->
                if (action == EditorInfo.IME_ACTION_SEND) {
                    sendCommand()
                    true
                } else {
                    false
                }
            }
        }
        layout.addView(input)

        button("Send command") {
            sendCommand()
        }

        setContentView(layout)
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == 10) {
            output.text = if (resultCode == RESULT_OK) {
                "Paired. Try status, then pause."
            } else {
                "Pairing was not accepted."
            }
        }
    }

    private fun sendCommand() {
        if (pendingId != null) return

        val text = input.text.toString().trim()
        val action = text.substringBefore(' ').lowercase()
        val argument = text.substringAfter(' ', "").trim()

        val allowed = setOf(
            "status",
            "pause",
            "resume",
            "next",
            "previous",
            "play",
            "timer",
            "cancel_timer"
        )

        if (
            action !in allowed ||
            (action == "play" && argument.isBlank()) ||
            (
                action == "timer" &&
                    (argument.toIntOrNull() ?: 0) !in 1..180
            )
        ) {
            output.text =
                "Use status, pause, resume, next, previous, " +
                    "play TITLE, timer 1–180, or cancel_timer."
            return
        }

        val token = try {
            vault.keyFor("vaani")
        } catch (_: Exception) {
            output.text = "The local key vault could not be opened."
            return
        }

        val id = UUID.randomUUID().toString()

        val request = Bundle().apply {
            putString("id", id)
            putString("key", token)
            putString("action", action)
            putString("query", argument.take(200))
            putInt("minutes", argument.toIntOrNull() ?: 0)
            putLong("issued", SystemClock.elapsedRealtime())
        }

        pendingId = id

        val replies = Messenger(
            Handler(Looper.getMainLooper()) { message ->
                if (message.data.getString("id") == pendingId) {
                    val state =
                        message.data.getString("status", "error")
                    val detail =
                        message.data.getString("detail", "No details")

                    finishRequest("$state: $detail")
                }
                true
            }
        )

        connection = object : ServiceConnection {
            override fun onServiceConnected(
                name: ComponentName?,
                binder: IBinder?
            ) {
                if (pendingId != id || binder == null) return

                try {
                    Messenger(binder).send(
                        Message.obtain(null, 1).apply {
                            data = request
                            replyTo = replies
                        }
                    )
                } catch (_: Exception) {
                    finishRequest(
                        "Connection failed. Check status before retrying."
                    )
                }
            }

            override fun onServiceDisconnected(name: ComponentName?) {
                finishRequest(
                    "Vaani disconnected. The command result is unknown."
                )
            }

            override fun onNullBinding(name: ComponentName?) {
                finishRequest("Vaani refused the connection.")
            }

            override fun onBindingDied(name: ComponentName?) {
                finishRequest(
                    "Vaani was updated or stopped. Reopen it and check status."
                )
            }
        }

        try {
            bound = bindService(
                Intent().setComponent(
                    ComponentName(
                        target,
                        "com.example.control.VyshuControlService"
                    )
                ),
                connection!!,
                Context.BIND_AUTO_CREATE
            )

            if (!bound) {
                finishRequest("Vaani control service is unavailable.")
            } else {
                output.text = "Waiting for Vaani…"
                main.postDelayed(timeout, 5000)
            }
        } catch (_: Exception) {
            finishRequest("Unable to bind to Vaani.")
        }
    }

    private fun finishRequest(text: String) {
        main.removeCallbacks(timeout)
        pendingId = null

        if (bound) {
            connection?.let {
                runCatching { unbindService(it) }
            }
        }

        bound = false
        connection = null

        if (::output.isInitialized) {
            output.text = text
        }
    }

    override fun onDestroy() {
        finishRequest("Closed.")
        super.onDestroy()
    }
}
""",

    "native-control/app/src/main/java/com/vyshu/botlink/WebBotClient.kt": r"""
package com.vyshu.botlink

import android.os.Looper
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.net.URL
import java.util.UUID
import javax.net.ssl.HttpsURLConnection

// Use an endpoint saved in your bot settings, never an AI-generated URL.
// The receiving web app must implement this command protocol.
class WebBotClient(
    private val endpoint: URL,
    private val key: String
) {
    init {
        require(
            endpoint.protocol == "https" &&
                endpoint.userInfo == null &&
                endpoint.ref == null &&
                endpoint.query == null
        )
        require(key.matches(Regex("vyshu_v1_[A-Za-z0-9_-]{43}")))
    }

    // Call on a worker thread. Do not automatically retry commands.
    fun execute(action: String, args: JSONObject): JSONObject {
        check(Looper.myLooper() != Looper.getMainLooper())
        require(action.matches(Regex("[a-z_]{1,40}")))

        val id = UUID.randomUUID().toString()

        val body = JSONObject()
            .put("id", id)
            .put("action", action)
            .put("args", args)
            .toString()
            .toByteArray(Charsets.UTF_8)

        require(body.size <= 16_384)

        val connection =
            endpoint.openConnection() as HttpsURLConnection

        try {
            connection.instanceFollowRedirects = false
            connection.requestMethod = "POST"
            connection.connectTimeout = 8000
            connection.readTimeout = 10000
            connection.doOutput = true

            connection.setRequestProperty(
                "Authorization",
                "Bearer $key"
            )
            connection.setRequestProperty(
                "Content-Type",
                "application/json"
            )
            connection.setFixedLengthStreamingMode(body.size)

            connection.outputStream.use {
                it.write(body)
            }

            val status = connection.responseCode
            check(status in 200..299) {
                "Bot returned HTTP $status"
            }

            val output = ByteArrayOutputStream()

            connection.inputStream.use { stream ->
                val buffer = ByteArray(4096)

                while (true) {
                    val read = stream.read(buffer)
                    if (read == -1) break

                    check(output.size() + read <= 65_536) {
                        "Bot response too large"
                    }

                    output.write(buffer, 0, read)
                }
            }

            val reply = JSONObject(output.toString("UTF-8"))

            check(reply.getString("id") == id) {
                "Response ID did not match"
            }

            check(
                reply.getString("status") in
                    setOf("accepted", "completed", "error")
            )

            return reply
        } finally {
            connection.disconnect()
        }
    }
}
""",

    "vaani-source/app/src/main/java/com/example/control/VyshuGate.kt": r"""
package com.example.control

import java.security.MessageDigest

class VyshuGate(
    val uid: Int,
    val digest: ByteArray
) {
    init {
        require(uid > 0 && digest.size == 32)
    }

    fun allows(callerUid: Int, key: String?): Boolean =
        callerUid == uid &&
            valid(key) &&
            MessageDigest.isEqual(digest, hash(key!!))

    companion object {
        fun valid(key: String?): Boolean =
            key?.matches(
                Regex("vyshu_v1_[A-Za-z0-9_-]{43}")
            ) == true

        fun hash(key: String): ByteArray =
            MessageDigest.getInstance("SHA-256").digest(
                key.toByteArray(Charsets.UTF_8)
            )

        fun pair(uid: Int, key: String): VyshuGate {
            require(valid(key))
            return VyshuGate(uid, hash(key))
        }
    }
}
""",

    "vaani-source/app/src/main/java/com/example/control/VyshuControl.kt": r"""
package com.example.control

import android.app.Activity
import android.app.AlertDialog
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.*
import android.util.AtomicFile
import android.util.Base64
import android.view.WindowManager
import com.example.ui.VaaniViewModel
import org.json.JSONObject
import java.io.File
import java.lang.ref.WeakReference

object VaaniControl {
    private var current = WeakReference<VaaniViewModel>(null)

    fun attach(model: VaaniViewModel) {
        current = WeakReference(model)
    }

    fun detach(model: VaaniViewModel) {
        if (current.get() === model) {
            current.clear()
        }
    }

    fun model(): VaaniViewModel? = current.get()
}

private object PairStore {
    private fun file(context: Context) =
        AtomicFile(
            File(context.noBackupFilesDir, "vyshu_pair_v1.json")
        )

    fun read(context: Context): VyshuGate? = try {
        val json = JSONObject(
            String(file(context).readFully(), Charsets.UTF_8)
        )

        VyshuGate(
            json.getInt("uid"),
            Base64.decode(json.getString("hash"), Base64.NO_WRAP)
        )
    } catch (_: Exception) {
        null
    }

    fun write(context: Context, gate: VyshuGate) {
        val record = JSONObject()
            .put("uid", gate.uid)
            .put(
                "hash",
                Base64.encodeToString(gate.digest, Base64.NO_WRAP)
            )
            .toString()
            .toByteArray(Charsets.UTF_8)

        val target = file(context)
        val stream = target.startWrite()

        try {
            stream.write(record)
            target.finishWrite(stream)
        } catch (e: Exception) {
            target.failWrite(stream)
            throw e
        }
    }

    fun revoke(context: Context) {
        file(context).delete()
    }
}

class VyshuPairActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

        val caller = callingPackage
        val key = intent.getStringExtra("key")

        if (
            caller !in setOf("com.vyshu.coretest", "com.vyshu.ai") ||
            !VyshuGate.valid(key)
        ) {
            setResult(RESULT_CANCELED)
            finish()
            return
        }

        val uid = try {
            packageManager.getApplicationInfo(caller!!, 0).uid
        } catch (_: Exception) {
            finish()
            return
        }

        AlertDialog.Builder(this)
            .setTitle("Connect Vyshu to Vaani?")
            .setMessage(
                "Allow $caller to request music status, playback " +
                    "controls and sleep timers on this phone? " +
                    "This replaces any previous pairing."
            )
            .setPositiveButton("Allow") { _, _ ->
                try {
                    PairStore.write(
                        this,
                        VyshuGate.pair(uid, key!!)
                    )
                    setResult(RESULT_OK)
                } catch (_: Exception) {
                    setResult(RESULT_CANCELED)
                }
                finish()
            }
            .setNeutralButton("Revoke access") { _, _ ->
                PairStore.revoke(this)
                setResult(RESULT_CANCELED)
                finish()
            }
            .setNegativeButton("Cancel") { _, _ ->
                finish()
            }
            .setOnCancelListener {
                finish()
            }
            .show()
    }
}

class VyshuControlService : Service() {
    private val recent =
        LinkedHashMap<String, Pair<String, Bundle>>()

    private val inbox = Messenger(
        Handler(Looper.getMainLooper()) { message ->
            handle(message)
            true
        }
    )

    override fun onBind(intent: Intent?): IBinder = inbox.binder

    private fun reply(message: Message, data: Bundle) {
        try {
            message.replyTo?.send(
                Message.obtain(null, 1).apply {
                    this.data = data
                }
            )
        } catch (_: Exception) {
            // The caller may have left. Never repeat the action.
        }
    }

    private fun result(
        id: String,
        status: String,
        detail: String
    ) = Bundle().apply {
        putString("id", id)
        putString("status", status)
        putString("detail", detail)
    }

    private fun handle(message: Message) {
        var id = ""

        try {
            val data = message.data
            id = data.getString("id").orEmpty()

            if (id.length !in 1..80 || message.what != 1) {
                return
            }

            val gate = PairStore.read(this)

            if (
                gate == null ||
                !gate.allows(
                    message.sendingUid,
                    data.getString("key")
                )
            ) {
                reply(
                    message,
                    result(
                        id,
                        "error",
                        "Not authorised. Pair Vyshu with Vaani."
                    )
                )
                return
            }

            val age = SystemClock.elapsedRealtime() -
                data.getLong("issued", -1)

            if (age !in 0L..10_000L) {
                reply(
                    message,
                    result(id, "error", "This request expired.")
                )
                return
            }

            val action = data.getString("action").orEmpty()
            val query = data.getString("query").orEmpty()
            val minutes = data.getInt("minutes", 0)

            require(action.length <= 30 && query.length <= 200)

            val fingerprint = JSONObject()
                .put("action", action)
                .put("query", query)
                .put("minutes", minutes)
                .toString()

            val cacheKey = "${message.sendingUid}:$id"

            recent[cacheKey]?.let { previous ->
                reply(
                    message,
                    if (previous.first == fingerprint) {
                        previous.second
                    } else {
                        result(
                            id,
                            "error",
                            "Request ID was reused with different arguments."
                        )
                    }
                )
                return
            }

            val response = execute(id, action, query, minutes)

            recent[cacheKey] = fingerprint to response

            if (recent.size > 128) {
                recent.remove(recent.keys.first())
            }

            reply(message, response)
        } catch (_: Exception) {
            reply(
                message,
                result(
                    id,
                    "error",
                    "Command could not be processed. Check status."
                )
            )
        }
    }

    private fun execute(
        id: String,
        action: String,
        query: String,
        minutes: Int
    ): Bundle {
        val model = VaaniControl.model()
            ?: return result(
                id,
                "error",
                "Open Vaani first. Its player is not running."
            )

        val player = model.player

        when (action) {
            "status" -> return result(
                id,
                "reported",
                "Track: ${player.currentSong.value?.title ?: "none"}; " +
                    "playing: ${player.isPlaying.value}; " +
                    "timer: ${player.sleepTimerRemainingSec.value}s"
            )

            "pause" -> player.pause()

            "resume" -> {
                if (player.currentSong.value == null) {
                    return result(
                        id,
                        "error",
                        "Choose a track in Vaani first."
                    )
                }
                player.resume()
            }

            "next", "previous" -> {
                if (model.allSongs.value.isEmpty()) {
                    return result(
                        id,
                        "error",
                        "Vaani's song list is not loaded."
                    )
                }

                if (action == "next") {
                    model.skipNext()
                } else {
                    model.skipPrevious()
                }
            }

            "play" -> {
                if (query.isBlank()) {
                    return result(
                        id,
                        "error",
                        "Provide a track title."
                    )
                }

                val songs = model.allSongs.value

                val exact = songs.filter {
                    it.title.equals(query, ignoreCase = true)
                }

                val matches = exact.ifEmpty {
                    songs.filter {
                        it.title.contains(query, ignoreCase = true)
                    }
                }

                if (matches.size != 1) {
                    return result(
                        id,
                        "error",
                        if (matches.isEmpty()) {
                            "No matching track in the loaded library."
                        } else {
                            "Several tracks match. Use the exact title."
                        }
                    )
                }

                model.playSong(matches.single())
            }

            "timer" -> {
                if (minutes !in 1..180) {
                    return result(
                        id,
                        "error",
                        "Timer must be 1–180 minutes."
                    )
                }
                player.setSleepTimer(minutes)
            }

            "cancel_timer" -> player.cancelSleepTimer()

            else -> return result(
                id,
                "error",
                "Unsupported action."
            )
        }

        // Playback may prepare asynchronously.
        // Acknowledging a command is not proof of audible playback.
        return result(
            id,
            "accepted",
            "$action was passed to Vaani's player. " +
                "Use status to inspect its reported state."
        )
    }
}
""",

    "vaani-source/app/src/test/java/com/example/control/VyshuGateTest.kt": r"""
package com.example.control

import org.junit.Assert.*
import org.junit.Test

class VyshuGateTest {
    private val key = "vyshu_v1_" + "A".repeat(43)

    @Test
    fun pairedCallerCanAuthenticate() {
        assertTrue(
            VyshuGate.pair(10001, key).allows(10001, key)
        )
    }

    @Test
    fun anotherAppCannotUseTheSameKey() {
        assertFalse(
            VyshuGate.pair(10001, key).allows(10002, key)
        )
    }

    @Test
    fun wrongKeyAndMissingKeyAreRejected() {
        val gate = VyshuGate.pair(10001, key)

        assertFalse(
            gate.allows(
                10001,
                "vyshu_v1_" + "B".repeat(43)
            )
        )
        assertFalse(gate.allows(10001, null))
        assertFalse(gate.allows(10001, key + "extra"))
    }

    @Test
    fun replacingPairingInvalidatesTheOldKey() {
        val newKey = "vyshu_v1_" + "C".repeat(43)
        val gate = VyshuGate.pair(10001, newKey)

        assertFalse(gate.allows(10001, key))
        assertTrue(gate.allows(10001, newKey))
    }
}
""",
}


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError(
            "Source changed; refusing an unsafe patch: " + old[:70]
        )
    return text.replace(old, new, 1)


def prepare():
    root = Path("vaani-source")
    activity_path = (
        root / "app/src/main/java/com/example/MainActivity.kt"
    )
    gradle_path = root / "app/build.gradle.kts"

    # Check every replacement before writing the generated files.
    activity = activity_path.read_text(encoding="utf-8")

    activity = replace_once(
        activity,
        "import com.example.ui.VaaniMainScreen",
        "import com.example.control.VaaniControl\n"
        "import com.example.ui.VaaniMainScreen",
    )

    activity = replace_once(
        activity,
        "super.onCreate(savedInstanceState)",
        "super.onCreate(savedInstanceState)\n"
        "    VaaniControl.attach(viewModel)",
    )

    activity = replace_once(
        activity,
        "\n}\n\n@androidx.compose.runtime.Composable",
        "\n  override fun onDestroy() {\n"
        "    if (!isChangingConfigurations) "
        "VaaniControl.detach(viewModel)\n"
        "    super.onDestroy()\n"
        "  }\n"
        "}\n\n@androidx.compose.runtime.Composable",
    )

    gradle = replace_once(
        gradle_path.read_text(encoding="utf-8"),
        'applicationId = "com.aistudio.vaani.vzqk"',
        'applicationId = "com.aistudio.vaani.vzqk.vyshutest"',
    )

    ns = "{http://schemas.android.com/apk/res/android}"
    ET.register_namespace("android", ns[1:-1])

    manifest_path = root / "app/src/main/AndroidManifest.xml"
    manifest = ET.parse(manifest_path)
    application = manifest.getroot().find("application")

    if application is None:
        raise RuntimeError("Vaani application element not found")

    application.set(ns + "label", "Vaani Link Test")

    for item in application.findall("activity"):
        item.set(ns + "label", "Vaani Link Test")

    components = [
        ("activity", "com.example.control.VyshuPairActivity"),
        ("service", "com.example.control.VyshuControlService"),
    ]

    for tag, name in components:
        if any(
            item.get(ns + "name") == name
            for item in application
        ):
            raise RuntimeError(
                "Adapter already exists; use a clean pinned checkout"
            )

        attributes = {
            ns + "name": name,
            ns + "exported": "true",
        }

        if tag == "activity":
            attributes[ns + "excludeFromRecents"] = "true"

        ET.SubElement(application, tag, attributes)

    queries = manifest.getroot().find("queries")

    if queries is None:
        queries = ET.SubElement(manifest.getroot(), "queries")

    for package in ["com.vyshu.coretest", "com.vyshu.ai"]:
        ET.SubElement(
            queries,
            "package",
            {ns + "name": package},
        )

    for name, content in FILES.items():
        path = Path(name)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content.strip() + "\n", encoding="utf-8")

    activity_path.write_text(activity, encoding="utf-8")
    gradle_path.write_text(gradle, encoding="utf-8")

    manifest.write(
        manifest_path,
        encoding="utf-8",
        xml_declaration=True,
    )

    # The integration test must not use a paid AI-provider key.
    for name in (".env", ".env.example"):
        (root / name).write_text(
            "GEMINI_API_KEY=\n",
            encoding="utf-8",
        )

    print(
        "Prepared native Vyshu and Vaani test sources. "
        "No API secrets generated on CI."
    )


if __name__ == "__main__":
    prepare()
