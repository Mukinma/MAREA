package com.marea.app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.BitmapFactory
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.opengl.Matrix
import android.os.Handler
import android.os.Looper
import android.view.View
import com.google.ar.core.*
import io.flutter.plugin.common.*
import io.flutter.plugin.platform.*
import java.nio.ByteBuffer
import java.nio.ByteOrder
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10

class TourAR(private val activity: Activity, messenger: BinaryMessenger) {
 private var sink: EventChannel.EventSink?=null
 private val main=Handler(Looper.getMainLooper())
 private val channel=MethodChannel(messenger,"marea/tour_ar")
 private val events=EventChannel(messenger,"marea/tour_ar/events")
 private val views=mutableSetOf<TourARView>()
 val factory=object: PlatformViewFactory(StandardMessageCodec.INSTANCE) {
  override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
   views.toList().forEach { it.dispose() }
   return TourARView(activity,args as? Map<*,*>,::emit) { views.remove(it) }.also { views.add(it); it.resume() }
  }
 }
 init {
  channel.setMethodCallHandler { call,result ->
   if(call.method=="supported") result.success(ArCoreApk.getInstance().checkAvailability(activity).isSupported) else result.notImplemented()
  }
  events.setStreamHandler(object: EventChannel.StreamHandler {
   override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) { sink=eventSink }
   override fun onCancel(arguments: Any?) { sink=null; pause() }
  })
 }
 private fun emit(value: Map<String,Any>) { main.post { sink?.success(value) } }
 fun pause() { views.toList().forEach { it.pause() } }
 fun resume() { views.toList().forEach { it.resume() } }
 fun dispose() { views.toList().forEach { it.dispose() }; events.setStreamHandler(null); channel.setMethodCallHandler(null); sink=null }
}

