package io.github.wessleph.divedown

import java.io.ByteArrayOutputStream
import java.io.InputStream

/**
 * Reads a file another app shares („Teilen → DiveDown“) straight into
 * memory: nothing is written to disk, the sender's name is only a label
 * (security.md A2, T5.9). Counterpart of lib/data/platform/share_channel.dart.
 */
object SharedFileIntake {
    /** Same limit as `maxImportFileBytes` in Dart (ui-spec §5.8). */
    const val MAX_BYTES = 10 * 1024 * 1024

    sealed class Result {
        data class Ok(val name: String, val bytes: ByteArray) : Result()

        /** [reason] is the Dart `FileImportFailure` name. */
        data class Failed(val name: String, val reason: String) : Result()
    }

    /** The last path segment of the sender's name, for display only. */
    fun displayName(raw: String?): String =
        raw?.split('/', '\\')?.last()?.trim()?.takeIf { it.isNotEmpty() && it != ".." }
            ?: "Datei"

    fun read(rawName: String?, declaredSize: Long?, input: InputStream?, max: Int = MAX_BYTES): Result {
        val name = displayName(rawName)
        if (declaredSize != null && declaredSize > max) return Result.Failed(name, "tooLarge")
        if (input == null) return Result.Failed(name, "unreadable")
        val out = ByteArrayOutputStream()
        val buffer = ByteArray(64 * 1024)
        while (true) {
            val n = input.read(buffer)
            if (n < 0) break
            if (out.size() + n > max) return Result.Failed(name, "tooLarge")
            out.write(buffer, 0, n)
        }
        return Result.Ok(name, out.toByteArray())
    }
}
