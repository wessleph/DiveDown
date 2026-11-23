// DiveDown: new file (security.md A5, T14.3). GPL-3.0-or-later.

package com.submersion.libdivecomputer

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

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
    fun get(address: String): ByteArray? {
        val key = key(address)
        store.get(key)?.let { sealed ->
            val plain = cipher.decrypt(sealed)
            // Unreadable (restored from another phone): forget it, the dive
            // computer asks for its PIN again.
            if (plain == null) store.remove(key)
            return plain
        }
        val old = legacy.get(key) ?: return null
        legacy.remove(key)
        val code = try {
            base64Decode(old)
        } catch (_: IllegalArgumentException) {
            return null
        }
        store.put(key, cipher.encrypt(code))
        return code
    }

    fun set(address: String, code: ByteArray) {
        store.put(key(address), cipher.encrypt(code))
        legacy.remove(key(address))
    }

    companion object {
        fun key(address: String) = "ble_access_code_$address"

        /** Store on the app's preferences and Android Keystore. */
        fun forContext(context: Context): AccessCodeStore = AccessCodeStore(
            PreferencesStore(context.getSharedPreferences(STORE_FILE, Context.MODE_PRIVATE)),
            PreferencesStore(context.getSharedPreferences(LEGACY_FILE, Context.MODE_PRIVATE)),
            KeystoreSecretCipher(),
        ) { Base64.decode(it, Base64.NO_WRAP) }

        /** Excluded from all backups (res/xml of the app, T14.3b). */
        const val STORE_FILE = "ble_access_codes_v2"
        const val LEGACY_FILE = "ble_access_codes"
    }
}

private class PreferencesStore(private val prefs: SharedPreferences) : KeyValueStore {
    override fun get(key: String): String? = prefs.getString(key, null)
    override fun put(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }
    override fun remove(key: String) {
        prefs.edit().remove(key).apply()
    }
}

/** AES-256-GCM with a key that lives only in the Android Keystore. */
private class KeystoreSecretCipher : SecretCipher {
    private val alias = "divedown_ble_access_codes"

    private fun key(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        (keyStore.getKey(alias, null) as? SecretKey)?.let { return it }
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
        return generator.generateKey()
    }

    override fun encrypt(plain: ByteArray): String {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key())
        val sealed = cipher.iv + cipher.doFinal(plain)
        return Base64.encodeToString(sealed, Base64.NO_WRAP)
    }

    override fun decrypt(sealed: String): ByteArray? = try {
        val data = Base64.decode(sealed, Base64.NO_WRAP)
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, key(), GCMParameterSpec(128, data, 0, 12))
        cipher.doFinal(data, 12, data.size - 12)
    } catch (_: Exception) {
        null
    }
}
