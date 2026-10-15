package net.trtl3.musicplayer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var mediaStore: MediaStoreChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        mediaStore = MediaStoreChannel(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            MediaStoreChannel.NAME,
        ).setMethodCallHandler(mediaStore)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        mediaStore.onRequestPermissionsResult(requestCode)
    }

    override fun onDestroy() {
        mediaStore.close()
        super.onDestroy()
    }
}
