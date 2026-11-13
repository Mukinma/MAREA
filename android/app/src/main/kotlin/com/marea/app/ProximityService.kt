package com.marea.app

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.location.*
import android.os.*
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

/** Native location tracking survives closing the Flutter activity. No user tokens or GPS uploads. */
class ProximityService : Service(), LocationListener {
    private val math = ProximityMath()
    private val preferences by lazy { getSharedPreferences(PREFS, Context.MODE_PRIVATE) }
    private val locations by lazy { getSystemService(Context.LOCATION_SERVICE) as LocationManager }
    override fun onCreate() { super.onCreate(); running = true }
    override fun onBind(intent: Intent?) = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!preferences.getBoolean("enabled", false) || !permissions(this)) {
            stopTracking(); return START_NOT_STICKY
        }
        channels(this)
        val foreground = NotificationCompat.Builder(this, SERVICE_CHANNEL)
            .setSmallIcon(R.drawable.ic_marea_notification).setContentTitle("Avisos cercanos de MAREA")
            .setContentText("Ubicación activa para avisarte a 20 metros")
            .setContentIntent(openIntent(this, null, 0)).setOngoing(true)
            .addAction(0, "Detener avisos", PendingIntent.getService(this, 1,
                Intent(this, ProximityStopService::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            .build()
        try {
            startForeground(SERVICE_ID, foreground)
            if (intent?.action != "refresh") {
                locations.removeUpdates(this)
                for (provider in listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER)) {
                    if (locations.allProviders.contains(provider)) locations.requestLocationUpdates(provider, 3000, 2f, this, Looper.getMainLooper())
                }
                restoreMemory()
            }
        } catch (_: SecurityException) { stopTracking(); return START_NOT_STICKY }
        return START_STICKY
    }
    override fun onLocationChanged(location: Location) {
        if (!permissions(this) || !preferences.getBoolean("enabled", false)) { stopTracking(); return }
        val account = preferences.getString("account", null) ?: return
        val places = parseTargets(preferences.getString("targets", "[]") ?: "[]")
        val now = System.currentTimeMillis()
        val entries = math.update(places, ProximitySample(location.latitude, location.longitude,
            if (location.hasAccuracy()) location.accuracy.toDouble() else Double.POSITIVE_INFINITY, location.time), now)
        preferences.edit().putLong("lastFix", now).apply()
        for (place in entries) {
            if (!preferences.getBoolean("enabled", false) || account != preferences.getString("account", null)) return
            val id = noticeId(account, place.key)
            val payload = JSONObject().put("type", "proximity").put("version", 1)
                .put("recipient_id", account).put("target_id", place.id)
                .put("target_kind", if (place.route.startsWith("/missions/")) "mission" else "marker")
                .put("route", place.route).toString()
            val notice = NotificationCompat.Builder(this, NOTICE_CHANNEL)
                .setSmallIcon(R.drawable.ic_marea_notification).setContentTitle(place.title)
                .setContentText("Estás cerca. Toca para explorar en MAREA.")
                .setContentIntent(openIntent(this, payload, id)).setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_HIGH).build()
            NotificationManagerCompat.from(this).notify("proximity:$account", id, notice)
        }
        val states = JSONObject()
        math.memory.forEach { (key, value) -> states.put(key, JSONObject().put("inside", value.inside).put("at", value.notifiedAt ?: 0L)) }
        preferences.edit().putString("memory", states.toString()).apply()
    }
    private fun restoreMemory() {
        math.memory.clear()
        try {
            val states = JSONObject(preferences.getString("memory", "{}") ?: "{}")
            states.keys().forEach { key -> val state = states.getJSONObject(key)
                math.memory[key] = ProximityMemory(state.optBoolean("inside"), state.optLong("at").takeIf { it > 0 }) }
        } catch (_: Exception) { math.memory.clear() }
    }
    private fun stopTracking() {
        preferences.edit().putBoolean("enabled", false).apply()
        stopForeground(STOP_FOREGROUND_REMOVE); stopSelf()
    }
    override fun onDestroy() { running = false; locations.removeUpdates(this); super.onDestroy() }
    override fun onProviderDisabled(provider: String) {}
    override fun onProviderEnabled(provider: String) {}
    @Deprecated("Legacy listener callback") override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
    companion object {
        const val PREFS = "marea.proximity"
        const val SERVICE_CHANNEL = "marea_location_service"
        const val NOTICE_CHANNEL = "marea_nearby"
        const val SERVICE_ID = 1547000000
        @Volatile var running = false
        fun permissions(context: Context): Boolean =
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED &&
            (Build.VERSION.SDK_INT < 29 || ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED) &&
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        fun channels(context: Context) {
            if (Build.VERSION.SDK_INT < 26) return
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(NotificationChannel(SERVICE_CHANNEL, "Seguimiento de ubicación", NotificationManager.IMPORTANCE_LOW))
            manager.createNotificationChannel(NotificationChannel(NOTICE_CHANNEL, "Lugares cercanos", NotificationManager.IMPORTANCE_HIGH))
        }
        fun parseTargets(raw: String): List<ProximityPlace> = try {
            val list = JSONArray(raw)
            (0 until minOf(list.length(), 1000)).mapNotNull { index ->
                val v = list.optJSONObject(index) ?: return@mapNotNull null
                ProximityPlace(v.optString("id"), v.optString("title"), v.optString("route"),
                    v.optDouble("latitude", Double.NaN), v.optDouble("longitude", Double.NaN), v.optBoolean("exact"),
                    if (v.has("expiresAt")) v.optLong("expiresAt") else null)
                    .takeIf { it.valid() }
            }
        } catch (_: Exception) { emptyList() }
        fun noticeId(account: String, key: String) = 0x40000000 or (("$account:$key").hashCode() and 0x0fffffff)
        fun openIntent(context: Context, payload: String?, id: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            if (payload != null) intent.putExtra("proximity_payload", payload)
            return PendingIntent.getActivity(context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
        fun stop(context: Context, forget: Boolean = false) {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val account = prefs.getString("account", "") ?: ""
            val manager = NotificationManagerCompat.from(context)
            parseTargets(prefs.getString("targets", "[]") ?: "[]").forEach { manager.cancel("proximity:$account", noticeId(account, it.key)) }
            if (forget) prefs.edit().clear().apply() else prefs.edit().putBoolean("enabled", false).apply()
            context.stopService(Intent(context, ProximityService::class.java))
        }
    }
}

class ProximityStopService : Service() {
    override fun onBind(intent: Intent?) = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ProximityService.stop(this); stopSelf(); return START_NOT_STICKY
    }
}
