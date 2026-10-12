import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var tours: TourNative?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MareaTours") { tours = TourNative(registrar: registrar) }
  }
}

import CoreMotion
import AVFoundation
import ARKit
import SceneKit

final class TourEventStream: NSObject, FlutterStreamHandler {
 var sink: FlutterEventSink?
 var cancel: (() -> Void)?
 func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)->FlutterError? { sink=events; return nil }
 func onCancel(withArguments arguments: Any?)->FlutterError? { sink=nil; cancel?(); return nil }
 func emit(_ data: [String:Any]) { DispatchQueue.main.async { [weak self] in self?.sink?(data) } }
}

final class TourNative: NSObject {
 private let motion=CMMotionManager()
 private let motionEvents=TourEventStream()
 fileprivate let arEvents=TourEventStream()
 private var origin: Double?
 private var observers=[NSObjectProtocol]()
 fileprivate weak var arView: TourARView?
 init(registrar: FlutterPluginRegistrar) {
  super.init()
  let messenger=registrar.messenger()
  FlutterEventChannel(name:"marea/tour_motion/events",binaryMessenger:messenger).setStreamHandler(motionEvents)
  FlutterEventChannel(name:"marea/tour_ar/events",binaryMessenger:messenger).setStreamHandler(arEvents)
  motionEvents.cancel={ [weak self] in self?.motion.stopDeviceMotionUpdates() }
  arEvents.cancel={ [weak self] in self?.arView?.pause() }
  FlutterMethodChannel(name:"marea/tour_motion",binaryMessenger:messenger).setMethodCallHandler { [weak self] call,result in
   guard let self=self else { result(FlutterError(code:"unavailable",message:"La sesión finalizó.",details:nil)); return }
   switch call.method {
   case "start":
    guard self.motion.isDeviceMotionAvailable else { result(FlutterError(code:"motion_unavailable",message:"Orientación no disponible. Puedes importar un panorama.",details:nil)); return }
    self.motion.stopDeviceMotionUpdates(); self.origin=nil; self.motion.deviceMotionUpdateInterval=1.0/30
    self.motion.startDeviceMotionUpdates(using:.xArbitraryZVertical,to:.main) { [weak self] reading,error in
     guard let self=self else { return }
     guard let reading=reading else { self.motionEvents.sink?(FlutterError(code:"motion_unavailable",message:error?.localizedDescription,details:nil)); return }
     let q=reading.attitude.quaternion
     // CoreMotion DCM maps reference vectors into device coordinates; invert
     // its quaternion to transform the rear-camera optical axis into the world.
     let pose=TourOrientation.pose(x:-q.x,y:-q.y,z:-q.z,w:q.w)
     if self.origin==nil && abs(pose.pitch)<89.5 { self.origin=pose.yaw }
     self.motionEvents.emit(["yaw":TourOrientation.relative(pose.yaw,self.origin ?? pose.yaw),"pitch":pose.pitch,"roll":pose.roll,"timestamp":Date().timeIntervalSince1970*1000])
    }; result(nil)
   case "stop": self.motion.stopDeviceMotionUpdates(); result(nil)
   case "cameraInfo": self.cameraInfo(call.arguments,result)
   default: result(FlutterMethodNotImplemented)
   }
  }
  FlutterMethodChannel(name:"marea/tour_ar",binaryMessenger:messenger).setMethodCallHandler { call,result in
   if call.method=="supported" { result(ARImageTrackingConfiguration.isSupported) } else { result(FlutterMethodNotImplemented) }
  }
  registrar.register(TourARFactory(owner:self),withId:"marea/tour_ar_view")
  observers.append(NotificationCenter.default.addObserver(forName:UIApplication.willResignActiveNotification,object:nil,queue:.main) { [weak self] _ in self?.motion.stopDeviceMotionUpdates(); self?.arView?.pause() })
  observers.append(NotificationCenter.default.addObserver(forName:UIApplication.didBecomeActiveNotification,object:nil,queue:.main) { [weak self] _ in self?.arView?.resume() })
 }
 deinit { motion.stopDeviceMotionUpdates(); observers.forEach { NotificationCenter.default.removeObserver($0) }; arView?.pause() }
 private func cameraInfo(_ arguments: Any?,_ result: FlutterResult) {
  guard let args=arguments as? [String:Any],let name=args["cameraName"] as? String,
   let width=(args["imageWidth"] as? NSNumber)?.doubleValue,let height=(args["imageHeight"] as? NSNumber)?.doubleValue,width>0,height>=width else {
   result(FlutterError(code:"camera_info_unavailable",message:"Se requiere una fotografía de calibración en retrato.",details:nil)); return
  }
  let devices=AVCaptureDevice.DiscoverySession(deviceTypes:[.builtInWideAngleCamera],mediaType:.video,position:.back).devices
  guard let device=devices.first(where:{$0.uniqueID==name}) else { result(FlutterError(code:"camera_info_unavailable",message:"No encontramos la cámara posterior principal seleccionada.",details:nil)); return }
  let format=device.activeFormat
  let dimensions=CMVideoFormatDescriptionGetDimensions(format.formatDescription)
  let horizontal=Double(format.videoFieldOfView)*Double.pi/180
  guard horizontal>0,horizontal<Double.pi,dimensions.width>0,dimensions.height>0,abs(device.videoZoomFactor-1)<0.01 else { result(FlutterError(code:"camera_info_unavailable",message:"No hay campo de visión fiable para la lente a 1×.",details:nil)); return }
  // videoFieldOfView is horizontal in landscape activeFormat. Derive equivalent
  // full photo aperture using the calibrated JPEG aspect (photos may be 4:3).
  let halfWidth=tan(horizontal/2)
  let landscapeAspect=height/width
  let vfov=horizontal*180/Double.pi
  let hfov=2*atan(halfWidth/landscapeAspect)*180/Double.pi
  result(["hfov":hfov,"vfov":vfov,"aspectRatio":width/height,"width":width,"height":height,"cameraName":name])
 }
}

