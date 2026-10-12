package com.marea.app

import android.app.Activity
import android.content.Context
import android.hardware.*
import android.hardware.camera2.*
import android.graphics.ImageFormat
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.*
import kotlin.math.*

object TourOrientation {
 fun relative(yaw: Double, origin: Double) = ((yaw-origin+540)%360)-180
 fun pitch(cameraZ: Double) = Math.toDegrees(asin((-cameraZ).coerceIn(-1.0,1.0)))
 fun pose(r: FloatArray): DoubleArray = doubleArrayOf(Math.toDegrees(atan2(-r[2].toDouble(),-r[5].toDouble())),pitch(r[8].toDouble()),Math.toDegrees(atan2(r[6].toDouble(),r[7].toDouble())))
}

class TourNative(private val activity: Activity, messenger: BinaryMessenger) : SensorEventListener {
 private val sensors = activity.getSystemService(Context.SENSOR_SERVICE) as SensorManager
 private val sensor = sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
 private var sink: EventChannel.EventSink? = null
 private var origin: Double? = null
 private var started = false
 private val method = MethodChannel(messenger,"marea/tour_motion")
 private val events = EventChannel(messenger,"marea/tour_motion/events")
 val ar = TourAR(activity,messenger)
 init {
  events.setStreamHandler(object: EventChannel.StreamHandler {
   override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink) { sink=eventSink }
   override fun onCancel(arguments: Any?) { sink=null; stop() }
  })
  method.setMethodCallHandler { call,result ->
   when(call.method) {
    "start" -> if(sensor==null) result.error("motion_unavailable","Este dispositivo no ofrece orientación de cámara.",null) else {
     stop(); origin=null; started=sensors.registerListener(this,sensor,SensorManager.SENSOR_DELAY_GAME)
     if(started) result.success(null) else result.error("motion_unavailable","No pudimos iniciar el sensor.",null)
    }
    "stop" -> { stop(); result.success(null) }
    "cameraInfo" -> try { result.success(cameraInfo(call.argument<String>("cameraName"),call.argument<Number>("imageWidth"),call.argument<Number>("imageHeight"))) } catch(e: Exception) { result.error("camera_info_unavailable",e.message,null) }
    else -> result.notImplemented()
   }
  }
 }
 private fun cameraInfo(name: String?, imageWidth: Number?, imageHeight: Number?): Map<String,Any> {
  val manager=activity.getSystemService(Context.CAMERA_SERVICE) as CameraManager
  require(name!=null && name in manager.cameraIdList) { "No hay datos de la cámara seleccionada." }
  val c=manager.getCameraCharacteristics(name)
  require(c.get(CameraCharacteristics.LENS_FACING)==CameraCharacteristics.LENS_FACING_BACK) { "Selecciona la cámara posterior." }
  val rotation=c.get(CameraCharacteristics.SENSOR_ORIENTATION)
  require(rotation==90 || rotation==270) { "La orientación de esta lente no admite calibración fiable en retrato." }
  val focals=c.get(CameraCharacteristics.LENS_INFO_AVAILABLE_FOCAL_LENGTHS) ?: error("Distancia focal no disponible.")
  require(focals.size==1 && focals[0]>0) { "Esta cámara combina lentes; selecciona la cámara principal física a 1×." }
  val focal=focals[0].toDouble()
  val sensor=c.get(CameraCharacteristics.SENSOR_INFO_PHYSICAL_SIZE) ?: error("Tamaño del sensor no disponible.")
  val pixel=c.get(CameraCharacteristics.SENSOR_INFO_PIXEL_ARRAY_SIZE) ?: error("Resolución no disponible.")
  val active=c.get(CameraCharacteristics.SENSOR_INFO_ACTIVE_ARRAY_SIZE) ?: error("Área activa no disponible.")
  val width=imageWidth?.toInt() ?: error("Captura una fotografía de calibración para medir su campo de visión.")
  val height=imageHeight?.toInt() ?: error("Falta la altura de la fotografía de calibración.")
  require(width>0 && height>0 && width<=height) { "Se requieren dimensiones reales en retrato." }
  val sw=sensor.width*active.width()/pixel.width.toDouble()
  val sh=sensor.height*active.height()/pixel.height.toDouble()
  val aspect=height.toDouble()/width
  var w=max(sw,sh); var h=min(sw,sh)
  if(w/h>aspect) w=h*aspect else h=w/aspect
  return mapOf("hfov" to Math.toDegrees(2*atan(h/(2*focal))),"vfov" to Math.toDegrees(2*atan(w/(2*focal))),"aspectRatio" to 1/aspect,"cameraName" to name,"width" to width,"height" to height)
 }
 override fun onSensorChanged(event: SensorEvent) {
  if(!started) return
  val r=FloatArray(9); SensorManager.getRotationMatrixFromVector(r,event.values)
  val pose=TourOrientation.pose(r)
  // At the poles azimuth is undefined: keep the previous yaw origin rather than resetting pitch.
  if(origin==null && abs(pose[1])<89.5) origin=pose[0]
  sink?.success(mapOf("yaw" to TourOrientation.relative(pose[0],origin ?: pose[0]),"pitch" to pose[1],"roll" to pose[2],"timestamp" to System.currentTimeMillis()))
 }
 override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
 fun stop() { started=false; sensors.unregisterListener(this) }
 fun pause() { stop(); ar.pause() }
 fun resume() { ar.resume() }
 fun permissionResult() { ar.resume() }
 fun dispose() { pause(); ar.dispose(); method.setMethodCallHandler(null); events.setStreamHandler(null); sink=null }
}
