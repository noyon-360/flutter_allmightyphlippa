package com.example.flutter_almightyflippa

import android.app.PictureInPictureParams
import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    /// Set by the video screens while something is playing: leaving the app
    /// (Home / Recents) should then shrink it into picture-in-picture.
    private var autoPipArmed = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "labby/device")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTv" -> result.success(isTv())
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "labby/pip")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setAutoEnter" -> {
                        setAutoPip(call.argument<Boolean>("enabled") ?: false)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Android TV / Google TV: the UI mode is "television" and the device
    // declares leanback. Either one is enough.
    private fun isTv(): Boolean {
        val uiModeManager = getSystemService(Context.UI_MODE_SERVICE) as UiModeManager
        return uiModeManager.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION ||
            packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)
    }

    private fun pipSupported(): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)

    private fun pipParams(autoEnter: Boolean): PictureInPictureParams {
        val builder = PictureInPictureParams.Builder().setAspectRatio(Rational(16, 9))
        // Android 12+: the system enters PiP itself, with a smooth animation.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(autoEnter)
        }
        return builder.build()
    }

    private fun setAutoPip(enabled: Boolean) {
        autoPipArmed = enabled
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && pipSupported()) {
            setPictureInPictureParams(pipParams(enabled))
        }
    }

    // Android 8–11 have no auto-enter: the user pressing Home / Recents is
    // reported here, while the activity is still resumed, so PiP can start.
    // (Not called when the screen is locked, which is what we want.)
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (autoPipArmed && pipSupported() &&
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S &&
            !isInPictureInPictureMode
        ) {
            try {
                enterPictureInPictureMode(pipParams(false))
            } catch (_: IllegalStateException) {
                // Activity no longer in a state that allows PiP; just leave.
            }
        }
    }
}