class TourARView(private val activity: Activity, private val args: Map<*,*>?, private val emit: (Map<String,Any>)->Unit, private val removed: (TourARView)->Unit): PlatformView, GLSurfaceView.Renderer {
 private val surface=GLSurfaceView(activity)
 private var session: Session?=null
 @Volatile private var disposed=false
 private var permissionAsked=false
 @Volatile private var running=false
 @Volatile private var width=1; @Volatile private var height=1
 private var texture=0; private var background=0; private var signal=0
 private val states=mutableMapOf<String,String>()
 private val anchors=mutableMapOf<String,Anchor>()
 private val points=floatArrayOf(-1f,-1f,1f,-1f,-1f,1f,1f,1f)
 init { surface.setEGLContextClientVersion(2); surface.preserveEGLContextOnPause=false; surface.setRenderer(this); surface.renderMode=GLSurfaceView.RENDERMODE_CONTINUOUSLY }
 override fun getView(): View=surface
 private fun reportError(message: String) { emit(mapOf("id" to "","state" to "error","message" to message)) }
 fun resume() {
  if(disposed || running) return
  if(activity.checkSelfPermission(Manifest.permission.CAMERA)!=PackageManager.PERMISSION_GRANTED) {
   if(!permissionAsked) { permissionAsked=true; activity.requestPermissions(arrayOf(Manifest.permission.CAMERA),360) }
   else reportError("Permite el acceso a cámara para usar AR; puedes continuar con la lista.")
   return
  }
  try {
   if(session==null) {
    if(ArCoreApk.getInstance().requestInstall(activity,true)==ArCoreApk.InstallStatus.INSTALL_REQUESTED) return
    val created=Session(activity)
    try {
     val database=AugmentedImageDatabase(created)
     val refs=args?.get("references") as? List<*> ?: error("No hay imágenes de referencia.")
     require(refs.isNotEmpty())
     for(raw in refs) {
      val ref=raw as Map<*,*>
      val id=ref["id"] as String; val path=ref["path"] as String; val size=(ref["widthMeters"] as Number).toFloat()
      require(size.isFinite() && size>0)
      val bitmap=BitmapFactory.decodeFile(path) ?: error("No pudimos leer la referencia.")
      try { database.addImage(id,bitmap,size) } finally { bitmap.recycle() }
     }
     val config=Config(created); config.augmentedImageDatabase=database; config.focusMode=Config.FocusMode.AUTO
     created.configure(config); session=created
    } catch(e: Exception) { created.close(); throw e }
   }
   session!!.resume(); running=true; surface.onResume()
  } catch(e: Exception) { reportError(e.message ?: "AR no está disponible."); pause() }
 }
 fun pause() {
  if(!running) return
  running=false; surface.onPause(); session?.pause()
  states.filterValues { it=="tracking" }.keys.toList().forEach { setState(it,"lost") }
 }
 override fun dispose() {
  if(disposed) return
  pause(); disposed=true; anchors.values.forEach { it.detach() }; anchors.clear(); session?.close(); session=null
  // The EGL context is destroyed on pause, releasing its textures/programs.
  removed(this)
 }
 private fun setState(id: String,state: String) { if(states[id]!=state) { states[id]=state; emit(mapOf("id" to id,"state" to state)) } }
 override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
  val ids=IntArray(1); GLES20.glGenTextures(1,ids,0); texture=ids[0]
  GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,texture)
  GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,GLES20.GL_TEXTURE_MIN_FILTER,GLES20.GL_LINEAR)
  GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,GLES20.GL_TEXTURE_MAG_FILTER,GLES20.GL_LINEAR)
  GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,GLES20.GL_TEXTURE_WRAP_S,GLES20.GL_CLAMP_TO_EDGE)
  GLES20.glTexParameteri(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,GLES20.GL_TEXTURE_WRAP_T,GLES20.GL_CLAMP_TO_EDGE)
  background=program("attribute vec2 p; attribute vec2 uv; varying vec2 t; void main(){t=uv;gl_Position=vec4(p,0.,1.);}","#extension GL_OES_EGL_image_external : require\nprecision mediump float; uniform samplerExternalOES image; varying vec2 t; void main(){gl_FragColor=texture2D(image,t);}")
  signal=program("attribute vec3 p; uniform mat4 m; void main(){gl_Position=m*vec4(p,1.);}","precision mediump float; void main(){gl_FragColor=vec4(0.1,0.9,0.65,1.);}")
 }
 override fun onSurfaceChanged(gl: GL10?,w: Int,h: Int) { width=w; height=h; GLES20.glViewport(0,0,w,h) }
 override fun onDrawFrame(gl: GL10?) {
  GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT or GLES20.GL_DEPTH_BUFFER_BIT)
  if(!running || disposed) return
  val current=session ?: return
  try {
   current.setCameraTextureName(texture); current.setDisplayGeometry(activity.windowManager.defaultDisplay.rotation,width,height)
   val frame=current.update()
   if(frame.timestamp==0L) return
   val uv=FloatArray(8); frame.transformCoordinates2d(Coordinates2d.OPENGL_NORMALIZED_DEVICE_COORDINATES,points,Coordinates2d.TEXTURE_NORMALIZED,uv)
   GLES20.glDisable(GLES20.GL_DEPTH_TEST); GLES20.glUseProgram(background)
   attribute(background,"p",2,points); attribute(background,"uv",2,uv)
   GLES20.glActiveTexture(GLES20.GL_TEXTURE0); GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES,texture)
   GLES20.glUniform1i(GLES20.glGetUniformLocation(background,"image"),0); GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP,0,4)
   for(image in current.getAllTrackables(AugmentedImage::class.java)) {
    val tracked=frame.camera.trackingState==TrackingState.TRACKING && image.trackingState==TrackingState.TRACKING && image.trackingMethod==AugmentedImage.TrackingMethod.FULL_TRACKING
    setState(image.name,if(tracked) "tracking" else "lost")
    if(tracked) {
     val anchor=anchors.getOrPut(image.name) { image.createAnchor(image.centerPose) }
     val model=FloatArray(16); val view=FloatArray(16); val projection=FloatArray(16); val mv=FloatArray(16); val mvp=FloatArray(16)
     anchor.pose.toMatrix(model,0); frame.camera.getViewMatrix(view,0); frame.camera.getProjectionMatrix(projection,0,0.05f,100f)
     Matrix.multiplyMM(mv,0,view,0,model,0); Matrix.multiplyMM(mvp,0,projection,0,mv,0)
     GLES20.glUseProgram(signal); GLES20.glUniformMatrix4fv(GLES20.glGetUniformLocation(signal,"m"),1,false,mvp,0)
     val radius=image.extentX*.15f
     attribute(signal,"p",3,floatArrayOf(-radius,.005f,-radius,radius,.005f,-radius,-radius,.005f,radius,radius,.005f,radius))
     GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP,0,4)
    }
   }
  } catch(e: Exception) { if(running) { Handler(Looper.getMainLooper()).post { pause(); reportError(e.message ?: "Se interrumpió la cámara AR.") } } }
 }
 private fun attribute(program: Int,name: String,size: Int,values: FloatArray) {
  val buffer=ByteBuffer.allocateDirect(values.size*4).order(ByteOrder.nativeOrder()).asFloatBuffer(); buffer.put(values).position(0)
  val location=GLES20.glGetAttribLocation(program,name); GLES20.glEnableVertexAttribArray(location); GLES20.glVertexAttribPointer(location,size,GLES20.GL_FLOAT,false,0,buffer)
 }
 private fun program(vertex: String,fragment: String): Int {
  fun shader(type: Int,source: String): Int { val shader=GLES20.glCreateShader(type); GLES20.glShaderSource(shader,source); GLES20.glCompileShader(shader); val status=IntArray(1); GLES20.glGetShaderiv(shader,GLES20.GL_COMPILE_STATUS,status,0); check(status[0]!=0) { GLES20.glGetShaderInfoLog(shader) }; return shader }
  val v=shader(GLES20.GL_VERTEX_SHADER,vertex); val f=shader(GLES20.GL_FRAGMENT_SHADER,fragment); val p=GLES20.glCreateProgram(); GLES20.glAttachShader(p,v); GLES20.glAttachShader(p,f); GLES20.glLinkProgram(p); GLES20.glDeleteShader(v); GLES20.glDeleteShader(f); return p
 }
}
