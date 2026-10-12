import Foundation
// CoreMotion's attitude quaternion rotates device vectors into a Z-up reference frame.
// The rear camera optical axis is negative device Z. Pitch remains gravity absolute.
enum TourOrientation {
 static func relative(_ yaw: Double,_ origin: Double)->Double {
  let value=(yaw-origin+180).truncatingRemainder(dividingBy:360)
  return (value<0 ? value+360 : value)-180
 }
 static func pitch(_ cameraZ: Double)->Double { asin(max(-1,min(1,-cameraZ)))*180 / .pi }
 static func pose(x: Double,y: Double,z: Double,w: Double)->(yaw: Double,pitch: Double,roll: Double) {
  let r02=2*(x*z+y*w),r12=2*(y*z-x*w),r22=1-2*(x*x+y*y)
  let r20=2*(x*z-y*w),r21=2*(y*z+x*w)
  return (atan2(-r02,-r12)*180 / .pi,pitch(r22),atan2(r20,r21)*180 / .pi)
 }
}

// Shared by image callbacks and frame updates; a remembered anchor alone is insufficient.
struct TourTrackingState {
 var running=false
 var cameraNormal=false
 func confirmed(imageTracked: Bool,frameNormal: Bool)->Bool {
  running && cameraNormal && frameNormal && imageTracked
 }
}
