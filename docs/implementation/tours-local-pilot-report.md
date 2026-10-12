# Piloto local de recorridos360° — 6 octubre2026

Este reporte distingue Supabase desplegado, Docker local y Cloud Run pendiente. No se instaló ni ejecutó MAREA en teléfonos. Los resultados de cosido proceden de fixtures geométricos sintéticos y no acreditan captura óptica ni reconocimiento AR físico.

## 1. Completado y verificado automáticamente

**Piloto aprobado para procesamiento software local contra Supabase real.** La imagen final `linux/amd64` es `sha256:c5915bcde169804be9899c0f7420d13bddf7afb9d12819a5300efe557b04e04c`, registrada con herramientas/dependencias y evidencia en [pilot-image.json](../../processing/tours/pilot-image.json). Ejecutó realmente cpfind, cpclean, autooptimiser, pano_modify, nona y Enblend sobre26 fotografías sintéticas. Produjo panorama4096×2048, preview2048×1024 y miniatura512×256 con GPano. Tiempo del worker162.279s; ejecución local total166.751s, exit0 y recibo `ready` confirmado en Supabase.

| Verificación | Resultado |
|---|---|
| Supabase alojado |57 comprobaciones aprobadas: TUS interrumpido/reanudado con hash idéntico, originales privados, captura inmutable, dos leases y contenedores simultáneos, límite global, cancelación, respuesta duplicada/perdida, recaptura, recovery, reintento, autorización administrativa, publicación, recursos de visitantes, progreso privado y eliminación durante escritura. |
| Lease de limpieza alojado |8 comprobaciones aprobadas: servicio autorizado, usuario rechazado, renovación vigente, expiración, token sustituido y eliminación del fixture. |
| Herramientas Docker, casos negativos | Sin techo rechazado como `incomplete_sphere_coverage` en64.433s; sin coincidencias rechazado como `disconnected_control_points` en2.053s. JPEG2:1 corriente rechazado con `gpano_full_sphere_required` en el pipeline alojado. |
| Flutter | Análisis sin incidencias;459 tests aprobados. APK debug, iOS debug sin firma y web compilados con configuración del proyecto. |
| Backend |25 tests Python,90 contratos SQL,15 migraciones/17 flags del catálogo,12 tests del gate remoto,6 del dispatcher y3 de limpieza recursiva aprobados; Deno check y gate remoto aprobados. |
| Nativo, sin hardware |3 tests Android;7 comprobaciones matemáticas Swift y8 de orden de callbacks. No acreditan cámara ni tracking físico. |
| Visor | Panorama de la imagen final abierto en widgets reales del recorrido, navegación A→B→A y detalle/regreso; revisión visual a320px. |

Los archivos de evidencia están en [output/tours-pilot](../../output/tours-pilot/): `final-live.log`, `live-result.json`, `cleanup-lease-result.json`, `final-incomplete/result.json`, `final-blank/result.json`, `final-python-tests.log`, logs de análisis/builds y `remote-final-state.json`. La consulta final confirmó cero cuentas temporales, trabajos, recorridos y objetos de tours tras limpiar los recursos propios. También se retiraron175 objetos de ejecuciones previas fallidas, únicamente bajo IDs de checkpoints de cuentas temporales ya eliminadas.

Se corrigieron fallos demostrados: Enblend4.2 sufría SIGSEGV al optimizar costuras; se usa `--no-optimize` conservando mezcla y validación estricta de cobertura. PostgREST204 ya no se intenta decodificar como JSON. Una descarga parcial interrumpida se clasifica como error transitorio y cierra su respuesta. GC verifica/renueva su lease antes de borrar, rechazando tokens vencidos. La función de eliminación desplegada inicialmente conservaba la versión anterior; se volvió a desplegar y recuperar su fuente para confirmar la limpieza anidada, y después pasó la prueba real. El futuro upload Google rechaza una imagen cuyo ID difiera del registro validado antes de llamar a Google.

El visor utiliza una copia offline del JSON público y del panorama recuperados durante el piloto, porque sus cuentas temporales se eliminan al finalizar. El acceso a recursos publicados y el aislamiento se comprobaron por HTTP autenticado real antes de esa eliminación. [Reproducir pruebas y visor](../../processing/tours/README.md).

![Visor real a320px con panorama de fixture sintético](../../output/tours-pilot/viewer-320.jpg)

El ejecutor [local_runner.py](../../processing/tours/local_runner.py) usa los RPC existentes y ofrece `--once`/`--watch`, máximo dos leases globales, contenedores4CPU/8Gi nominales, plazo900s y verificación del recibo de Supabase. Un exit0 sin recibo confirmado se reporta como no listo; el caso negativo de GPano comprobó precisamente esa situación.

