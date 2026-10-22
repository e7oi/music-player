package net.trtl3.tuneshell

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * MediaStore and audio permission for the Dart side (ADR-005, FR-003,
 * FR-004). The permission is requested here rather than through a plugin:
 * CLAUDE.md rules out permission_handler.
 *
 * It lives as long as the Flutter engine, which outlives the activity
 * (MainActivity): every call gets an answer, even after the activity is gone.
 */
class MediaStoreChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "net.trtl3.tuneshell/media_store"
        private const val PERMISSION_REQUEST = 4201
        private const val PREFS = "media_store"

        // Android only tells "never ask again" apart from "never asked" by
        // remembering that the dialog was shown once.
        private const val ASKED_KEY = "audio_permission_asked"
    }

    // The query can take a while on a large library: never on the main thread.
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainThread = Handler(Looper.getMainLooper())
    private var activity: Activity? = null
    private var pendingRequest: MethodChannel.Result? = null

    private val permission: String
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.READ_MEDIA_AUDIO
        } else {
            Manifest.permission.READ_EXTERNAL_STORAGE
        }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "audioPermissionStatus" -> result.success(permissionStatus())
            "requestAudioPermission" -> requestPermission(result)
            "openAppSettings" -> {
                val intent = Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", context.packageName, null),
                )
                val current = activity
                if (current == null) {
                    result.error("no_activity", "No activity to open the settings from", null)
                } else {
                    current.startActivity(intent)
                    result.success(null)
                }
            }
            "internalStorageRoot" ->
                result.success(Environment.getExternalStorageDirectory().absolutePath)
            "queryInternalAudio" -> executor.execute {
                try {
                    val rows = queryInternalAudio()
                    reply { result.success(rows) }
                } catch (e: Exception) {
                    reply { result.error("query_failed", e.message, null) }
                }
            }
            else -> result.notImplemented()
        }
    }

    fun attach(activity: Activity) {
        this.activity = activity
    }

    /**
     * On a configuration change the dialog result goes to the new instance:
     * the pending request waits for it. Otherwise it never comes.
     */
    fun detach(activity: Activity, recreating: Boolean) {
        if (this.activity !== activity) return
        val status = permissionStatus()
        this.activity = null
        if (recreating) return
        pendingRequest?.success(status)
        pendingRequest = null
    }

    fun onRequestPermissionsResult(activity: Activity, requestCode: Int) {
        if (requestCode != PERMISSION_REQUEST || this.activity !== activity) return
        val pending = pendingRequest ?: return
        pendingRequest = null
        pending.success(permissionStatus())
    }

    private fun reply(action: () -> Unit) {
        mainThread.post(action)
    }

    private fun permissionStatus(): String {
        if (context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            return "granted"
        }
        val asked = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(ASKED_KEY, false)
        return when {
            !asked -> "notRequested"
            // Also true after the dialog was dismissed on Android 11+: the
            // Dart side tries the dialog once more before the settings.
            // Without an activity Android cannot tell: assume it still asks.
            activity?.shouldShowRequestPermissionRationale(permission) == false ->
                "permanentlyDenied"
            else -> "denied"
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            result.success("granted")
            return
        }
        val current = activity
        if (current == null) {
            result.error("no_activity", "No activity to show the permission dialog", null)
            return
        }
        if (pendingRequest != null) {
            result.error("request_pending", "A permission request is already running", null)
            return
        }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(ASKED_KEY, true).apply()
        pendingRequest = result
        current.requestPermissions(arrayOf(permission), PERMISSION_REQUEST)
    }

    /** Files marked as music on the internal storage, with the FR-003 fields. */
    private fun queryInternalAudio(): List<Map<String, Any?>> {
        val uri = MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val projection = arrayOf(
            MediaStore.Audio.Media.RELATIVE_PATH,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ARTIST,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.GENRE,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_MODIFIED,
        )
        val rows = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(
            uri,
            projection,
            "${MediaStore.Audio.Media.IS_MUSIC} != 0",
            null,
            null,
        )?.use { cursor ->
            fun string(i: Int): String? = if (cursor.isNull(i)) null else cursor.getString(i)
            fun long(i: Int): Long? = if (cursor.isNull(i)) null else cursor.getLong(i)
            while (cursor.moveToNext()) {
                rows.add(
                    mapOf(
                        "relativePath" to string(0),
                        "displayName" to string(1),
                        "title" to string(2),
                        "artist" to string(3),
                        "album" to string(4),
                        "albumArtist" to string(5),
                        "track" to long(6),
                        "year" to long(7),
                        "genre" to string(8),
                        "durationMs" to long(9),
                        "size" to long(10),
                        "dateModified" to long(11),
                    ),
                )
            }
        }
        return rows
    }
}
