// Offline preparation only. This module has no network, database or auth client.
// Planned IDs are placeholders; Auth and ordinary application RPCs remain the
// authority for the identities and records created during an eventual pilot.
import {randomUUID} from 'node:crypto';
import {constants} from 'node:fs';
import {lstat, mkdir, open, realpath} from 'node:fs/promises';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const titlePrefix = 'Prueba RA MAREA';
const outputRelativePath = 'outputs/ar-live-pilot/plan.json';
const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const day = 24 * 60 * 60 * 1000;
const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function instant(value) {
  let milliseconds;
  if (value instanceof Date) {
    milliseconds = value.getTime();
  } else if (typeof value === 'number' && Number.isSafeInteger(value)) {
    milliseconds = value;
  } else if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?Z$/.test(value)) {
    milliseconds = Date.parse(value);
    const expected = value.includes('.') ? value : value.replace('Z', '.000Z');
    if (Number.isFinite(milliseconds) && new Date(milliseconds).toISOString() !== expected) {
      throw new TypeError('A valid UTC instant is required.');
    }
  } else {
    throw new TypeError('A valid UTC instant is required.');
  }
  if (!Number.isFinite(milliseconds) || !Number.isFinite(new Date(milliseconds + 14 * day).getTime())) {
    throw new TypeError('A valid UTC instant is required.');
  }
  return milliseconds;
}