final class TourARFactory: NSObject, FlutterPlatformViewFactory {
 private let owner: TourNative
 init(owner: TourNative) { self.owner=owner }
 func createArgsCodec()->FlutterMessageCodec & NSObjectProtocol { FlutterStandardMessageCodec.sharedInstance() }
 func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?)->FlutterPlatformView {
  owner.arView?.pause()
  let view=TourARView(frame:frame,args:args,events:owner.arEvents)
  owner.arView=view; view.resume(); return view
 }
}

final class TourARView: NSObject, FlutterPlatformView, ARSCNViewDelegate {
 private let scene: ARSCNView
 private let events: TourEventStream
 private var configuration: ARImageTrackingConfiguration?
 private var states=[String:Bool]()
 private let stateLock=NSRecursiveLock()
 private var trackingState=TourTrackingState()
 private var cameraNormal: Bool { get { trackingState.cameraNormal } set { trackingState.cameraNormal=newValue } }
 private var minimumFrameTimestamp: TimeInterval=0
 private var signals=[UUID:(id:String,node:SCNNode,imageTracked:Bool)]()
 private var running: Bool { get { trackingState.running } set { trackingState.running=newValue } }
 private var permissionPending=false
 private var invalid=false
 init(frame: CGRect,args: Any?,events: TourEventStream) {
  scene=ARSCNView(frame:frame); self.events=events
  super.init(); scene.delegate=self; scene.automaticallyUpdatesLighting=true
  guard ARImageTrackingConfiguration.isSupported else { fail("AR no está disponible en este dispositivo."); return }
  guard let args=args as? [String:Any],let references=args["references"] as? [[String:Any]], !references.isEmpty else { fail("No hay imágenes de referencia."); return }
  var images=Set<ARReferenceImage>()
  for ref in references {
   guard let id=ref["id"] as? String,let path=ref["path"] as? String,let width=(ref["widthMeters"] as? NSNumber)?.doubleValue,width.isFinite,width>0,
    let source=UIImage(contentsOfFile:path),let cg=source.cgImage else { fail("No pudimos leer la imagen de referencia."); return }
   let image=ARReferenceImage(cg,orientation:.up,physicalWidth:CGFloat(width)); image.name=id; images.insert(image)
  }
  let config=ARImageTrackingConfiguration(); config.trackingImages=images; config.maximumNumberOfTrackedImages=min(images.count,4); configuration=config
 }
 func view()->UIView { scene }
 func resume() {
  stateLock.lock(); defer { stateLock.unlock() }
  guard !running,!invalid,let configuration=configuration else { return }
  switch AVCaptureDevice.authorizationStatus(for:.video) {
  case .authorized:
   minimumFrameTimestamp=scene.session.currentFrame?.timestamp ?? 0
   cameraNormal=false; running=true; updateSignalsLocked()
   scene.session.run(configuration,options:[.resetTracking,.removeExistingAnchors])
  case .notDetermined:
   guard !permissionPending else { return }; permissionPending=true
   AVCaptureDevice.requestAccess(for:.video) { [weak self] granted in DispatchQueue.main.async { guard let self=self else { return }; self.permissionPending=false; if granted { self.resume() } else { self.fail("Permite el acceso a cámara para usar AR. Puedes consultar la lista.") } } }
  default: fail("Permite el acceso a cámara para usar AR. Puedes consultar la lista.")
  }
 }
 func pause() {
  stateLock.lock(); running=false; cameraNormal=false; updateSignalsLocked(); stateLock.unlock()
  scene.session.pause()
 }
 private func validCamera(_ frame: ARFrame?)->Bool {
  guard let frame=frame,frame.timestamp>minimumFrameTimestamp else { return false }
  if case .normal = frame.camera.trackingState { return true }; return false
 }
 private func updateSignalsLocked() {
  for signal in signals.values {
   let confirmed=trackingState.confirmed(imageTracked:signal.imageTracked,frameNormal:validCamera(scene.session.currentFrame))
   signal.node.isHidden = !confirmed
   emit(signal.id,confirmed)
  }
 }
 private func updateSignal(_ node: SCNNode,_ image: ARImageAnchor) {
  guard let id=image.referenceImage.name else { node.isHidden=true; return }
  stateLock.lock(); defer { stateLock.unlock() }
  signals[image.identifier]=(id,node,image.isTracked)
  updateSignalsLocked()
 }
 private func fail(_ message: String) { invalid=true; pause(); events.emit(["id":"","state":"error","message":message]) }
 private func emit(_ id: String,_ tracking: Bool) { stateLock.lock(); let changed=states[id] != tracking; states[id]=tracking; stateLock.unlock(); if changed { events.emit(["id":id,"state":tracking ? "tracking" : "lost"]) } }
 func renderer(_ renderer: SCNSceneRenderer,nodeFor anchor: ARAnchor)->SCNNode? {
  guard let image=anchor as? ARImageAnchor else { return nil }
  let node=SCNNode(); let shape=SCNPlane(width:image.referenceImage.physicalSize.width*0.3,height:image.referenceImage.physicalSize.height*0.3)
  shape.firstMaterial?.diffuse.contents=UIColor.systemMint; shape.firstMaterial?.isDoubleSided=true
  let signal=SCNNode(geometry:shape); signal.eulerAngles.x = -.pi/2; signal.position.y=0.005; node.addChildNode(signal)
  updateSignal(node,image); return node
 }
 func renderer(_ renderer: SCNSceneRenderer,didUpdate node: SCNNode,for anchor: ARAnchor) {
  guard let image=anchor as? ARImageAnchor else { return }
  updateSignal(node,image)
 }
 func renderer(_ renderer: SCNSceneRenderer,didRemove node: SCNNode,for anchor: ARAnchor) {
  guard let image=anchor as? ARImageAnchor,let id=image.referenceImage.name else { return }
  stateLock.lock(); defer { stateLock.unlock() }
  node.isHidden=true; signals.removeValue(forKey:image.identifier); emit(id,false)
 }
 // ARSCNView forwards ARSessionObserver methods to its view delegate. It
 // retains its own session delegate for rendering; do not replace that delegate.
 func session(_ session: ARSession,cameraDidChangeTrackingState camera: ARCamera) {
  stateLock.lock(); defer { stateLock.unlock() }
  if case .normal = camera.trackingState { cameraNormal=true } else { cameraNormal=false }
  let images=Dictionary(uniqueKeysWithValues:(session.currentFrame?.anchors ?? []).compactMap { anchor -> (UUID,Bool)? in
   guard let image=anchor as? ARImageAnchor else { return nil }; return (image.identifier,image.isTracked)
  })
  for (key,var signal) in signals { signal.imageTracked=images[key] ?? false; signals[key]=signal }
  updateSignalsLocked()
 }
 func session(_ session: ARSession,didFailWithError error: Error) { DispatchQueue.main.async { [weak self] in self?.fail(error.localizedDescription) } }
 func sessionWasInterrupted(_ session: ARSession) { DispatchQueue.main.async { [weak self] in self?.pause() } }
 deinit { scene.session.pause(); scene.delegate=nil }
}
