# MAREA — TASK-002 / E2-S0
## Autorización de implementación local y validación técnica

Actúa como **Principal Software Engineer, Database Architect, Security Engineer y Staff SRE**, con responsabilidad sobre la integridad, mantenibilidad y evolución segura del sistema MAREA.

Trabaja con mentalidad de ingeniería de producto: prioriza implementaciones correctas, simples, verificables y compatibles con el sistema existente. Evita sobreingeniería, documentación redundante y ciclos innecesarios de autorización.

## 1. Contexto y autorización

E2-A quedó IMPLEMENTADO Y VALIDADO exclusivamente en copias locales sintéticas y aisladas.

Sus resultados incluyen sincronización de identidades, atomicidad de registro, controles privados, reconciliación, concurrencia, recuperación y conservación de datos.

TASK-002 sigue incompleta.

**Autorizo exclusivamente E2-S0 para implementación y pruebas en copias locales nuevas, sintéticas, desechables y aisladas.**

No autorizo todavía la aplicación de cambios al producto existente, entornos remotos ni el comienzo de E2-B u otros incrementos.

## 2. Objetivo

Diseñar, implementar y verificar una barrera efectiva contra operaciones destructivas heredadas que puedan eliminar recursos de MAREA durante la transición al nuevo modelo de identidad y titularidad.

El problema central es que el proceso actual de eliminación de cuentas puede borrar medios por prefijo personal antes de ejecutar la eliminación Auth.

Una protección que actúe únicamente durante DELETE Auth llega demasiado tarde.

S0 debe demostrar que ninguna ruta destructiva heredada incluida en el alcance probado pueda destruir recursos protegidos durante el proceso de transición.

El criterio crítico es **E2-T49: inflight_legacy_cleanup_is_fenced**.

## 3. Primera etapa: inspección técnica

Antes de implementar, inspecciona el código efectivo del repositorio, el SRS y los expedientes E2 aprobados.

Identifica:

- Puntos de entrada de `delete-account`.
- Implementación real de limpieza de Storage.
- Dependencias de Auth y perfiles.
- Workers, reintentos y operaciones privilegiadas.
- Rutas de acceso directo y posibles evasiones.
- Orden efectivo de las operaciones destructivas.
- Comportamiento del cliente actual ante respuestas HTTP 2xx.
- Capacidades reales de la versión instalada de Supabase Auth y Storage.

No inventes servicios, APIs, workers o contratos inexistentes.

Produce un diagnóstico técnico breve y utilízalo inmediatamente para seleccionar la implementación mínima suficiente.

No conviertas esta etapa en una nueva auditoría general del producto.

## 4. Arquitectura de S0

Implementa en el laboratorio una estrategia verificable de contención de operaciones destructivas.

La estrategia deberá contemplar:

**A. Bloqueo de nuevas operaciones incompatibles**

Impedir que se inicien nuevas ejecuciones destructivas heredadas durante la transición.

**B. Control de operaciones en curso**

Identificar, detener, drenar o invalidar operaciones iniciadas antes de activar S0.

No asumir que bloquear nuevas solicitudes cancela automáticamente operaciones ya iniciadas.

**C. Protección en la frontera física**

Verificar que una operación heredada no pueda eliminar bytes protegidos mediante Storage API después de la transición de seguridad.

Una comprobación de RLS o un trigger Auth no constituyen por sí solos evidencia suficiente.

**D. Estado y coordinación**

Utilizar únicamente los mecanismos persistentes, versiones, barreras o controles de ejecución realmente necesarios para demostrar seguridad e idempotencia.

No introducir infraestructura distribuida innecesaria.

**E. Compatibilidad**

No responder con éxito de eliminación cuando únicamente se registró o bloqueó una solicitud.

El cliente legado no debe recibir una confirmación falsa de purga completada.

Si la implementación requiere modificar código existente de Edge, crea una copia o variante de laboratorio. Documenta el parche necesario para el producto, pero no lo apliques a las fuentes operativas sin autorización posterior.

## 5. Entorno de ejecución

Crear clones completamente nuevos derivados de fuentes E2-A verificadas.

Antes de ejecutar servicios:

1. Validar aislamiento real de red y namespaces.
2. Verificar imágenes, versiones y permisos.
3. Confirmar procedencia de respaldos.
4. Comprobar recuperación PostgreSQL y Storage.
5. Registrar hashes y catálogo inicial.
6. Garantizar ausencia de conexiones a proyectos remotos.

Se permite arrancar Auth, PostgreSQL, Storage API y servicios locales estrictamente necesarios para realizar pruebas reales, únicamente dentro del laboratorio sintético y aislado.

No reutilizar los volúmenes de E1, E2-A, TASK-001 ni las corridas fallidas anteriores.

## 6. Desarrollo guiado por pruebas

Primero reproduce el comportamiento peligroso en fixtures desechables y conserva evidencia RED.

Después implementa S0 y ejecuta las pruebas GREEN.

### Prueba obligatoria E2-T49

Construye un escenario reproducible:

1. Existe un medio físico usado por un recurso protegido.
2. Una ejecución heredada inicia su procedimiento de limpieza.
3. La ejecución alcanza una frontera controlable anterior a la eliminación física.
4. Se activa la barrera S0.
5. Se intenta reanudar la ejecución anterior.
6. Se comprueba que no elimina el archivo ni sus referencias protegidas.

No basta con que el worker devuelva un error.

Compara físicamente los bytes, hashes, metadatos y relaciones persistentes antes y después.

Comprueba también las operaciones nuevas, reintentos tardíos, ejecución concurrente y rutas privilegiadas relevantes.

Si la versión heredada permite completar una eliminación ya autorizada e iniciada antes del control, no declares PASS por simular una protección inexistente. Demuestra una estrategia real de quiescencia y drenaje o registra el bloqueo.

### Pruebas adicionales

Incluye:

- Solicitudes duplicadas.
- Respuestas perdidas y reintentos.
- Fallos antes y después de operaciones externas.
- Workers detenidos y reanudados.
- Intentos de evasión desde contextos privilegiados.
- Activos utilizados por más de un recurso.
- Protección de referencias y archivos físicos.
- Conservación y recuperación tras fallos.
- Rechazo seguro cuando el estado de S0 sea desconocido o inconsistente.

Utiliza la Storage API efectiva para las operaciones físicas que deban comprobarse. No simules la eliminación de archivos mediante DELETE SQL de metadatos.

## 7. Autonomía técnica y resolución de incidencias

Tienes autorización para diagnosticar, corregir y volver a ejecutar problemas internos de herramientas y fixtures dentro de este mismo laboratorio.

Esto incluye errores de harness, instrumentación, serialización, manifiestos, transporte PAX y verificadores, siempre que las correcciones:

- Permanezcan dentro del alcance local autorizado.
- No reduzcan ninguna garantía de integridad o aislamiento.
- No ignoren fallos reales.
- No alteren resultados históricos.
- Conserven la causa y evidencia original del fallo.
- Se verifiquen primero mediante pruebas pequeñas y reproducibles.

No solicites nueva autorización por cada defecto ordinario de instrumentación.

Sin embargo, **detente obligatoriamente** ante exposición externa, pérdida inesperada de datos protegidos, drift no explicado, ampliación de privilegios, necesidad de modificar entornos reales o cambios que excedan S0.

No continúes indefinidamente ante fallos repetidos del laboratorio. Identifica la causa raíz y entrega un bloqueo concreto si no puede resolverse dentro del alcance.

## 8. Restricciones innegociables

No realizar:

- Operaciones remotas o acceso a datos reales.
- Cambios en Flutter.
- Modificaciones operativas de Edge, Auth o Storage del producto.
- Cambios en `missions.author_id` o sus claves foráneas.
- Modificaciones destructivas de datos históricos.
- Implementación de E2-B, C, D, M, K, F, X o R.
- Implementación de TASK-003.
- Cambios normativos o interpretaciones nuevas del SRS.
- Commits o staging automáticos.

Las decisiones D02–D10 que correspondan a hitos posteriores permanecen pendientes.

No afirmar que S0 resuelve el ciclo completo de eliminación de cuentas.

## 9. Criterios de aceptación

Considera S0 VALIDADO_LOCALMENTE únicamente si:

1. El preflight y las pruebas de recuperación son satisfactorios.
2. La implementación de laboratorio demuestra bloqueo efectivo de las rutas relevantes.
3. E2-T49 pasa mediante ejecución real con archivos sintéticos.
4. Las operaciones iniciadas antes de la barrera se contienen o drenan de manera verificable.
5. No se pierden recursos protegidos.
6. Las rutas privilegiadas incluidas en el alcance están verificadas.
7. Los datos legados y las evidencias anteriores se conservan.
8. Los fallos y reintentos permanecen controlados.
9. Las pruebas negativas demuestran rechazo efectivo.
10. El mecanismo puede explicarse, mantenerse y reproducirse.

No elevar pruebas unitarias, simulaciones o ausencia de errores a aceptación integral si falta evidencia real.

## 10. Entrega esperada

Produce un informe ejecutivo y técnico con:

- Resultado: PASS, FAIL o BLOCKED.
- Qué problema se resolvió.
- Arquitectura implementada y justificación.
- Archivos nuevos y cambios de laboratorio.
- Prueba E2-T49, pasos y resultados.
- Pruebas positivas, negativas y de concurrencia.
- Conservación de datos, Storage y fuentes.
- Defectos encontrados y corregidos.
- Límites del laboratorio y riesgos restantes.
- Cambios operativos futuros que requerirán autorización.
- Siguiente incremento recomendado y sus dependencias.

Evita informes gigantescos que repitan toda la historia de TASK-001 y TASK-002. Conserva la trazabilidad técnica necesaria y presenta una síntesis útil para tomar decisiones.

**Al finalizar S0, detente. No comiences automáticamente E2-B.**

El objetivo es avanzar con rigor y eficiencia, no maximizar la cantidad de documentos o pruebas irrelevantes.

La fecha de entrega académica de MAREA es el **19 de noviembre de 2026**. Prioriza el camino crítico y elimina trabajo incidental sin reducir garantías esenciales.