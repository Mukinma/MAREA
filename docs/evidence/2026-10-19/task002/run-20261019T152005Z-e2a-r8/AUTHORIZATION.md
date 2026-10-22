# Autorización E2-A R3, dos etapas

1. Corregir transporte PAX exclusivamente con archivos/contenedores sintéticos desechables sin datos de proyecto ni volúmenes históricos. Preservar rutas, bytes, tamaños, tipos, modos, uid/gid y precisión temporal; conjunto pequeño con enlaces seguros, ciclo completo y negativos. No debilitar comparaciones ni pasar a E2-A antes de PASS completo.
2. Tras PASS, ejecutor nuevo y copias nuevas sintéticas de fuentes E1 autorizadas; preflight/aislamiento antes de datos, catálogo/permisos/digests y recuperación completa antes de DDL A. Sólo T01–06/T08 y reparación T44. Sin cuentas DELETE/T07, otros incrementos, misiones, candidaturas, FK, RPC negocio, Flutter, Edge, remoto, volúmenes originales ni commits.

Imagen offline Docker ~995GB excluida completamente de los insumos e inventarios. Preservar fuentes/recibos previos. Ante bloqueo nuevo diagnosticar sin ampliar permisos ni relajar garantías y detener operaciones que comprometan integridad/aislamiento. Si A queda validado, detener antes del siguiente incremento. TASK-002 incompleta.

Esta nueva corrida conserva la misma autorización humana. R3 quedó detenido por probe obsoleto tras reiniciar PG; se corrige sólo su ciclo de vida, se verifica en vacío y se crean otras copias nuevas. No se reutiliza/desbloquea ningún ejecutor/copia fallida.

Nueva corrida R5 tras error de GUC de escritura en ensayo R4, antes de persistir objetos A. Se mantiene la misma autorización humana actual; no se desbloquean corridas previas ni amplían privilegios.

R6: el ensayo R5 se revirtió sin persistir A. Diagnóstico: auth.users tiene RLS sin política para el nuevo propietario NOLOGIN/NOBYPASSRLS, por lo que SELECT devolvía cero filas. Corrección mínima del incremento A: política SELECT sólo para ese rol y columnas id/deleted_at ya previstas. Sin BYPASSRLS, membresías ni acceso cliente; no se cambian políticas existentes ni permisos administrativos previos. Se repiten preflight, fuentes y recuperación en copias nuevas.

R7 conserva la autorización, crea copias nuevas y repite todos los gates/casos. R6 se detuvo por parseo JSON en el test de espera concurrente; se corrige con to_jsonb sin alterar SQL A ni garantías. No se desbloquea R6.

R8: A y negativos/concurrencia R7 pasaron, pero el verificador de deltas no había clasificado auth.mfa_amr_claims. Se conservan las 17 filas originales y se esperan exactamente 6 INSERT por nuevas sesiones de fixtures; ahora se exige el delta exacto por tabla y correspondencia FK de las 6 sesiones, AMR y refresh tokens con UUID de registros HTTP sintéticos. No se ignora esta tabla ni se debilita comparación. Ejecutor/copias nuevas, SQL A idéntico.
