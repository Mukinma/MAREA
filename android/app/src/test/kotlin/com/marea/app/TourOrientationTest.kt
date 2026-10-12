package com.marea.app
import org.junit.Test
import org.junit.Assert.*
class TourOrientationTest {
 @Test fun seamUsesShortestRelativeYaw() { assertEquals(2.0, TourOrientation.relative(-179.0,179.0),1e-6) }
 @Test fun cameraDirectionPreservesAbsolutePitchAtPoles() {
  assertEquals(90.0,TourOrientation.pitch(-1.0),1e-6)
  assertEquals(-90.0,TourOrientation.pitch(1.0),1e-6)
  assertEquals(0.0,TourOrientation.pitch(0.0),1e-6)
 }
 @Test fun rotationMatrixLooksAlongNegativeDeviceZ() {
  val r=floatArrayOf(1f,0f,0f,0f,0f,1f,0f,-1f,0f)
  val p=TourOrientation.pose(r)
  assertEquals(180.0,kotlin.math.abs(p[0]),1e-6)
  assertEquals(0.0,p[1],1e-6)
 }
}
