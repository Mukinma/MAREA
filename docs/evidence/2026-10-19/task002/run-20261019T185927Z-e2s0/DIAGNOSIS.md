# S0 — diagnóstico efectivo y contención seleccionada

- `delete-account/index.ts`: valida Auth, llama request_account_deletion, elimina cinco buckets por prefijo y recorre tour-inputs/tour-assets, luego intenta Auth DELETE; sólo al final responde 204. No registra un plan por recurso.
- `auth_repository.dart:139`: cualquier 2xx se interpreta como baja completa y cierra sesión. S0 devuelve 503 incluso al confirmar recepción del marcador, nunca 202/204 de purga.
- Otras rutas reales: profile-media elimina borradores; story-cleanup borra bytes antes de historias/snapshots; showcase_repository elimina Storage; processing/tours/worker.py elimina salidas mediante API y usa leases/RPC de tours. tour-dispatch inicia Cloud Run; no se inicia ni contacta ese servicio remoto en el laboratorio. Cron, push y geocoding permanecen desactivados.
- Storage instalado: imagen v1.72.1 fijada por digest. `ObjectStorage.deleteObjects` elimina metadata dentro de una transacción, llama `FileBackend.deleteObjects` para bytes y luego confirma. Un rollback DB posterior no recupera bytes ya borrados. El corte debe parar el proceso antes de esa llamada física y confirmar quiescencia.

## Implementación mínima elegida

1. Declarar PREPARING, invalidar el proceso Storage que tiene la petición en curso, comprobar PID=0/sesiones=0 y comparar recursos/árbol físico antes de declarar éxito. No se simula cancelación de una llamada que siga ejecutándose.
2. Instalar guardas temporales constantes para metadatos Storage, bajas Auth/perfil y referencias de medios. Sin permisos de excepción, GUC cliente, cambios de FK, titularidad o ciclo de baja B.
3. Reiniciar la API instalada con su volumen físico de sólo lectura; el volumen RW de inspección queda sólo al operador Docker del laboratorio. No se promete defensa contra ese operador o un superusuario que desactive controles.
4. Servir una variante S0 de ingreso: bloquea productores heredados y mutaciones Storage, conserva lecturas y recibe el marcador existente de solicitud tras validar Auth. Se inserta sólo ese marcador por REST con privilegios ya existentes; no se llama la RPC legada que además limpia resultados/leases de tours. No es un nuevo plan de baja ni política de retención.
5. Un archivo mínimo con epoch/digest en volumen de control persiste la activación; el ingreso lo monta sólo lectura y falla cerrado si falta o no coincide. La protección física/SQL no depende de que ese archivo indique ACTIVE.

La pausa antes de FileBackend es instrumentación de interleaving sólo de test, conservando el backend real. La medida operativa es detener/invalidar y verificar; el hook no es una protección de producto. Si una llamada ya hubiera borrado bytes, el manifiesto no coincidiría y se prohibiría activar S0.

S0 es contención de mantenimiento. No demuestra eliminación autorizada positiva, revocación TASK-003, retención D02 ni operación de Cloud Run remoto. Antes de un corte real haría falta inventariar/detener ejecuciones reales y autorizar los parches operativos por separado.
