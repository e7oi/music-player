package net.trtl3.tuneshell

import android.app.Activity
import android.graphics.Rect
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Keeps parts of the window out of the system Back gesture (ADR-010, FR-010.5).
 * The handle of the alphabet index sits against the screen edge: without this
 * a drag that starts on it would go back instead. Android limits the excluded
 * height to 200 dp per edge, so only the handle is declared.
 *
 * It lives as long as the Flutter engine; the rectangles belong to the window
 * of the attached activity and are dropped with it.
 */
class GestureExclusionChannel : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "net.trtl3.tuneshell/gesture_exclusion"
    }

    private var activity: Activity? = null
    private var rects: List<Rect> = emptyList()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setRects" -> try {
                @Suppress("UNCHECKED_CAST")
                val raw = call.arguments as List<Map<String, Int>>
                rects = raw.map { Rect(it["left"]!!, it["top"]!!, it["right"]!!, it["bottom"]!!) }
                apply()
                result.success(null)
            } catch (e: Exception) {
                // A badly formed call must not take the handler down.
                result.error("bad_arguments", e.message, null)
            }
            else -> result.notImplemented()
        }
    }

    fun attach(activity: Activity) {
        this.activity = activity
        apply()
    }

    fun detach(activity: Activity) {
        if (this.activity !== activity) return
        activity.window.decorView.systemGestureExclusionRects = emptyList()
        this.activity = null
    }

    private fun apply() {
        activity?.window?.decorView?.systemGestureExclusionRects = rects
    }
}
