package com.marea.app

import android.Manifest
import android.app.Activity
import android.content.*
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.*
import org.json.JSONArray
import org.json.JSONObject

class ProximityBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "marea/proximity_background")
    private val preferences get() = activity.getSharedPreferences(ProximityService.PREFS, Context.MODE_PRIVATE)
    private var notificationRequest: MethodChannel.Result? = null
    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "status" -> result.success(status())
                    "supported" -> result.success(true)
                    "requestNotifications" -> {
                        if (Build.VERSION.SDK_INT < 33 || NotificationManagerCompat.from(activity).areNotificationsEnabled()) result.success(true)
                        else if (notificationRequest != null) result.error("busy", "La solicitud de permiso sigue abierta.", null)
                        else {
                            notificationRequest = result
                            activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST)
                        }
                    }
                    "openSettings" -> {
                        activity.startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${activity.packageName}")))
                        result.success(null)
                    }
                    "bindAccount" -> {
                        val account = call.argument<String>("accountId")
                        if (account != preferences.getString("account", null)) {
                            ProximityService.stop(activity, true)
                        } else if (call.argument<Boolean>("foreground") == true &&
                            preferences.getBoolean("enabled", false) && !ProximityService.running && ProximityService.permissions(activity)) {
                            ContextCompat.startForegroundService(activity, Intent(activity, ProximityService::class.java))
                        }
                        result.success(status())
                    }
                    "start", "updateTargets" -> {
                        val account = call.argument<String>("accountId") ?: error("No hay una cuenta activa.")
                        require(Regex("^[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}$").matches(account))
                        if (call.method == "updateTargets") require(account == preferences.getString("account", null))
                        if (!ProximityService.permissions(activity)) {
                            result.error("permissions_required", "Permite ubicación precisa todo el tiempo y notificaciones.", null)
                        } else {
                            val raw = JSONArray(call.argument<List<Map<String, Any?>>>("targets") ?: emptyList<Map<String, Any?>>()).toString()
                            val valid = ProximityService.parseTargets(raw)
                            require(valid.size == JSONArray(raw).length()) { "Hay lugares de aviso inválidos." }
                            val keep = valid.map { it.key }.toSet()
                            ProximityService.parseTargets(preferences.getString("targets", "[]") ?: "[]")
                                .filter { it.key !in keep }.forEach {
                                    NotificationManagerCompat.from(activity).cancel("proximity:$account", ProximityService.noticeId(account, it.key))
                                }
                            if (account != preferences.getString("account", null)) ProximityService.stop(activity, true)
                            preferences.edit().putString("account", account).putString("targets", raw)
                                .putLong("updatedAt", System.currentTimeMillis()).apply()
                            if (call.method == "start") {
                                preferences.edit().putBoolean("enabled", true).apply()
                                try {
                                    ContextCompat.startForegroundService(activity, Intent(activity, ProximityService::class.java))
                                } catch (e: Exception) {
                                    preferences.edit().putBoolean("enabled", false).apply()
                                    throw e
                                }
                            }
                            result.success(status())
                        }
                    }
                    "stop" -> { ProximityService.stop(activity, call.argument<Boolean>("forget") == true); result.success(status()) }
                    "takeLaunchPayload" -> {
                        val payload = activity.intent?.getStringExtra("proximity_payload")
                        activity.intent?.removeExtra("proximity_payload")
                        result.success(payload)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) { result.error("proximity_unavailable", e.message ?: "No pudimos activar los avisos.", null) }
        }
    }
    private fun status() = mapOf(
        "supported" to true,
        "enabled" to preferences.getBoolean("enabled", false),
        "running" to ProximityService.running,
        "accountId" to preferences.getString("account", null),
        "count" to ProximityService.parseTargets(preferences.getString("targets", "[]") ?: "[]").size,
        "updatedAt" to preferences.getLong("updatedAt", 0L),
        "precise" to (ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED),
        "always" to (Build.VERSION.SDK_INT < 29 || ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED),
        "notifications" to NotificationManagerCompat.from(activity).areNotificationsEnabled(),
    )
    fun permissionResult(requestCode: Int, grants: IntArray) {
        if (requestCode != REQUEST) return
        notificationRequest?.success(grants.isNotEmpty() && grants[0] == PackageManager.PERMISSION_GRANTED)
        notificationRequest = null
    }
    fun opened(intent: Intent) {
        val payload = intent.getStringExtra("proximity_payload") ?: return
        intent.removeExtra("proximity_payload")
        channel.invokeMethod("opened", payload)
    }
    fun dispose() {
        notificationRequest?.success(false); notificationRequest = null
        channel.setMethodCallHandler(null)
    }
    companion object { const val REQUEST = 7321 }
}
