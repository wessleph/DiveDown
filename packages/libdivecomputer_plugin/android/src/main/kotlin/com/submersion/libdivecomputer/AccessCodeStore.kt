// DiveDown: new file (security.md A5, T14.3). GPL-3.0-or-later.

package com.submersion.libdivecomputer

/** Minimal key-value storage, so the logic is testable without Android. */
interface KeyValueStore {
    fun get(key: String): String?
    fun put(key: String, value: String)
    fun remove(key: String)
}

/**
 * Encrypts small secrets. The Android implementation keeps an AES-GCM key
 * in the Android Keystore; that key never leaves the device and is not part
 * of any backup, so a restored copy of the stored text cannot be read.
 */
interface SecretCipher {
    /** IV and ciphertext, Base64 or similar text. */
    fun encrypt(plain: ByteArray): String

    /** null when the text cannot be decrypted (other device, key gone). */
    fun decrypt(sealed: String): ByteArray?
}

/**
 * BLE access codes per device address (security.md A5, T14.3): stored
 * encrypted in [store]; plain Base64 values from the old `ble_access_codes`
 * preferences ([legacy]) are moved over on first read and deleted.
 */
class AccessCodeStore(
    private val store: KeyValueStore,
    private val legacy: KeyValueStore,
    private val cipher: SecretCipher,
    private val base64Decode: (String) -> ByteArray,
) {
    fun get(address: String): ByteArray? =
        throw NotImplementedError("AccessCodeStore.get")

    fun set(address: String, code: ByteArray): Unit =
        throw NotImplementedError("AccessCodeStore.set")

    companion object {
        fun key(address: String) = "ble_access_code_$address"
    }
}
