package net.trtl3.tuneshell

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.os.storage.StorageManager
import android.provider.DocumentsContract
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Removable disks reached through the Android folder picker (D25, ADR-008,
 * FR-006). A disk is identified by the UUID of its volume; a file by its
 * path relative to the volume root. With the external storage provider the
 * document id of a file is `UUID:relative/path`, so no URI is stored: the
 * persisted grants held by Android are the only record of the access.
 *
 * It lives as long as the Flutter engine, like [MediaStoreChannel].
 */
class RemovableStorageChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "net.trtl3.tuneshell/removable_storage"
        const val AUTHORITY = "com.android.externalstorage.documents"
        private const val PICK_REQUEST = 4202
        private val AUDIO_EXTENSIONS = setOf(
            "mp3", "flac", "m4a", "aac", "ogg", "opus", "wav", "wma",
        )
    }

    // A long scan must not delay opening the next track: separate threads.
    private val scanExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    private val ioExecutor: ExecutorService = Executors.newFixedThreadPool(2)
    private val mainThread = Handler(Looper.getMainLooper())
    private var activity: Activity? = null
    private var pendingPick: MethodChannel.Result? = null

    @Volatile
    private var cancelled = false

    class Failure(val code: String, message: String) : Exception(message)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "grantedFolders" -> run(ioExecutor, result) { grantedFolders() }
            "mountedVolumes" -> run(ioExecutor, result) { mountedVolumes() }
            "releaseFolder" -> run(ioExecutor, result) {
                releaseFolder(call.argument<String>("uuid")!!, call.argument<String>("path")!!)
                null
            }
            "scan" -> {
                cancelled = false
                run(scanExecutor, result) {
                    scan(call.argument<String>("uuid")!!, call.argument<String>("path")!!)
                }
            }
            "cancelScan" -> {
                cancelled = true
                result.success(null)
            }
            "openFd" -> run(ioExecutor, result) {
                openFd(call.argument<String>("uuid")!!, call.argument<String>("path")!!)
            }
            "closeFd" -> run(ioExecutor, result) {
                ParcelFileDescriptor.adoptFd(call.argument<Int>("fd")!!).close()
                null
            }
            else -> result.notImplemented()
        }
    }

    fun attach(activity: Activity) {
        this.activity = activity
    }

    /** On a configuration change the picker result goes to the new activity. */
    fun detach(activity: Activity, recreating: Boolean) {
        if (this.activity !== activity) return
        this.activity = null
        if (recreating) return
        pendingPick?.success(null)
        pendingPick = null
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != PICK_REQUEST) return
        val pending = pendingPick ?: return
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            pending.success(null)
            return
        }
        try {
            pending.success(accept(uri))
        } catch (e: Failure) {
            pending.error(e.code, e.message, null)
        } catch (e: Exception) {
            pending.error("pick_failed", e.message, null)
        }
    }

    /** Keeps the grant of [uri] if it is a folder of a removable volume. */
    private fun accept(uri: Uri): Map<String, Any?> {
        if (uri.authority != AUTHORITY) {
            throw Failure("unsupported_provider", "Not a folder of the device storage")
        }
        val (uuid, path) = splitId(DocumentsContract.getTreeDocumentId(uri))
        if (uuid.equals("primary", ignoreCase = true)) {
            throw Failure("not_removable", "The internal storage is read through MediaStore")
        }
        context.contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION,
        )
        return mapOf("uuid" to spelling(uuid), "path" to path, "label" to label(uuid))
    }

    private fun pickFolder(result: MethodChannel.Result) {
        val current = activity
        if (current == null) {
            result.error("no_activity", "No activity to open the picker from", null)
            return
        }
        if (pendingPick != null) {
            result.error("pick_pending", "The picker is already open", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
        )
        pendingPick = result
        current.startActivityForResult(intent, PICK_REQUEST)
    }

    private fun <T> run(
        executor: ExecutorService,
        result: MethodChannel.Result,
        action: () -> T,
    ) {
        executor.execute {
            try {
                val value = action()
                mainThread.post { result.success(value) }
            } catch (e: Failure) {
                mainThread.post { result.error(e.code, e.message, null) }
            } catch (e: SecurityException) {
                mainThread.post { result.error("access_lost", e.message, null) }
            } catch (e: Throwable) {
                // Even an Error answers Dart, which would wait for ever.
                mainThread.post { result.error("failed", e.message, null) }
            }
        }
    }

    private fun splitId(documentId: String): Pair<String, String> {
        val colon = documentId.indexOf(':')
        if (colon < 0) return Pair(documentId, "")
        return Pair(documentId.substring(0, colon), documentId.substring(colon + 1).trimEnd('/'))
    }

    /** Folders the app may still read, read from the grants Android keeps. */
    private fun grantedTrees(): List<Triple<Uri, String, String>> =
        context.contentResolver.persistedUriPermissions
            .filter {
                it.isReadPermission &&
                    it.uri.authority == AUTHORITY &&
                    DocumentsContract.isTreeUri(it.uri)
            }
            .mapNotNull {
                val (uuid, path) = splitId(DocumentsContract.getTreeDocumentId(it.uri))
                if (uuid.equals("primary", ignoreCase = true)) null else Triple(it.uri, uuid, path)
            }

    private fun grantedFolders(): List<Map<String, Any?>> = grantedTrees().map { (_, uuid, path) ->
        mapOf("uuid" to spelling(uuid), "path" to path, "label" to label(uuid))
    }

    /** The volume's own spelling of its UUID, so that Dart sees one identifier. */
    private fun spelling(uuid: String): String = volume(uuid)?.uuid ?: uuid

    /**
     * The grant that covers [path] on [uuid] and the UUID spelling of that
     * grant: document ids are built with it, as the provider compares them
     * case-sensitively.
     */
    private fun coveringTree(uuid: String, path: String): Pair<Uri, String> {
        for ((tree, treeUuid, base) in grantedTrees()) {
            if (!treeUuid.equals(uuid, ignoreCase = true)) continue
            if (base.isEmpty() || path == base || path.startsWith("$base/")) {
                return Pair(tree, treeUuid)
            }
        }
        throw Failure("access_lost", "No access granted to this folder")
    }

    private fun volume(uuid: String) = (context.getSystemService(Context.STORAGE_SERVICE) as StorageManager)
        .storageVolumes
        .firstOrNull { it.uuid.equals(uuid, ignoreCase = true) }

    private fun label(uuid: String): String = volume(uuid)?.getDescription(context) ?: uuid

    /**
     * Removable volumes Android lists as mounted, plus the volumes of the
     * granted folders that answer a query. The second source covers a volume
     * the storage manager does not list to apps (ADR-008).
     */
    private fun mountedVolumes(): List<Map<String, Any?>> {
        val manager = context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
        val found = linkedMapOf<String, String>()
        for (volume in manager.storageVolumes) {
            val uuid = volume.uuid ?: continue
            if (volume.isRemovable && volume.state == android.os.Environment.MEDIA_MOUNTED) {
                found[uuid] = volume.getDescription(context)
            }
        }
        for ((tree, uuid, base) in grantedTrees()) {
            if (found.keys.any { it.equals(uuid, ignoreCase = true) }) continue
            val children = DocumentsContract.buildChildDocumentsUriUsingTree(
                tree,
                "$uuid:$base",
            )
            try {
                context.contentResolver.query(
                    children,
                    arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID),
                    null,
                    null,
                    null,
                )?.use { found[uuid] = label(uuid) }
            } catch (e: Exception) {
                // Not mounted, or not readable: absent.
            }
        }
        return found.map { mapOf("uuid" to it.key, "label" to it.value) }
    }

    private fun releaseFolder(uuid: String, path: String) {
        for ((tree, treeUuid, base) in grantedTrees()) {
            if (treeUuid.equals(uuid, ignoreCase = true) && base == path) {
                context.contentResolver.releasePersistableUriPermission(
                    tree,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            }
        }
    }

    /** URI of a file, for the tag reader as well (BR-006.3). */
    fun documentUri(uuid: String, relativePath: String): Uri {
        val (tree, treeUuid) = coveringTree(uuid, relativePath)
        return DocumentsContract.buildDocumentUriUsingTree(tree, "$treeUuid:$relativePath")
    }

    /**
     * Opens the file for the engine and gives the descriptor away: from then
     * on the engine owns it and `closeFd` closes it (D25, BR-002, BR-006).
     */
    private fun openFd(uuid: String, relativePath: String): Int {
        val descriptor = context.contentResolver.openFileDescriptor(
            documentUri(uuid, relativePath),
            "r",
        ) ?: throw Failure("open_failed", "The file cannot be opened")
        return descriptor.detachFd()
    }

    private class Entry(val documentId: String, val name: String, val mime: String?, val size: Long, val modified: Long) {
        val isDirectory: Boolean get() = mime == DocumentsContract.Document.MIME_TYPE_DIR
    }

    /**
     * Audio files of a folder and its subfolders (FR-006.5, .6). Any failure
     * fails the whole scan: a partial list would make the library drop
     * tracks (FR-006.9).
     */
    private fun scan(uuid: String, path: String): List<Map<String, Any?>> {
        val (tree, treeUuid) = coveringTree(uuid, path)
        val files = mutableListOf<Map<String, Any?>>()
        val folders = ArrayDeque<String>()
        folders.add("$treeUuid:$path")
        while (folders.isNotEmpty()) {
            if (cancelled) throw Failure("cancelled", "Scan cancelled")
            val entries = children(tree, folders.removeLast())
            // Like MediaStore: a .nomedia file hides its folder and below.
            if (entries.any { it.name == ".nomedia" }) continue
            for (entry in entries) {
                if (entry.name.startsWith(".")) continue
                if (entry.isDirectory) {
                    folders.add(entry.documentId)
                } else if (isAudio(entry)) {
                    files.add(
                        mapOf(
                            "relativePath" to splitId(entry.documentId).second,
                            "size" to entry.size,
                            "modifiedMs" to entry.modified,
                        ),
                    )
                }
            }
        }
        return files
    }

    private fun isAudio(entry: Entry): Boolean {
        if (entry.mime?.startsWith("audio/") == true) return true
        return entry.name.substringAfterLast('.', "").lowercase() in AUDIO_EXTENSIONS
    }

    private fun children(tree: Uri, parentId: String): List<Entry> {
        val uri = DocumentsContract.buildChildDocumentsUriUsingTree(tree, parentId)
        val cursor = context.contentResolver.query(
            uri,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                DocumentsContract.Document.COLUMN_MIME_TYPE,
                DocumentsContract.Document.COLUMN_SIZE,
                DocumentsContract.Document.COLUMN_LAST_MODIFIED,
            ),
            null,
            null,
            null,
        ) ?: throw Failure("scan_failed", "The folder cannot be listed")
        cursor.use {
            // A provider reports a failure in the extras, with an empty
            // cursor: taking it for an empty folder would drop its tracks.
            if (it.extras?.getString(DocumentsContract.EXTRA_ERROR) != null) {
                throw Failure("scan_failed", "The folder cannot be listed")
            }
            val entries = mutableListOf<Entry>()
            while (it.moveToNext()) {
                entries.add(
                    Entry(
                        it.getString(0),
                        it.getString(1) ?: "",
                        it.getString(2),
                        if (it.isNull(3)) 0 else it.getLong(3),
                        if (it.isNull(4)) 0 else it.getLong(4),
                    ),
                )
            }
            return entries
        }
    }
}