/** Pure construction: injected time and UUID factory make the plan reproducible. */
export function makePlan({now, runId, uuidFactory = randomUUID} = {}) {
  const milliseconds = instant(now);
  if (typeof runId !== 'string' || !/^[a-z0-9][a-z0-9-]{0,19}$/.test(runId) || typeof uuidFactory !== 'function') {
    throw new TypeError('A safe run identifier and UUID factory are required.');
  }
  const used = new Set();
  const allocate = () => {
    const value = uuidFactory();
    if (typeof value !== 'string' || !uuidPattern.test(value) || used.has(value.toLowerCase())) {
      throw new TypeError('Distinct valid proposed UUIDs are required.');
    }
    used.add(value.toLowerCase());
    return value.toLowerCase();
  };
  const ids = Object.fromEntries([
    'owner', 'visitor', 'mission', 'tour', 'zone', 'scene', 'point', 'reference', 'referenceVersion',
  ].map(name => [name, allocate()]));
  const title = suffix => `${titlePrefix} · ${runId} · ${suffix}`;
  const coordinate = {latitude: 19.4326, longitude: -99.1332};
  const referencePath = `${ids.owner}/references/${ids.reference}.jpg`;
  const usernameSuffix = runId.replaceAll('-', '_');
  const prerequisite = (code, requirement) => ({code, status: 'pending_verification', requirement});
  const prerequisites = [
    prerequisite('new_test_accounts_and_confirmed_emails',
      'Registrar dos cuentas nuevas con correos controlados por quien prueba y confirmar sus correos mediante el flujo normal.'),
    prerequisite('current_legal_policy_and_personal_consent',
      'Comprobar que el registro esté habilitado y que cada persona acepte por sí misma los documentos legales vigentes y confirme la mayoría de edad.'),
    prerequisite('actual_new_account_ids_and_session_access',
      'Obtener las sesiones autorizadas de las cuentas nuevas y sustituir ambos IDs propuestos por los IDs que Auth asigne antes de escribir registros o rutas.'),
    prerequisite('owned_reference_jpeg_and_measured_print',
      'Cargar desde el editor la imagen JPEG de referencia bajo la cuenta nueva del organizador y medir el ancho físico de la impresión; el ancho previsto es 20 cm.'),
    prerequisite('real_gpano_or_guided_spherical_capture',
      'Aportar un GPano esférico completo real o realizar una captura guiada; una imagen decorativa no sustituye el panorama.'),
    prerequisite('successful_processing_job_and_attached_result',
      'Procesar la captura mediante el pipeline existente y adjuntar el resultado del trabajo exitoso propio; este plan no inventa trabajo ni rutas de panorama.'),
    prerequisite('physical_ar_tracking_current_reference_version',
      'Probar la referencia actual en un teléfono compatible y obtener al menos 3 segundos reales de seguimiento mediante el flujo existente. Una versión de imagen nueva requiere otra prueba.'),
    prerequisite('legitimate_space_and_publication_review',
      'Enviar el recorrido completo y obtener revisión legítima del espacio y la publicación con los permisos existentes; no crear administradores ni cambiar roles para aprobarlo.'),
    prerequisite('public_revision_and_map_visibility',
      'Comprobar como visitante que la revisión pública del mismo organizador contiene la referencia probada y que la nueva Misión futura aparece en la zona del Mapa.'),
  ];
  return {
    version: 1,
    mode: 'offline_preview',
    remotelyExecuted: false,
    generatedAt: new Date(milliseconds).toISOString(),
    runId,
    titlePrefix,
    scope: {
      target: 'existing_production_new_test_records_only',
      proposedIdsAreNotExistingRecords: true,
      mustRebindAccountIdsAfterSignup: true,
      mustUseServerReturnedRecordIds: true,
      remoteRequestsExecuted: 0,
      allowExistingRecordUpdates: false,
      allowExistingRecordDeletes: false,
      allowAdministratorCreation: false,
      allowRoleChanges: false,
      allowDeployment: false,
    },
    accounts: {
      owner: {
        id: ids.owner,
        identityStatus: 'proposed_offline_not_created',
        profile: {
          full_name: title('Organizador'),
          username: `pra_o_${usernameSuffix}`,
          user_type: 'Negocio',
          bio: `${titlePrefix}. Cuenta nueva destinada exclusivamente al piloto autorizado; no representa una convocatoria real.`,
        },
      },
      visitor: {
        id: ids.visitor,
        identityStatus: 'proposed_offline_not_created',
        profile: {
          full_name: title('Visitante'),
          username: `pra_v_${usernameSuffix}`,
          user_type: 'Usuario general',
          bio: `${titlePrefix}. Cuenta nueva de visitante para comprobar la experiencia del piloto.`,
        },
      },
    },
    mission: {
      id: ids.mission,
      author_id: ids.owner,
      status: 'open',
      title: title('Misión de prueba'),
      body: `${titlePrefix}. Contenido de prueba autorizado para validar Mapa y realidad aumentada. ` +
        'No es un evento real ni solicita asistencia o postulaciones. La ubicación de CDMX es un punto ficticio de QA.',
      category: 'arte',
      location: `${titlePrefix} · CDMX · ubicación ficticia, sin evento real`,
      starts_at: new Date(milliseconds + 7 * day).toISOString(),
      capacity: 1,
      target_type: null,
      compensation_type: null,
      compensation_amount_cents: null,
      image_path: null,
      requirements: 'No acudir a esta ubicación ni postularse: es exclusivamente contenido del piloto RA.',
      conditions: 'No representa una actividad presencial real.',
      location_latitude: coordinate.latitude,
      location_longitude: coordinate.longitude,
      location_precision: 'approximate',
      location_city: null,
    },
    tour: {
      id: ids.tour,
      owner_id: ids.owner,
      state: 'draft',
      title: title('Recorrido de prueba'),
      space: {
        name: title('Espacio de prueba'),
        location_label: 'CDMX · punto ficticio del piloto, sin acceso público real',
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        context: `${titlePrefix}. Espacio de prueba pendiente de aportar panorama real y evidencia propia para revisión legítima.`,
        evidence_paths: [],
      },
      document: {
        start_scene_id: ids.scene,
        starts_at: new Date(milliseconds).toISOString(),
        ends_at: new Date(milliseconds + 14 * day).toISOString(),
        ar_order: [ids.point],
        zones: [{
          id: ids.zone,
          name: title('Zona de prueba'),
          description: 'Preparación del piloto; aún no hay panorama procesado.',
          scenes: [{
            id: ids.scene,
            name: title('Posición de prueba'),
            initial_yaw: 0,
            connections: [],
            points: [{
              id: ids.point,
              name: title('Referencia de prueba'),
              description: 'Busca la imagen física que el organizador cargue para este piloto. Reconocimiento real pendiente.',
              yaw: null,
              pitch: null,
              link: null,
              ar: {
                reference_path: referencePath,
                reference_version: ids.referenceVersion,
                width_cm: 20,
              },
            }],
          }],
        }],
      },
    },
    storage: [{
      bucket: 'tour-assets',
      owner_id: ids.owner,
      path: referencePath,
      uploadStatus: 'not_uploaded',
      contentType: 'image/jpeg',
      purpose: 'physical_image_reference',
    }],
    missingPrerequisites: prerequisites.map(item => item.code),
    prerequisites,
    readiness: {
      remoteCreationReady: false,
      publicationReady: false,
      arEntryReady: false,
      physicalRecognitionVerified: false,
      reason: 'offline_plan_with_unverified_prerequisites',
    },
    workflow: [
      'Registrar y confirmar las dos cuentas nuevas por los flujos existentes; conservar sus IDs reales.',
      'Vincular exclusivamente esos IDs nuevos al plan y crear la Misión con el organizador previsto.',
      'Preparar la referencia y el recorrido propio desde el editor, importar o capturar el panorama real y esperar el procesamiento.',
      'Completar la prueba física de RA de la versión actual mediante el flujo normal.',
      'Solicitar y obtener la revisión legítima existente del espacio y la publicación.',
      'Entrar con el visitante al Mapa, seleccionar la Misión y comprobar reconocimiento, tarjeta, pérdida de seguimiento y navegación.',
    ],
  };
}

