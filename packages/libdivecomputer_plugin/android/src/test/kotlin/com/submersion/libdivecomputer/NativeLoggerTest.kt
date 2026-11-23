// DiveDown: new file (security.md A4, T14.2). GPL-3.0-or-later.

package com.submersion.libdivecomputer

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

// Release builds must not mirror protocol details into logcat, where every
// app with log access could read them. The Flutter side keeps its own
// filtered diagnostic log (T10).
class NativeLoggerTest {

    private val written = mutableListOf<String>()

    private fun logAll() {
        NativeLogger.logcat = { _, tag, message -> written.add("$tag $message") }
        NativeLogger.d("T", "BLE", "debug")
        NativeLogger.i("T", "BLE", "info")
        NativeLogger.w("T", "BLE", "warn")
        NativeLogger.e("T", "BLE", "error")
    }

    @After
    fun reset() {
        NativeLogger.debuggable = false
    }

    @Test
    fun releaseWritesNothingToLogcat() {
        NativeLogger.debuggable = false
        logAll()
        assertTrue("logcat in release: $written", written.isEmpty())
    }

    @Test
    fun debugBuildsKeepLogcat() {
        NativeLogger.debuggable = true
        logAll()
        assertEquals(listOf("T debug", "T info", "T warn", "T error"), written)
    }
}
