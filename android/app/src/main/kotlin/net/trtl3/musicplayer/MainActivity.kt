package net.trtl3.musicplayer

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /**
     * One Flutter engine for the whole process. When an activity owns its
     * engine, finishing the activity (back gesture) kills the Dart isolate
     * while mpv keeps running: mpv then calls a freed wakeup callback and
     * crashes, or plays on beside the player of the next engine. The
     * prototype got the same from AudioServiceActivity: MPL-036 replaces
     * this object with it.
     */
    private object Shared {
        private var engine: FlutterEngine? = null
        lateinit var mediaStore: MediaStoreChannel

        fun engine(context: Context): FlutterEngine = engine ?: FlutterEngine(
            context.applicationContext,
        ).also { created ->
            mediaStore = MediaStoreChannel(context.applicationContext)
            MethodChannel(
                created.dartExecutor.binaryMessenger,
                MediaStoreChannel.NAME,
            ).setMethodCallHandler(mediaStore)
            created.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault(),
            )
            engine = created
        }
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine = Shared.engine(context)

    // Never, even when an intent asks for it: Shared would keep a dead engine.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
