package net.trtl3.musicplayer

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
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
 */
class MediaStoreChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "net.trtl3.musicplayer/media_store"
        private const val PERMISSION_REQUEST = 4201
        private const val PREFS = "media_store"

        // Android only tells "never ask again" apart from "never asked" by
        // remembering that the dialog was shown once.
        private const val ASKED_KEY = "audio_permission_asked"
    }

    // The query can take a while on a large library: never on the main thread.
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
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
                activity.startActivity(
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", activity.packageName, null),
                    ),
                )
                result.success(null)
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

    fun onRequestPermissionsResult(requestCode: Int) {
        if (requestCode != PERMISSION_REQUEST) return
        val pending = pendingRequest ?: return
        pendingRequest = null
        pending.success(permissionStatus())
    }

    fun close() {
        executor.shutdownNow()
    }

    /** Replies on the main thread, unless the activity is already gone. */
    private fun reply(action: () -> Unit) {
        activity.runOnUiThread {
            if (!activity.isDestroyed) action()
        }
    }

    private fun permissionStatus(): String {
        if (activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            return "granted"
        }
        val asked = activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(ASKED_KEY, false)
        return when {
            !asked -> "notRequested"
            // Also true after the dialog was dismissed on Android 11+: the
            // Dart side tries the dialog once more before the settings.
            !activity.shouldShowRequestPermissionRationale(permission) -> "permanentlyDenied"
            else -> "denied"
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED) {
            result.success("granted")
            return
        }
        if (pendingRequest != null) {
            result.error("request_pending", "A permission request is already running", null)
            return
        }
        activity.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean(ASKED_KEY, true).apply()
        pendingRequest = result
        activity.requestPermissions(arrayOf(permission), PERMISSION_REQUEST)
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
        activity.contentResolver.query(
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
