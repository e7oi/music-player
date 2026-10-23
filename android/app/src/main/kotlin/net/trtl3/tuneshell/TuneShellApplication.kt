package net.trtl3.tuneshell

import android.app.Application
import android.os.Process
import com.ryanheise.audioservice.AudioServicePlugin
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Creates the process's only Flutter engine, the one audio_service caches
 * (ADR-006), and wires it before Dart can call it. A media button or a media
 * browser may start the process through the audio service with no activity at
 * all: the engine then runs main() without MainActivity ever configuring it,
 * and the library stayed on its loading screen once the app was opened.
 */
class TuneShellApplication : Application() {
    /**
     * audio_service destroys its engine when its service stops while no
     * activity is attached (stop from the notification after a back gesture,
     * for instance). mpv cannot be released from here and would outlive the
     * Dart isolate, as in the crash of MPL-018: the process ends with the
     * engine, and the next launch starts afresh.
     */
    private object EndProcessWithEngine : FlutterEngine.EngineLifecycleListener {
        override fun onPreEngineRestart() = Unit

        override fun onEngineWillDestroy() = Process.killProcess(Process.myPid())
    }

    lateinit var mediaStore: MediaStoreChannel
        private set

    lateinit var removableStorage: RemovableStorageChannel
        private set

    override fun onCreate() {
        super.onCreate()
        val engine = AudioServicePlugin.getFlutterEngine(this)
        // Main thread: Dart's first call can only be handled after this returns.
        mediaStore = MediaStoreChannel(this)
        MethodChannel(engine.dartExecutor.binaryMessenger, MediaStoreChannel.NAME)
            .setMethodCallHandler(mediaStore)
        removableStorage = RemovableStorageChannel(this)
        MethodChannel(engine.dartExecutor.binaryMessenger, RemovableStorageChannel.NAME)
            .setMethodCallHandler(removableStorage)
        MethodChannel(engine.dartExecutor.binaryMessenger, FileTagsChannel.NAME)
            .setMethodCallHandler(FileTagsChannel(this, removableStorage))
        engine.addEngineLifecycleListener(EndProcessWithEngine)
    }
}
