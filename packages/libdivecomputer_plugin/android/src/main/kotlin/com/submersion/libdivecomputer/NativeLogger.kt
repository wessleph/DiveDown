// Derived from Submersion (https://github.com/submersion-app/submersion), commit e78a87cb, GPL-3.0. Modified for DiveDown.

package com.submersion.libdivecomputer

import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * Centralized logger that sends log events back to Flutter via Pigeon
 * while also logging to Android logcat.
 */
object NativeLogger {
    private var flutterApi: DiveComputerFlutterApi? = null
    // DiveDown: lazy, so JUnit can use the logger without a main looper.
    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    /** logcat output (DiveDown, security.md A4, T14.2); replaceable in tests. */
    var logcat: (priority: Int, tag: String, message: String) -> Unit =
        { priority, tag, message -> Log.println(priority, tag, message) }

    /**
     * DiveDown: true only in debuggable builds; set from the app's
     * ApplicationInfo when the plugin is attached (T14.2).
     */
    @Volatile
    var debuggable: Boolean = false

    fun setFlutterApi(api: DiveComputerFlutterApi?) {
        flutterApi = api
    }

    fun d(tag: String, category: String, message: String) {
        logcat(Log.DEBUG, tag, message)
        sendToFlutter(category, "DEBUG", message)
    }

    fun i(tag: String, category: String, message: String) {
        logcat(Log.INFO, tag, message)
        sendToFlutter(category, "INFO", message)
    }

    fun w(tag: String, category: String, message: String) {
        logcat(Log.WARN, tag, message)
        sendToFlutter(category, "WARN", message)
    }

    fun e(tag: String, category: String, message: String) {
        logcat(Log.ERROR, tag, message)
        sendToFlutter(category, "ERROR", message)
    }

    private fun sendToFlutter(category: String, level: String, message: String) {
        val api = flutterApi ?: return
        mainHandler.post {
            try {
                api.onLogEvent(category, level, message) {}
            } catch (_: Exception) {
                // Don't let logging failures crash the app
            }
        }
    }
}
