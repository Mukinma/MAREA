package com.marea.app

import org.junit.Assert.*
import org.junit.Test

class TourProjectionFramesTest {
 @Test fun cachedAndOlderFramesCannotRefreshTracking() {
  val frames=TourProjectionFrames()
  assertFalse(frames.advance(0))
  assertTrue(frames.advance(100))
  repeat(20) { assertFalse(frames.advance(100)) }
  assertFalse(frames.advance(99))
  assertTrue(frames.advance(101))
 }

 @Test fun eachNewNativeScanOwnsItsFrameClock() {
  val previous=TourProjectionFrames()
  assertTrue(previous.advance(500))
  val current=TourProjectionFrames()
  assertTrue(current.advance(1))
  assertFalse(previous.advance(500))
  assertFalse(current.advance(1))
  assertTrue(current.advance(2))
 }
}
