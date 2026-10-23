package net.trtl3.tuneshell

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.os.Environment
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.concurrent.Executors

/**
 * Tags and artwork read inside the audio files (FR-007, ADR-009). Each call
 * opens one file and closes it before answering (BR-006.3), whatever happens.
 *
 * Artwork is reduced, stored as `artwork/<hash>.jpg` in the private files
 * directory, once per distinct embedded image.
 */
class FileTagsChannel(
    private val context: Context,
    private val removable: RemovableStorageChannel,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "net.trtl3.tuneshell/tags"
        private const val MAX_SIDE = 512
        private const val QUALITY = 85
    }

    // Dart limits the number of reads in flight (BR-006.4); the pool is only
    // a ceiling.
    private val executor = Executors.newFixedThreadPool(4)
    private val mainThread = Handler(Looper.getMainLooper())
    private val artworkDir = File(context.filesDir, "artwork")

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "readTags" -> executor.execute {
                try {
                    val tags = readTags(call.argument<String?>("uuid"), call.argument<String>("path")!!)
                    mainThread.post { result.success(tags) }
                } catch (e: Exception) {
                    mainThread.post { result.error("read_failed", e.message, null) }
                }
            }
            "artworkDirectory" -> {
                artworkDir.mkdirs()
                result.success(artworkDir.absolutePath)
            }
            "pruneArtwork" -> executor.execute {
                val keep = call.argument<List<String>>("keep")!!.toSet()
                artworkDir.listFiles()?.forEach {
                    if (it.nameWithoutExtension !in keep || it.extension != "jpg") it.delete()
                }
                mainThread.post { result.success(null) }
            }
            else -> result.notImplemented()
        }
    }

    private fun readTags(uuid: String?, relativePath: String): Map<String, Any?> {
        val retriever = MediaMetadataRetriever()
        try {
            if (uuid == null) {
                val root = Environment.getExternalStorageDirectory().absolutePath
                retriever.setDataSource("$root/$relativePath")
            } else {
                retriever.setDataSource(context, removable.documentUri(uuid, relativePath))
            }
            fun meta(key: Int): String? = retriever.extractMetadata(key)?.trim()?.ifEmpty { null }
            // "3/12" -> 3
            fun number(key: Int): Int? = meta(key)?.substringBefore('/')?.trim()?.toIntOrNull()
            return mapOf(
                "title" to meta(MediaMetadataRetriever.METADATA_KEY_TITLE),
                "artist" to meta(MediaMetadataRetriever.METADATA_KEY_ARTIST),
                "album" to meta(MediaMetadataRetriever.METADATA_KEY_ALBUM),
                "albumArtist" to meta(MediaMetadataRetriever.METADATA_KEY_ALBUMARTIST),
                "track" to number(MediaMetadataRetriever.METADATA_KEY_CD_TRACK_NUMBER),
                "disc" to number(MediaMetadataRetriever.METADATA_KEY_DISC_NUMBER),
                "year" to meta(MediaMetadataRetriever.METADATA_KEY_YEAR)?.take(4)?.toIntOrNull(),
                "genre" to meta(MediaMetadataRetriever.METADATA_KEY_GENRE),
                "durationMs" to meta(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull(),
                "artwork" to retriever.embeddedPicture?.let { store(it) },
            )
        } finally {
            retriever.release()
        }
    }

    /** Hash of the embedded bytes: the image is decoded only the first time. */
    private fun store(embedded: ByteArray): String? {
        val hash = MessageDigest.getInstance("SHA-1").digest(embedded)
            .joinToString("") { "%02x".format(it) }
        artworkDir.mkdirs()
        val target = File(artworkDir, "$hash.jpg")
        if (target.exists()) return hash

        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(embedded, 0, embedded.size, bounds)
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
        var sample = 1
        while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= MAX_SIDE) sample *= 2
        val decoded = BitmapFactory.decodeByteArray(
            embedded,
            0,
            embedded.size,
            BitmapFactory.Options().apply { inSampleSize = sample },
        ) ?: return null
        val longest = maxOf(decoded.width, decoded.height)
        val image = if (longest > MAX_SIDE) {
            val scale = MAX_SIDE.toFloat() / longest
            Bitmap.createScaledBitmap(
                decoded,
                maxOf(1, (decoded.width * scale).toInt()),
                maxOf(1, (decoded.height * scale).toInt()),
                true,
            )
        } else {
            decoded
        }
        val temporary = File(artworkDir, "$hash.tmp")
        FileOutputStream(temporary).use { image.compress(Bitmap.CompressFormat.JPEG, QUALITY, it) }
        if (!temporary.renameTo(target)) temporary.delete()
        return hash
    }
}
