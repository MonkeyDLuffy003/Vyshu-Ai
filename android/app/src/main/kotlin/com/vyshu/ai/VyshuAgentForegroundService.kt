package com.vyshu.ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.util.Log
import java.util.Locale

/**
 * VyshuAgentForegroundService — Always-On Foreground Service with Wake-Word Loop ("Hey Vyshu").
 * After waking, speaks "What do you need?" and dispatches the recognized goal to VyshuBrain.
 * Automatically restarts on task kill (START_STICKY) and starts on device boot if enabled.
 * Tag: VYSHU_AGENT
 */
class VyshuAgentForegroundService : Service(), TextToSpeech.OnInitListener {

    companion object {
        private const val TAG = "VYSHU_AGENT"
        private const val CHANNEL_ID = "vyshu_always_on_channel"
        private const val NOTIF_ID = 1042
        const val PREFS_NAME = "vyshu_agent_service_prefs"
        const val KEY_ENABLED = "always_on_enabled"

        var isRunning = false
        var onWakeWordGoalCaptured: ((String) -> Unit)? = null
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var speechRecognizer: SpeechRecognizer? = null
    private var tts: TextToSpeech? = null
    private var awaitingCommandAfterWake = false
    private var isDestroyed = false

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        isDestroyed = false
        createNotificationChannel()
        startForeground(NOTIF_ID, buildNotification("Listening for 'Hey Vyshu'..."))
        tts = TextToSpeech(this, this)
        initWakeRecognizer()
        Log.i(TAG, "[AlwaysOnService] Foreground service started.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isRunning = true
        return START_STICKY
    }

    override fun onDestroy() {
        isDestroyed = true
        isRunning = false
        mainHandler.removeCallbacksAndMessages(null)
        try {
            speechRecognizer?.destroy()
            speechRecognizer = null
        } catch (_: Exception) {}
        try {
            tts?.stop()
            tts?.shutdown()
        } catch (_: Exception) {}
        Log.i(TAG, "[AlwaysOnService] Foreground service stopped.")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale("en", "IN")
        }
    }

    private fun initWakeRecognizer() {
        mainHandler.post {
            if (isDestroyed || !SpeechRecognizer.isRecognitionAvailable(this)) return@post
            try {
                speechRecognizer?.destroy()
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this).apply {
                    setRecognitionListener(object : RecognitionListener {
                        override fun onReadyForSpeech(params: Bundle?) {}
                        override fun onBeginningOfSpeech() {}
                        override fun onRmsChanged(rmsdB: Float) {}
                        override fun onBufferReceived(buffer: ByteArray?) {}
                        override fun onEndOfSpeech() {}

                        override fun onError(error: Int) {
                            scheduleRestartListening(1200)
                        }

                        override fun onResults(results: Bundle?) {
                            val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            val phrase = matches?.firstOrNull()?.trim() ?: ""
                            if (phrase.isNotEmpty()) {
                                handleSpokenPhrase(phrase)
                            } else {
                                scheduleRestartListening(600)
                            }
                        }

                        override fun onPartialResults(partialResults: Bundle?) {}
                        override fun onEvent(eventType: Int, params: Bundle?) {}
                    })
                }
                startListeningCycle()
            } catch (e: Exception) {
                Log.e(TAG, "[AlwaysOnService] SpeechRecognizer init error: ${e.message}")
            }
        }
    }

    private fun handleSpokenPhrase(phrase: String) {
        val lower = phrase.lowercase(Locale.ROOT)
        Log.d(TAG, "[AlwaysOnService] Heard phrase: '$phrase' (awaitingCommand=$awaitingCommandAfterWake)")

        if (lower == "stop" || lower == "vyshu stop") {
            VyshuAccessibilityService.onEmergencyStopPressed?.invoke()
            awaitingCommandAfterWake = false
            scheduleRestartListening(800)
            return
        }

        if (awaitingCommandAfterWake) {
            awaitingCommandAfterWake = false
            updateNotification("Running: $phrase")
            onWakeWordGoalCaptured?.invoke(phrase)
            scheduleRestartListening(2500)
            return
        }

        // Check for wake word "vyshu" / "hey vyshu"
        if (lower.contains("vyshu") || lower.contains("vaishu")) {
            val remainder = lower
                .replace("hey vyshu", "")
                .replace("ok vyshu", "")
                .replace("vyshu", "")
                .replace("vaishu", "")
                .trim()

            if (remainder.length > 3) {
                // User spoke wake word + command in one breath
                updateNotification("Running: $remainder")
                onWakeWordGoalCaptured?.invoke(remainder)
                scheduleRestartListening(2500)
            } else {
                // Ask "What do you need?" and capture the next utterance as the task
                awaitingCommandAfterWake = true
                updateNotification("Awake — What do you need?")
                tts?.speak("What do you need?", TextToSpeech.QUEUE_FLUSH, null, "wake_prompt")
                scheduleRestartListening(1600)
            }
        } else {
            scheduleRestartListening(500)
        }
    }

    private fun startListeningCycle() {
        if (isDestroyed) return
        try {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            }
            speechRecognizer?.startListening(intent)
        } catch (e: Exception) {
            scheduleRestartListening(2000)
        }
    }

    private fun scheduleRestartListening(delayMs: Long) {
        if (isDestroyed) return
        mainHandler.removeCallbacksAndMessages(null)
        mainHandler.postDelayed({ startListeningCycle() }, delayMs)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Vyshu Always-On Agent",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps Vyshu wake-word and autonomous agent active"
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(statusText: String): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
        val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pi = PendingIntent.getActivity(this, 0, launchIntent, pendingFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Vyshu AI Agent Active")
            .setContentText(statusText)
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentIntent(pi)
            .setOngoing(true)
            .build()
    }

    private fun updateNotification(statusText: String) {
        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.notify(NOTIF_ID, buildNotification(statusText))
    }
}

/**
 * BootReceiver — Automatically restarts VyshuAgentForegroundService after device reboot if enabled.
 */
class VyshuBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            val prefs = context.getSharedPreferences(
                VyshuAgentForegroundService.PREFS_NAME,
                Context.MODE_PRIVATE
            )
            if (prefs.getBoolean(VyshuAgentForegroundService.KEY_ENABLED, false)) {
                val svcIntent = Intent(context, VyshuAgentForegroundService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(svcIntent)
                } else {
                    context.startService(svcIntent)
                }
            }
        }
    }
}
