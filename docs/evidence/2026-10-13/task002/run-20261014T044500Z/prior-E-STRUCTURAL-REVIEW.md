# E — Referencia de autoría y conservación del legado

Estado: **PROPUESTA; NO APROBADA PARA EJECUCIÓN**. Fuente de diseño: SRS v5.1.1. Alcance de este expediente: análisis estático y SQL propuesto. No hay migraciones ni pruebas de datos ejecutadas.

## Decisión técnica solicitada

Conservar `public.missions` como ancla de UUID y referencias sociales; `author_id` seguirá siendo autoría, no titularidad contractual. Introducir un principal personal estable privado, relacionado con Auth mediante referencia anulable, y reemplazar la FK de misión a perfil con una referencia `ON DELETE RESTRICT` al principal. La organización y los acuerdos nuevos tendrán relaciones propias, nunca propiedad derivada de la etiqueta «Negocio».

La aprobación conceptual no autoriza esta sustitución. El SQL final y su ventana local se aprobarán tras completar las comprobaciones abajo. Este documento no solicita ni acredita autorización remota.

## Dependencias reales observadas

| Dependencia | Fuente | Impacto |
|---|---|---|
| `auth.users → profiles → missions` con cascada | migrations/001 y 003; missions.author_id NOT NULL/default auth.uid | El borrado de credenciales puede eliminar la misión y sus hijos. El nuevo principal rompe esa dependencia destructiva, pero exige limpieza explícita por recurso. |
| Candidaturas y reportes referencian misión | 003; ampliaciones 005/013 | Conservar UUID evita huérfanos. `accepted` legado no demuestra consentimiento bilateral. |
| Borradores, guardados, finalistas, recibos de candidatura y notificaciones | 013 | Borradores vinculados usan SET NULL; otros vínculos a misión tienen cascada. Algunas relaciones siguen dependiendo de perfiles: no se asume que el cambio de una FK protege todo el dominio. |
| Reacciones, comentarios y recibos de comentarios | 020 | Conservar IDs preserva navegación social. Autorización/moderación y destinatarios actuales dependen del autor; deben adaptarse al titular/contexto. |
| RPC de gestión y wrappers encadenados | 005/013/021 | El permiso actual usa author_id. No debe reconocer al autor histórico como representante vigente. No eliminar wrappers históricos con dependencias activas. |
| Listado, guardados, mapa y feed | 005/012/013/016/020/021 | JOIN a profiles puede ocultar una misión organizacional al borrar a su creador. Los conteos accepted son incompatibles con reservas/acuerdos nuevos. |
| RLS de misiones, candidaturas y finalistas | 003/005/013 | INSERT/DELETE/SELECT legados requieren inventario de grants y policies efectivos, no sólo lectura de SQL. Las políticas nuevas no deben admitir escritura directa que eluda contratos. |
| mission-images | 013; delete-account Edge | Rutas personales, policies/triggers y eliminación por prefijo pueden borrar medios organizacionales. Una FK nueva no evita ese borrado. |
| Eliminación de cuenta | Edge delete-account; request_account_deletion | El flujo actual elimina Storage y Auth. Se necesita preparación por recurso y protección de todos los puntos destructivos, incluida eliminación directa de Auth autorizada. Reautenticación/revocación/restore pertenecen a TASK-003. |
| Flutter y navegación | CommunityRepository, MissionSocialRepository, router, notificaciones | Mantener IDs; sustituir permisos y DTO contractuales. No modificar Flutter en este expediente. |

El recibo `E-source-dependencies.json` contiene 52 referencias localizadas con archivo/línea. El catálogo de TASK-001 acredita históricamente 46 tablas, 139 rutinas y 55 políticas; no contiene un inventario suficiente de filas ni todas las FK efectivas. No se presenta como estado actual ni equivalente remoto.

## Filas afectadas y límites de análisis

Docker no está accesible por el socket local. No se arrancó ni restauró un stack. Por tanto:

| Medición | Estado |
|---|---|
| Total actual de misiones, autores y perfiles | PENDIENTE: sin consulta a una copia local operativa |
| Autores sin perfil o usuario Auth | PENDIENTE |
| Candidaturas accepted, borradores publicados y referencias huérfanas | PENDIENTE |
| Objetos mission-images y referencias compartidas | PENDIENTE; la consulta inicial de conteo no resuelve por sí sola titularidad/uso |
| Digests de filas antes/después | PENDIENTE |
| Filas remotas/reales y equivalencia con laboratorio | NO INSPECCIONADAS; fuera de autorización |

`E-PREFLIGHT.sql` propone inspección bajo `BEGIN READ ONLY`, con conteos, referencias, RLS y digests. No exporta textos personales ni credenciales. Antes de ejecutarlo debe comprobarse identidad/aislamiento del laboratorio, recibo de origen y ausencia de conexión remota. Los datos reales no se infieren de fixtures sintéticos.

