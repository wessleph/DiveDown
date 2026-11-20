package io.github.wessleph.divedown

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.OpenableColumns
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var shareChannel: MethodChannel? = null

    /** A share that arrived before Dart listened (cold start). */
    private var pendingShare: Map<String, Any>? = null
    private var dartListening = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Counterpart of lib/data/platform/share_channel.dart (T5.9).
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .apply {
                setMethodCallHandler { call, result ->
                    if (call.method == "initial") {
                        dartListening = true
                        result.success(pendingShare)
                        pendingShare = null
                    } else {
                        result.notImplemented()
                    }
                }
            }
        handleShare(intent)
        // Counterpart of lib/data/platform/device_channel.dart (ui-spec §5.6, §5.7).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                    "isBluetoothOn" -> result.success(bluetoothAdapter()?.isEnabled == true)
                    "requestBluetoothEnable" -> {
                        try {
                            @Suppress("DEPRECATION")
                            startActivityForResult(
                                Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE),
                                REQUEST_ENABLE_BT,
                            )
                            result.success(null)
                        } catch (e: SecurityException) {
                            result.error("no_permission", e.message, null)
                        }
                    }
                    "keepScreenOn" -> {
                        if (call.arguments == true) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleShare(intent)
    }

    /** „Teilen → DiveDown“: read the file into memory, off the main thread. */
    private fun handleShare(intent: Intent?) {
        val uri = when (intent?.action) {
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            Intent.ACTION_VIEW -> intent.data
            else -> null
        } ?: return
        // Handled once, not again after a rotation.
        setIntent(Intent(Intent.ACTION_MAIN))
        Thread {
            val result = try {
                val (name, size) = describe(uri)
                contentResolver.openInputStream(uri).use { SharedFileIntake.read(name, size, it) }
            } catch (e: Exception) {
                SharedFileIntake.Result.Failed(SharedFileIntake.displayName(null), "unreadable")
            }
            val payload: Map<String, Any> = when (result) {
                is SharedFileIntake.Result.Ok -> mapOf("name" to result.name, "bytes" to result.bytes)
                is SharedFileIntake.Result.Failed -> mapOf("name" to result.name, "error" to result.reason)
            }
            runOnUiThread {
                val channel = shareChannel
                if (channel != null && dartListening) {
                    channel.invokeMethod("shared", payload)
                } else {
                    pendingShare = payload
                }
            }
        }.start()
    }

    private fun describe(uri: Uri): Pair<String?, Long?> {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val name = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val size = cursor.getColumnIndex(OpenableColumns.SIZE)
                return Pair(
                    if (name >= 0) cursor.getString(name) else null,
                    if (size >= 0 && !cursor.isNull(size)) cursor.getLong(size) else null,
                )
            }
        }
        return Pair(uri.lastPathSegment, null)
    }

    private fun bluetoothAdapter(): BluetoothAdapter? =
        (getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    private companion object {
        const val DEVICE_CHANNEL = "io.github.wessleph.divedown/device"
        const val SHARE_CHANNEL = "io.github.wessleph.divedown/share"
        const val REQUEST_ENABLE_BT = 1
    }
}
