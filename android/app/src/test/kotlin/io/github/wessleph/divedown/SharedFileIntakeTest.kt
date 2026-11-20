package io.github.wessleph.divedown

import java.io.ByteArrayInputStream
import java.io.InputStream
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

// „Teilen → DiveDown“ (T5.9, security.md A2): the shared file is read into
// memory with a size cap; its name is only a label, never a path.
class SharedFileIntakeTest {

    @Test
    fun nameIsOnlyTheLastSegment() {
        assertEquals("x.fit", SharedFileIntake.displayName("../../databases/x.fit"))
        assertEquals("x.fit", SharedFileIntake.displayName("..\\..\\x.fit"))
        assertEquals("Tauchgang 14.11.fit", SharedFileIntake.displayName(" Tauchgang 14.11.fit "))
        assertEquals("Datei", SharedFileIntake.displayName(null))
        assertEquals("Datei", SharedFileIntake.displayName("../"))
    }

    @Test
    fun smallFileIsReadIntoMemory() {
        val result = SharedFileIntake.read("a.fit", 3, ByteArrayInputStream(byteArrayOf(1, 2, 3)), max = 10)

        result as SharedFileIntake.Result.Ok
        assertEquals("a.fit", result.name)
        assertArrayEquals(byteArrayOf(1, 2, 3), result.bytes)
    }

    @Test
    fun declaredTooLargeIsRefusedWithoutReading() {
        val stream = TrackingStream(ByteArray(20))

        val result = SharedFileIntake.read("big.fit", 20, stream, max = 10)

        assertEquals(SharedFileIntake.Result.Failed("big.fit", "tooLarge"), result)
        assertFalse(stream.read)
    }

    @Test
    fun undeclaredSizeStopsAtTheCap() {
        val result = SharedFileIntake.read("big.fit", null, ByteArrayInputStream(ByteArray(11)), max = 10)

        assertEquals(SharedFileIntake.Result.Failed("big.fit", "tooLarge"), result)
    }

    @Test
    fun missingStreamIsUnreadable() {
        assertEquals(
            SharedFileIntake.Result.Failed("a.fit", "unreadable"),
            SharedFileIntake.read("a.fit", null, null, max = 10),
        )
    }

    private class TrackingStream(bytes: ByteArray) : InputStream() {
        private val inner = ByteArrayInputStream(bytes)
        var read = false

        override fun read(): Int {
            read = true
            return inner.read()
        }

        override fun read(b: ByteArray, off: Int, len: Int): Int {
            read = true
            return inner.read(b, off, len)
        }
    }
}