function samePath(left, right) {
  return process.platform === 'win32' ? left.toLowerCase() === right.toLowerCase() : left === right;
}

async function writePreview(plan) {
  // Fixed, owned output directory only. Existing files are never overwritten.
  let current = projectRoot;
  for (const component of ['outputs', 'ar-live-pilot']) {
    const parent = await lstat(current);
    if (!parent.isDirectory() || parent.isSymbolicLink() || !samePath(await realpath(current), current)) {
      throw new Error('Unsafe output directory.');
    }
    current = join(current, component);
    try { await mkdir(current); }
    catch (error) { if (error.code !== 'EEXIST') throw error; }
  }
  const finalDirectory = await lstat(current);
  if (!finalDirectory.isDirectory() || finalDirectory.isSymbolicLink() || !samePath(await realpath(current), current)) {
    throw new Error('Unsafe output directory.');
  }
  const handle = await open(join(current, 'plan.json'),
    constants.O_WRONLY | constants.O_CREAT | constants.O_EXCL | (constants.O_NOFOLLOW ?? 0), 0o600);
  try { await handle.writeFile(`${JSON.stringify(plan, null, 2)}\n`); }
  finally { await handle.close(); }
}

async function cli(arguments_) {
  let output = false, runId;
  for (let index = 0; index < arguments_.length; index++) {
    if (arguments_[index] === '--out' && !output) {
      output = true;
      if (arguments_[index + 1] && !arguments_[index + 1].startsWith('--')) {
        if (arguments_[++index].replaceAll('\\', '/') !== outputRelativePath) {
          throw new Error('Unsupported output path.');
        }
      }
    } else if (arguments_[index] === '--run-id' && runId === undefined) {
      runId = arguments_[++index];
      if (runId === undefined) throw new Error('A run identifier is required.');
    } else {
      throw new Error('Unsupported plan argument.');
    }
  }
  const now = new Date();
  runId ??= `ra-${now.toISOString().slice(0, 10).replaceAll('-', '')}-${randomUUID().slice(0, 6)}`;
  const plan = makePlan({now, runId});
  if (output) await writePreview(plan);
  process.stdout.write(`${JSON.stringify(plan, null, 2)}\n`);
}

if (process.argv[1] && samePath(resolve(process.argv[1]), fileURLToPath(import.meta.url))) {
  try { await cli(process.argv.slice(2)); }
  catch {
    process.stdout.write(`${JSON.stringify({mode: 'offline_preview', remotelyExecuted: false,
      status: 'blocked', error: 'invalid_plan_arguments_or_unsafe_or_existing_output'})}\n`);
    process.exitCode = 1;
  }
}
