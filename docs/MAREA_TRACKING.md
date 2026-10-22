

<!-- MAREA:GENERATED:BEGIN -->
# Seguimiento de MAREA

Línea base histórica **AUDIT-2026-10-13**, revisión 2026-10-13T06:52:08.029Z, commit 989e5b5845deff0afd13703a067a7d7a3775d3bc, SRS v5.0. [Fuente histórica](evidence/2026-10-13/task002/run-20261014T003000Z/SRS-5.0.md). Fuente de diseño autorizada: [SRS v5.1.1](MAREA_SRS.md), SHA256 4a1c28594e68d26180390b9aea3affce18a619039ad25ad1c8c528dc3d2f4388. Adopción efectiva: **PENDIENTE_COMPATIBILIDAD_LOCAL**. Registro canónico: [YAML](MAREA_REQUIREMENTS_STATUS.yaml). Integración documental no acredita migración, datos reales, release ni autorización remota. Estados/criterios preexistentes conservan su evaluación histórica; 144 registros requieren reauditoría y 21 casos TC permanecen pendientes.

## Diagnóstico ejecutivo

MAREA contiene una aplicación Flutter amplia y un backend legado desplegado en desarrollo. Su implementación no coincide todavía con varios contratos v5 del flujo central: organización/membresía, ofertas con reserva y TTL, acuerdos bilaterales, versiones aceptadas y resultados verificables. Las suites locales aprobadas no acreditan esos contratos ni un release multiplataforma. No se declara ningún módulo terminado. Las características sociales y AR requieren decisión de alcance/aislamiento; no se elimina código. TASK-002 consolida SRS v5.1.1 y trazabilidad documental con autorización acotada. Sus contratos aplican al organizador autorizado personal u organizacional. E/U0 son propuestas: no se ejecutaron migraciones ni código funcional. La baseline efectiva histórica v5.0 y TASK-001 se conservan; adopción v5.1.1 pendiente de compatibilidad. Datos sintéticos no prueban todos los datos reales ni autorizan remoto.

| Ámbito | Auditoría RF | Implementados | Validación histórica | Validación vigente | Con pruebas asociadas | Pendientes | Retrabajo |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BASE | 94/95 (98.9 %) | 5/95 (5.3 %) | 0/95 (0.0 %) | 0/95 (0.0 %) | 47/95 (49.5 %) | 30 | 10 |
| PILOTO | 185/186 (99.5 %) | 10/186 (5.4 %) | 0/186 (0.0 %) | 0/186 (0.0 %) | 82/186 (44.1 %) | 70 | 20 |
| PRODUCTO_COMPLETO | 311/313 (99.4 %) | 28/313 (8.9 %) | 0/313 (0.0 %) | 0/313 (0.0 %) | 137/313 (43.8 %) | 106 | 37 |

Catálogo completo: 517/684 (75.6 %) evaluado. Candidatos ORF: 7; innecesarios confirmados: 0. Evidencias potencialmente obsoletas por cambio detectado: E-NORM-001, E-RUN-TRACKING, E-SRC-101, E-RUN-TRACKING-FINAL, E-RUN-TRACKING-SOURCE-BINDING, E-TASK001-SUPABASE-20261013T164530Z, E-TASK001-SCHEMA-20261013T164530Z, E-TASK001-SUITES-20261013T164530Z, E-TASK001-GUARDS-20261013T164530Z, E-TASK001-INTEGRITY-20261013T164530Z, E-TASK002-E, E-TASK002-U0, E-TASK002-U0-CONSISTENCY, E-TASK002-E-DIAGNOSIS, E-TASK002-E2A-ISOLATION-20261019.

## Por módulo y fase

