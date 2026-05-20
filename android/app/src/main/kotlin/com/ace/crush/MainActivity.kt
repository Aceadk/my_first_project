package com.ace.crush

import android.Manifest
import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val pipChannelName = "crushhour/native_pip"
    private val permissionsChannelName = "crushhour/native_permissions"
    private val trackingChannelName = "app_tracking_transparency"
    private val permissionRequestCode = 4307
    private var pendingPermissionResult: MethodChannel.Result? = null

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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            permissionsChannelName
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "hasPermission" -> {
                    val permission = androidPermissionFor(call)
                    if (permission == null) {
                        result.error("invalid_args", "Unknown permission.", null)
                    } else {
                        result.success(hasAndroidPermission(permission))
                    }
                }
                "requestPermission" -> {
                    val permission = androidPermissionFor(call)
                    if (permission == null) {
                        result.error("invalid_args", "Unknown permission.", null)
                    } else {
                        requestAndroidPermission(permission, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            trackingChannelName
        ).setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "getTrackingAuthorizationStatus", "requestTrackingAuthorization" -> result.success(4)
                "getAdvertisingIdentifier" -> result.success("")
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

    private fun androidPermissionFor(call: MethodCall): String? {
        val args = call.arguments as? Map<*, *> ?: return null
        return when (args["permission"] as? String) {
            "camera" -> Manifest.permission.CAMERA
            "microphone" -> Manifest.permission.RECORD_AUDIO
            else -> null
        }
    }

    private fun hasAndroidPermission(permission: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestAndroidPermission(permission: String, result: MethodChannel.Result) {
        if (hasAndroidPermission(permission)) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("permission_request_pending", "A permission request is already pending.", null)
            return
        }
        pendingPermissionResult = result
        requestPermissions(arrayOf(permission), permissionRequestCode)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != permissionRequestCode) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }
}
