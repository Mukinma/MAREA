# Procesamiento 360° privado

Este directorio prepara un Cloud Run **Job**, sin endpoint público, para `marea-f6a92/us-central1`: 4 CPU, 8 GiB, timeout900s, un task, retries de Cloud Run deshabilitados. PostgreSQL decide los dos cupos globales y los tres intentos totales. Solo errores transitorios (`network`, `storage_unavailable`, `dispatch_unavailable`, `timeout`, `lease_expired`) pueden reencolarse; datos inválidos son terminales.

La migración `015_tours.sql` define el contrato público del plan. Los jobs públicos usan `queued/running/ready/needs_recapture/failed/cancelled`; el servicio usa internamente `processing/succeeded`. Una captura enviada es inmutable y su reenvío idéntico es idempotente. `tours_save` permite UUID cliente para crear/reintentar sin duplicación. Editar una revisión enviada crea otro borrador; solicitudes y publicación conservan el snapshot enviado. La aprobación de espacio se deriva de permisos del servidor vinculados al espacio y alcance exactos, nunca de `space.verified` del cliente ni de ser autor de un post. El primer envío necesita revisión manual/admin; ediciones con alcance ya aprobado pueden publicar directamente.

Una publicación conserva puntos independientes con texto y omite vínculos pendientes/AR sin prueba; el borrador conserva esos pendientes. AR se activa después de `tours_ar_report_test(p_tour,p_point,p_reference_version,p_platform,p_tracking_seconds)`, invocado por la app tras >=3 segundos de reconocimiento nativo. La fila es **un reporte de prueba de producto del usuario**, no una certificación de seguridad, y queda ligada a referencia/version/ancho exactos. Reemplazar un panorama invalida posiciones (`needs_review=true`, ángulos null) hasta reubicarlas. `tours_progress` acepta `{scene_id,visited,skipped,revision_id}`; una revisión nueva devuelve el marcador anterior sin copiar identificadores antiguos.

## Pipeline

1. El dispatcher se autentica con secreto servidor, firma JWT RSA para OAuth Google y llama la API v2 de Cloud Run con `job/lease` y prueba HMAC. El worker carga manifest/autor desde `tours_job_context`; nunca usa URLs, comandos ni PTO enviados por cliente.
2. Descarga JPEGs privados `tour-inputs/owner/capture/frame.jpg`, hasta96 frames de32MiB. Comprueba IDs, ruta exacta, dimensiones reales, orientación normalizada, valores finitos y FOV rectilíneo para fotos.
3. Fotos: PTO generado con orientación/FOV numéricos, `cpfind`, `cpclean`, grafo conectado de puntos de control, `autooptimiser`, `pano_modify` a esfera360×180, `nona` con canvas completo, unión de alpha real de remapeos **sin huecos**, `enblend --no-optimize --wrap=horizontal`. Una imagen incompleta no se rellena para fingir cobertura. El techo/suelo y la unión longitudinal deben estar cubiertos.
4. Importación: requiere XMP GPano real del JPEG con proyección equirectangular y dimensiones/área completa sin crop. Un JPEG 2:1 normal o texto GPano agregado fuera del XMP se rechaza.
5. Salidas JPEG GPano4096×2048, preview2048×1024, thumbnail512×256 bajo `tour-assets/owner/jobs/job/`. FOV usado: el reportado por la app; orientación es una inicialización, no la prueba de cobertura.
6. CAS de lease antes de escribir y concluir. Guardas de escritura de60s se renuevan antes de cada subida (red limitada a25s), bloquean recovery/GC y eliminación de cuenta. Cancelación elimina parciales; el dispatcher reserva guardas para GC de residuos tras procesos interrumpidos. Ante timeout ambiguo al lanzar Cloud Run se conserva lease hasta expiración, evitando ejecución doble inmediata.