Entorno local preparado: `.venv-tours` con Python3.12.14 y `config/.env.tours-local`, ignorado y0600. Credenciales de servicio exclusivas del procesador; Flutter conserva su configuración pública. Mantener el procesamiento activo:

```bash
cd /Users/crisis/Proyectos/marea
.venv-tours/bin/python processing/tours/local_runner.py --watch
```

El ejecutor no queda activo en segundo plano: abrir esa terminal cuando se pruebe la app. Ctrl+C detiene las ejecuciones propias; recovery/GC usa leases y guardas de Storage. Mac apagado o ejecutor detenido significa cola pendiente. Docker Desktop dispone de aproximadamente7.65Gi totales compartidos: los límites8Gi por contenedor no garantizan dos cargas máximas simultáneas; aumentar asignación a16Gi antes de exigir esa capacidad.

## 2. Desplegado en servicios reales

Supabase `alxdipzfunbpaywmpndi`: aplicada únicamente015 tras dry-run exclusivo; historial001–015 comprobado y gate remoto aprobado. Buckets `tour-inputs`/`tour-assets` privados. `delete-account` actualizado conservando autenticación JWT; `tour-dispatch` desplegado con secreto servidor.

Se aplicó además el correctivo aditivo [repair-cleanup-lease.sql](../../supabase/tours/repair-cleanup-lease.sql), también incluido al final de015 para instalaciones nuevas: añade `tours_renew_cleanup`, exclusivamente para `service_role`. No se aplicó otra migración numerada. Runner/dispatcher usan esta RPC; sus permisos y expiración se comprobaron contra Supabase real.

Dispatcher:401 sin autorización;503 `tours_not_configured` con secreto válido y Google pendiente, antes de reclamar trabajos. No hay secretos de tours en Vault ni cron de tours. `marea-push-minute` continúa activo y su configuración no se modificó. Docker ejecuta el procesador local; no es despliegue Cloud Run.

## 3. Pendiente por credenciales/permisos

Google billing sigue pendiente de verificación del usuario; `gcloud` no está instalado/autenticado en este equipo. Cloud Run `marea-f6a92/us-central1/marea-tour-stitch`, IAM, Secret Manager, Artifact Registry y alertas quedan preparados mediante scripts, sin ejecutar operaciones Google. Ver [traspaso reproducible](../../processing/tours/README.md#traspaso-posterior-a-cloud-run-pendiente-no-ejecutado): detener runner, verificar facturación/permisos, subir la misma imagen, configurar secretos/cuentas, desplegar, verificar un trabajo real y entonces activar Vault/cron.

iOS todavía no tiene equipo de firma. Abrir `ios/Runner.xcworkspace`, seleccionar Runner → Signing & Capabilities, habilitar firma automática y escoger tu equipo Apple. Mantener `com.marea.app` salvo conflicto indicado por Xcode. [Configuración oficial](https://docs.flutter.dev/platform-integration/ios/setup).

## 4. Pendiente exclusivamente de prueba física

Capturas reales de celular, calidad de costuras y calibración/FOV; fotos de ventanas, objetos cercanos y poca textura; sensores, recuperación de orientación y cámara; ARCore/ARKit en Android/iPhone, permiso rechazado, dispositivo incompatible, reflejos, referencia ilegible, pérdida de tracking, segundo plano y mobiliario modificado. La unión de los fixtures acredita ejecución/cobertura software, sin acreditar calidad óptica del local. No se invoca `tours_ar_report_test` en la verificación automática ni se marca una referencia como probada físicamente.

## 5. Comando exacto para Android

```bash
cd /Users/crisis/Proyectos/marea
adb devices
flutter devices
flutter run -d <ANDROID_DEVICE_ID> -t lib/main.dart \
  --dart-define-from-file=config/supabase.production.json \
  --dart-define-from-file=config/firebase.android.json
```

Conservar ambos archivos para mantener Firebase/push existentes. Si ADB no está en PATH, usar `/Users/crisis/Library/Android/sdk/platform-tools/adb devices`.

## 6. Comando exacto para iPhone

```bash
cd /Users/crisis/Proyectos/marea
flutter devices
flutter run -d <IPHONE_DEVICE_ID> -t lib/main.dart \
  --dart-define-from-file=config/supabase.production.json
```

Los IDs salen de `flutter devices`. Conectar, desbloquear y confiar en el Mac; habilitar Developer Mode cuando corresponda. La app no necesita defines adicionales para Cloud Run. Configuración/secretos no se imprimen en este reporte.
