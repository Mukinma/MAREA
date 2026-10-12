import Foundation
var state=TourTrackingState()
state.running=true
state.cameraNormal=true
precondition(state.confirmed(imageTracked:true,frameNormal:true))
// Image update followed by camera loss hides the same signal.
state.cameraNormal=false
precondition(!state.confirmed(imageTracked:true,frameNormal:false))
// A late image update after camera loss cannot reconfirm it.
precondition(!state.confirmed(imageTracked:true,frameNormal:true))
state.cameraNormal=true
precondition(state.confirmed(imageTracked:true,frameNormal:true))
// Pause wins over later image/camera callbacks.
state.running=false
precondition(!state.confirmed(imageTracked:true,frameNormal:true))
state.cameraNormal=false
state.cameraNormal=true
precondition(!state.confirmed(imageTracked:true,frameNormal:true))
// Resume waits for fresh camera validity and current reference tracking.
state.running=true
precondition(!state.confirmed(imageTracked:true,frameNormal:false))
precondition(!state.confirmed(imageTracked:false,frameNormal:true))
print("8 callback-order tracking checks passed")
