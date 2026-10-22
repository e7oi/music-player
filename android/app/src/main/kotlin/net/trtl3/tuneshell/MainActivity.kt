package net.trtl3.tuneshell

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

    // Never, even when an intent asks for it: the process keeps one engine.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStore.attach(this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        mediaStore.detach(this, isChangingConfigurations)
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
}