| Módulo | Fases normativas | Auditoría | Implementados | Validación vigente | Parciales | Retrabajo | Pendientes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| M01 | BASE | 13/14 (92.9 %) | 1/14 (7.1 %) | 0/14 (0.0 %) | 7 | 3 | 2 |
| M02 | BASE | 15/15 (100.0 %) | 0/15 (0.0 %) | 0/15 (0.0 %) | 3 | 0 | 12 |
| M03 | BASE | 14/14 (100.0 %) | 1/14 (7.1 %) | 0/14 (0.0 %) | 8 | 3 | 2 |
| M04 | PILOTO | 12/12 (100.0 %) | 2/12 (16.7 %) | 0/12 (0.0 %) | 6 | 0 | 4 |
| M05 | PILOTO | 10/10 (100.0 %) | 0/10 (0.0 %) | 0/10 (0.0 %) | 5 | 1 | 4 |
| M06 | PILOTO | 6/7 (85.7 %) | 1/7 (14.3 %) | 0/7 (0.0 %) | 2 | 0 | 3 |
| M07 | PILOTO | 12/12 (100.0 %) | 2/12 (16.7 %) | 0/12 (0.0 %) | 9 | 0 | 1 |
| M08 | PILOTO | 19/19 (100.0 %) | 0/19 (0.0 %) | 0/19 (0.0 %) | 11 | 4 | 4 |
| M09 | PILOTO | 14/14 (100.0 %) | 1/14 (7.1 %) | 0/14 (0.0 %) | 8 | 4 | 1 |
| M10 | PILOTO | 14/14 (100.0 %) | 0/14 (0.0 %) | 0/14 (0.0 %) | 3 | 0 | 11 |
| M11 | PILOTO | 12/12 (100.0 %) | 0/12 (0.0 %) | 0/12 (0.0 %) | 6 | 2 | 4 |
| M12 | PILOTO | 12/12 (100.0 %) | 0/12 (0.0 %) | 0/12 (0.0 %) | 7 | 1 | 4 |
| M13 | PILOTO | 12/12 (100.0 %) | 0/12 (0.0 %) | 0/12 (0.0 %) | 2 | 1 | 9 |
| M14 | PILOTO | 11/11 (100.0 %) | 1/11 (9.1 %) | 0/11 (0.0 %) | 5 | 3 | 2 |
| M15 | PILOTO | 11/11 (100.0 %) | 2/11 (18.2 %) | 0/11 (0.0 %) | 5 | 3 | 1 |
| M16 | POST | 8/8 (100.0 %) | 2/8 (25.0 %) | 0/8 (0.0 %) | 3 | 2 | 1 |
| M17 | BASE | 14/14 (100.0 %) | 1/14 (7.1 %) | 0/14 (0.0 %) | 8 | 0 | 5 |
| M18 | PILOTO | 10/10 (100.0 %) | 1/10 (10.0 %) | 0/10 (0.0 %) | 6 | 0 | 3 |
| M19 | BASE | 11/11 (100.0 %) | 0/11 (0.0 %) | 0/11 (0.0 %) | 7 | 1 | 3 |
| M20 | PILOTO | 11/11 (100.0 %) | 0/11 (0.0 %) | 0/11 (0.0 %) | 1 | 0 | 10 |
| M21 | POST | 11/11 (100.0 %) | 3/11 (27.3 %) | 0/11 (0.0 %) | 3 | 0 | 5 |
| M22 | PILOTO | 10/10 (100.0 %) | 0/10 (0.0 %) | 0/10 (0.0 %) | 5 | 1 | 4 |
| M23 | BASE | 15/15 (100.0 %) | 2/15 (13.3 %) | 0/15 (0.0 %) | 10 | 1 | 2 |
| M24 | PILOTO | 9/9 (100.0 %) | 0/9 (0.0 %) | 0/9 (0.0 %) | 4 | 0 | 5 |
| M25 | BASE | 12/12 (100.0 %) | 0/12 (0.0 %) | 0/12 (0.0 %) | 6 | 2 | 4 |
| M26 | CONDICIONAL | 13/13 (100.0 %) | 8/13 (61.5 %) | 0/13 (0.0 %) | 0 | 5 | 0 |

Un módulo requiere todos sus RF vigentes y controles aplicables validados para considerarse terminado. Ningún módulo se declara terminado por contar archivos.

## Por plataforma

| Plataforma | Denominador RF | Implementación auditada | Implementación completa identificada | Validación vigente | Distribución acreditada |
| --- | --- | --- | --- | --- | --- |
| web | 305 | 270/305 (88.5 %) | 26/305 (8.5 %) | 0/305 (0.0 %) | 0 |
| android | 309 | 274/309 (88.7 %) | 28/309 (9.1 %) | 0/309 (0.0 %) | 0 |
| ios | 309 | 274/309 (88.7 %) | 28/309 (9.1 %) | 0/309 (0.0 %) | 0 |

Backend DESARROLLO por confirmación humana; entorno operativo pendiente de piloto pequeño y lanzamiento. El backend no prueba distribución de clientes.

## Implementación completa identificada

- RF-01-013: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-03-011: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-04-004: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-04-007: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-06-002: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-07-003: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-07-010: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-09-003: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-14-007: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-15-004: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-15-008: Ejecutar pruebas específicas contra backend aislado cuando aplique, evaluar casos límite/autorización y verificar web, Android e iOS antes de marcar VALIDADO.
- RF-16-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-16-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-013: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-009: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-010: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-015: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-26-001: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-002: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-003: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-004: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-005: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-006: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-007: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-012: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.

## Parciales

