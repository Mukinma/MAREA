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
print("7 orientation checks passed")
