# MAREA — TASK-002 / E2-B
## Implementación estructural de solicitudes de eliminación

Actúa como Principal Software Engineer, PostgreSQL Architect y Application Security Engineer.

Tu responsabilidad es implementar una solución técnicamente correcta, mínima, verificable y compatible con los requisitos existentes de MAREA.

**Autorizo exclusivamente la implementación y validación estructural local de E2-B**, utilizando copias nuevas, sintéticas y aisladas.

### 1. Estado de partida

Los incrementos E1, E2-A y E2-S0 cuentan con validación local y evidencias conservadas.

S0 demostró mediante Storage API real que las rutas destructivas heredadas pueden contenerse, incluidas operaciones iniciadas antes de activar la barrera.

TASK-002 permanece incompleta.

No confundas estos resultados con autorización operativa ni preparación para producción.

### 2. Decisiones acotadas para este incremento

**D02 — Política de datos**

Autorizo diseñar la infraestructura necesaria para representar finalidad, categoría, responsable, plazo, estado de conservación y disposición de datos.

Para las pruebas utiliza únicamente políticas sintéticas explícitamente etiquetadas.

No establezcas plazos legales o comerciales definitivos ni declares cumplimiento normativo integral.

Todo recurso sin política aplicable aprobada debe permanecer protegido contra purga irreversible.

**D03 — Candidaturas y relaciones dependientes**

Adopta una estrategia conservadora de protección.

Preserva identificadores, referencias y evidencias mínimas pertinentes. Registra las dependencias de perfiles y Auth y clasifica su tratamiento pendiente.

No autorices todavía eliminación física, cambios de FK ni retención universal de datos personales.

**D08 — Protocolo de eliminación**

Diseña contratos separados para solicitar eliminación, consultar progreso y confirmar finalización.

Una solicitud recibida no significa cuenta eliminada.

Los consumidores heredados no deben recibir respuestas que interpreten como eliminación final cuando solamente existe una solicitud pendiente.

No modifiques todavía Flutter ni el endpoint operativo.

Estas decisiones autorizan exclusivamente diseño implementable y pruebas estructurales sintéticas de B. Sus aspectos operativos, legales y destructivos siguen pendientes de aprobación.

### 3. Objetivo técnico

Implementar un mecanismo privado que:

1. Registre solicitudes de eliminación de manera durable e idempotente.
2. Vincule cada solicitud con el principal personal estable.
3. Mantenga controles de ciclo de vida independientes de las cascadas Auth.
4. Impida estados inconsistentes, duplicados o transiciones no autorizadas.
5. Permita consultar el progreso real de la operación.
6. Prepare manifiestos de recursos afectados sin recolectar información personal innecesaria.
7. Bloquee nuevas obligaciones personales incompatibles mediante controles transaccionales, donde existan motores reales capaces de verificarlos.
8. Impida la purga de una cuenta cuando falten postcondiciones o dependencias obligatorias.
9. Conserve las evidencias necesarias para continuar posteriormente con E2-D y E2-M.

No implementes mecanismos contractuales ficticios para aparentar que un flujo está terminado.

### 4. Metodología de ejecución

Inspecciona primero las fuentes reales de E2-A, S0, Auth, perfiles, candidaturas y eliminación existentes.

Reutiliza mecanismos probados cuando sean adecuados.

No recrees todo el laboratorio o las herramientas de aislamiento desde cero si los componentes verificados pueden reutilizarse con procedencia comprobable.

Prepara dos copias nuevas y ejecuta los preflight indispensables de aislamiento, integridad, catálogo, versiones, recuperación y permisos.

Después:

- Implementa las estructuras privadas mínimas.
- Escribe pruebas RED para los contratos faltantes.
- Implementa el comportamiento estructural autorizado.
- Ejecuta pruebas GREEN positivas y negativas.
- Verifica los permisos efectivos.
- Comprueba idempotencia y concurrencia.
- Realiza backup y restauración del resultado.
- Compara datos originales y deltas autorizados.

### 5. Pruebas obligatorias

Prioriza los casos estructurales aplicables del expediente E2:

- E2-T09: denegación de eliminación no preparada, utilizando únicamente intentos negativos seguros sobre fixtures desechables.
- E2-T10: reintentos y consistencia de solicitudes.
- E2-T46: acceso restringido a expedientes por autorización y finalidad.

Incluye pruebas de:

- Solicitudes duplicadas y claves reutilizadas con contenido distinto.
- Pérdida de respuesta después del commit.
- Estado de solicitud ausente o corrupto.
- Concurrencia entre solicitud y operaciones permitidas de laboratorio.
- Privilegios y accesos cruzados.
- Integridad de los controles tras recuperación.
- Compatibilidad estructural con E2-A y S0.

Ejecuta solamente las partes de E2-T11 que puedan demostrarse con funcionalidades realmente implementadas.

Marca BLOQUEADO o NO_IMPLEMENTADO cualquier escenario dependiente de acuerdos, ofertas, reservas, cliente Flutter, revocación TASK-003 o eliminación física completa.

No conviertas pruebas mock en evidencia de integración real.

### 6. Autonomía y eficiencia

Puedes corregir fallos ordinarios de instrumentación, fixtures y herramientas dentro del laboratorio autorizado.

Conserva las evidencias RED y documenta las correcciones importantes.

No solicites autorización por problemas menores de implementación que no modifiquen los límites establecidos.

Antes de repetir una restauración costosa, reproduce y resuelve el defecto en una prueba sintética mínima.

Evita auditorías generales, recreación innecesaria de herramientas y documentación duplicada.

Ante pérdida imprevista de datos, aislamiento no verificable, drift inexplicable, necesidad de ampliar privilegios o cambio de alcance, detén la ejecución.

### 7. Prohibiciones

No ejecutar purga exitosa de Auth, perfiles ni medios.

No modificar claves foráneas de misiones o candidaturas.

No ejecutar E2-C, D, M, K, F, X o R.

No modificar fuentes operativas Edge, RPC de negocio ni Flutter.

No modificar el SRS ni adoptar requisitos normativos nuevos por inferencia.

No acceder a datos reales, entornos remotos o volúmenes históricos.

No hacer commits ni staging.

No implementar TASK-003 como efecto secundario.

### 8. Entregables

Entrega un informe conciso que permita comprobar:

- Qué estructuras, funciones y controles se implementaron.
- Cuáles son sus permisos efectivos.
- Qué pruebas estructurales pasaron.
- Qué pruebas continúan bloqueadas y por qué.
- Qué filas y objetos cambiaron exactamente.
- Qué demuestran los respaldos y restauraciones.
- Qué decisiones de privacidad siguen pendientes.
- Qué dependencia concreta debe cerrarse después.

Actualiza el seguimiento y la trazabilidad únicamente con resultados efectivamente demostrados.

**Detente al completar E2-B estructural. No inicies otro incremento sin autorización.**

Fecha límite académica: 19 de noviembre de 2026. Prioriza resultados reproducibles y reduce trabajo incidental sin comprometer la integridad del sistema.