- RF-01-002: Evaluar/implementar: Verificar dirección antes de activar. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-01-003: Evaluar/implementar: Impedir activación sin declaración; Tratar cuentas no elegibles. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-01-004: Evaluar/implementar: Gestionar expiración; Revocar remotamente sesiones activas. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-01-005: Evaluar/implementar: Expirar y rechazar reutilización en servidor; Limitar intentos en servidor. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-01-010: Evaluar/implementar: Gestionar sesión expirada y retorno; Mostrar acceso suspendido. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-01-011: Evaluar/implementar: Iniciar borrado Android; Iniciar borrado iOS; Ofrecer mecanismo web externo claro. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-01-014: Evaluar/implementar: Proteger verificación frente a reenvíos; Rechazar OTP reutilizado; Rechazar vínculo manipulado; Proteger invitaciones. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-001: Evaluar/implementar: Creador como capacidad personal. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-005: Evaluar/implementar: Resolver permiso organizacional por acción; Resolver estado operativo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-007: Evaluar/implementar: Indicar representación de organización. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-002: Evaluar/implementar: Seleccionar ciudad piloto declarada. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-004: Evaluar/implementar: Habilidades opcionales editables. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-005: Evaluar/implementar: Retomar guía de perfil; Retomar tutorial por ayuda contextual. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-006: Evaluar/implementar: Selector Sistema/Español; Resolver locale automático. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-009: Evaluar/implementar: Localizar UI y errores; Localizar push; Localizar correo Auth; Localizar avisos legales. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-012: Evaluar/implementar: Elegir claro/oscuro; Tamaño dinámico de texto; Reducción de movimiento. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-013: Evaluar/implementar: Consentimientos separados por finalidad; Revocar permiso SO sin bloquear descubrimiento; Revocar consentimiento de difusión independiente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-014: Evaluar/implementar: Gestionar sesiones activas; Exportar datos; Acceder a soporte; Bloquear usuario. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-001: Evaluar/implementar: Publicar disciplina y habilidades; Publicar ciudad personal; Evitar domicilio personal. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-002: Evaluar/implementar: Identidad comercial autónoma; Sector; Contacto controlado. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-003: Evaluar/implementar: Fecha orientativa de proyecto. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-005: Evaluar/implementar: Validar tamaño/tipo de archivo adjunto. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-008: Evaluar/implementar: Verificar destino externo; Advertir salida de MAREA. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-012: Evaluar/implementar: Registrar última actualización; Mostrar fecha pública pertinente; Pedir revisión de datos antiguos. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-001: Evaluar/implementar: Nombre y dirección comercial; IANA de sede; Mapa; Contacto autorizado. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-002: Evaluar/implementar: Distinguir sede verificada/reclamada; Distinguir aportación de usuario. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-003: Evaluar/implementar: Excepciones; Accesibilidad; Servicios de sede. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-009: Evaluar/implementar: Evitar falsa apertura actual; Vigencia de horario/accesibilidad; Definir señal de verificación. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-010: Evaluar/implementar: Control de seguridad/autoridad por sede. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-06-001: Evaluar/implementar: Disciplinas/categorías consistentes; Versionar taxonomía; Catalogar habilidades; Catalogar tipo de sede. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-06-004: Evaluar/implementar: Múltiples etiquetas; Habilidades profesionales múltiples; Vocabulario libre limitado. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-001: Evaluar/implementar: Leer oportunidad real de backend; Filtrar ciudad; Filtrar publicable; Mostrar actualización. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-002: Evaluar/implementar: Filtrar disciplina; Filtrar compensación; Filtrar disponibilidad. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-004: Evaluar/implementar: No aparentar oferta disponible sin cupo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-005: Evaluar/implementar: Cambiar zona; Crear alerta voluntaria. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-006: Evaluar/implementar: Excluir expiradas sin automatización de estado; Mostrar historial no disponible. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-007: Evaluar/implementar: Minimizar datos públicos de misión. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-008: Evaluar/implementar: Explicar orden visible. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-011: Evaluar/implementar: URL estable de misión; Usable públicamente web; Redirigir a app instalada con vínculo verificado. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-012: Evaluar/implementar: Excluir privados en proyección; Limitar scraping abusivo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-001: Evaluar/implementar: Crear como organización autorizada; Comprobar elegibilidad. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-002: Evaluar/implementar: Objetivo y descripción; Habilidades/requisitos; Modalidad participación; Plazo independiente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-006: Evaluar/implementar: Responsable; Contacto; Alcance geográfico. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-007: Evaluar/implementar: Recuperar cambio tras interrupción; Preservar offline protegido con conflicto. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-008: Evaluar/implementar: Validar campos obligatorios antes de publicar. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-009: Evaluar/implementar: Validar políticas/seguridad; Validar membresía/estado operativo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-013: Evaluar/implementar: Impedir postular al plazo; Impedir por cupos bilaterales; Persistir expiración automática. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-014: Evaluar/implementar: Validar existencia/autoridad ubicación; Denegar actor suspendido. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-016: Evaluar/implementar: Registrar transición temporal; Actor auditado por evento; Razón cancelación; Razón moderación. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-017: Evaluar/implementar: Conservar convocatoria cerrada. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-018: Evaluar/implementar: Evento separado físicamente; PublicActivity canónica. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-001: Evaluar/implementar: Comprobar restricciones de bloqueo/control. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-002: Evaluar/implementar: Disponibilidad; Contexto actuación/revisión. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-004: Evaluar/implementar: Retener fila sin borrado inmediato; Retener evidencia de abuso según política. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-006: Evaluar/implementar: Filtrar criterios publicados; Evitar inferencias presentadas como hechos. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-008: Evaluar/implementar: Estado canónico. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-012: Evaluar/implementar: Mostrar a organizador legítimo; Permiso organizacional application.review. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-013: Evaluar/implementar: Detectar control relacionado; Excluir reputación artificial. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-014: Evaluar/implementar: Gestionar cambio material y ofertas temporales. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-004: Evaluar/implementar: No presentar revisión jurídica; Comunicar ausencia garantía económica al acuerdo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-011: Evaluar/implementar: Documentar compensación de acuerdo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-014: Evaluar/implementar: Idempotencia selección actual; Idempotencia aceptación bilateral; Idempotencia cancelación de acuerdo; Idempotencia cambio. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-001: Evaluar/implementar: Conversación privada de acuerdo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-003: Evaluar/implementar: Mostrar organización representada. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-004: Evaluar/implementar: Enviar adjuntos permitidos; Validar tipo tamaño contenido adjunto. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-005: Evaluar/implementar: Estado envío/error; Estado recibido comprobable. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-011: Evaluar/implementar: Minimizar contacto/ubicación personal; Preview configurable segura. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-012: Evaluar/implementar: Conservar orden de conversación; Reintentar adjuntos privados. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-001: Evaluar/implementar: Actividad futura distinta de Mission; Resultado confirmado independiente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-003: Evaluar/implementar: Fecha/hora y sede; Condiciones de acceso/capacidad; Nivel visibilidad. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-004: Evaluar/implementar: Consentir publicación desde acuerdo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-007: Evaluar/implementar: Mostrar capacidad informativa. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-008: Evaluar/implementar: Guardar actividad como contenido; Agenda personal; Añadir a calendario externo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-010: Evaluar/implementar: Despublicar por moderación; Detectar riesgo/sede no autorizada; Auditar y notificar. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-012: Evaluar/implementar: No inferir asistencia de vistas/guardados. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-011: Evaluar/implementar: No atribuir puntuación de seguridad; No atribuir fiabilidad sin evidencia. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-012: Evaluar/implementar: Registrar cancelación; Registrar no respuesta/disputa; Excluir detalle privado de proyección pública. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-001: Evaluar/implementar: Mapa de sedes autorizadas; Mapa de actividades autorizadas. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-002: Evaluar/implementar: Ciudad/barrio manual. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-005: Evaluar/implementar: Mostrar precisión del marcador; Mostrar incertidumbre sensor cuando pertinente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-006: Evaluar/implementar: Alternar a lista equivalente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-009: Evaluar/implementar: Reportar misión que contiene punto; Clasificar marcador equivocado/cerrado/duplicado/sensible; Ocultación proporcional. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-15-001: Evaluar/implementar: Selección; Aceptación bilateral; Cambios acuerdo; Reporte/cuenta. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-15-003: Evaluar/implementar: Preferencia push; Preferencia correo; Preferencia dentro app; Preferencia por clase de evento. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-15-005: Evaluar/implementar: Revalidar acceso recurso actual. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-15-007: Evaluar/implementar: Agrupar repetidos; Frecuencia MAREA; Limitar actividad masiva. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-15-010: Evaluar/implementar: Plantilla push español; Plantilla correo localizada; Resolver idioma preferido al envío. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-16-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-16-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-16-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-009: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-011: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-014: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-009: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-010: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-009: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-011: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-009: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-011: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-009: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-010: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-009: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-010: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-012: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-013: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-24-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-24-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-24-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-24-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-009: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-010: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.

