package net.trtl3.tuneshell

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * The Flutter engine comes from audio_service, which caches it for the whole
 * process (ADR-006). When an activity owned its engine, finishing it (back
 * gesture) killed the Dart isolate while mpv kept running: mpv then called a
 * freed wakeup callback and crashed, or played on beside the player of the
 * next engine. The engine and its MediaStore channel are wired by
 * TuneShellApplication; this activity only lends itself to the channel.
 */
class MainActivity : AudioServiceActivity() {
    private val mediaStore: MediaStoreChannel
        get() = (application as TuneShellApplication).mediaStore

    private val removableStorage: RemovableStorageChannel
        get() = (application as TuneShellApplication).removableStorage

    private val gestureExclusion: GestureExclusionChannel
        get() = (application as TuneShellApplication).gestureExclusion

    // Never, even when an intent asks for it: the process keeps one engine.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStore.attach(this)
        removableStorage.attach(this)
        gestureExclusion.attach(this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        mediaStore.detach(this, isChangingConfigurations)
        removableStorage.detach(this, isChangingConfigurations)
        gestureExclusion.detach(this)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        mediaStore.onRequestPermissionsResult(this, requestCode)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        removableStorage.onActivityResult(requestCode, resultCode, data)
    }
}
