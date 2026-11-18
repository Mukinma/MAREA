import Foundation
func close(_ a: Double,_ b: Double) { precondition(abs(a-b)<0.000001,"Expected \(b), got \(a)") }
close(TourOrientation.relative(-179,179),2)
close(TourOrientation.pitch(-1),90)
close(TourOrientation.pitch(1),-90)
close(TourOrientation.pitch(0),0)
// CoreMotion quaternion device -> Z-up reference: camera looks along negative Z.
let horizon=TourOrientation.pose(x: sqrt(0.5),y:0,z:0,w:sqrt(0.5))
close(horizon.pitch,0)
close(TourOrientation.pose(x:0,y:0,z:0,w:1).pitch,-90)
close(TourOrientation.pose(x:1,y:0,z:0,w:0).pitch,90)
for pitch in [-90.0,-89.5,89.5,90.0] {
 precondition(TourOrientation.headingOrigin(nil,yaw:137,pitch:pitch)==nil)
}
let establishedOrigin=TourOrientation.headingOrigin(nil,yaw:42,pitch:86)
precondition(establishedOrigin != nil)
close(establishedOrigin!,42)
close(TourOrientation.relative(42,establishedOrigin!),0)
for pitch in [-90.0,90.0,0.0] {
 close(TourOrientation.headingOrigin(establishedOrigin,yaw:97,pitch:pitch)!,42)
}
print("17 orientation checks passed")