## En progreso

Ninguno acreditado en esta línea base.

Sin evidencia de tarea activa, no se infiere desarrollo actual de commits recientes.

## Pendientes

- RF-01-008: Evaluar/implementar: Ofrecer MFA a usuario; Exigir MFA administrativo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-01-012: Evaluar/implementar: Distinguir baja personal; Distinguir renuncia organizacional; Conservar contenido compartido ajeno. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-002: Evaluar/implementar: Crear organización diferenciada; Representarla sin sustituir identidad personal. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-003: Evaluar/implementar: Pertenecer a varias organizaciones; Evitar copia/fusión de cuentas. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-004: Evaluar/implementar: Registrar membresía vigente; Asignar roles organizacionales mínimos; Aplicar permisos mínimos. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-006: Evaluar/implementar: Seleccionar identidad antes de publicar; Seleccionar contexto al postular; Seleccionar contexto al mensajear. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-008: Evaluar/implementar: Varias sedes por organización; Separar sede de domicilio personal. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-009: Evaluar/implementar: Invitar membresía; Aceptar/rechazar membresía; Revocar membresía; Registrar emisor receptor vigencia contexto. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-010: Evaluar/implementar: Controlar abandono de último propietario; Permitir eliminación personal con UNOWNED_RESTRICTED; Supervisar transferencia/disolución. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-011: Evaluar/implementar: Reautenticar propietario; Aceptar receptor elegible; Auditar transferencia. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-012: Evaluar/implementar: Conservar recursos organizacionales; Eliminar/desvincular identidad personal; Aplicar retención por categoría. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-013: Evaluar/implementar: Revocar lectura; Revocar escritura; Revocar archivos; Revocar Realtime sin reconexión voluntaria. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-014: Evaluar/implementar: Cerrar organización y sede; Suspender nuevas obligaciones; Reclamar con prueba de control. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-02-015: Evaluar/implementar: Probar titular de varias entidades; Rechazar recurso de entidad ajena. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-007: Evaluar/implementar: Persistir idioma por cuenta; Persistir local sin sesión; Resolver precedencia cuenta/local/OS. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-008: Evaluar/implementar: Actualizar UI al cambiar idioma; Actualizar mensajes; Preservar borrador activo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-006: Evaluar/implementar: Distinguir propia/colaboración; Registrar créditos autorizados. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-009: Evaluar/implementar: Mostrar badge por hecho comprobado; Explicar límites de señal. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-010: Evaluar/implementar: Denegar privado a bloqueado; Aplicar permiso al enlace compartido. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-04-011: Evaluar/implementar: Abrir vista de tercero del perfil propio; Comprobar proyección pública. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-004: Evaluar/implementar: Vincular sede habilitada; Exigir permiso administrador de sede. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-006: Evaluar/implementar: Reclamar duplicado; Corregir sede cerrada/incorrecta; Investigar suplantación. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-007: Evaluar/implementar: Definir zonas sensibles/prohibidas; Denegar publicación de punto. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-008: Evaluar/implementar: Ocultar sede; Despublicar sede; Conservar historial de acuerdos. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-06-003: Evaluar/implementar: Configurar dos categorías piloto; No presentar inexistentes/activas sin operación. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-06-006: Evaluar/implementar: Separar categoría editorial; Separar clasificación comercial; Separar filtro de seguridad. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-06-007: Evaluar/implementar: Estado activa/oculta/archivada/revisión; Estado por ciudad. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-07-009: Evaluar/implementar: Registrar búsqueda vacía agregada; Respetar consentimiento. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-005: Evaluar/implementar: Advertir compensación ambigua; Advertir trabajo gratuito engañoso. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-010: Evaluar/implementar: Persistir revisión inmutable; Enlazar revisión a cada postulación. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-015: Evaluar/implementar: Limitar publicaciones abusivas; Detectar duplicadas/fraudulentas; Revisar falsos positivos. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-019: Evaluar/implementar: Fusión como intención descriptiva; Trueque como compensación. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-010: Evaluar/implementar: Invitar creador concreto; Enlace/aviso autorizado; Respetar bloqueos/límites. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-001: Evaluar/implementar: Acuerdo independiente; Aceptar expresamente cada parte; Convertir reserva atómicamente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-002: Evaluar/implementar: Alcance y entregables; Lugar fecha ventana ejecución; Compensación declarada; Participantes. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-003: Evaluar/implementar: Versionar acuerdo; Registrar actor/contexto/revisión; Timestamp UTC y zona. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-005: Evaluar/implementar: Proponer fecha/alcance/lugar/compensación; Nueva revisión; Aceptar todas las partes afectadas. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-006: Evaluar/implementar: Conservar versiones anteriores; Restringir auditoría/disputa. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-007: Evaluar/implementar: Mostrar compromisos en agenda; Impedir publicación privada a terceros. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-008: Evaluar/implementar: Activar disponibilidad; Evitar dobles reservas de recurso. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-009: Evaluar/implementar: Cancelar anticipadamente acuerdo; Registrar causa y responsable; Notificar partes. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-010: Evaluar/implementar: Terminar acuerdo; Bloquear interpersonal; Denunciar seguridad sin destruir expediente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-012: Evaluar/implementar: Advertir no verificación de pago externo; Mostrar aviso junto a compensación acordada. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-10-013: Evaluar/implementar: Reportar no asistencia; Reportar incumplimiento; Reportar inseguridad; Preservar expediente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-006: Evaluar/implementar: Silenciar conversación; Cerrar alertas no críticas. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-008: Evaluar/implementar: Reportar mensaje; Evidencia mínima a moderación; Bloquear usuario. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-009: Evaluar/implementar: Cortar contacto abusivo; Canal administrativo acotado. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-010: Evaluar/implementar: Retención documentada; Privacidad conversación; Acceso excepcional por caso; No prometer E2EE inexistente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-002: Evaluar/implementar: Crear actividad de colaboración; Crear editorial autorizada; Registrar origen/fuente/vigencia. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-005: Evaluar/implementar: Programada/reprogramada; Cancelada/realizada; Suspendida; Evidencia de transición. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-006: Evaluar/implementar: Detectar cambio sustancial; Aceptar partes contratadas. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-009: Evaluar/implementar: Persistir UTC; Persistir IANA sede; Mostrar hora de sede. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-001: Evaluar/implementar: Confirmación independiente de cada parte; Vincular resultado a acuerdo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-003: Evaluar/implementar: No confirmar por silencio; Registrar SIN_RESPUESTA a plazo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-004: Evaluar/implementar: Evidencia proporcional resultado; No exigir fotos sin consentimiento. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-005: Evaluar/implementar: Autorizar publicación resultado; Etiqueta exacta nivel verificación. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-006: Evaluar/implementar: Atribuir colaboración elegible al portafolio; Gestionar permisos exhibición. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-007: Evaluar/implementar: Registrar disputa de autoría/créditos; Retirar material controvertido. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-008: Evaluar/implementar: Evaluación posterior elegible; Excluir reseña sin colaboración. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-009: Evaluar/implementar: Bloquear autoevaluación; Detectar evaluación coordinada/relacionada. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-010: Evaluar/implementar: Denunciar reseña; Solicitar revisión; Respuesta limitada. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-010: Evaluar/implementar: Abrir ruta externa explícita; Advertir abandono de MAREA. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-011: Evaluar/implementar: Desactivar categoría no operativa; Desactivar región; No fabricar ubicaciones. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-15-009: Evaluar/implementar: Recordar compromiso en hora sede; Respetar preferencias; No ejecutar acción crítica automáticamente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-16-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-010: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-17-012: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-18-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-010: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-010: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-20-011: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-007: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-21-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-014: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-24-002: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-24-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-24-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-24-008: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-24-009: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-005: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-006: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-012: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.

