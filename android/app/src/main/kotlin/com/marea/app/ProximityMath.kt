package com.marea.app

import kotlin.math.*

data class ProximityPlace(val id: String, val title: String, val route: String,
    val latitude: Double, val longitude: Double, val exact: Boolean, val expiresAt: Long? = null) {
    val key get() = route
    fun valid(): Boolean = exact && title.isNotBlank() && title.length <= 120 &&
        ProximityMath.coordinate(latitude, longitude) &&
        Regex("^/(missions/[a-fA-F0-9-]{36}|ar-markers/[a-fA-F0-9-]{36}/scan)$").matches(route) &&
        Regex("^[a-fA-F0-9]{8}(-[a-fA-F0-9]{4}){3}-[a-fA-F0-9]{12}$").matches(id) &&
        route.split('/').getOrNull(2) == id
}
data class ProximitySample(val latitude: Double, val longitude: Double,
    val accuracy: Double, val timestamp: Long)
data class ProximityMemory(var inside: Boolean = false, var notifiedAt: Long? = null)

class ProximityMath {
    val memory = mutableMapOf<String, ProximityMemory>()
    private var lastFix: Long? = null
    fun update(places: List<ProximityPlace>, fix: ProximitySample, now: Long): List<ProximityPlace> {
        if (!coordinate(fix.latitude, fix.longitude) || !fix.accuracy.isFinite() ||
            fix.accuracy < 0 || fix.accuracy > 20 || now < fix.timestamp || now - fix.timestamp > 30000 ||
            lastFix?.let { fix.timestamp < it } == true) return emptyList()
        lastFix = fix.timestamp
        val valid = places.filter { it.valid() && (it.expiresAt == null || now < it.expiresAt) }.distinctBy { it.key }
        memory.keys.retainAll(valid.map { it.key }.toSet())
        return valid.filter { place ->
            val state = memory.getOrPut(place.key) { ProximityMemory() }
            val distance = distance(fix.latitude, fix.longitude, place.latitude, place.longitude)
            if (distance >= 30 - 1e-7) state.inside = false
            if (distance <= 20 + 1e-7 && !state.inside) {
                state.inside = true
                val previous = state.notifiedAt
                if (previous == null || now >= previous && now - previous >= 300000) {
                    state.notifiedAt = now
                    true
                } else false
            } else false
        }
    }
    companion object {
        fun coordinate(lat: Double, lng: Double) = lat.isFinite() && lng.isFinite() && lat in -90.0..90.0 && lng in -180.0..180.0
        fun distance(a: Double, b: Double, c: Double, d: Double): Double {
            val dy = Math.toRadians(c - a); val dx = Math.toRadians(d - b)
            val h = sin(dy / 2).pow(2) + cos(Math.toRadians(a)) * cos(Math.toRadians(c)) * sin(dx / 2).pow(2)
            return 6371000.0 * 2 * asin(sqrt(h.coerceIn(0.0, 1.0)))
        }
    }
}