## SQL y estrategia expand → verify → replace

`E-PROPOSED-REFERENCE.sql` es una propuesta, ubicada en docs, fuera de supabase/migrations. Tiene una barrera de excepción al inicio y termina en ROLLBACK. **No se ha ejecutado ni se ha comprobado su compilación contra PostgreSQL.**

Secuencia propuesta:

1. Congelar el esquema efectivo, conteos, digests y grafo de referencias; comprobar el constraint real y autores vinculables.
2. Crear principales técnicos privados conservando UUID existentes. No registrar elegibilidad ni titularidad organizacional por ese backfill.
3. Añadir la nueva FK NOT VALID; validar antes de retirar la anterior. Ajustar el alcance/ventana de bloqueo según filas reales locales; no asumir operación online por usar NOT VALID.
4. Comprobar hooks de eliminación por recurso, proyecciones, grants y medios. La mera existencia de una función no demuestra su registro ni protección de Auth/Storage; verificar cuerpos, triggers, ACL y postcondiciones.
5. Retirar exclusivamente la FK revisada, dentro de la transacción aprobada. Conservar author_id, filas y referencias entrantes.
6. Verificar digests y acceso; no habilitar contratos nuevos ni proceso destructivo incompatible antes de completar sus dependencias.

Los pasos 4–6 no están autorizados ahora. Si falta cualquier precondición, abortar; no desactivar constraints ni inventar autores para continuar.

## Clasificación: proceso distinto del backfill técnico

- Personal inequívoca: manifestar titular, evidencia y aprobación; no basta la ausencia de una organización creada automáticamente.
- Organizacional: Organization existente, representación válida, procedencia y transferencia explícita aprobada.
- Ambigua/disputada: histórico sólo lectura, REVIEW_REQUIRED interno, sin incorporarla al modelo operativo XOR.
- Compromiso legado accepted: conservar el registro, bloquear nuevas ofertas si podría sobreasignar compromisos no reconciliados. No fabricar firmas, revision_id conocida ni plazas bilaterales.
- Snapshot al migrar: identificarlo como captura de migración; no como términos aceptados en el pasado.

## Recuperación propuesta

Antes de ejecutar: backup privado de DB, esquema/roles relevantes y Storage referenciado; manifiestos SHA, conteos/digests y prueba de restore en un namespace local distinto. Los respaldos documentales N/T no son respaldos de volúmenes DB/Storage.

Antes de COMMIT, un error revierte DDL/backfill en la misma transacción. Después, volver a FK de perfil sólo es viable si todos los autores conservan perfil y no existen recursos que necesiten conservación independiente; debe comprobarse de nuevo. No borrar principales para forzar reversión. Ante incompatibilidad, deshabilitar escrituras del nuevo dominio y conservar datos con corrección hacia adelante.

Restore debe verificar filas/objetos y reaplicar supresiones antes de exposición. Esa garantía completa depende de TASK-003; no se acredita con este documento. Nunca restablecer aceptación unilateral como rollback.

## Pruebas de conservación exigidas, todavía no ejecutadas

| Caso | Postcondición |
|---|---|
| Migración sin operaciones de negocio | Mismos UUID, valores legados y referencias; conteos/digests iguales |
| Perfil Negocio y titularidad incierta | Ninguna organización/membresía/firma generada; histórico preservado |
| Organizador personal y organizacional | XOR y autorización correcta; autoría histórica no concede permiso |
| Borrar representante con recursos organizacionales | Misiones/acuerdos/versiones conservados; medios organizacionales no borrados por prefijo; acceso posterior acorde a permiso |
| Eliminar titular personal con oferta | Oferta cancelada, reserva liberada y preliminar cancelado atómicamente; públicos retirados |
| Eliminar cuenta con acuerdo activo | Expediente mínimo protegido y acceso segregado; no cascada de consentimiento histórico |
| Cambio estructural fallido | Rollback completo, sin huérfanos ni retirada parcial de constraints |
| Backup/restore local | DB+Storage verificados; límites/supresiones documentados, sin falsa certificación TASK-003 |
| Lecturas/feed/guardados/social | IDs y destinos conservados; sin JOIN que borre visibilidad organizacional por ausencia del fundador |

## Puerta pendiente

**E no está listo para autorizar ejecución:** faltan filas locales efectivas, FK/grants actuales, ensayo de recuperación y revisión del conjunto de hooks/proyecciones/medios. Se presenta el diseño y SQL para revisión; la obtención de esas comprobaciones en una copia local y la aplicación del cambio son autorizaciones distintas. Ningún resultado sintético autorizará remoto.
