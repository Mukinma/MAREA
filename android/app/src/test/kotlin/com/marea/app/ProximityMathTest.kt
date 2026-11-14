package com.marea.app

import org.junit.Assert.*
import org.junit.Test

class ProximityMathTest {
    private val id = "11111111-1111-4111-8111-111111111111"
    private val place = ProximityPlace(id, "Misión", "/missions/$id", 0.0, 0.0, true)
    private fun fix(meters: Double, time: Long = 1000000L, accuracy: Double = 3.0) =
        ProximitySample(Math.toDegrees(meters / 6371000.0), 0.0, accuracy, time)
    @Test fun onlyEntersAtTwentyMetersNotRoundedOutside() {
        val math = ProximityMath()
        assertTrue(math.update(listOf(place), fix(20.1), 1000000).isEmpty())
        assertEquals(1, math.update(listOf(place), fix(20.0), 1000000).size)
        assertTrue(math.update(listOf(place), fix(19.0), 1000000).isEmpty())
    }
    @Test fun rejectsUncertainOldFutureAndInvalidLocations() {
        for (sample in listOf(fix(0.0, accuracy=21.0), fix(0.0, time=969999),
            fix(0.0, time=1000001), ProximitySample(Double.NaN,0.0,1.0,1000000))) {
            assertTrue(ProximityMath().update(listOf(place), sample,1000000).isEmpty())
        }
    }
    @Test fun hysteresisAndCooldownRequireANewVisit() {
        val math=ProximityMath()
        assertEquals(1,math.update(listOf(place),fix(19.0),1000000).size)
        assertTrue(math.update(listOf(place),fix(25.0,1001000),1001000).isEmpty())
        assertTrue(math.update(listOf(place),fix(19.0,1002000),1002000).isEmpty())
        math.update(listOf(place),fix(31.0,1003000),1003000)
        assertTrue(math.update(listOf(place),fix(19.0,1004000),1004000).isEmpty())
        math.update(listOf(place),fix(31.0,1301000),1301000)
        assertEquals(1,math.update(listOf(place),fix(19.0,1302000),1302000).size)
    }
    @Test fun ignoresApproximatePlacesAndUntrustedRoutes() {
        assertFalse(place.copy(exact=false).valid())
        assertFalse(place.copy(route="https://example.com").valid())
        assertFalse(place.copy(route="/missions/22222222-2222-4222-8222-222222222222").valid())
        assertTrue(ProximityMath().update(listOf(place.copy(exact=false)),fix(0.0),1000000).isEmpty())
    }
    @Test fun recognizesMarkersAndWrapsLongitude() {
        val marker=place.copy(route="/ar-markers/$id/scan")
        assertTrue(marker.valid())
        assertEquals(1,ProximityMath().update(listOf(marker),fix(0.0),1000000).size)
        assertTrue(ProximityMath.distance(0.0,179.99999,0.0,-179.99999)<3.0)
    }
    @Test fun expiredMissionsCannotNotifyWhileAppIsClosed() {
        val expires = place.copy(expiresAt=1000000)
        assertTrue(ProximityMath().update(listOf(expires),fix(0.0),1000000).isEmpty())
        assertEquals(1,ProximityMath().update(listOf(expires.copy(expiresAt=1000001)),fix(0.0),1000000).size)
    }
    @Test fun outOfOrderGpsCannotManufactureAnExitAndRepeatNotice() {
        val math=ProximityMath()
        assertEquals(1,math.update(listOf(place),fix(0.0),1000000).size)
        math.update(listOf(place),fix(0.0,1300000),1300000)
        math.update(listOf(place),fix(40.0,1299999),1300000)
        assertTrue(math.update(listOf(place),fix(0.0,1300001),1300001).isEmpty())
    }
}
