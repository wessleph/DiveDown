// DiveDown: new file (security.md A5, T14.3). GPL-3.0-or-later.

package com.submersion.libdivecomputer

import java.util.Base64
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

// BLE access codes were kept as plain Base64 in shared preferences, which
// Android backs up. They now go through a cipher whose key stays on the
// device; old values move over once.
class AccessCodeStoreTest {

    private class MapStore : KeyValueStore {
        val map = mutableMapOf<String, String>()
        override fun get(key: String) = map[key]
        override fun put(key: String, value: String) { map[key] = value }
        override fun remove(key: String) { map.remove(key) }
    }

    /** Reversible, visibly different from the input; "bad" cannot be read. */
    private class FakeCipher : SecretCipher {
        override fun encrypt(plain: ByteArray) =
            "sealed:" + plain.reversed().joinToString(",") { it.toString() }

        override fun decrypt(sealed: String): ByteArray? {
            if (!sealed.startsWith("sealed:")) return null
            val body = sealed.removePrefix("sealed:")
            if (body.isEmpty()) return ByteArray(0)
            return body.split(",").map { it.toByte() }.reversed().toByteArray()
        }
    }

    private val store = MapStore()
    private val legacy = MapStore()
    private val codes = AccessCodeStore(store, legacy, FakeCipher()) {
        Base64.getDecoder().decode(it)
    }
    private val address = "D4:22:CD:00:3F:7A"
    private val code = byteArrayOf(1, 2, 3, 4, 5, 6)

    @Test
    fun storedEncryptedAndReadBack() {
        codes.set(address, code)

        val stored = store.map[AccessCodeStore.key(address)]!!
        assertFalse(
            "plain Base64 stored",
            stored.contains(Base64.getEncoder().encodeToString(code)),
        )
        assertTrue(stored.startsWith("sealed:"))
        assertArrayEquals(code, codes.get(address))
    }

    @Test
    fun unknownDevice() {
        assertNull(codes.get(address))
    }

    @Test
    fun oldPlainValueMovesOverOnce() {
        legacy.put(AccessCodeStore.key(address), Base64.getEncoder().encodeToString(code))

        assertArrayEquals(code, codes.get(address))
        assertNull(legacy.get(AccessCodeStore.key(address)))
        assertTrue(store.map[AccessCodeStore.key(address)]!!.startsWith("sealed:"))
    }

    @Test
    fun unreadableValueIsDroppedSoThePinIsAskedAgain() {
        store.put(AccessCodeStore.key(address), "from another phone")

        assertNull(codes.get(address))
        assertEquals(emptyMap<String, String>(), store.map)
    }
}