## Bloqueados y pausados

Ninguno acreditado en esta línea base.

Ninguno acreditado en esta línea base.

## Retrabajo

- RF-01-001: Corregir/completar: Explorar fichas sin sesión; Excluir campos privados de proyecciones. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-01-006: Corregir/completar: Reautenticar cambio de contraseña; Reautenticar eliminación; Reautenticar transferencia. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-01-007: Corregir/completar: No revelar existencia de correo al registrar; Respuesta neutra de recuperación; No enumerar al cambiar correo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-001: Corregir/completar: Explicar valor de oportunidades; Ofrecer descubrir/publicar como acción de bienvenida. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-003: Corregir/completar: Mostrar ciudad activa; Limitar cambio a zonas operativas; Informar fuera de cobertura. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-03-010: Corregir/completar: Persistir IANA de sede; Mostrar hora de sede inequívoca; Formato monetario regional; Pluralización regional. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-05-005: Corregir/completar: Consentimiento antes de publicar domicilio; Autoridad para propiedad ajena. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-003: Corregir/completar: Calcular cupo confirmado por acuerdo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-004: Corregir/completar: Compensación pagada; No remunerada explícita; Intercambio; Impedir modalidad ambigua; Términos explícitos. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-011: Corregir/completar: Corregir editorial; Detectar todo cambio material; Crear nueva revisión; Renovar aceptación afectada. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-08-012: Corregir/completar: Pausar; Cerrar sin selección; Cancelar; Reapertura conforme contrato canónico; Duplicar sin propuestas. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-005: Corregir/completar: Mostrar enviada/no seleccionada/retirada; Mostrar en revisión/preseleccionada/oferta/caducada; Mostrar aceptación sólo como acuerdo activo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-007: Corregir/completar: Reservar cupo mediante oferta; Convertir reserva tras firma válida. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-009: Corregir/completar: Resolver pendientes sin espera eterna; Conservar información de cierre. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-09-011: Corregir/completar: Distinguir candidatura/preselección; Separar selección de aceptación bilateral. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-002: Corregir/completar: Autorizar actores por etapa; Restringir chat posterior a partes legítimas. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-11-007: Corregir/completar: Vincular lectura a misión; No exponer conversación privada a terceros; Revocar exmiembro; Aplicar bloqueo. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-12-011: Corregir/completar: Enlace público indexable; Actualizar cancelación; Datos estructurados válidos. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-13-002: Corregir/completar: Distinguir autodeclarado; Confirmado bilateral; Disputado/cancelado/sin respuesta. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-003: Corregir/completar: No exponer domicilio personal preciso. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-004: Corregir/completar: Validar autoridad antes de marcador exacto; Revocar difusión al cesar permiso. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-14-008: Corregir/completar: Privacidad en mapa; Privacidad en búsqueda/API; Privacidad en deep link. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-15-002: Corregir/completar: Clasificar actividad y mensajes MAREA; Promoción sólo opcional consentida; Canal esencial independiente. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-15-006: Corregir/completar: Minimizar payload confidencial; Proteger pantalla bloqueada; Proteger previews. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-15-011: Corregir/completar: Exigir consentimiento marketing; Evitar envío masivo sin finalidad aceptada. Añadir evidencia de servidor y pruebas pertinentes permitido/denegado/casos límite; comprobar runtime de web, Android e iOS sin inferirlo de Dart compartido.
- RF-16-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-16-003: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-19-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-22-001: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-23-011: Preparar integración LocalStorage protegida con Keychain/Keystore, migración de preferencias y prueba de sesión/borrado; no se modifica el producto en esta auditoría.
- RF-25-004: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-25-011: Completar las brechas descritas y verificar criterios positivos, negativos y permisos con evidencia por plataforma.
- RF-26-008: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-009: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-010: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-011: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.
- RF-26-013: Aportar aprobación y asegurar gate/aislamiento antes de habilitar; ejecutar criterios aplicables con evidencias.