Enblend4.2 se cayó dos veces con SIGSEGV al optimizar costuras de los remapeos completos del fixture en el piloto remoto. Se desactiva únicamente esa optimización mediante `--no-optimize`; sigue mezclando las fotografías y se valida alpha antes y después. Puede cambiar la colocación de la costura, por lo que su calidad debe revisarse con fotos reales. La opción está documentada en [el tutorial oficial de máscaras de Hugin](https://hugin.sourceforge.io/tutorials/Blend-masks/en.shtml).

Las fotos se reducen internamente a2560px para control de recursos; el límite de archivos temporales es3GB. Debe medirse calidad y memoria con escenas reales en el contenedor antes de habilitar producción.

## Configuración y despliegue explícito

No se ejecuta despliegue al aplicar la migración. Se requieren Artifact Registry repositorio `marea`, Cloud Build/Run/Secret Manager activados, cuenta runtime con acceso a los tres secretos y cuenta dispatcher con `roles/run.jobsExecutorWithOverrides` sobre este job. Mantener cuentas distintas y restringir la llave del dispatcher.

Secret Manager: `marea-supabase-url`, `marea-supabase-service-role`, `marea-tour-worker-secret` (>=32 caracteres aleatorios). Edge secrets: `TOUR_WORKER_SECRET` (mismo secreto), `TOUR_GOOGLE_SERVICE_ACCOUNT_JSON` (cuenta dispatcher), opcionales `TOUR_GCP_PROJECT`, `TOUR_GCP_REGION`, `TOUR_CLOUD_RUN_JOB`. Supabase inyecta URL/service role al Edge. No incluir secretos en Git, argumentos ni logs.

```bash
export TOUR_RUNTIME_SA='runtime@PROJECT.iam.gserviceaccount.com'
export TOUR_DISPATCH_SA='dispatcher@PROJECT.iam.gserviceaccount.com'
./processing/tours/deploy.sh
supabase functions deploy tour-dispatch
```

El script usa Secret Manager y fija4CPU/8Gi/900s, un task y `--max-retries 0`. Crear y conceder permisos a secretos/cuentas con la política del proyecto antes de ejecutarlo. En Vault, guardar `marea_tour_dispatch_url` (URL de la función Edge) y `marea_tour_worker_secret`. Después de verificar worker/credenciales y migración, aplicar `activate.sql`: wake por trigger y cron cada minuto para nuevos jobs, retries, recovery y GC. No usar un JWT de usuario para dispatcher. Pausar implica retirar/rotar wake-secret y desprogramar el cron.

La eliminación de cuenta marca/bloquea al autor, cancela jobs y pausa recorridos, espera las escrituras activas y recorre **ambos buckets anidados** antes de borrar auth. Revisiones, capturas, jobs y progreso hacen cascade. Originals nunca son públicos: únicamente autor o revisor autorizado de un envío pendiente puede leerlos. Contexto/evidencias de espacio se omiten del Tour público; firmar una URL de Storage exige RLS. Las URLs ya firmadas pueden durar hasta600s (TTL elegido por la app).

## Pruebas locales

```bash
python3 -m venv /tmp/marea-tours-test
/tmp/marea-tours-test/bin/pip install -r processing/tours/requirements.txt
PYTHONPATH=processing/tours /tmp/marea-tours-test/bin/python -m unittest discover -s processing/tours/tests -v
MAREA_PGLITE_MODULE=/path/to/@electric-sql/pglite/dist/index.js node tool/check_tours_database.mjs
MAREA_PGLITE_MODULE=/path/to/@electric-sql/pglite/dist/index.js node tool/check_tours_migrations.mjs
node --experimental-strip-types supabase/functions/tour-dispatch/dispatch_test.ts
node --experimental-strip-types supabase/functions/delete-account/tour-storage_test.ts
deno check supabase/functions/tour-dispatch/index.ts supabase/functions/delete-account/index.ts
node --test test/tool/backend_contract_test.mjs
```

Las pruebas unitarias ejecutan PostgreSQL aislado, permisos/RLS y validación/exportación JPEG. La verificación adicional del piloto ejecuta las herramientas reales de la imagen `linux/amd64` contra Supabase alojado. Sus fixtures son proyecciones geométricas sintéticas reproducibles, **no capturas de celular ni pruebas físicas de AR**. Consulte resultados y límites en [el reporte del piloto](../../docs/implementation/tours-local-pilot-report.md).

## Ejecución local mientras Cloud Run espera facturación

La migración015 y las funciones `delete-account`/`tour-dispatch` se despliegan en Supabase real. El dispatcher conserva su destino Google: responde401 sin secreto y503 con configuración Google pendiente, antes de reclamar. No activar Vault ni cron de tours hasta comprobar una ejecución real de Cloud Run; conservar el cron de push.

```sh
cd /Users/crisis/Proyectos/marea
python3.12 -m venv .venv-tours
.venv-tours/bin/pip install -r processing/tours/requirements.txt
# Recupera el acceso administrativo existente del CLI; no imprime valores.
.venv-tours/bin/python processing/tours/configure_local.py
docker buildx build --builder desktop-linux --platform linux/amd64 --load \
  -t marea/tour-stitch:local-pilot processing/tours
.venv-tours/bin/python processing/tours/local_runner.py --once
# Mantener esta terminal abierta mientras se prueba la app:
.venv-tours/bin/python processing/tours/local_runner.py --watch
```

El entorno `.venv-tours` ya está preparado en este checkout con Python3.12; para recrearlo se necesita Python3.12 (el `python3` del sistema es3.9 y no sirve para estas dependencias).

`config/.env.tours-local` está ignorado y debe tener permisos0600. Contiene servicio/secretos exclusivamente para backend. `configure_local.py` conserva el secreto existente, actualiza solo `TOUR_WORKER_SECRET` en Edge y no crea credenciales Google, Vault ni cron. Requiere acceso administrativo autenticado en Supabase CLI.

El ejecutor utiliza cola, cupos globales, leases y RPC de limpieza existentes. Lanza hasta dos contenedores con4CPU/8Gi nominales cada uno y límite900s; verifica el recibo duradero del lease en Supabase para declarar `ready`. Código0 por sí solo nunca es éxito. Interrumpir con Ctrl+C detiene contenedores propios y reencola con lease protegido; un cierre abrupto se recupera cuando vence el lease. Sin Mac/terminal activo, los trabajos permanecen pendientes. Docker Desktop comparte su RAM total: asignar al menos16Gi si se necesitan dos cargas cercanas al límite simultáneas. El piloto actual tiene aproximadamente7.65Gi totales y no certifica capacidad máxima con fotos reales.

Pruebas opt-in (crean y eliminan solo cuentas/recursos temporales):

```sh
.venv-tours/bin/python processing/tours/fixtures/generate.py output/tours-pilot/fixtures
# Crea carpetas de salidas escribibles por uid10001 del contenedor.
mkdir -p output/tours-pilot/container-complete
chmod 777 output/tours-pilot/container-complete
docker run --rm --platform linux/amd64 --cpus 4 --memory 8g \
  -e PYTHONPATH=/app --entrypoint python \
  -v "$PWD/processing/tours/fixtures:/tests:ro" \
  -v "$PWD/output/tours-pilot:/fixtures" marea/tour-stitch:local-pilot \
  /tests/container_check.py /fixtures/fixtures /fixtures/container-complete --case complete
# Repetir con carpeta propia y --case incomplete / blank.
.venv-tours/bin/python processing/tours/check_live.py --run
```

La prueba real interrumpe TUS entre dos conexiones, consulta HEAD y reanuda bytes, ejecuta el worker contra Storage real y verifica publicación/RLS, leases concurrentes y eliminación. La expiración/backoff se acelera explícitamente solo en jobs temporales. Los checkpoints de recursos contienen únicamente IDs/emails `.invalid`, no passwords/tokens; el script registra si hubo fallo de limpieza. Artifacts y configuración local quedan fuera de Git. No ejecutar mientras haya trabajos ajenos pendientes ni otro runner activo.

Con la cola sin trabajo ni limpieza pendiente, comprobar también el lease de GC:

```sh
.venv-tours/bin/python processing/tours/check_cleanup_lease.py --run
```

Este contrato remoto crea una cuenta temporal, sube el panorama sintético y cancela su trabajo antes de procesarlo. Comprueba renovación, expiración, sustitución del token y rechazo a usuarios. `tours_renew_cleanup` renueva únicamente el token vigente de un trabajo no listo; runner y dispatcher lo comprueban antes de borrar cada lote. El correctivo aditivo está incluido al final de015 y se puede aplicar a instalaciones que ya tienen015 mediante `supabase/tours/repair-cleanup-lease.sql`; no crea otra migración ni cambia datos de usuarios.

Si una prueba anterior dejó objetos de cuentas temporales ya eliminadas, `cleanup_pilot.py --run` recupera únicamente los IDs de checkpoints propios, valida emails `marea-tours-…@example.invalid`, comprueba que Auth devuelve404 y borra sus objetos mediante Storage API. Omite cuentas que todavía existen. La prueba principal exige que la respuesta204 de eliminación coincida con cero medios y Auth404; no considera204 suficiente por sí sola.

## Traspaso posterior a Cloud Run (pendiente; no ejecutado)

1. Detener el ejecutor local con Ctrl+C y esperar que no tenga contenedores activos.
2. Instalar/autenticar `gcloud`, verificar facturación de `marea-f6a92` y permisos para servicios, IAM y secretos.
3. Crear la cuenta dispatcher restringida y su clave local con permisos0600. No reutilizar FCM. Configurar valores desde `config/.env.tours-local` con `configure_cloud_secrets.py --run --dispatcher-key <ruta-restringida>`; no imprime valores ni activa cron.
4. Ejecutar `bootstrap.sh` para APIs, repositorio, cuentas y acceso del runtime a los tres secretos. La cuenta dispatcher es `marea-tour-dispatch@marea-f6a92.iam.gserviceaccount.com`; el runtime es `marea-tour-runtime@marea-f6a92.iam.gserviceaccount.com`.
5. `publish_local_image.sh` compara el ID de Docker con `pilot-image.json` antes de cualquier operación Google y sube **la misma imagen amd64 validada**, con tag basado en su ID. Pasar la URL impresa como `TOUR_IMAGE` a `deploy.sh`, junto con `TOUR_RUNTIME_SA`/`TOUR_DISPATCH_SA`. Así no reconstruye otro contenedor. El deploy conserva4CPU/8Gi/900s, un task, retries0 e IAM sobre el job.
6. Crear una captura piloto, llamar el dispatcher autorizado y consultar `tours_job_get` hasta `ready`; revisar GPano/visor/logs. Una operación Google aceptada tampoco prueba `ready`.
7. Configurar y probar canales de alerta en `monitoring-alert.json`. **Solo después** guardar los dos valores de Vault y ejecutar `activate.sql` para wake/cron. Nunca tocar `marea-push-minute` ni `private.push_settings`.

`configure_cloud_secrets.py` necesita las cuentas creadas previamente si la clave aún no existe: `gcloud services enable iam.googleapis.com secretmanager.googleapis.com` y `gcloud iam service-accounts create marea-tour-dispatch`, con el proyecto explícito. Crear la clave bajo `config/.env.google-tour-dispatch.json` con `umask 077`; ese destino también está ignorado. No se ha ejecutado ningún paso Google durante este piloto.

Fuentes primarias: [scripting Hugin](https://hugin.sourceforge.io/docs/manual/Panorama_scripting_in_a_nutshell.html), [PTO/nona](https://hugin.sourceforge.io/docs/nona/nona.txt), [pano_modify](https://hugin.sourceforge.io/docs/manual/Pano_modify.html), [Cloud Run run v2](https://docs.cloud.google.com/run/docs/reference/rest/v2/projects.locations.jobs/run).

## Recuperación y piloto

`tours_completion_receipt` es una operación exclusiva de backend: liga el resultado comprometido al lease exacto. Repetir finish con ese lease y el mismo resultado es idempotente. Si se pierde su respuesta y no se puede consultar el recibo, el worker conserva los medios; recuperación/GC decide después. Un error de red nunca borra archivos posiblemente publicados. `needs_recapture` distingue fallos de cobertura/entrada de errores operativos. Adjuntar un resultado anterior a otra captura ya confirmada de la misma posición se rechaza.

`tours_permission_revoke` permite al autor/responsable retirar un permiso aprobado desde Solicitudes; revocar espacio pausa el recorrido y la lectura pública exige un permiso espacial vigente sobre el alcance de la versión pública. Reanudar no elude esa comprobación. Los permisos de contenido se resuelven de nuevo al leer: contenido oculto/retirado no permanece visible por estar en un snapshot.

`bootstrap.sh` comprueba facturación y prepara APIs, Artifact Registry, cuentas separadas e IAM para secretos existentes. No crea ni imprime valores secretos; ejecutarlo explícitamente después de configurar los tres secretos. `deploy.sh` despliega la imagen y concede ejecución con overrides solo al dispatcher. La activación de cola/cron continúa siendo un paso explícito después de aplicar la migración y validar credenciales.

El worker emite JSON estructurado con `component=marea_tour_worker`, job, evento, duración y error sin fotos, tokens ni propietarios. Configurar una alerta de Cloud Monitoring usando `monitoring-alert.json` **después de completar notificationChannels**; el archivo sin canales no notifica a nadie. Ejemplo de creación, sin ejecución automática:

```sh
gcloud monitoring policies create --project marea-f6a92 --policy-from-file processing/tours/monitoring-alert.json
```

Para el piloto: activar solo un local autorizado, anotar latencia de cola/ejecución, duración, CPU/memoria, tasas `ready/needs_recapture/failed`, reintentos y calidad de costura por posición. Consultar logs del job por `jsonPayload.job_id`; medir coste real en Cloud Billing por servicio/región/ejecución. `elapsed_seconds` del worker no incluye arranque del contenedor y no equivale a tiempo total facturable. No fijar un coste sin medirlo. Los fallos o finalizaciones ambiguas generan eventos para la alerta; supervisar también leases abandonados desde Supabase.

Referencia de configuración: [crear una política de alertas con gcloud](https://docs.cloud.google.com/sdk/gcloud/reference/monitoring/policies/create). El canal y la entrega de la notificación deben probarse en el piloto.

Para reproducir la revisión visual después de `check_live.py`:

```sh
.venv-tours/bin/python processing/tours/fixtures/serve.py
# En otra terminal; web local solamente, no teléfonos:
flutter run -d web-server -t test/browser/tours_probe.dart --web-port 7368 \
  --dart-define=TOUR_PILOT_ORIGIN=http://localhost:7369
```

Abrir `http://localhost:7368`. Es una copia offline del resultado real y del JSON público recuperado durante la prueba; su sesión/repo del harness son aislados. Los permisos y recursos publicados se acreditan mediante HTTP autenticado real en `check_live.py`, antes de eliminar cuentas. El servidor solo ofrece el JSON público y el panorama sintético, enlazado a loopback. Detener ambas terminales al terminar. No es evidencia de captura de celular ni AR.
