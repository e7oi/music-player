package net.trtl3.musicplayer

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The Flutter engine comes from audio_service, which caches it for the whole
 * process (ADR-006). When an activity owned its engine, finishing it (back
 * gesture) killed the Dart isolate while mpv kept running: mpv then called a
 * freed wakeup callback and crashed, or played on beside the player of the
 * next engine.
 */
class MainActivity : AudioServiceActivity() {
    private object Shared {
        var engine: FlutterEngine? = null
        lateinit var mediaStore: MediaStoreChannel
    }

    // Never, even when an intent asks for it: the process keeps one engine.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The channel lives with the engine, not with this activity.
        if (Shared.engine !== flutterEngine) {
            Shared.mediaStore = MediaStoreChannel(applicationContext)
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                MediaStoreChannel.NAME,
            ).setMethodCallHandler(Shared.mediaStore)
            Shared.engine = flutterEngine
        }
        Shared.mediaStore.attach(this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        Shared.mediaStore.detach(this, isChangingConfigurations)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        Shared.mediaStore.onRequestPermissionsResult(this, requestCode)
    }
}