## Defectos, seguridad y valor

Ver [informe](MAREA_AUDIT_REPORT.md) para evidencia por hallazgo y candidatos ORF. Ninguna recomendación autoriza eliminación de código.

## Respuestas a las quince preguntas

### 1. ¿Qué porcentaje está realmente implementado?

28/313 RF (8.9 %) con implementación completa identificada. 10 con comportamiento afirmativo localizado y 18 prohibiciones/posposiciones satisfechas. No equivale a funcionalidades operativas ni esfuerzo. 2 RF sin auditar.

### 2. ¿Qué porcentaje está implementado y verificado?

0/313 con validación integral vigente; 0 con estado histórico VALIDADO.

### 3. ¿Qué módulos están terminados?

No se certifica cierre de módulos con esta auditoría: ver criterios, controles, evidencia y plataformas en la matriz.

### 4. ¿Cuáles están parcialmente desarrollados?

La tabla de módulos detalla parciales y pendientes individualmente.

### 5. ¿Qué se está desarrollando actualmente?

0 RF con EN_PROGRESO registrado; no se infiere actividad actual sin asignación comprobada.

### 6. ¿Qué requisitos no tienen implementación localizada?

106 RF NO_INICIADO; ausencia observada tras revisión, sin afirmar que nunca se trabajó en ellos.

### 7. ¿Qué funcionalidades tienen errores?

Los FND documentan defectos de código/contrato y evidencia insuficiente; no son explotaciones o E2E remotos confirmados.

