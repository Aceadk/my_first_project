package com.ace.crush

import android.app.PictureInPictureParams
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val pipChannelName = "crushhour/native_pip"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            pipChannelName
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "enterPictureInPicture" -> {
                    result.success(enterNativePictureInPicture())
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enterNativePictureInPicture(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val params = PictureInPictureParams.Builder().build()
            enterPictureInPictureMode(params)
            true
        } catch (_: Throwable) {
            false
        }
    }
}
