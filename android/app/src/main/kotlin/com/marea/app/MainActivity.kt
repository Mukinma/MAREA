package com.marea.app

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var tours: TourNative? = null
    private var proximity: ProximityBridge? = null
    override fun onPause() { tours?.pause(); super.onPause() }
    override fun onResume() { super.onResume(); tours?.resume() }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) { proximity?.dispose(); proximity=null; tours?.dispose(); tours=null; super.cleanUpFlutterEngine(flutterEngine) }
    override fun onDestroy() { tours?.dispose(); super.onDestroy() }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        proximity?.permissionResult(requestCode, grantResults)
        if (requestCode == 360) tours?.permissionResult()
    }
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        proximity = ProximityBridge(this, flutterEngine.dartExecutor.binaryMessenger)
        tours = TourNative(this, flutterEngine.dartExecutor.binaryMessenger)
        flutterEngine.platformViewsController.registry.registerViewFactory("marea/tour_ar_view", tours!!.ar.factory)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "marea/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method == "openSettings") {
                    startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                        .putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        proximity?.opened(intent)
    }
}