### 8. ¿Qué partes necesitan retrabajo?

37 RF; lista completa y motivos en esta vista y matriz.

### 9. ¿Qué código se desarrolló innecesariamente?

7 candidatos ORF y 0 innecesarios confirmados con aprobación humana. Ninguno autoriza retiro automático.

### 10. ¿Qué funcionalidades existen pero no están documentadas?

Stories, seguidores y feed general tienen diferencias de alcance. CMP sin correspondencia es investigación pendiente, no prueba de inutilidad.

### 11. ¿Qué falta para terminar cada fase?

Requisitos no completos/no validados de BASE/PILOTO, controles con fase pendiente y puertas G/B; ver sus registros individuales.

### 12. ¿Qué funciona en web, Android e iOS?

Consultar evidencia de compilación y corridas locales: no acredita runtime integral ni distribución. Ver tabla por plataforma y limitaciones.

### 13. ¿Qué requisitos carecen de pruebas?

176/313 RF sin prueba asociada. Una prueba asociada no demuestra suficiencia ni aprobación completa.

### 14. ¿Qué problemas de seguridad están pendientes?

Permisos negativos de servidor, sesiones móviles, medios/consentimiento, moderación/MFA, borrado/restauración y avisos Auth; ver FND y snapshots remotos.

### 15. ¿Cuáles son las próximas tareas y por qué?

TASK priorizadas: staging/autorización y contratos centrales, seguridad, aislamiento de fase y QA por plataforma.

## Próximas tareas priorizadas

### TASK-001 · P0 · Preparar staging y pruebas de autorización/contratos

La configuración remota sólo prueba existencia; pruebas mock pueden pasar con contratos RPC incompatibles.

Requisitos: RF-23-001, CTR5-01, CTR5-02, CTR5-03. Dependencias: ninguna declarada.

Cierre verificable: Entorno aislado aprobado, fixtures sintéticos y casos permitido/denegado/concurrencia/expiración sin tocar desarrollo remoto en esta auditoría.

### TASK-002 · P0 · Cerrar diseño organización, oferta, reserva y acuerdo

Selección unilateral no constituye acuerdo; cambios materiales y cupo necesitan servidor transaccional.

Requisitos: RF-02-002, RF-02-003, RF-02-004, RF-09-007, RF-10-001, CTR5-01, CTR5-03, CTR5-02, RF-02-005, RF-02-006, RF-02-007, RF-08-010, RF-08-011, RF-09-011, RF-09-012, RF-09-013, RF-10-003, RF-10-005, RF-10-006, RF-10-009, RF-10-010, RF-10-014. Dependencias: TASK-001.

Cierre verificable: N/T documentales + E aprobado técnicamente + migraciones/pruebas locales posteriores + U0 aprobado antes de Flutter; ambas modalidades; validación integral condicionada a TASK-003 y QA aplicable. Sin autorización remota.

### TASK-003 · P0 · Resolver seguridad de sesión, medios, moderación y borrado

Se identifican storage de sesión ordinario, controles de archivo incompletos, rol admin amplio y borrado sin garantías de supresión durable.

Requisitos: RF-01-006, RF-01-008, RF-01-011, RF-01-012, RF-23-004, RF-23-005, RF-23-011, RF-17-001, RF-25-004, CTR5-06. Dependencias: TASK-001.

Cierre verificable: Pruebas negativas, reautenticación/MFA, autorización por caso, procesamiento y restauración con supresiones; sin cambio remoto no autorizado.

### TASK-004 · P1 · Aprobar aislamiento de capacidades POST/CONDICIONAL

Feed, stories y AR aparecen antes de demostrar puertas/capacidad operativa.

Requisitos: RF-26-009, RF-26-011, RF-26-013. Dependencias: ninguna declarada.

Cierre verificable: Decisión humana por ORF, gates verificables y conservación del código sin retiro automático.

### TASK-005 · P1 · Completar descubrimiento público y QA por plataforma

Router público/SEO, permisos, idiomas y accesibilidad necesitan evidencia específica.

Requisitos: RF-01-001, RF-22-001, RF-22-003, RF-22-009, RF-23-013. Dependencias: TASK-001.

Cierre verificable: E2E web/Android/iOS, versiones/permiso rechazado/offline/lector y release separado.

### TASK-006 · P1 · Asignar responsables y resolver obligaciones/fases ambiguas

Gobernanza y evidencia externa no se sustituyen por IA; 0 validaciones integrales acreditadas.

Requisitos: G0, B01. Dependencias: ninguna declarada.

Cierre verificable: Responsables efectivos, aprobación de interpretaciones DEC y evidencias vigentes por ID, sin modificar SRS tácitamente.

## Fórmulas y exclusiones

PRODUCTO_COMPLETO es un ámbito agregado, no una fase asignada: incluye RF BASE, PILOTO, POST, CONDICIONAL y fase no resuelta. Todos los indicadores por cantidad son cobertura, no porcentaje de esfuerzo ni avance funcional desplegado.

- Auditoría RF = RF evaluados (implementación distinta de NO_AUDITADO) / RF vigentes del ámbito.
- Implementación = RF IMPLEMENTADO / RF vigentes; PARCIAL y REQUIERE_RETRABAJO no suman completos.
- Validación histórica = RF IMPLEMENTADO + estado registrado VALIDADO / RF vigentes.
- Validación vigente = RF completos con criterios y plataformas requeridos validados mediante evidencia PASS completa y actualmente aplicable / RF vigentes. Evidencia potencialmente obsoleta no suma; no se cambia el estado histórico.
- Cobertura de pruebas = RF con pruebas asociadas / RF vigentes; no demuestra suficiencia. Ejecución y aprobación se informan por corrida. El denominador global de casos obligatorios sigue sin validación integral y no se inventa.
- Pendientes, bloqueados y retrabajo = cantidad en cada estado / RF vigentes.
- Cobertura total = registros evaluados / todos los registros, incluidos controles, escenarios y auxiliares.
- Huérfanos = candidatos ORF registrados; innecesarios confirmados exige decisión humana aprobada.
- Avance individual = null salvo método documentado CRITERIA_EQUAL_COUNT (100 × criterios implementados / criterios obligatorios), que tampoco equivale a esfuerzo.

No se suman padres y subcriterios como RF independientes. VIGENTE y EN_REVISION permanecen en denominadores. Se excluyen NO_APLICA justificado, DUPLICADO, REEMPLAZADO, DESCARTADO y FUERA_DE_ALCANCE aprobados. Propuestas sin aprobar no excluyen trabajo. Fases ambiguas sólo se excluyen de sus cálculos específicos y siguen en el total.

RF de otras fases fuera de BASE: 218; fuera de PILOTO: 127. IDs y motivos reproducibles mediante cli.mjs metrics. Exclusiones de vigencia BASE: []; PILOTO: []; PRODUCTO_COMPLETO: []. Fase ambigua: 0 RF; 371 registros del catálogo. Con auditoría incompleta, las cifras representan mínimos acreditados; no se publica un porcentaje global definitivo de MAREA.

## Limitaciones

- **LIM-001:** Sin pruebas E2E contra backend ni matriz permitido/denegado con identidades reales o temporales: remoto sólo metadata. Evidencia pendiente: Staging aislado autorizado y fixtures controlados para RLS/Storage/Realtime/RPC.
- **LIM-002:** Compilaciones web, APK debug y app iOS simulador aprobaron en copia temporal con configuración ficticia. No se ejecutaron flujos completos en esas plataformas ni distribución. Xcode/simuladores disponibles, sin ejecución iOS de app/ARKit; tests Swift sólo host macOS. Evidencia pendiente: Corridas por plataforma con dispositivo/navegador, versión, permisos y recibos; publicación separada del backend.
- **LIM-003:** Sin equivalencia completa del cuerpo de migraciones/funciones locales y remotas; Deno no disponible y pruebas DB con escritura excluidas. Evidencia pendiente: Dump normalizado de metadatos/definiciones no personales y pruebas aisladas; no ejecutar tool/check_* sin revisar sus efectos.
- **LIM-004:** Controles externos y cláusulas transversales sin evidencia suficiente se conservan NO_AUDITADO individualmente. No existe porcentaje global definitivo ni esfuerzo realizado inferible. Evidencia pendiente: Responsables, documentos humanos, pruebas de obligación completa y aprobaciones por ID.
- **LIM-005:** No se consultaron conteos/filas de auth.users ni datos de personas; no se buscó demostrar ausencia de usuarios reales. Evidencia pendiente: Confirmación humana de entorno (ya recibida) y revisión agregada mínima sólo si necesaria.
- **LIM-006:** Subcriterios /Cxx son descomposición de auditoría, no IDs normativos nuevos ni ponderación aprobada. IDs TR-S* sólo identifican cláusulas antes sin ID. Evidencia pendiente: Congelar correspondencia de fragmento/hash; cambios normativos sólo con aprobación/versionado; no renumerar historial.
- **LIM-TASK001-20261013T164530Z:** Limitación histórica conservada de run-20261013T164530Z. TASK-001 incompleta: H1/H2 PASS; H3 falla conexión al PostgreSQL local con red interna. H4/H5 detenidos. No se acreditan autorizado/denegado/concurrencia/expiración reales. DDL destructivo histórico y job automático también impiden replay bajo las restricciones vigentes. Bloqueo superado en la continuación local; consultar E-TASK001-CONT-CAUSE/SCHEMA/SUITES/REPRO/CHECKS. Evidencia pendiente: Resolver arranque con aislamiento efectivo, revisar ruta no destructiva del esquema, ejecutar fixtures .invalid y Node HTTP/pgTAP/Dart; QA Android/iOS separado. Evidencias E-TASK001-SUPABASE-20261013T164530Z y E-TASK001-SUITES-20261013T164530Z.
- **LIM-TASK001-CONT:** El bloqueo histórico de run-20261013T164530Z queda superado por evidencia local H3/H4/H5; se conserva el evento anterior. Persisten cinco regresiones fallidas, cuatro contratos ausentes, tres restricciones de sesión sin configurar y seis escenarios de dispositivo pendientes. Cobertura parcial de filas/RPC. Ningún requisito VALIDADO por esta corrida. Evidencia pendiente: TASK-002/TASK-003 y QA posterior con pruebas de criterios completos, datos sintéticos y dispositivos reales.
<!-- MAREA:GENERATED:END -->
