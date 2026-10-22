# MAREA — cronograma detallado de actividades

**Periodo:** 1 de septiembre–18 de noviembre de 2026. **Corte del estado real:** 6 de octubre de 2026, America/Mexico_City.

**Contenido:** 939 subtareas en 62 grupos. Investigación, aplicación, backend, diseños, pruebas y entrega técnica.

## Cómo leer E y R

- **E — Tiempo estimado:** duración propuesta en bloques y ubicación programada. Hasta el corte es una propuesta retrospectiva; después del corte es planificación futura.
- **R — Tiempo real:** duración que tomó efectivamente la tarea. No se infiere de commits, fechas de informes ni tiempos de ejecución de un procesador.
- Las filas R y sus duraciones quedan vacías porque las fuentes consultadas no registran intervalos laborales de ejecución por subtarea. Completado acredita resultado, no duración conocida.
- Un bloque es una de las cuatro divisiones del mes. Varios trabajos pueden coincidir en un bloque; no sumar tareas paralelas para calcular la duración del proyecto. La estimación no garantiza capacidad sin asignar responsables.
- Responsable asignado y Realizado por son espacios independientes para los nombres. En Excel se editan en Detalle y se reflejan en Cronograma.
- Para capturar R en Excel, registrar inicio real, fin real y duración real en bloques en Detalle. Las barras R aparecerán al completar los tres datos. No sustituir la duración efectiva por el mero número de semanas con un commit.

## Bloques del calendario

| Mes | S1 | S2 | S3 | S4 |
|---|---|---|---|---|
| Septiembre | 1–7 | 8–14 | 15–21 | 22–30 |
| Octubre | 1–7 | 8–14 | 15–21 | 22–31 |
| Noviembre | 1–7 | 8–14 | 15–18 | Fuera del periodo |

## Criterios de reconstrucción

El primer commit conservado es b92a237 del 11/09; b321100 del 17/09 contiene un checkpoint WIP. La raíz pública 1c7a5d0 del 22/09 no es el inicio del desarrollo. Se revisaron ramas y cambios actuales sin commit. Los merges y checkpoints no se cuentan como nuevas funciones.

Realización de investigación confirmada por el usuario en este chat; desglose temático reconstruido desde los requisitos y la arquitectura del repositorio. No acredita fechas ni el estudio individual de cada tema.

Los estados describen el resultado al corte. Completado puede significar código implementado, diseño entregado o prueba reportada, según el resultado y la fuente. Los reportes históricos se contrastaron con el piloto más reciente: push Android está activo; el piloto Docker/Supabase está verificado con fixtures sintéticos; Cloud Run y AR físico siguen pendientes. AR se conserva como WIP.

Las verificaciones del desarrollo se citan como resultados documentados: esta extracción no vuelve a ejecutar pruebas de la aplicación ni cambia servicios. Las correcciones futuras son condicionales a fallos observados. Firma iOS y facturación Google conservan sus dependencias externas. No se incluye informe ni presentación académicos.

Paleta del Excel: navy #0B255E, E azul #0D4397, R aqua #22C5C1, actividades mint #DDF5EF, blanco/Paper #FAF9F6 y cuadrícula #D9E5F0.

## Índice de etapas

| ID | Grupo | Subtareas | Bloques E |
|---|---|---:|---|
| INV01 | Investigación del problema y requisitos | 12 | SEP-1 |
| INV02 | Fundamentos de arquitectura, datos y seguridad | 14 | SEP-1 |
| INV03 | Fundamentos de mapas, panoramas y AR | 12 | SEP-1 |
| MVP01 | Base técnica y arquitectura inicial | 15 | SEP-2 |
| MVP02 | Diseño y navegación del primer MVP | 12 | SEP-2 |
| MVP03 | Autenticación del primer MVP | 15 | SEP-2 |
| MVP04 | Base de datos y cuenta del primer MVP | 13 | SEP-2 |
| MVP05 | Verificación del MVP | 7 | SEP-2 |
| ACC01 | Ampliación de acceso, seguridad y consentimientos | 20 | SEP-2 |
| ACC02 | Fotografías de perfil y almacenamiento privado | 19 | SEP-2 |
| COM01 | Comunidad y publicaciones iniciales | 20 | SEP-3 |
| QA01 | Verificaciones de cuenta y comunidad tempranas | 13 | SEP-3 |
| COM02 | Ubicación de publicaciones | 12 | SEP-3 |
| MIS01 | Primer flujo y ciclo de vida de misiones | 18 | SEP-3 |
| COM03 | Moderación y eliminación ampliada de cuenta | 11 | SEP-3 |
| GIT01 | Publicación del repositorio e integración del historial | 6 | SEP-4 |
| PRO01 | Experiencia profesional y confirmación de perfil | 16 | SEP-4 |
| PRO02 | Fichas de portafolio, catálogo y servicios | 25 | SEP-4 |
| ACC03 | Rediseño de registro mínimo y guías opcionales | 19 | SEP-4 |
| ACC04 | Reparación de registro, cámara y contrato remoto | 15 | SEP-4 |
| PRO04 | Herramientas y permisos de los cuatro perfiles | 12 | SEP-4 |
| PRO03 | Rediseño de perfil, edición y configuración | 16 | SEP-4 |
| DIS01 | Evolución visual y propuestas sustituidas | 16 | SEP-4 |
| DIS02 | Acabado v7 e identidad oficial | 8 | SEP-4 |
| SOC01 | Implementación de Inicio y post social v7 | 15 | SEP-4 |
| SOC02 | Reacciones, comentarios y compartir | 18 | SEP-4 |
| SOC03 | Guardados y colaboración en publicaciones | 12 | SEP-4 |
| SOC04 | Bandeja, privacidad y enlaces sociales | 15 | SEP-4 |
| SOC05 | Validación y correcciones de la experiencia social | 14 | SEP-4 |
| DIS03 | Implementaciones experimentales archivadas | 7 | SEP-4 |
| MIS02 | Rediseño del compositor y borradores de misión | 18 | SEP-4 |
| MIS03 | Candidatura estructurada y seguimiento | 16 | SEP-4 |
| MIS04 | Gestión privada y avisos del ciclo de misión | 18 | SEP-4 |
| MIS05 | Verificación y despliegue del rediseño de misiones | 14 | SEP-4 |
| MAP01 | Mapa de misiones y consulta geográfica | 29 | SEP-4 a OCT-1 |
| MAR01 | Iconos y recursos de identidad de la aplicación | 6 | OCT-1 |
| INT01 | Reacciones e interacciones modernas | 14 | OCT-1 |
| INT02 | Cargas, botones y paneles compartidos | 13 | OCT-1 |
| PUS01 | Cliente Android de notificaciones y preferencias | 17 | OCT-1 |
| PUS02 | Cola y entrega push en Supabase | 17 | OCT-1 |
| PUS03 | Configuración Firebase, despliegue y distribución | 20 | OCT-1 |
| PUS04 | Correcciones y pruebas de push ejecutadas | 14 | OCT-1 |
| TOU01 | Diseño de recorridos y experiencia presencial | 12 | OCT-1 |
| TOU02 | Editor del local, zonas, puntos y versiones | 24 | OCT-1 |
| TOU03 | Captura guiada y persistencia local | 18 | OCT-1 |
| TOU04 | Orientación nativa Android e iOS | 12 | OCT-1 |
| TOU05 | Importación GPano y carga privada reanudable | 14 | OCT-1 |
| TOU06 | Backend de recorridos, permisos y limpieza | 20 | OCT-1 |
| TOU07 | Procesador Hugin y Enblend | 19 | OCT-1 |
| TOU08 | Visor 360° y navegación del recorrido | 13 | OCT-1 |
| AR01 | Implementación AR nativa y recuperación — WIP | 22 | OCT-1 a OCT-3 |
| TOU09 | Progreso e integración de recorridos | 13 | OCT-1 |
| PIL01 | Piloto Docker local con Supabase real | 25 | OCT-1 |
| TOU10 | Verificación automática de recorridos | 12 | OCT-1 |
| FIS01 | Captura óptica real y calibración de panoramas | 19 | OCT-2 |
| FIS02 | Aceptación física de reconocimiento AR | 18 | OCT-2 a OCT-3 |
| COR01 | Correcciones posteriores a pruebas físicas | 9 | OCT-3 |
| CLO01 | Traspaso del procesador a Cloud Run | 18 | OCT-4 |
| QA02 | Pruebas reales pendientes de acceso, medios y ubicación | 10 | NOV-1 |
| QA03 | Matriz física adicional de push y regresión integrada | 12 | NOV-1 |
| PIL02 | Piloto de aceptación en un local real | 14 | NOV-2 |
| ENT01 | Estabilización y entrega técnica de la aplicación | 12 | NOV-3 |

## INV01 — Investigación del problema y requisitos

Realización de investigación confirmada por el usuario en este chat; desglose temático reconstruido desde los requisitos y la arquitectura del repositorio. No acredita fechas ni el estudio individual de cada tema.

### INV01.001 — Delimitar el problema de conexión comunitaria

**Estado:** Completado. **Tarea superior:** INV01.

Definir la necesidad de descubrir personas, proyectos y oportunidades locales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.002 — Identificar al usuario general

**Estado:** Completado. **Tarea superior:** INV01.

Describir su participación mediante publicaciones, búsqueda, guardados y misiones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.003 — Identificar necesidades de artistas y creadores

**Estado:** Completado. **Tarea superior:** INV01.

Separar exposición de obras, portafolio y colaboración.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.004 — Identificar necesidades de emprendimientos

**Estado:** Completado. **Tarea superior:** INV01.

Distinguir catálogo, productos, servicios y contacto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.005 — Identificar necesidades de negocios

**Estado:** Completado. **Tarea superior:** INV01.

Distinguir servicios, espacios, horarios, ubicación y recorridos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.006 — Definir funciones de administración

**Estado:** Completado. **Tarea superior:** INV01.

Separar moderación y acreditación del tipo de perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.007 — Inventariar requisitos funcionales

**Estado:** Completado. **Tarea superior:** INV01.

Organizar acceso, identidad, contenido, participación y recorridos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.008 — Inventariar requisitos no funcionales

**Estado:** Completado. **Tarea superior:** INV01.

Considerar privacidad, persistencia, compatibilidad y accesibilidad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.009 — Delimitar el primer MVP

**Estado:** Completado. **Tarea superior:** INV01.

Priorizar cuenta, sesión y perfil antes de la comunidad completa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.010 — Definir límites de alcance

**Estado:** Completado. **Tarea superior:** INV01.

Separar la aplicación de pagos, chat y reconstrucción 3D no implementados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.011 — Definir criterios de aceptación por módulo

**Estado:** Completado. **Tarea superior:** INV01.

Vincular cada capacidad con un resultado comprobable.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV01.012 — Estudiar navegación social móvil y web

**Estado:** Completado. **Tarea superior:** INV01.

Revisar jerarquía de Inicio, Explorar, Crear, Misiones y Perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** Sin dependencia identificada.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S002, S003.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

## INV02 — Fundamentos de arquitectura, datos y seguridad

Realización de investigación confirmada por el usuario en este chat; desglose temático reconstruido desde los requisitos y la arquitectura del repositorio. No acredita fechas ni el estudio individual de cada tema.

### INV02.001 — Estudiar Flutter y Dart para el cliente

**Estado:** Completado. **Tarea superior:** INV02.

Fundamentar la aplicación compartida para Android, web e iOS.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.002 — Estudiar integración nativa móvil

**Estado:** Completado. **Tarea superior:** INV02.

Separar responsabilidades Flutter, Kotlin y Swift.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.003 — Estudiar Supabase como backend

**Estado:** Completado. **Tarea superior:** INV02.

Relacionar Auth, PostgreSQL, Storage y Edge Functions.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.004 — Estudiar arquitectura por funcionalidades

**Estado:** Completado. **Tarea superior:** INV02.

Separar presentación, modelos, repositorios y servicios compartidos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.005 — Estudiar navegación y guards

**Estado:** Completado. **Tarea superior:** INV02.

Fundamentar protección de rutas y continuidad del destino interno.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.006 — Estudiar ciclo de sesión

**Estado:** Completado. **Tarea superior:** INV02.

Considerar persistencia, renovación, cierre y cambio de cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.007 — Estudiar modelado relacional

**Estado:** Completado. **Tarea superior:** INV02.

Relacionar perfiles, contenido, misiones y participación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.008 — Estudiar RLS y permisos por columna

**Estado:** Completado. **Tarea superior:** INV02.

Fundamentar aislamiento de filas y protección de campos internos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.009 — Estudiar operaciones atómicas

**Estado:** Completado. **Tarea superior:** INV02.

Considerar cupos, publicación, confirmaciones y cambios coordinados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.010 — Estudiar idempotencia de operaciones

**Estado:** Completado. **Tarea superior:** INV02.

Prevenir duplicados por reintentos y respuestas perdidas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.011 — Estudiar almacenamiento privado

**Estado:** Completado. **Tarea superior:** INV02.

Diferenciar originales privados, recursos visibles y URLs firmadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.012 — Estudiar privacidad de identidad y preferencias

**Estado:** Completado. **Tarea superior:** INV02.

Separar datos de acceso de la presentación pública.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.013 — Estudiar diseño accesible

**Estado:** Completado. **Tarea superior:** INV02.

Considerar contraste, controles de 48 px, teclado y texto ampliado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV02.014 — Estudiar pruebas por capas

**Estado:** Completado. **Tarea superior:** INV02.

Distinguir unidades, widgets, SQL aislado y servicios reales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S004, S005, S006.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

## INV03 — Fundamentos de mapas, panoramas y AR

Realización de investigación confirmada por el usuario en este chat; desglose temático reconstruido desde los requisitos y la arquitectura del repositorio. No acredita fechas ni el estudio individual de cada tema.

### INV03.001 — Estudiar coordenadas y precisión de ubicación

**Estado:** Completado. **Tarea superior:** INV03.

Diferenciar posición exacta, aproximada y ubicación textual.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.002 — Estudiar cartografía OpenStreetMap

**Estado:** Completado. **Tarea superior:** INV03.

Considerar teselas, atribución y consulta por área visible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.003 — Estudiar permisos de geolocalización

**Estado:** Completado. **Tarea superior:** INV03.

Distinguir solicitud explícita y exploración sin GPS.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.004 — Estudiar panoramas equirectangulares

**Estado:** Completado. **Tarea superior:** INV03.

Distinguir una esfera 360°×180° de una imagen horizontal común.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.005 — Estudiar metadatos GPano

**Estado:** Completado. **Tarea superior:** INV03.

Relacionar proyección, dimensiones y cobertura de esfera completa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.006 — Estudiar campo de visión y solapamiento

**Estado:** Completado. **Tarea superior:** INV03.

Fundamentar anillos, techo, piso y tomas desde una posición fija.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.007 — Estudiar cosido Hugin y mezcla Enblend

**Estado:** Completado. **Tarea superior:** INV03.

Separar coincidencias, optimización, remapeo y mezcla.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.008 — Estudiar reconocimiento de imágenes AR

**Estado:** Completado. **Tarea superior:** INV03.

Diferenciar reconocimiento físico de un QR o coordenada GPS.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.009 — Estudiar ARCore y ARKit

**Estado:** Completado. **Tarea superior:** INV03.

Considerar soporte nativo, ancho físico de referencia y tracking.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.010 — Estudiar orientación yaw, pitch y roll

**Estado:** Completado. **Tarea superior:** INV03.

Considerar ejes ópticos, horizonte, polos y costura angular.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.011 — Estudiar cargas reanudables TUS

**Estado:** Completado. **Tarea superior:** INV03.

Fundamentar checkpoints, offsets y recuperación por HEAD.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

### INV03.012 — Estudiar colas y leases de procesamiento

**Estado:** Completado. **Tarea superior:** INV03.

Considerar concurrencia, cancelación, reintentos y limpieza.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/09/2026 (SEP-1) | 07/09/2026 (SEP-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV01, INV02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S007, S008, S009, S010.

**Para cerrar o completar el registro:** Confirmar el detalle del tema estudiado y capturar su duración real.

## MVP01 — Base técnica y arquitectura inicial

La fecha corresponde al primer commit conservado; no identifica inicio ni duración de cada subtarea.

### MVP01.001 — Crear el proyecto Flutter

**Estado:** Completado. **Tarea superior:** MVP01.

Preparar la estructura ejecutable inicial de MAREA.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.002 — Configurar dependencias del MVP

**Estado:** Completado. **Tarea superior:** MVP01.

Integrar go_router y supabase_flutter en el manifiesto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.003 — Crear la entrada main.dart

**Estado:** Completado. **Tarea superior:** MVP01.

Inicializar Flutter y la configuración del cliente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.004 — Leer configuración pública de Supabase

**Estado:** Completado. **Tarea superior:** MVP01.

Obtener URL y clave publicable mediante defines.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.005 — Mostrar error de configuración faltante

**Estado:** Completado. **Tarea superior:** MVP01.

Evitar inicializar Supabase sin valores necesarios.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.006 — Crear AppSessionController

**Estado:** Completado. **Tarea superior:** MVP01.

Centralizar estado de sesión y carga del perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.007 — Crear el enrutador de la aplicación

**Estado:** Completado. **Tarea superior:** MVP01.

Definir destinos y redirecciones por sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.008 — Crear estados de error comunes

**Estado:** Completado. **Tarea superior:** MVP01.

Traducir fallos técnicos a mensajes de la aplicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.009 — Definir validadores de formularios

**Estado:** Completado. **Tarea superior:** MVP01.

Validar nombre, usuario, correo y contraseña.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.010 — Configurar Android com.marea.app

**Estado:** Completado. **Tarea superior:** MVP01.

Preparar identificador y minSdk 24 del MVP.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.011 — Preparar el proyecto iOS

**Estado:** Completado. **Tarea superior:** MVP01.

Conservar Runner, configuración Flutter y esquema de ejecución.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.012 — Preparar el cliente web

**Estado:** Completado. **Tarea superior:** MVP01.

Crear index, manifiesto e iconos iniciales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.013 — Configurar exclusiones de archivos locales

**Estado:** Completado. **Tarea superior:** MVP01.

Separar configuración y artefactos del código compartido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.014 — Configurar análisis estático

**Estado:** Completado. **Tarea superior:** MVP01.

Definir reglas Dart y análisis del proyecto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

### MVP01.015 — Documentar configuración y ejecución

**Estado:** Completado. **Tarea superior:** MVP01.

Explicar cómo conectar y ejecutar el primer MVP.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV02.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S012, S013, S014.

## MVP02 — Diseño y navegación del primer MVP

### MVP02.001 — Definir la paleta inicial MAREA

**Estado:** Completado. **Tarea superior:** MVP02.

Crear tokens navy, azul, aqua y superficies claras.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.002 — Instalar Nunito Sans local

**Estado:** Completado. **Tarea superior:** MVP02.

Incorporar pesos y licencia de la tipografía.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.003 — Definir espaciados y radios

**Estado:** Completado. **Tarea superior:** MVP02.

Uniformar formularios, tarjetas y controles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.004 — Personalizar Material 3

**Estado:** Completado. **Tarea superior:** MVP02.

Aplicar tema compartido a pantallas del MVP.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.005 — Crear el logotipo provisional en código

**Estado:** Completado. **Tarea superior:** MVP02.

Mostrar identidad inicial antes de integrar archivos oficiales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.006 — Crear el campo de texto compartido

**Estado:** Completado. **Tarea superior:** MVP02.

Reutilizar etiquetas, errores y entrada de datos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.007 — Crear el botón primario

**Estado:** Completado. **Tarea superior:** MVP02.

Unificar acción principal y estado de envío.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.008 — Crear layout de autenticación

**Estado:** Completado. **Tarea superior:** MVP02.

Adaptar formularios a móvil y escritorio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.009 — Crear shell de navegación

**Estado:** Completado. **Tarea superior:** MVP02.

Presentar Inicio, Explorar, Crear, Misiones y Perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.010 — Adaptar navegación al ancho de pantalla

**Estado:** Completado. **Tarea superior:** MVP02.

Separar presentación móvil y escritorio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.011 — Mostrar secciones próximas del MVP

**Estado:** Completado. **Tarea superior:** MVP02.

Explicar módulos aún no implementados sin datos falsos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

### MVP02.012 — Crear indicador inicial de avatar

**Estado:** Completado. **Tarea superior:** MVP02.

Mostrar iniciales o presentación disponible del perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S015, S016, S017.

## MVP03 — Autenticación del primer MVP

### MVP03.001 — Crear pantalla de carga inicial

**Estado:** Completado. **Tarea superior:** MVP03.

Resolver sesión antes de mostrar el destino.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.002 — Crear formulario inicial de registro

**Estado:** Completado. **Tarea superior:** MVP03.

Capturar identidad y credenciales del MVP.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.003 — Validar campos obligatorios de registro

**Estado:** Completado. **Tarea superior:** MVP03.

Impedir envío de datos incompletos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.004 — Validar formato de correo

**Estado:** Completado. **Tarea superior:** MVP03.

Mostrar errores antes de enviar el formulario.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.005 — Validar contraseña mínima

**Estado:** Completado. **Tarea superior:** MVP03.

Aplicar el requisito de acceso establecido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.006 — Consultar disponibilidad del username

**Estado:** Completado. **Tarea superior:** MVP03.

Detectar colisiones sin exponer perfiles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.007 — Registrar usuario en Supabase Auth

**Estado:** Completado. **Tarea superior:** MVP03.

Crear cuenta usando el repositorio de autenticación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.008 — Mostrar instrucción de confirmación de correo

**Estado:** Completado. **Tarea superior:** MVP03.

Presentar el siguiente paso tras registrar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.009 — Crear formulario de inicio de sesión

**Estado:** Completado. **Tarea superior:** MVP03.

Permitir acceso con correo y contraseña.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.010 — Mostrar fallos de autenticación

**Estado:** Completado. **Tarea superior:** MVP03.

Presentar error y permitir reintento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.011 — Persistir sesión entre aperturas

**Estado:** Completado. **Tarea superior:** MVP03.

Restaurar estado de acceso desde Supabase.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.012 — Cargar perfil después de autenticar

**Estado:** Completado. **Tarea superior:** MVP03.

Sincronizar identidad con la sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.013 — Proteger destinos privados

**Estado:** Completado. **Tarea superior:** MVP03.

Redirigir a acceso cuando no existe sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.014 — Cerrar sesión desde configuración

**Estado:** Completado. **Tarea superior:** MVP03.

Limpiar estado y regresar al acceso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

### MVP03.015 — Bloquear envíos repetidos

**Estado:** Completado. **Tarea superior:** MVP03.

Evitar solicitudes paralelas desde los botones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S018, S019, S020.

## MVP04 — Base de datos y cuenta del primer MVP

### MVP04.001 — Crear migración 001 de perfiles

**Estado:** Completado. **Tarea superior:** MVP04.

Definir perfil relacionado con auth.users.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.002 — Crear perfil mediante trigger de Auth

**Estado:** Completado. **Tarea superior:** MVP04.

Asignar identidad y rol desde servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.003 — Habilitar RLS en perfiles

**Estado:** Completado. **Tarea superior:** MVP04.

Restringir lectura y actualización a la cuenta autorizada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.004 — Proteger rol y timestamps

**Estado:** Completado. **Tarea superior:** MVP04.

Impedir escritura cliente de campos internos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.005 — Crear consulta segura de username

**Estado:** Completado. **Tarea superior:** MVP04.

Devolver disponibilidad sin publicar datos privados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.006 — Crear modelo Profile inicial

**Estado:** Completado. **Tarea superior:** MVP04.

Representar nombre, usuario y presentación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.007 — Crear repositorio de perfil

**Estado:** Completado. **Tarea superior:** MVP04.

Leer y actualizar los campos autorizados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.008 — Crear pantalla de perfil inicial

**Estado:** Completado. **Tarea superior:** MVP04.

Mostrar la identidad persistida.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.009 — Crear editor de identidad inicial

**Estado:** Completado. **Tarea superior:** MVP04.

Editar nombre, username y bio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.010 — Crear pantalla de configuración

**Estado:** Completado. **Tarea superior:** MVP04.

Reunir sesión y acciones de cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.011 — Implementar eliminación autenticada de cuenta

**Estado:** Completado. **Tarea superior:** MVP04.

Obtener identidad del JWT antes del borrado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.012 — Eliminar perfil mediante cascade

**Estado:** Completado. **Tarea superior:** MVP04.

Coordinar borrado de Auth y datos asociados del MVP.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

### MVP04.013 — Confirmar borrado desde el cliente

**Estado:** Completado. **Tarea superior:** MVP04.

Solicitar confirmación antes de ejecutar la acción.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S021, S022, S023.

## MVP05 — Verificación del MVP

Los archivos de pruebas acreditan su implementación; los comandos de README no se toman como prueba de ejecución.

### MVP05.001 — Probar configuración de la aplicación

**Estado:** Completado. **Tarea superior:** MVP05.

Cubrir valores disponibles y configuración faltante.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, MVP03, MVP04.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S024, S025.

### MVP05.002 — Probar validadores iniciales

**Estado:** Completado. **Tarea superior:** MVP05.

Cubrir entradas válidas y mensajes de error.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, MVP03, MVP04.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S024, S025.

### MVP05.003 — Probar estados de sesión

**Estado:** Completado. **Tarea superior:** MVP05.

Cubrir acceso, carga de perfil y cierre.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, MVP03, MVP04.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S024, S025.

### MVP05.004 — Probar redirecciones de rutas

**Estado:** Completado. **Tarea superior:** MVP05.

Verificar guards para destinos privados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, MVP03, MVP04.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S024, S025.

### MVP05.005 — Probar modelo inicial de perfil

**Estado:** Completado. **Tarea superior:** MVP05.

Verificar lectura de los campos del backend.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, MVP03, MVP04.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S024, S025.

### MVP05.006 — Probar pantallas y formularios

**Estado:** Completado. **Tarea superior:** MVP05.

Cubrir acciones visibles y errores del MVP.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, MVP03, MVP04.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S024, S025.

### MVP05.007 — Documentar comprobaciones remotas del MVP

**Estado:** Completado. **Tarea superior:** MVP05.

Separar instrucciones de pruebas de evidencia de ejecución.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, MVP03, MVP04.

**Fecha de evidencia:** 11/09/2026. **Fuentes:** S011, S024, S025.

## ACC01 — Ampliación de acceso, seguridad y consentimientos

Fecha de evidencia del reporte de cuenta; las actualizaciones posteriores se desglosan en sus propias etapas.

### ACC01.001 — Crear bienvenida pública

**Estado:** Completado. **Tarea superior:** ACC01.

Ofrecer Crear cuenta e Iniciar sesión sin autenticar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.002 — Publicar rutas de términos y privacidad

**Estado:** Completado. **Tarea superior:** ACC01.

Permitir lectura de documentos sin sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.003 — Publicar ayuda de eliminación de cuenta

**Estado:** Completado. **Tarea superior:** ACC01.

Ofrecer instrucciones sin reinstalar la aplicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.004 — Crear política de registro del servidor

**Estado:** Completado. **Tarea superior:** ACC01.

Consultar documentos vigentes y apertura de registros.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.005 — Bloquear registro con documentos faltantes

**Estado:** Completado. **Tarea superior:** ACC01.

Validar la política en cliente y trigger de Auth.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.006 — Agregar declaración separada de mayoría de edad

**Estado:** Completado. **Tarea superior:** ACC01.

Exigir selección explícita sin recopilar cumpleaños.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.007 — Agregar aceptación contractual explícita

**Estado:** Completado. **Tarea superior:** ACC01.

Evitar casillas preseleccionadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.008 — Persistir versiones de consentimiento

**Estado:** Completado. **Tarea superior:** ACC01.

Registrar versiones y fecha generada por servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.009 — Proteger historial de aceptaciones

**Estado:** Completado. **Tarea superior:** ACC01.

Impedir inserción, modificación y borrado directos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.010 — Solicitar aceptación a cuentas existentes

**Estado:** Completado. **Tarea superior:** ACC01.

No fabricar consentimientos para perfiles previos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.011 — Permitir gestionar cuenta sin aceptar cambios

**Estado:** Completado. **Tarea superior:** ACC01.

Mantener acceso a eliminación y administración básica.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.012 — Crear pantalla de código de correo

**Estado:** Completado. **Tarea superior:** ACC01.

Capturar OTP y mostrar destino de verificación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.013 — Implementar reenvío con espera

**Estado:** Completado. **Tarea superior:** ACC01.

Aplicar cooldown de 60 segundos tras solicitud aceptada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.014 — Separar solicitud de recuperación

**Estado:** Completado. **Tarea superior:** ACC01.

Capturar correo sin revelar si existe una cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.015 — Verificar código de recuperación

**Estado:** Completado. **Tarea superior:** ACC01.

Validar OTP antes de cambiar contraseña.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.016 — Guardar nueva contraseña recuperada

**Estado:** Completado. **Tarea superior:** ACC01.

Completar el flujo tras verificación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.017 — Crear cambio de correo seguro

**Estado:** Completado. **Tarea superior:** ACC01.

Solicitar contraseña actual y confirmación requerida.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.018 — Crear cambio de contraseña autenticado

**Estado:** Completado. **Tarea superior:** ACC01.

Solicitar contraseña actual y reautenticación cuando corresponda.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.019 — Clasificar sesión inválida y errores de red

**Estado:** Completado. **Tarea superior:** ACC01.

Dar mensajes y acciones adecuados en acceso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

### ACC01.020 — Conservar destino durante pasos de cuenta

**Estado:** Completado. **Tarea superior:** ACC01.

Retomar la ruta interna tras completar autenticación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP03, MVP04.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S026, S027, S028.

## ACC02 — Fotografías de perfil y almacenamiento privado

### ACC02.001 — Seleccionar avatar desde galería

**Estado:** Completado. **Tarea superior:** ACC02.

Abrir selector de imágenes de la plataforma.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.002 — Mostrar vista previa del avatar

**Estado:** Completado. **Tarea superior:** ACC02.

Revisar la imagen antes de guardar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.003 — Seleccionar portada desde galería

**Estado:** Completado. **Tarea superior:** ACC02.

Preparar imagen de cabecera del perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.004 — Ofrecer portadas prediseñadas MAREA

**Estado:** Completado. **Tarea superior:** ACC02.

Permitir elegir entre cuatro portadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.005 — Validar peso de imagen de entrada

**Estado:** Completado. **Tarea superior:** ACC02.

Rechazar archivos que excedan el límite de entrada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.006 — Validar resolución de entrada

**Estado:** Completado. **Tarea superior:** ACC02.

Rechazar imágenes que excedan 24 megapíxeles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.007 — Normalizar avatar localmente

**Estado:** Completado. **Tarea superior:** ACC02.

Generar PNG de hasta 640 px sin EXIF.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.008 — Normalizar portada localmente

**Estado:** Completado. **Tarea superior:** ACC02.

Generar PNG de hasta 1600 px sin EXIF.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.009 — Aplicar ajuste centrado de imagen

**Estado:** Completado. **Tarea superior:** ACC02.

Preparar salida sin introducir recorte manual.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.010 — Crear bucket privado profile-media

**Estado:** Completado. **Tarea superior:** ACC02.

Guardar recursos bajo propiedad de la cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.011 — Validar JWT en profile-media

**Estado:** Completado. **Tarea superior:** ACC02.

Verificar identidad antes de aceptar escritura.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.012 — Volver a decodificar imagen en Edge

**Estado:** Completado. **Tarea superior:** ACC02.

Normalizar PNG y validar tamaño y dimensiones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.013 — Restringir escritura directa de medios

**Estado:** Completado. **Tarea superior:** ACC02.

Exigir función validada para upload y eliminación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.014 — Generar URLs firmadas de presentación

**Estado:** Completado. **Tarea superior:** ACC02.

Entregar acceso temporal de diez minutos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.015 — Conservar imagen anterior durante guardado

**Estado:** Completado. **Tarea superior:** ACC02.

Reemplazar referencia solo tras confirmar perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.016 — Quitar avatar o portada

**Estado:** Completado. **Tarea superior:** ACC02.

Eliminar referencia de forma controlada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.017 — Avisar sobre edición sin guardar

**Estado:** Completado. **Tarea superior:** ACC02.

Ofrecer continuar o descartar cambios.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.018 — Limpiar imágenes de edición abandonada

**Estado:** Completado. **Tarea superior:** ACC02.

Retirar archivos sin referencias tras el plazo definido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

### ACC02.019 — Coordinar subidas con eliminación de cuenta

**Estado:** Completado. **Tarea superior:** ACC02.

Bloquear nuevas escrituras cuando comienza el borrado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/09/2026 (SEP-2) | 14/09/2026 (SEP-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S005, S029, S030, S031.

## COM01 — Comunidad y publicaciones iniciales

### COM01.001 — Crear tablas de publicaciones

**Estado:** Completado. **Tarea superior:** COM01.

Persistir autor, tipo, categoría y contenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.002 — Crear catálogo de categorías

**Estado:** Completado. **Tarea superior:** COM01.

Compartir opciones entre búsqueda y formularios.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.003 — Definir tipos de publicaciones por perfil

**Estado:** Completado. **Tarea superior:** COM01.

Limitar nuevas opciones según capacidades.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.004 — Crear modelo de publicación

**Estado:** Completado. **Tarea superior:** COM01.

Representar datos persistidos del feed.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.005 — Crear repositorio de comunidad

**Estado:** Completado. **Tarea superior:** COM01.

Conectar lectura y operaciones de contenido con Supabase.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.006 — Crear feed de Inicio

**Estado:** Completado. **Tarea superior:** COM01.

Mostrar publicaciones reales de la comunidad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.007 — Crear pantalla Explorar

**Estado:** Completado. **Tarea superior:** COM01.

Reunir búsqueda y filtrado de publicaciones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.008 — Buscar publicaciones en servidor

**Estado:** Completado. **Tarea superior:** COM01.

Consultar texto sin simular resultados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.009 — Filtrar publicaciones por categoría

**Estado:** Completado. **Tarea superior:** COM01.

Aplicar categoría seleccionada a la consulta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.010 — Crear formulario de publicación

**Estado:** Completado. **Tarea superior:** COM01.

Capturar título, descripción y categoría.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.011 — Añadir fotografía opcional al post

**Estado:** Completado. **Tarea superior:** COM01.

Procesar imagen seleccionada desde galería.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.012 — Crear almacenamiento privado post-images

**Estado:** Completado. **Tarea superior:** COM01.

Vincular lectura de fotos a publicaciones visibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.013 — Publicar contenido propio

**Estado:** Completado. **Tarea superior:** COM01.

Guardar la publicación con identidad verificada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.014 — Editar publicaciones propias

**Estado:** Completado. **Tarea superior:** COM01.

Conservar autorización del propietario.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.015 — Eliminar publicación con confirmación

**Estado:** Completado. **Tarea superior:** COM01.

Retirar contenido y relaciones asociadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.016 — Crear guardados privados de posts

**Estado:** Completado. **Tarea superior:** COM01.

Persistir relación por usuario.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.017 — Guardar y quitar publicaciones

**Estado:** Completado. **Tarea superior:** COM01.

Actualizar colección personal desde la interfaz.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.018 — Crear directorio público autenticado

**Estado:** Completado. **Tarea superior:** COM01.

Exponer presentación sin correo ni preferencias privadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.019 — Abrir perfil de otra persona

**Estado:** Completado. **Tarea superior:** COM01.

Consultar sus publicaciones y misiones visibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

### COM01.020 — Mantener edición de contenido histórico

**Estado:** Completado. **Tarea superior:** COM01.

Permitir al dueño editar posts previos a cambios de capacidades.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S032, S026, S033, S034.

## QA01 — Verificaciones de cuenta y comunidad tempranas

El reporte incluye hechos del 14 y 16; las fechas puntuales de cada ejecución no equivalen a duración real.

### QA01.001 — Verificar migraciones 001 y 002 desplegadas

**Estado:** Completado. **Tarea superior:** QA01.

Confirmar proyecto y contrato sin reaplicar versiones idénticas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.002 — Verificar funciones de medios y borrado

**Estado:** Completado. **Tarea superior:** QA01.

Comparar código remoto y rechazo sin sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.003 — Probar almacenamiento administrativo temporal

**Estado:** Completado. **Tarea superior:** QA01.

Comprobar subida, descarga idéntica y limpieza.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 14/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.004 — Publicar documentos escolares y abrir registro

**Estado:** Completado. **Tarea superior:** QA01.

Registrar política escolar-1.0 sin consentimientos inventados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S026, S035, S036, S037.

**Observación:** Documento actualizado de despliegue; publicación escolar confirmada sin fecha individual explícita en ese apartado.

### QA01.005 — Aplicar migración 003 de comunidad

**Estado:** Completado. **Tarea superior:** QA01.

Extender el proyecto sin reset de tablas existentes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.006 — Desplegar limpieza de fotos de posts

**Estado:** Completado. **Tarea superior:** QA01.

Actualizar delete-account conservando autenticación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.007 — Validar SQL aislado de comunidad

**Estado:** Completado. **Tarea superior:** QA01.

Reporte acredita 100 comprobaciones de comunidad y 33 previas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.008 — Validar pantallas de comunidad

**Estado:** Completado. **Tarea superior:** QA01.

Reporte acredita 133 pruebas Flutter antes de la corrección Web.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.009 — Corregir dimensiones de imágenes en navegador

**Estado:** Completado. **Tarea superior:** QA01.

Usar imagen decodificada en lugar de getters no implementados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.010 — Regenerar registro del plugin de fotos Web

**Estado:** Completado. **Tarea superior:** QA01.

Incluir ImagePickerPlugin en la compilación corregida.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.011 — Probar selector y vista previa en Chrome

**Estado:** Completado. **Tarea superior:** QA01.

Comprobar entrega de fotografía en perfil y publicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.012 — Validar regresión de fotos Web

**Estado:** Completado. **Tarea superior:** QA01.

Reporte acredita 137 pruebas locales y cuatro Chrome.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S026, S035, S036, S037.

### QA01.013 — Compilar Web y APK de comunidad

**Estado:** Completado. **Tarea superior:** QA01.

Registrar builds locales con configuración del proyecto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, ACC02, COM01.

**Fecha de evidencia:** 16/09/2026. **Fuentes:** S026, S035, S036, S037.

## COM02 — Ubicación de publicaciones

El commit del 17 acredita presencia del cambio; no fija el día exacto de implementación.

### COM02.001 — Agregar coordenadas opcionales a posts

**Estado:** Completado. **Tarea superior:** COM02.

Conservar compatibilidad con ubicaciones solo textuales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.002 — Registrar precisión exacta o aproximada

**Estado:** Completado. **Tarea superior:** COM02.

Persistir elección junto a coordenadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.003 — Crear selector visual de ubicación

**Estado:** Completado. **Tarea superior:** COM02.

Elegir un punto sobre OpenStreetMap.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.004 — Buscar dirección con Nominatim

**Estado:** Completado. **Tarea superior:** COM02.

Permitir localizar el punto mediante texto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.005 — Mover punto manualmente

**Estado:** Completado. **Tarea superior:** COM02.

Ajustar ubicación antes de confirmarla.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.006 — Solicitar ubicación mediante acción explícita

**Estado:** Completado. **Tarea superior:** COM02.

No obtener GPS al abrir el formulario.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.007 — Manejar permiso de ubicación rechazado

**Estado:** Completado. **Tarea superior:** COM02.

Mantener disponibles búsqueda y selección manual.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.008 — Redondear posición aproximada

**Estado:** Completado. **Tarea superior:** COM02.

Reducir precisión antes de persistir.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.009 — Confirmar ubicación seleccionada

**Estado:** Completado. **Tarea superior:** COM02.

Devolver texto, punto y precisión al compositor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.010 — Retirar ubicación opcional

**Estado:** Completado. **Tarea superior:** COM02.

Permitir publicación sin punto en mapa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.011 — Mostrar ubicación guardada

**Estado:** Completado. **Tarea superior:** COM02.

Abrir el contexto de posición desde contenido visible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

### COM02.012 — Configurar permisos Android y web

**Estado:** Completado. **Tarea superior:** COM02.

Declarar acceso y dejar solicitud bajo control de la persona.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, INV03.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S038, S039, S032, S040.

## MIS01 — Primer flujo y ciclo de vida de misiones

b321100 se guardó como WIP. Estas capacidades se conservan en etapas posteriores; la aceptación del rediseño se registra en MIS05.

### MIS01.001 — Crear entidades de misión y candidatura

**Estado:** Completado. **Tarea superior:** MIS01.

Relacionar organizador, convocatoria y participante.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.002 — Crear formulario inicial de misión

**Estado:** Completado. **Tarea superior:** MIS01.

Capturar descripción, fecha, cupo y ubicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.003 — Crear listado inicial de misiones

**Estado:** Completado. **Tarea superior:** MIS01.

Mostrar convocatorias desde Supabase.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.004 — Crear detalle inicial de misión

**Estado:** Completado. **Tarea superior:** MIS01.

Mostrar condiciones y acción de participación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.005 — Filtrar elegibilidad por tipo solicitado

**Estado:** Completado. **Tarea superior:** MIS01.

Aceptar perfiles coincidentes o convocatoria abierta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.006 — Bloquear candidatura del organizador

**Estado:** Completado. **Tarea superior:** MIS01.

Impedir postularse a una misión propia.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.007 — Validar fecha límite de candidatura

**Estado:** Completado. **Tarea superior:** MIS01.

Impedir solicitud fuera del periodo permitido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.008 — Validar disponibilidad de cupo

**Estado:** Completado. **Tarea superior:** MIS01.

No aceptar participantes fuera de capacidad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.009 — Enviar candidatura inicial

**Estado:** Completado. **Tarea superior:** MIS01.

Persistir mensaje y participante autorizado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.010 — Consultar candidaturas propias

**Estado:** Completado. **Tarea superior:** MIS01.

Mostrar el estado de participación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.011 — Retirar candidatura propia

**Estado:** Completado. **Tarea superior:** MIS01.

Conservar historial y aplicar restricciones temporales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.012 — Aceptar candidatura desde organizador

**Estado:** Completado. **Tarea superior:** MIS01.

Respetar propiedad y cupo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.013 — Rechazar candidatura individual

**Estado:** Completado. **Tarea superior:** MIS01.

Actualizar estado autorizado por el organizador.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.014 — Cerrar convocatoria

**Estado:** Completado. **Tarea superior:** MIS01.

Detener nuevas solicitudes sin borrar historial.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.015 — Reabrir convocatoria válida

**Estado:** Completado. **Tarea superior:** MIS01.

Permitir nuevas solicitudes antes de la fecha.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.016 — Cancelar misión con motivo

**Estado:** Completado. **Tarea superior:** MIS01.

Registrar estado terminal y razón.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.017 — Finalizar misión

**Estado:** Completado. **Tarea superior:** MIS01.

Conservar historial de la colaboración.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

### MIS01.018 — Bloquear condiciones tras primera candidatura

**Estado:** Completado. **Tarea superior:** MIS01.

Evitar modificaciones incompatibles con solicitudes recibidas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, COM02.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S040, S041, S032, S042.

## COM03 — Moderación y eliminación ampliada de cuenta

### COM03.001 — Reportar publicaciones

**Estado:** Completado. **Tarea superior:** COM03.

Guardar razón de reporte vinculada a contenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.002 — Reportar misiones

**Estado:** Completado. **Tarea superior:** COM03.

Permitir revisión de convocatorias.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.003 — Crear cola privada de moderación

**Estado:** Completado. **Tarea superior:** COM03.

Mostrar reportes solo a administradores.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.004 — Ocultar contenido reportado

**Estado:** Completado. **Tarea superior:** COM03.

Retirar disponibilidad sin dar control a usuarios comunes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.005 — Restaurar contenido desde historial

**Estado:** Completado. **Tarea superior:** COM03.

Recuperar visibilidad mediante acción administrativa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.006 — Separar rol administrador del tipo de perfil

**Estado:** Completado. **Tarea superior:** COM03.

No asignar moderación mediante registro.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.007 — Crear marcador durable de eliminación

**Estado:** Completado. **Tarea superior:** COM03.

Permitir reintentar borrado interrumpido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.008 — Bloquear escrituras de cuenta en eliminación

**Estado:** Completado. **Tarea superior:** COM03.

Evitar crear recursos durante el proceso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.009 — Esperar operaciones de imagen en curso

**Estado:** Completado. **Tarea superior:** COM03.

Coordinar limpieza con las subidas pendientes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.010 — Limpiar imágenes de publicaciones al borrar cuenta

**Estado:** Completado. **Tarea superior:** COM03.

Incluir post-images en la eliminación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

### COM03.011 — Eliminar Auth tras limpieza

**Estado:** Completado. **Tarea superior:** COM03.

Completar cascadas de datos de la cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/09/2026 (SEP-3) | 21/09/2026 (SEP-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM01, MIS01.

**Fecha de evidencia:** 17/09/2026. **Fuentes:** S032, S005, S043, S044.

## GIT01 — Publicación del repositorio e integración del historial

La publicación del 22 reinició la raíz principal. Merges, stashes y checkpoints no se suman como nuevas capacidades.

### GIT01.001 — Preparar archivos públicos del proyecto

**Estado:** Completado. **Tarea superior:** GIT01.

Publicar el snapshot de Flutter, backend, pruebas y documentación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01, COM01, MIS01.

**Fecha de evidencia:** 22/09/2026. **Fuentes:** S045, S046, S001.

### GIT01.002 — Conservar ejemplos de configuración

**Estado:** Completado. **Tarea superior:** GIT01.

Compartir plantillas sin secretos administrativos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01, COM01, MIS01.

**Fecha de evidencia:** 22/09/2026. **Fuentes:** S045, S046, S001.

### GIT01.003 — Excluir configuración privada del snapshot público

**Estado:** Completado. **Tarea superior:** GIT01.

Separar valores locales de archivos distribuibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01, COM01, MIS01.

**Fecha de evidencia:** 22/09/2026. **Fuentes:** S045, S046, S001.

### GIT01.004 — Conservar etapa previa del MVP

**Estado:** Completado. **Tarea superior:** GIT01.

Identificar b92a237 y b321100 fuera de la nueva raíz principal.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01, COM01, MIS01.

**Fecha de evidencia:** 22/09/2026. **Fuentes:** S045, S046, S001.

### GIT01.005 — Registrar nueva raíz de publicación

**Estado:** Completado. **Tarea superior:** GIT01.

Identificar 1c7a5d0 sin atribuirle todo el trabajo desde cero.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01, COM01, MIS01.

**Fecha de evidencia:** 22/09/2026. **Fuentes:** S045, S046, S001.

### GIT01.006 — Conservar checkpoint previo de trabajo

**Estado:** Completado. **Tarea superior:** GIT01.

Usar stash como evidencia auxiliar sin contarlo como implementación nueva.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP01, COM01, MIS01.

**Fecha de evidencia:** 22/09/2026. **Fuentes:** S045, S046, S001.

## PRO01 — Experiencia profesional y confirmación de perfil

### PRO01.001 — Agregar marca de confirmación inicial

**Estado:** Completado. **Tarea superior:** PRO01.

Persistir confirmación de tipo desde servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.002 — Crear complete_initial_profile

**Estado:** Completado. **Tarea superior:** PRO01.

Confirmar elección una sola vez con validaciones atómicas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.003 — Proteger tipo confirmado contra edición

**Estado:** Completado. **Tarea superior:** PRO01.

Mantener capacidades consistentes tras completar perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.004 — Persistir intereses privados

**Estado:** Completado. **Tarea superior:** PRO01.

Guardar preferencias sin exponerlas en directorio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.005 — Persistir objetivos privados

**Estado:** Completado. **Tarea superior:** PRO01.

Separar metas personales de presentación pública.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.006 — Agregar enlace HTTPS de contacto

**Estado:** Completado. **Tarea superior:** PRO01.

Mostrar acción únicamente con enlace configurado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.007 — Agregar disponibilidad para colaborar

**Estado:** Completado. **Tarea superior:** PRO01.

Permitir declaración profesional de creadores.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.008 — Agregar datos de negocio

**Estado:** Completado. **Tarea superior:** PRO01.

Persistir ubicación y contexto profesional opcionales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.009 — Agregar horarios semanales

**Estado:** Completado. **Tarea superior:** PRO01.

Permitir intervalo por día o día cerrado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.010 — Crear herramientas por tipo de perfil

**Estado:** Completado. **Tarea superior:** PRO01.

Distinguir Portafolio, Catálogo y Servicios.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.011 — Separar perfil propio y público

**Estado:** Completado. **Tarea superior:** PRO01.

Exponer controles privados solo al propietario.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.012 — Separar publicaciones y fichas profesionales

**Estado:** Completado. **Tarea superior:** PRO01.

No duplicar contenido de Inicio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.013 — Integrar lectura pública de avatar y portada

**Estado:** Completado. **Tarea superior:** PRO01.

Mostrar fotografías reales de perfiles visibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.014 — Desplegar migración 006

**Estado:** Completado. **Tarea superior:** PRO01.

Reporte del 27 acredita contrato remoto actualizado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.015 — Actualizar limpieza de showcase-media

**Estado:** Completado. **Tarea superior:** PRO01.

Incluir fotografías de fichas en delete-account.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

### PRO01.016 — Verificar perfiles y fichas

**Estado:** Completado. **Tarea superior:** PRO01.

Reporte acredita 194 pruebas Flutter y 277 checks SQL aislados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC01, COM01.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S005, S032, S026, S047.

## PRO02 — Fichas de portafolio, catálogo y servicios

### PRO02.001 — Crear modelo de ficha profesional

**Estado:** Completado. **Tarea superior:** PRO02.

Representar project, product y service independientemente de posts.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.002 — Crear repositorio de showcase

**Estado:** Completado. **Tarea superior:** PRO02.

Conectar lectura, escritura y cambios de estado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.003 — Crear compositor de obra o proyecto

**Estado:** Completado. **Tarea superior:** PRO02.

Ofrecer ficha de portafolio para creador.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.004 — Crear compositor de producto

**Estado:** Completado. **Tarea superior:** PRO02.

Ofrecer ficha de catálogo para emprendimiento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.005 — Crear compositor de servicio

**Estado:** Completado. **Tarea superior:** PRO02.

Ofrecer ficha autorizada por tipo de perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.006 — Capturar título y descripción de ficha

**Estado:** Completado. **Tarea superior:** PRO02.

Validar información de presentación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.007 — Seleccionar categoría de ficha

**Estado:** Completado. **Tarea superior:** PRO02.

Aplicar catálogo compatible con el contenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.008 — Agregar hasta seis fotos ordenadas

**Estado:** Completado. **Tarea superior:** PRO02.

Conservar secuencia de la galería.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.009 — Crear bucket privado showcase-media

**Estado:** Completado. **Tarea superior:** PRO02.

Relacionar fotos con fichas visibles y propietario.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.010 — Exigir foto para obra y producto publicados

**Estado:** Completado. **Tarea superior:** PRO02.

Permitir servicio publicado sin imagen.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.011 — Capturar precio opcional en MXN

**Estado:** Completado. **Tarea superior:** PRO02.

Mostrar Consultar precio cuando no existe importe.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.012 — Capturar disponibilidad de ficha

**Estado:** Completado. **Tarea superior:** PRO02.

Controlar disponibilidad del contenido publicado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.013 — Guardar borrador privado

**Estado:** Completado. **Tarea superior:** PRO02.

Permitir preparación sin exposición pública.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.014 — Publicar ficha válida

**Estado:** Completado. **Tarea superior:** PRO02.

Cambiar estado con validación atómica del servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.015 — Editar ficha propia

**Estado:** Completado. **Tarea superior:** PRO02.

Conservar contenido y permisos del propietario.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.016 — Archivar ficha

**Estado:** Completado. **Tarea superior:** PRO02.

Retirar disponibilidad conservando datos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.017 — Volver ficha a borrador

**Estado:** Completado. **Tarea superior:** PRO02.

Permitir edición privada de contenido publicado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.018 — Eliminar ficha con confirmación

**Estado:** Completado. **Tarea superior:** PRO02.

Limpiar relaciones y recursos sin referencias.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.019 — Mostrar detalle y galería de ficha

**Estado:** Completado. **Tarea superior:** PRO02.

Permitir navegación de fotografías.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.020 — Mostrar contacto del perfil en ficha

**Estado:** Completado. **Tarea superior:** PRO02.

Abrir únicamente el enlace HTTPS disponible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.021 — Buscar fichas en Explorar

**Estado:** Completado. **Tarea superior:** PRO02.

Filtrar por título, categoría y tipo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.022 — Guardar y quitar fichas

**Estado:** Completado. **Tarea superior:** PRO02.

Mantener colección personal privada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.023 — Reportar ficha profesional

**Estado:** Completado. **Tarea superior:** PRO02.

Integrar reporte con moderación existente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.024 — Conservar formulario ante fallo

**Estado:** Completado. **Tarea superior:** PRO02.

Permitir reintento sin perder imágenes o texto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

### PRO02.025 — Limpiar fotos reemplazadas tras éxito

**Estado:** Completado. **Tarea superior:** PRO02.

No borrar imágenes anteriores cuando falla el guardado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC02.

**Fecha de evidencia:** 27/09/2026. **Fuentes:** S032, S048, S049, S047.

## ACC03 — Rediseño de registro mínimo y guías opcionales

### ACC03.001 — Crear referencias visuales de acceso

**Estado:** Completado. **Tarea superior:** ACC03.

Preparar cuatro láminas móviles/escritorio y sus prompts.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.002 — Rediseñar bienvenida con marca MAREA

**Estado:** Completado. **Tarea superior:** ACC03.

Presentar acciones de acceso y superficies compactas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.003 — Crear selector de cuatro tipos de perfil

**Estado:** Completado. **Tarea superior:** ACC03.

Ofrecer elección explícita durante registro.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.004 — Dividir registro mínimo en tres pasos

**Estado:** Completado. **Tarea superior:** ACC03.

Separar tipo, identidad y credenciales/verificación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.005 — Retirar preferencias obligatorias del registro

**Estado:** Completado. **Tarea superior:** ACC03.

Permitir llegar a Inicio con información mínima.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.006 — Confirmar tipo en nuevo registro

**Estado:** Completado. **Tarea superior:** ACC03.

Persistir la elección autorizada desde el trigger.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.007 — Crear confirmación mínima heredada

**Estado:** Completado. **Tarea superior:** ACC03.

Solicitar solo el tipo a cuentas pendientes compatibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.008 — Crear guía de usuario general

**Estado:** Completado. **Tarea superior:** ACC03.

Ofrecer orientación opcional específica del tipo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.009 — Crear guía de artista o creador

**Estado:** Completado. **Tarea superior:** ACC03.

Ofrecer pasos opcionales del portafolio y colaboración.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.010 — Crear guía de emprendimiento

**Estado:** Completado. **Tarea superior:** ACC03.

Ofrecer orientación de catálogo y contacto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.011 — Crear guía de negocio

**Estado:** Completado. **Tarea superior:** ACC03.

Ofrecer orientación de servicios y datos del local.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.012 — Permitir omitir guía

**Estado:** Completado. **Tarea superior:** ACC03.

No impedir el acceso a Inicio por orientación pendiente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.013 — Retomar guía desde perfil

**Estado:** Completado. **Tarea superior:** ACC03.

Recuperar paso guardado al volver.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.014 — Persistir avance privado de guía

**Estado:** Completado. **Tarea superior:** ACC03.

Guardar paso confirmado en lugar de pregunta abierta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.015 — Editar preferencias después del registro

**Estado:** Completado. **Tarea superior:** ACC03.

Actualizar intereses y objetivos sin cambiar el tipo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.016 — Proteger borradores al cambiar cuenta

**Estado:** Completado. **Tarea superior:** ACC03.

Evitar aplicar datos de una sesión anterior.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.017 — Corregir disposición al cerrar sesión

**Estado:** Completado. **Tarea superior:** ACC03.

Inicializar controladores antes de la limpieza de estado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.018 — Validar registro a 320 px y texto 200%

**Estado:** Completado. **Tarea superior:** ACC03.

Cubrir teclado y cuatro tipos de perfil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

### ACC03.019 — Verificar acceso rediseñado

**Estado:** Completado. **Tarea superior:** ACC03.

Reporte acredita 239 pruebas Flutter y 35 checks SQL aislados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, ACC01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S050, S051, S052.

## ACC04 — Reparación de registro, cámara y contrato remoto

La prueba de recepción del último registro tiene fecha propia 2026-09-18; se corrige en el registro individual al finalizar la carga.

### ACC04.001 — Detectar desfase cliente-servidor de registro

**Estado:** Completado. **Tarea superior:** ACC04.

Identificar preferencias exigidas y setup_step faltante.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.002 — Crear migración 008 de recuperación

**Estado:** Completado. **Tarea superior:** ACC04.

Recuperar elecciones válidas sin alterar perfiles confirmados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.003 — Conservar cuentas con datos incompatibles

**Estado:** Completado. **Tarea superior:** ACC04.

Dejar confirmación explícita sin perder contenido profesional.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.004 — Aplicar migraciones 007 y 008

**Estado:** Completado. **Tarea superior:** ACC04.

Actualizar únicamente el contrato necesario del proyecto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.005 — Crear mensaje de esquema desactualizado

**Estado:** Completado. **Tarea superior:** ACC04.

Mostrar acción útil ante backend incompatible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.006 — Corregir área real del botón de cámara

**Estado:** Completado. **Tarea superior:** ACC04.

Garantizar objetivo táctil de 48 px que recibe clics.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.007 — Ampliar gate de backend

**Estado:** Completado. **Tarea superior:** ACC04.

Comprobar salida estructurada y trigger AFTER INSERT activo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.008 — Verificar registro entre sesiones reales

**Estado:** Completado. **Tarea superior:** ACC04.

Reporte acredita 61 checks con cinco cuentas temporales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.009 — Verificar aislamiento de fotos entre usuarios

**Estado:** Completado. **Tarea superior:** ACC04.

Probar subir, leer, reemplazar y quitar con JWT individual.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.010 — Limpiar cuentas y archivos de comprobación

**Estado:** Completado. **Tarea superior:** ACC04.

Confirmar cero recursos temporales propios.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.011 — Actualizar APK en emulador conservando datos

**Estado:** Completado. **Tarea superior:** ACC04.

Comprobar Inicio con sesión y posts reales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.012 — Detectar respuesta de registro repetido

**Estado:** Completado. **Tarea superior:** ACC04.

Rechazar usuario sin identidades ni sesión como registro incompleto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.013 — Ofrecer login o recuperación en correo repetido

**Estado:** Completado. **Tarea superior:** ACC04.

Conservar correo y no afirmar envío de OTP inexistente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.014 — Verificar SMTP Gmail y plantilla de confirmación

**Estado:** Completado. **Tarea superior:** ACC04.

Reporte del 28 acredita SMTP activo y token en plantilla.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S053, S054, S026, S055.

### ACC04.015 — Registrar recepción de confirmación existente

**Estado:** Completado. **Tarea superior:** ACC04.

El documento acredita una confirmación el 18; no valida todos los correos nuevos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC03, ACC02.

**Fecha de evidencia:** 18/09/2026. **Fuentes:** S053, S054, S026, S055.

**Observación:** docs/email-setup.md acredita recepción y confirmación de una cuenta el 18/09; no duración de la actividad.

## PRO04 — Herramientas y permisos de los cuatro perfiles

### PRO04.001 — Crear panel privado de herramientas

**Estado:** Completado. **Tarea superior:** PRO04.

Mostrar acciones sobre la navegación global.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.002 — Abrir creación de publicación desde perfil

**Estado:** Completado. **Tarea superior:** PRO04.

Permitir a todos los tipos publicar comunidad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.003 — Abrir creación de misión desde perfil

**Estado:** Completado. **Tarea superior:** PRO04.

Dar permisos de organización a los cuatro tipos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.004 — Ofrecer obra al creador

**Estado:** Completado. **Tarea superior:** PRO04.

Mantener herramientas de portafolio específicas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.005 — Ofrecer producto y servicio al emprendimiento

**Estado:** Completado. **Tarea superior:** PRO04.

Mantener capacidades de catálogo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.006 — Ofrecer servicio al negocio

**Estado:** Completado. **Tarea superior:** PRO04.

Conservar separación respecto de Productos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.007 — Abrir datos profesionales desde herramientas

**Estado:** Completado. **Tarea superior:** PRO04.

Seleccionar pestaña correspondiente del editor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.008 — Abrir colaboraciones compatibles

**Estado:** Completado. **Tarea superior:** PRO04.

Consultar misiones para el tipo actual y para todos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.009 — Agregar filtros de respuestas en postulaciones

**Estado:** Completado. **Tarea superior:** PRO04.

Separar pendientes, aceptadas, rechazadas y retiradas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.010 — Mostrar causas específicas de inelegibilidad

**Estado:** Completado. **Tarea superior:** PRO04.

Explicar cierre, fecha, cupo y tipo solicitado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.011 — Verificar matriz de permisos de misiones

**Estado:** Completado. **Tarea superior:** PRO04.

Reporte acredita 337 checks SQL y cuatro tipos organizadores.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

### PRO04.012 — Verificar herramientas en interfaz

**Estado:** Completado. **Tarea superior:** PRO04.

Reporte acredita 269 pruebas Flutter y revisión móvil/escritorio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO03, MIS01.

**Fecha de evidencia:** 28/09/2026. **Fuentes:** S056, S032, S057.

## PRO03 — Rediseño de perfil, edición y configuración

El reporte del rediseño no tiene fecha propia; el commit del 29 acredita integración.

### PRO03.001 — Crear cabecera compacta de perfil

**Estado:** Completado. **Tarea superior:** PRO03.

Mostrar portada, avatar e identidad en primer viewport.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.002 — Adaptar perfil a dos columnas

**Estado:** Completado. **Tarea superior:** PRO03.

Usar distribución de escritorio desde 1024 px.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.003 — Conservar estado de pestañas

**Estado:** Completado. **Tarea superior:** PRO03.

Mantener carga y desplazamiento al cambiar secciones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.004 — Redirigir enlace público al perfil propio

**Estado:** Completado. **Tarea superior:** PRO03.

Evitar controles contradictorios para la misma cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.005 — Separar editor de identidad y profesional

**Estado:** Completado. **Tarea superior:** PRO03.

Organizar campos sin perder valores al cambiar sección.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.006 — Validar campos entre secciones

**Estado:** Completado. **Tarea superior:** PRO03.

Detectar errores aunque el campo no esté visible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.007 — Corregir foco de campos ocultos

**Estado:** Completado. **Tarea superior:** PRO03.

Retirar foco al cambiar pestaña manteniendo estado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.008 — Actualizar identidad tras cambiar enlaces

**Estado:** Completado. **Tarea superior:** PRO03.

Refrescar presentación profesional después de guardar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.009 — Crear configuración compacta

**Estado:** Completado. **Tarea superior:** PRO03.

Agrupar herramientas y seguridad con acabado MAREA.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.010 — Rediseñar formularios de seguridad

**Estado:** Completado. **Tarea superior:** PRO03.

Simplificar etiquetas y distribución de correo y contraseña.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.011 — Mantener guardar visible sobre teclado

**Estado:** Completado. **Tarea superior:** PRO03.

Evitar que la acción quede fuera del formulario móvil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.012 — Crear controles de galería accesibles

**Estado:** Completado. **Tarea superior:** PRO03.

Operar fotos con botones además de gestos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.013 — Corregir selectores con texto ampliado

**Estado:** Completado. **Tarea superior:** PRO03.

Permitir ancho adaptable y alturas variables.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.014 — Agregar regreso en enlaces directos

**Estado:** Completado. **Tarea superior:** PRO03.

Dar salida explícita a pantallas derivadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.015 — Verificar rediseño de perfil

**Estado:** Completado. **Tarea superior:** PRO03.

Reporte acredita 216 pruebas, análisis y build Web correctos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

### PRO03.016 — Inspeccionar diez vistas de perfil en navegador

**Estado:** Completado. **Tarea superior:** PRO03.

Revisar móvil, escritorio, seguridad, perfil público y fichas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PRO01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S058, S056, S059.

## DIS01 — Evolución visual y propuestas sustituidas

Las propuestas son entregables de diseño, no funciones probadas. Los prompts iniciales carecen de fecha propia; el 29 acredita conservación/integración de antecedentes.

### DIS01.001 — Explorar composición híbrida de Inicio

**Estado:** Sustituido. **Tarea superior:** DIS01.

Conservar prompt local como antecedente, sin acreditar implementación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S060.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.002 — Explorar composición editorial v2

**Estado:** Sustituido. **Tarea superior:** DIS01.

Conservar prompt local previo al diseño social v3.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S061.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.003 — Diseñar unidad social v3

**Estado:** Sustituido. **Tarea superior:** DIS01.

Definir foto, texto, autor, reacciones y participación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.004 — Diseñar acciones y estados sociales v3

**Estado:** Sustituido. **Tarea superior:** DIS01.

Definir guardados, actividad, errores y reintentos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.005 — Diseñar post vertical v4

**Estado:** Sustituido. **Tarea superior:** DIS01.

Reordenar lectura y fotografía dentro de una unidad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.006 — Diseñar adaptación móvil y web v4

**Estado:** Sustituido. **Tarea superior:** DIS01.

Mantener límites y comportamiento por superficie.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.007 — Diseñar cabecera con marca v5

**Estado:** Sustituido. **Tarea superior:** DIS01.

Usar originales oficiales como referencia de colocación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.008 — Diseñar distribución de escritorio v5

**Estado:** Sustituido. **Tarea superior:** DIS01.

Revisar composición de cabecera y contenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.009 — Diseñar Buscar y Actividad v5

**Estado:** Sustituido. **Tarea superior:** DIS01.

Definir acceso y estados de estos paneles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.010 — Diseñar cabeceras definitivas v6

**Estado:** Sustituido. **Tarea superior:** DIS01.

Separar marca, guardados, notificaciones y Crear.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.011 — Diseñar colección de Guardados v6

**Estado:** Sustituido. **Tarea superior:** DIS01.

Distinguir colección de un panel de actividad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.012 — Diseñar Notificaciones v6

**Estado:** Sustituido. **Tarea superior:** DIS01.

Definir filtros y marcado de lectura al abrir destino.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.013 — Retirar visor independiente de foto en v6

**Estado:** Sustituido. **Tarea superior:** DIS01.

Conservar lectura y expansión dentro del post.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.014 — Corregir láminas v6

**Estado:** Sustituido. **Tarea superior:** DIS01.

Revisar dock, Crear web, Ver más y etiquetas de guardados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.015 — Archivar concepto social mobile redesign

**Estado:** Sustituido. **Tarea superior:** DIS01.

Conservar propuesta sin sustituir la experiencia integrada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS01.016 — Archivar concepto mobile social UI

**Estado:** Sustituido. **Tarea superior:** DIS01.

Conservar segundo experimento visual como antecedente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MVP02, COM01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S062, S063, S064, S065, S066.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

## DIS02 — Acabado v7 e identidad oficial

### DIS02.001 — Definir paleta neutral del acabado v7

**Estado:** Completado. **Tarea superior:** DIS02.

Usar Paper, blanco, navy, aqua y mint con contraste.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S067, S068, S069.

### DIS02.002 — Definir profundidad de superficies

**Estado:** Completado. **Tarea superior:** DIS02.

Aplicar sombras y brillos moderados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S067, S068, S069.

### DIS02.003 — Diseñar cápsula de navegación web

**Estado:** Completado. **Tarea superior:** DIS02.

Mantener destinos con selección mint.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S067, S068, S069.

### DIS02.004 — Diseñar cápsula móvil y Crear separado

**Estado:** Completado. **Tarea superior:** DIS02.

Reservar espacio de navegación en el contenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S067, S068, S069.

### DIS02.005 — Equilibrar columnas del post v7

**Estado:** Completado. **Tarea superior:** DIS02.

Concentrar color en selección y acciones principales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S067, S068, S069.

### DIS02.006 — Integrar logotipo oficial móvil

**Estado:** Completado. **Tarea superior:** DIS02.

Usar archivo original sin deformar proporciones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S067, S068, S069.

### DIS02.007 — Integrar isotipo oficial escritorio

**Estado:** Completado. **Tarea superior:** DIS02.

Usar recurso de marca en cabecera.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S067, S068, S069.

### DIS02.008 — Actualizar assets oficiales de marca

**Estado:** Completado. **Tarea superior:** DIS02.

Conservar archivos de identidad en el proyecto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S067, S068, S069.

## SOC01 — Implementación de Inicio y post social v7

### SOC01.001 — Integrar cabecera compacta móvil

**Estado:** Completado. **Tarea superior:** SOC01.

Presentar marca y controles accesibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.002 — Integrar navegación neumórfica escritorio

**Estado:** Completado. **Tarea superior:** SOC01.

Compartir cápsula entre destinos del shell.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.003 — Mover búsqueda a Explorar

**Estado:** Completado. **Tarea superior:** SOC01.

Retirar controles de búsqueda del encabezado de Inicio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.004 — Crear componente de post reutilizable

**Estado:** Completado. **Tarea superior:** SOC01.

Usarlo en Inicio, Explorar, perfil y detalle.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.005 — Aplicar ancho máximo de post

**Estado:** Completado. **Tarea superior:** SOC01.

Limitar a 820 px y adaptar desde 760 px disponibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.006 — Mostrar imagen completa sin deformación

**Estado:** Completado. **Tarea superior:** SOC01.

Usar contain en bloque fotográfico 3:5.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.007 — Centrar lectura de posts sin fotografía

**Estado:** Completado. **Tarea superior:** SOC01.

Evitar columna vacía reservada a imagen.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.008 — Mostrar autor, avatar y metadata reales

**Estado:** Completado. **Tarea superior:** SOC01.

Cargar fecha, tipo y categoría del contenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.009 — Expandir texto dentro del post

**Estado:** Completado. **Tarea superior:** SOC01.

Alternar Ver más y Ver menos sin visor separado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.010 — Consultar estadísticas por lote

**Estado:** Completado. **Tarea superior:** SOC01.

Evitar una consulta independiente por cada post.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.011 — Paginar feed en páginas de 30

**Estado:** Completado. **Tarea superior:** SOC01.

Conservar contenido recibido al cargar más.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.012 — Descartar respuestas antiguas del feed

**Estado:** Completado. **Tarea superior:** SOC01.

Evitar que consulta obsoleta reemplace resultados actuales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.013 — Reintentar carga sin perder páginas

**Estado:** Completado. **Tarea superior:** SOC01.

Mantener contenido visible ante fallo posterior.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.014 — Integrar detalle de post con URL interna

**Estado:** Completado. **Tarea superior:** SOC01.

Usar /posts/:id como destino de lectura.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

### SOC01.015 — Integrar v7 con el perfil y cuenta existentes

**Estado:** Completado. **Tarea superior:** SOC01.

Unir ramas sin duplicar capacidades.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02, COM01, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S070, S071.

## SOC02 — Reacciones, comentarios y compartir

### SOC02.001 — Crear reacción única por usuario y post

**Estado:** Completado. **Tarea superior:** SOC02.

Persistir selección sin duplicados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.002 — Crear selector de tres reacciones

**Estado:** Completado. **Tarea superior:** SOC02.

Ofrecer Me gusta, Me inspira y Lo apoyo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.003 — Retirar reacción activa

**Estado:** Completado. **Tarea superior:** SOC02.

Interpretar selección repetida como eliminación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.004 — Cambiar tipo de reacción

**Estado:** Completado. **Tarea superior:** SOC02.

Reemplazar selección previa conservando unicidad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.005 — Calcular total de reacciones

**Estado:** Completado. **Tarea superior:** SOC02.

Mostrar agregado confirmado por servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.006 — Crear estadísticas sociales privadas/autorizadas

**Estado:** Completado. **Tarea superior:** SOC02.

Evitar escritura directa de conteos desde el cliente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.007 — Crear tabla de comentarios

**Estado:** Completado. **Tarea superior:** SOC02.

Persistir autor, post y contenido plano.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.008 — Validar longitud de comentario

**Estado:** Completado. **Tarea superior:** SOC02.

Aceptar texto de 1 a 1000 caracteres.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.009 — Crear panel de comentarios móvil/web

**Estado:** Completado. **Tarea superior:** SOC02.

Adaptar sheet inferior y panel lateral.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.010 — Paginar comentarios en páginas de 30

**Estado:** Completado. **Tarea superior:** SOC02.

Cargar entradas siguientes con offset real.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.011 — Conservar borrador e ID de comentario

**Estado:** Completado. **Tarea superior:** SOC02.

Mantener operación estable al cerrar y reintentar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.012 — Eliminar comentario autorizado

**Estado:** Completado. **Tarea superior:** SOC02.

Solicitar confirmación y aplicar permisos de servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.013 — Crear notificación transaccional de comentario

**Estado:** Completado. **Tarea superior:** SOC02.

Coordinar publicación del comentario y evento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.014 — Corregir paginación con comentario destacado

**Estado:** Completado. **Tarea superior:** SOC02.

Contar solo filas de páginas recibidas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.015 — Generar enlace público del post

**Estado:** Completado. **Tarea superior:** SOC02.

Usar APP_PUBLIC_URL y ruta interna.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.016 — Compartir enlace mediante plataforma

**Estado:** Completado. **Tarea superior:** SOC02.

Integrar share_plus y gestionar disponibilidad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.017 — Ofrecer copiar enlace como alternativa

**Estado:** Completado. **Tarea superior:** SOC02.

Usar Clipboard cuando compartir no está disponible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

### SOC02.018 — Manejar cancelación de compartir

**Estado:** Completado. **Tarea superior:** SOC02.

No mostrar confirmación de éxito tras cancelar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S072, S073, S074.

## SOC03 — Guardados y colaboración en publicaciones

### SOC03.001 — Abrir Guardados desde cabecera

**Estado:** Completado. **Tarea superior:** SOC03.

Usar /explore?section=saved y repositorios existentes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.002 — Separar Publicaciones y Fichas guardadas

**Estado:** Completado. **Tarea superior:** SOC03.

Reutilizar colecciones privadas sin almacenamiento paralelo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.003 — Agregar confirmación temporal de guardado

**Estado:** Completado. **Tarea superior:** SOC03.

Mostrar acción Deshacer sin bloquear navegación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.004 — Deshacer quitar guardado

**Estado:** Completado. **Tarea superior:** SOC03.

Conservar fila durante ventana de recuperación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.005 — Crear menú de acciones del post

**Estado:** Completado. **Tarea superior:** SOC03.

Mostrar guardar, detalle, reporte y edición según permisos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.006 — Agregar invitación opcional de colaboración

**Estado:** Completado. **Tarea superior:** SOC03.

Mantener desactivada inicialmente en compositor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.007 — Mostrar CTA solo en posts habilitados

**Estado:** Completado. **Tarea superior:** SOC03.

No ofrecer interés al autor de su propia publicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.008 — Capturar mensaje privado de interés

**Estado:** Completado. **Tarea superior:** SOC03.

Validar entre 1 y 1000 caracteres.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.009 — Persistir interés único por solicitante

**Estado:** Completado. **Tarea superior:** SOC03.

Evitar duplicados tras cerrar o reintentar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.010 — Restringir lectura de mensaje de interés

**Estado:** Completado. **Tarea superior:** SOC03.

Permitir solo a participantes autorizados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.011 — Actualizar CTA tras enviar interés

**Estado:** Completado. **Tarea superior:** SOC03.

Mostrar Interés enviado sin depender del cierre del panel.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

### SOC03.012 — Notificar interés al autor

**Estado:** Completado. **Tarea superior:** SOC03.

Crear evento sin añadir conversación de chat.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, PRO02.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S075, S076.

## SOC04 — Bandeja, privacidad y enlaces sociales

### SOC04.001 — Crear bandeja privada de notificaciones

**Estado:** Completado. **Tarea superior:** SOC04.

Mostrar reacciones, comentarios e intereses reales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.002 — Filtrar Todo y Sin leer

**Estado:** Completado. **Tarea superior:** SOC04.

Conservar selección al recargar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.003 — Mostrar punto de actividad pendiente

**Estado:** Completado. **Tarea superior:** SOC04.

Sincronizar indicador con entradas no leídas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.004 — Marcar lectura al abrir destino válido

**Estado:** Completado. **Tarea superior:** SOC04.

No leer entradas únicamente al mostrar el listado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.005 — Marcar todo con corte temporal de servidor

**Estado:** Completado. **Tarea superior:** SOC04.

Evitar afectar eventos nuevos fuera del corte.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.006 — Sincronizar bandeja mediante Realtime

**Estado:** Completado. **Tarea superior:** SOC04.

Actualizar mientras la cuenta está activa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.007 — Recargar bandeja al abrir o reanudar

**Estado:** Completado. **Tarea superior:** SOC04.

Recuperar cambios perdidos fuera de sesión activa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.008 — Limpiar controlador al cerrar sesión

**Estado:** Completado. **Tarea superior:** SOC04.

Separar notificaciones entre cuentas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.009 — Evitar autonotificaciones

**Estado:** Completado. **Tarea superior:** SOC04.

No avisar al autor de sus propias acciones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.010 — Actualizar evento al cambiar reacción

**Estado:** Completado. **Tarea superior:** SOC04.

Mantener coherencia de reacción y notificación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.011 — Eliminar evento al retirar reacción

**Estado:** Completado. **Tarea superior:** SOC04.

Retirar actividad que ya no corresponde.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.012 — Proteger destinos después de autenticación

**Estado:** Completado. **Tarea superior:** SOC04.

Conservar ruta interna durante login y registro.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.013 — Rechazar destinos externos o inválidos

**Estado:** Completado. **Tarea superior:** SOC04.

Evitar navegación no autorizada desde parámetros.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.014 — Resolver contenido retirado

**Estado:** Completado. **Tarea superior:** SOC04.

Mostrar estado explícito en lugar de detalle inexistente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

### SOC04.015 — Mantener un panel modal activo

**Estado:** Completado. **Tarea superior:** SOC04.

Restaurar foco con cierre, regreso o Escape.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC03, ACC03.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S077, S072.

## SOC05 — Validación y correcciones de la experiencia social

### SOC05.001 — Aplicar migraciones sociales 009 a 011

**Estado:** Completado. **Tarea superior:** SOC05.

Actualizar backend con gate remoto aprobado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.002 — Validar idempotencia y privacidad social

**Estado:** Completado. **Tarea superior:** SOC05.

Reporte acredita 21 comprobaciones Supabase reales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.003 — Verificar publicación Realtime

**Estado:** Completado. **Tarea superior:** SOC05.

Cubrir entrega y limpieza asociadas a la cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.004 — Verificar cascadas de contenido social

**Estado:** Completado. **Tarea superior:** SOC05.

No conservar relaciones huérfanas tras eliminación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.005 — Actualizar gate histórico de migraciones

**Estado:** Completado. **Tarea superior:** SOC05.

Comprobar 009–011 y publicación Realtime.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.006 — Corregir pie con teclado y texto ampliado

**Estado:** Completado. **Tarea superior:** SOC05.

Mantener campos y acción alcanzables.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.007 — Corregir límite semántico de Navigator

**Estado:** Completado. **Tarea superior:** SOC05.

Hacer accesibles controles de cabecera Web.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.008 — Retirar refresco aislado de Inicio

**Estado:** Completado. **Tarea superior:** SOC05.

Conservar actualización del feed dentro del contenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.009 — Validar layouts entre 360 y 1440 px

**Estado:** Completado. **Tarea superior:** SOC05.

Cubrir móvil, tablet, escritorio y texto 200%.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.010 — Validar compartir cancelado y Deshacer

**Estado:** Completado. **Tarea superior:** SOC05.

Cubrir estados sin éxito ficticio ni SnackBar permanente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.011 — Verificar recarga directa del enlace de post

**Estado:** Completado. **Tarea superior:** SOC05.

Comprobar fallback a index.html y retorno tras login.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.012 — Compilar Web, Android e iOS sin firma

**Estado:** Completado. **Tarea superior:** SOC05.

Reporte acredita builds de v7 correctos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.013 — Registrar suite social integrada

**Estado:** Completado. **Tarea superior:** SOC05.

Reporte acredita 295 Flutter y 820 checks SQL aislados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

### SOC05.014 — Limpiar datos temporales de validación

**Estado:** Completado. **Tarea superior:** SOC05.

Retirar cuentas, posts e imagen de comprobación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC01, SOC02, SOC03, SOC04.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S069, S078, S079.

## DIS03 — Implementaciones experimentales archivadas

Los commits b565ef0 y d54f4e5 conservan código de las propuestas. El merge con estrategia ours mantiene v7 como interfaz activa.

### DIS03.001 — Probar shell de navegación Corrientes locales

**Estado:** Sustituido. **Tarea superior:** DIS03.

Conservar composición móvil y rail de escritorio del experimento archivado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S066, S080, S081, S082, S083.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS03.002 — Probar superficies Paper y acentos mint

**Estado:** Sustituido. **Tarea superior:** DIS03.

Conservar tema experimental sin aplicarlo a la interfaz v7 vigente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S066, S080, S081, S082, S083.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS03.003 — Probar encabezados de comunidad experimentales

**Estado:** Sustituido. **Tarea superior:** DIS03.

Conservar énfasis editorial y contexto de autor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S066, S080, S081, S082, S083.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS03.004 — Probar reorganización experimental de perfil

**Estado:** Sustituido. **Tarea superior:** DIS03.

Mantener implementación archivada como antecedente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S066, S080, S081, S082, S083.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS03.005 — Probar rail adaptable a 600 y 1024 px

**Estado:** Sustituido. **Tarea superior:** DIS03.

Conservar distribución del segundo concepto móvil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S066, S080, S081, S082, S083.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS03.006 — Probar anillos aqua de avatar

**Estado:** Sustituido. **Tarea superior:** DIS03.

Conservar tratamiento visual del experimento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S066, S080, S081, S082, S083.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

### DIS03.007 — Archivar código de ambos experimentos

**Estado:** Sustituido. **Tarea superior:** DIS03.

Documentar implementaciones existentes sin contar los merges de conservación como funciones nuevas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS01.

**Fecha de evidencia:** 29/09/2026. **Fuentes:** S066, S080, S081, S082, S083.

**Para cerrar o completar el registro:** Propuesta conservada como antecedente; no representa la interfaz vigente.

## MIS02 — Rediseño del compositor y borradores de misión

### MIS02.001 — Dividir compositor en cuatro pasos

**Estado:** Completado. **Tarea superior:** MIS02.

Organizar idea, colaboración, lugar/fecha y revisión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.002 — Compartir flujo entre crear y editar

**Estado:** Completado. **Tarea superior:** MIS02.

Mantener restricciones y datos existentes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.003 — Agregar portada opcional de misión

**Estado:** Completado. **Tarea superior:** MIS02.

Conservar privacidad mientras es borrador.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.004 — Capturar requisitos de participación

**Estado:** Completado. **Tarea superior:** MIS02.

Mostrar condiciones claras de la convocatoria.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.005 — Capturar condiciones de colaboración

**Estado:** Completado. **Tarea superior:** MIS02.

Conservar acuerdos antes de publicar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.006 — Agregar compensación sin pago

**Estado:** Completado. **Tarea superior:** MIS02.

Registrar modalidad explícita.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.007 — Agregar compensación por acordar

**Estado:** Completado. **Tarea superior:** MIS02.

Separar ausencia de importe de modalidad acordable.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.008 — Agregar importe fijo en céntimos MXN

**Estado:** Completado. **Tarea superior:** MIS02.

Validar monto sin introducir pagos en la aplicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.009 — Mostrar compensación histórica no indicada

**Estado:** Completado. **Tarea superior:** MIS02.

No inventar importe para misiones previas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.010 — Bloquear compensación tras candidatura

**Estado:** Completado. **Tarea superior:** MIS02.

Mantener condiciones de participantes existentes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.011 — Crear tabla de borradores privados

**Estado:** Completado. **Tarea superior:** MIS02.

Separar preparación del contenido público.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.012 — Guardar borradores incompletos

**Estado:** Completado. **Tarea superior:** MIS02.

Aceptar texto temporalmente inválido sin publicarlo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.013 — Recuperar borrador desde Mis misiones

**Estado:** Completado. **Tarea superior:** MIS02.

Retomar preparación persistida.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.014 — Ofrecer guardar, descartar o continuar al salir

**Estado:** Completado. **Tarea superior:** MIS02.

Evitar pérdida silenciosa de edición.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.015 — Publicar borrador con UUID estable

**Estado:** Completado. **Tarea superior:** MIS02.

Evitar duplicación por reintentos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.016 — Registrar journal de publicación

**Estado:** Completado. **Tarea superior:** MIS02.

Recuperar misión publicada tras respuesta perdida.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.017 — Evitar resurrección de misión eliminada

**Estado:** Completado. **Tarea superior:** MIS02.

No volver a mostrarla como borrador.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

### MIS02.018 — Limpiar portadas sin referencias

**Estado:** Completado. **Tarea superior:** MIS02.

Retirar imágenes tras borrar borrador o misión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS01, COM02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S085, S086.

## MIS03 — Candidatura estructurada y seguimiento

### MIS03.001 — Crear pantalla de candidatura en tres pasos

**Estado:** Completado. **Tarea superior:** MIS03.

Separar revisión, datos y envío.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.002 — Mostrar revisión inicial de misión

**Estado:** Completado. **Tarea superior:** MIS03.

Presentar condiciones y elegibilidad actual.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.003 — Capturar motivación de candidatura

**Estado:** Completado. **Tarea superior:** MIS03.

Guardar mensaje estructurado del participante.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.004 — Exigir confirmación de disponibilidad

**Estado:** Completado. **Tarea superior:** MIS03.

Confirmar participación con acción explícita.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.005 — Agregar hasta tres muestras opcionales

**Estado:** Completado. **Tarea superior:** MIS03.

Limitar evidencia profesional de la solicitud.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.006 — Seleccionar fichas propias publicadas

**Estado:** Completado. **Tarea superior:** MIS03.

Validar propiedad y disponibilidad en servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.007 — Agregar enlaces HTTPS con título

**Estado:** Completado. **Tarea superior:** MIS03.

Permitir muestra externa identificable.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.008 — Mostrar muestra no disponible

**Estado:** Completado. **Tarea superior:** MIS03.

Explicar ficha retirada u oculta sin romper historial.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.009 — Mostrar revisión antes de enviar

**Estado:** Completado. **Tarea superior:** MIS03.

Permitir corregir información del formulario.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.010 — Enviar con ID estable de candidatura

**Estado:** Completado. **Tarea superior:** MIS03.

Recuperar reintentos sin solicitudes duplicadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.011 — Detectar conflicto de payload

**Estado:** Completado. **Tarea superior:** MIS03.

No aceptar otro contenido bajo el mismo ID.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.012 — Conservar formulario tras fallo

**Estado:** Completado. **Tarea superior:** MIS03.

Permitir reintento sin perder motivación ni muestras.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.013 — Refrescar elegibilidad al fallar

**Estado:** Completado. **Tarea superior:** MIS03.

Explicar cambios de cupo, fecha o estado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.014 — Mostrar confirmación con misión real

**Estado:** Completado. **Tarea superior:** MIS03.

No prometer tiempos de respuesta del organizador.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.015 — Filtrar Mis candidaturas por estado

**Estado:** Completado. **Tarea superior:** MIS03.

Mostrar pendiente, aceptada, no seleccionada y retirada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

### MIS03.016 — Permitir retirada y repostulación válida

**Estado:** Completado. **Tarea superior:** MIS03.

Conservar historial y restricciones del ciclo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, PRO02.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S087, S086.

## MIS04 — Gestión privada y avisos del ciclo de misión

### MIS04.001 — Crear pantalla privada del organizador

**Estado:** Completado. **Tarea superior:** MIS04.

Excluir controles de gestión para visitantes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.002 — Mostrar contadores reales de candidaturas

**Estado:** Completado. **Tarea superior:** MIS04.

Consultar estados desde backend.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.003 — Filtrar candidatos de gestión

**Estado:** Completado. **Tarea superior:** MIS04.

Conservar organización de solicitudes por estado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.004 — Consultar perfil y muestras del candidato

**Estado:** Completado. **Tarea superior:** MIS04.

Respetar acceso privado de organizador y participante.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.005 — Marcar finalistas internos

**Estado:** Completado. **Tarea superior:** MIS04.

No cambiar estado público ni enviar aviso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.006 — Crear selección provisional de grupo

**Estado:** Completado. **Tarea superior:** MIS04.

Permitir revisar personas antes de confirmar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.007 — Confirmar selección atómica

**Estado:** Completado. **Tarea superior:** MIS04.

Aceptar grupo sin superar cupo en concurrencia.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.008 — Conservar rechazo individual

**Estado:** Completado. **Tarea superior:** MIS04.

Permitir decisión específica sin rechazar al resto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.009 — Cerrar y reabrir sin selección automática

**Estado:** Completado. **Tarea superior:** MIS04.

Separar estado de convocatoria y candidaturas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.010 — Avisar candidatura recibida

**Estado:** Completado. **Tarea superior:** MIS04.

Crear notificación idempotente para organizador.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.011 — Avisar aceptación y rechazo

**Estado:** Completado. **Tarea superior:** MIS04.

Informar resolución al participante autorizado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.012 — Avisar retirada de candidatura

**Estado:** Completado. **Tarea superior:** MIS04.

Actualizar conocimiento del organizador.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.013 — Avisar cierre, reapertura y cancelación

**Estado:** Completado. **Tarea superior:** MIS04.

Notificar participantes activos según el evento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.014 — Avisar finalización de misión

**Estado:** Completado. **Tarea superior:** MIS04.

Completar información del ciclo sin avisos duplicados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.015 — Conservar navegación si falla lectura de aviso

**Estado:** Completado. **Tarea superior:** MIS04.

No impedir apertura por fallo de marcado leído.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.016 — Integrar panel Crear por tipo de perfil

**Estado:** Completado. **Tarea superior:** MIS04.

Ofrecer misión a todos y fichas profesionales autorizadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.017 — Guardar misiones en colección privada

**Estado:** Completado. **Tarea superior:** MIS04.

Ofrecer Guardadas dentro de Explorar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

### MIS04.018 — Conservar filtros y scroll del listado

**Estado:** Completado. **Tarea superior:** MIS04.

Volver del detalle sin perder posición.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, SOC04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S084, S088, S086.

## MIS05 — Verificación y despliegue del rediseño de misiones

### MIS05.001 — Validar contrato 013 en aislamiento

**Estado:** Completado. **Tarea superior:** MIS05.

Reporte acredita 146 comprobaciones específicas previas al despliegue.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.002 — Aplicar únicamente migración 013

**Estado:** Completado. **Tarea superior:** MIS05.

Comparar historial y dry-run antes de actualizar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.003 — Verificar gate y lint remotos

**Estado:** Completado. **Tarea superior:** MIS05.

Confirmar contrato 001–013 y esquema sin errores.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.004 — Probar publicación y candidatura idempotentes

**Estado:** Completado. **Tarea superior:** MIS05.

Cubrir reintentos y operaciones concurrentes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.005 — Probar selección atómica con cupo uno

**Estado:** Completado. **Tarea superior:** MIS05.

Evitar sobreadmisión en condiciones simultáneas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.006 — Probar privacidad de borradores y finalistas

**Estado:** Completado. **Tarea superior:** MIS05.

Separar datos de organización y contenido público.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.007 — Probar bloqueo de compensación y muestras

**Estado:** Completado. **Tarea superior:** MIS05.

Validar propiedad y restricciones de edición.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.008 — Probar retirada, repostulación y avisos

**Estado:** Completado. **Tarea superior:** MIS05.

Verificar ciclo entre sesiones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.009 — Registrar validación real de misiones

**Estado:** Completado. **Tarea superior:** MIS05.

Reporte acredita 54 comprobaciones remotas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.010 — Ejecutar regresión social del rediseño

**Estado:** Completado. **Tarea superior:** MIS05.

Reporte acredita otras 21 comprobaciones con Realtime.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.011 — Registrar suite integrada de misiones

**Estado:** Completado. **Tarea superior:** MIS05.

Reporte acredita 387 Flutter, 720 SQL aislados y 10 del gate.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.012 — Revisar móvil, tablet y escritorio

**Estado:** Completado. **Tarea superior:** MIS05.

Comprobar capturas, texto ampliado y teclado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.013 — Compilar clientes del rediseño

**Estado:** Completado. **Tarea superior:** MIS05.

Registrar Web, APK debug e iOS sin firma correctos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

### MIS05.014 — Limpiar recursos temporales de misiones

**Estado:** Completado. **Tarea superior:** MIS05.

Confirmar cero cuentas de pruebas remotas restantes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 30/09/2026 (SEP-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** MIS02, MIS03, MIS04.

**Fecha de evidencia:** 30/09/2026. **Fuentes:** S026, S085, S089.

## MAP01 — Mapa de misiones y consulta geográfica

El intervalo E es propuesto. El commit del 2 acredita integración de mapa, no duración real; despliegue posterior se acredita por el historial 001–015 del piloto.

### MAP01.001 — Crear ruta /map integrada al shell

**Estado:** Completado. **Tarea superior:** MAP01.

Conservar navegación y Crear en móvil.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.002 — Crear lienzo OpenStreetMap

**Estado:** Completado. **Tarea superior:** MAP01.

Ocupar área disponible con atribución visible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.003 — Configurar proveedor de teselas por defines

**Estado:** Completado. **Tarea superior:** MAP01.

Permitir URL y atribución sin cambiar widgets.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.004 — Extraer DeviceLocationService

**Estado:** Completado. **Tarea superior:** MAP01.

Reutilizar permisos y ubicación del selector existente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.005 — Consultar posición con permiso ya concedido

**Estado:** Completado. **Tarea superior:** MAP01.

No solicitar permiso automáticamente al abrir mapa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.006 — Solicitar permiso desde botón de ubicación

**Estado:** Completado. **Tarea superior:** MAP01.

Mantener exploración manual si se rechaza.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.007 — Manejar rechazo permanente o timeout

**Estado:** Completado. **Tarea superior:** MAP01.

Mostrar alternativas sin seguimiento en segundo plano.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.008 — Aplicar centro de respaldo del mapa

**Estado:** Completado. **Tarea superior:** MAP01.

Usar perfil válido o centro CDMX sin fingir GPS actual.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.009 — Cancelar centrado tras interacción manual

**Estado:** Completado. **Tarea superior:** MAP01.

No mover cámara si la persona ya exploró.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.010 — Crear RPC list_map_missions

**Estado:** Completado. **Tarea superior:** MAP01.

Consultar viewport, texto, categoría, fechas y radio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.011 — Crear índice parcial de misiones ubicadas

**Estado:** Completado. **Tarea superior:** MAP01.

Optimizar conjunto disponible del mapa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.012 — Filtrar misiones abiertas y futuras

**Estado:** Completado. **Tarea superior:** MAP01.

Excluir ocultas, sin coordenadas o sin cupo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.013 — Buscar texto dentro del viewport

**Estado:** Completado. **Tarea superior:** MAP01.

Consultar título, lugar, categoría y organizador.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.014 — Crear chips Todo y Hoy

**Estado:** Completado. **Tarea superior:** MAP01.

Compartir estado con los filtros.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.015 — Crear hoja de filtros de mapa

**Estado:** Completado. **Tarea superior:** MAP01.

Configurar categoría, fecha y radio 1/3/5/10 km.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.016 — Limpiar filtros conservando búsqueda

**Estado:** Completado. **Tarea superior:** MAP01.

Restablecer estado sin borrar el texto introducido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.017 — Convertir límites de fecha a UTC

**Estado:** Completado. **Tarea superior:** MAP01.

Usar días locales y próximos siete días correctamente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.018 — Crear clusters de puntos reales

**Estado:** Completado. **Tarea superior:** MAP01.

Contar miembros y desplegar posiciones coincidentes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.019 — Crear preview de misión seleccionada

**Estado:** Completado. **Tarea superior:** MAP01.

Mostrar categoría, título, autor, fecha, lugar y foto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.020 — Mostrar distancia solo con ubicación real

**Estado:** Completado. **Tarea superior:** MAP01.

Presentar aproximación sin tiempo de ruta inventado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.021 — Cerrar preview con mapa o deslizamiento

**Estado:** Completado. **Tarea superior:** MAP01.

Mantener salidas explícitas de la tarjeta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.022 — Conservar cámara y filtros al volver

**Estado:** Completado. **Tarea superior:** MAP01.

Actualizar disponibilidad tras visitar detalle.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.023 — Crear acción Buscar en esta zona

**Estado:** Completado. **Tarea superior:** MAP01.

Mostrarla tras cambio relevante sin consultar en cada gesto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.024 — Descartar respuestas antiguas de mapa

**Estado:** Completado. **Tarea superior:** MAP01.

Proteger resultados frente a consultas obsoletas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.025 — Conservar resultados ante error

**Estado:** Completado. **Tarea superior:** MAP01.

Ofrecer reintento sin vaciar contenido válido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.026 — Manejar límite de 300 misiones

**Estado:** Completado. **Tarea superior:** MAP01.

Mostrar recorte y pedir acercamiento de zona.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.027 — Aceptar viewport sobre antimeridiano

**Estado:** Completado. **Tarea superior:** MAP01.

Tratar límites oeste mayores que este.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.028 — Proteger RPC de consulta anónima

**Estado:** Completado. **Tarea superior:** MAP01.

Exigir cuenta activa y campos públicos autorizados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

### MAP01.029 — Crear pruebas y arnés de mapa

**Estado:** Completado. **Tarea superior:** MAP01.

Cubrir UI, ubicación, repositorio y consulta SQL.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/09/2026 (SEP-4) | 07/10/2026 (OCT-1) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** COM02, MIS01, SOC01.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S007, S090, S091.

## MAR01 — Iconos y recursos de identidad de la aplicación

### MAR01.001 — Preparar imagen de icono de aplicación

**Estado:** Completado. **Tarea superior:** MAR01.

Agregar marea_app como recurso de marca.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S092, S093, S094.

### MAR01.002 — Generar iconos Android por densidad

**Estado:** Completado. **Tarea superior:** MAR01.

Actualizar hdpi, mdpi, xhdpi, xxhdpi y xxxhdpi.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S092, S093, S094.

### MAR01.003 — Generar variantes del icono iOS

**Estado:** Completado. **Tarea superior:** MAR01.

Actualizar AppIcon en los tamaños del proyecto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S092, S093, S094.

### MAR01.004 — Actualizar catálogo AppIcon

**Estado:** Completado. **Tarea superior:** MAR01.

Relacionar archivos con sus tamaños y escalas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S092, S093, S094.

### MAR01.005 — Actualizar configuración de identidad iOS

**Estado:** Completado. **Tarea superior:** MAR01.

Mantener referencia al icono y nombre de aplicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S092, S093, S094.

### MAR01.006 — Conservar logotipo e isotipo separados

**Estado:** Completado. **Tarea superior:** MAR01.

No reemplazar recursos de cabecera por icono de launcher.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** DIS02.

**Fecha de evidencia:** 02/10/2026. **Fuentes:** S092, S093, S094.

## INT01 — Reacciones e interacciones modernas

Estado reconstruido por inspección del checkout al 06/10/2026 y reportes locales. La fecha de evidencia es la fecha de corte, salvo fecha individual explícita. Sin duración real registrada.

### INT01.001 — Reaccionar con toque directo

**Estado:** Completado. **Tarea superior:** INT01.

Activar reacción desde el control principal.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.002 — Abrir selector manteniendo pulsado

**Estado:** Completado. **Tarea superior:** INT01.

Mostrar alternativas mediante gesto sostenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.003 — Seleccionar mediante deslizar y soltar

**Estado:** Completado. **Tarea superior:** INT01.

Resolver reacción al finalizar el gesto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.004 — Actualizar reacción de forma optimista

**Estado:** Completado. **Tarea superior:** INT01.

Mostrar selección inmediata mientras confirma servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.005 — Restaurar selección tras error

**Estado:** Completado. **Tarea superior:** INT01.

Revertir cambio optimista y permitir reintento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.006 — Operar selector mediante teclado

**Estado:** Completado. **Tarea superior:** INT01.

Mantener navegación y elección accesibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.007 — Cancelar selector sin modificar reacción

**Estado:** Completado. **Tarea superior:** INT01.

Cerrar con gesto o acción de cancelación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.008 — Ignorar respuesta tardía de cuenta anterior

**Estado:** Completado. **Tarea superior:** INT01.

No aplicar reacción tras cambio de sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.009 — Evitar controles semánticos duplicados

**Estado:** Completado. **Tarea superior:** INT01.

Presentar una acción accesible coherente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.010 — Usar InkRipple compatible con pruebas

**Estado:** Completado. **Tarea superior:** INT01.

Conservar ondas Material y animación de escala.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.011 — Coordinar paneles en navegación raíz

**Estado:** Completado. **Tarea superior:** INT01.

Evitar desplazamiento inesperado del feed.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.012 — Ocultar dock al abrir panel

**Estado:** Completado. **Tarea superior:** INT01.

Mantener espacio y visibilidad coordinados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.013 — Restaurar dock al cerrar panel

**Estado:** Completado. **Tarea superior:** INT01.

Recuperar navegación tras regresar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

### INT01.014 — Proteger cierre de paneles anidados

**Estado:** Completado. **Tarea superior:** INT01.

No dejar estado de navegación residual.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC02, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S096, S097.

## INT02 — Cargas, botones y paneles compartidos

Estado reconstruido por inspección del checkout al 06/10/2026 y reportes locales. La fecha de evidencia es la fecha de corte, salvo fecha individual explícita. Sin duración real registrada.

### INT02.001 — Crear MareaSkeleton compartido

**Estado:** Completado. **Tarea superior:** INT02.

Representar carga sin ruedas en contenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.002 — Agregar esqueletos al feed

**Estado:** Completado. **Tarea superior:** INT02.

Mostrar estructura de publicaciones durante carga.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.003 — Agregar esqueletos a comentarios

**Estado:** Completado. **Tarea superior:** INT02.

Mantener contexto del panel mientras consulta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.004 — Agregar esqueletos a perfiles y fichas

**Estado:** Completado. **Tarea superior:** INT02.

Adaptar cargas de recursos profesionales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.005 — Agregar esqueletos a misiones y mapa

**Estado:** Completado. **Tarea superior:** INT02.

Unificar estados de consulta disponibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.006 — Crear botón con texto de progreso

**Estado:** Completado. **Tarea superior:** INT02.

Mostrar acción en curso sin perder nombre del control.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.007 — Bloquear doble envío en botones compartidos

**Estado:** Completado. **Tarea superior:** INT02.

Evitar mutaciones repetidas mientras espera.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.008 — Crear panel compartido de acciones

**Estado:** Completado. **Tarea superior:** INT02.

Unificar disposición y estados de superficies.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.009 — Reemplazar refresco por indicador lineal

**Estado:** Completado. **Tarea superior:** INT02.

Conservar contenido durante actualización.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.010 — Conservar contenido de showcase al recargar

**Estado:** Completado. **Tarea superior:** INT02.

No vaciar fichas mientras llega consulta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.011 — Adaptar esqueletos pequeños

**Estado:** Completado. **Tarea superior:** INT02.

Evitar errores con tamaños mínimos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.012 — Respetar movimiento reducido

**Estado:** Completado. **Tarea superior:** INT02.

Mantener experiencia usable sin animaciones innecesarias.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

### INT02.013 — Abreviar Acciones a Más donde corresponde

**Estado:** Completado. **Tarea superior:** INT02.

Evitar desbordamiento con texto ampliado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INT01, SOC01, PRO02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S095, S098, S099, S100.

## PUS01 — Cliente Android de notificaciones y preferencias

Estado reconstruido por inspección del checkout al 06/10/2026 y reportes locales. La fecha de evidencia es la fecha de corte, salvo fecha individual explícita. Sin duración real registrada.

### PUS01.001 — Crear modelos de preferencias de notificación

**Estado:** Completado. **Tarea superior:** PUS01.

Representar permisos de eventos y mensajes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.002 — Crear repositorio de preferencias

**Estado:** Completado. **Tarea superior:** PUS01.

Persistir opciones privadas en Supabase.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.003 — Crear abstracción PushGateway

**Estado:** Completado. **Tarea superior:** PUS01.

Separar Android de clientes con bandeja únicamente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.004 — Inicializar Firebase solo en transporte Android

**Estado:** Completado. **Tarea superior:** PUS01.

Mantener Web e iOS con bandeja interna.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.005 — Solicitar permiso de avisos del celular

**Estado:** Completado. **Tarea superior:** PUS01.

Hacer explícita la autorización del dispositivo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.006 — Registrar dispositivo y token FCM

**Estado:** Completado. **Tarea superior:** PUS01.

Asociar versión del token a la cuenta activa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.007 — Actualizar registro tras renovación del token

**Estado:** Completado. **Tarea superior:** PUS01.

Evitar conservar un token anterior como vigente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.008 — Mostrar configuración de notificaciones

**Estado:** Completado. **Tarea superior:** PUS01.

Permitir cambiar preferencias desde ajustes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.009 — Desactivar mensajes ocasionales

**Estado:** Completado. **Tarea superior:** PUS01.

Cancelar pendientes al retirar preferencia.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.010 — Presentar aviso local en primer plano

**Estado:** Completado. **Tarea superior:** PUS01.

Evitar duplicación del mismo evento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.011 — Recibir apertura de aviso en segundo plano

**Estado:** Completado. **Tarea superior:** PUS01.

Resolver destino compartido con la bandeja.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.012 — Recibir apertura con proceso cerrado

**Estado:** Completado. **Tarea superior:** PUS01.

Recuperar ruta desde arranque en frío.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.013 — Marcar lectura al abrir destino de push

**Estado:** Completado. **Tarea superior:** PUS01.

Coordinar navegación con read_at.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.014 — Actualizar actividad durante sesión

**Estado:** Completado. **Tarea superior:** PUS01.

Registrar entrada, reanudación y actividad periódica.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.015 — Cancelar programación al volver

**Estado:** Completado. **Tarea superior:** PUS01.

No enviar mensaje de inactividad a una cuenta activa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.016 — Limpiar registro al cerrar sesión

**Estado:** Completado. **Tarea superior:** PUS01.

Conservar seguridad entre cuentas y recuperación offline.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

### PUS01.017 — Mostrar ausencia de configuración Firebase

**Estado:** Completado. **Tarea superior:** PUS01.

Mantener bandeja sin afirmar avisos disponibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** SOC04, INT02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S102, S103, S104.

## PUS02 — Cola y entrega push en Supabase

Estado reconstruido por inspección del checkout al 06/10/2026 y reportes locales. La fecha de evidencia es la fecha de corte, salvo fecha individual explícita. Sin duración real registrada.

### PUS02.001 — Crear migración 014 de push

**Estado:** Completado. **Tarea superior:** PUS02.

Agregar dispositivos, preferencias y cola privada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.002 — Proteger dispositivos con permisos de servidor

**Estado:** Completado. **Tarea superior:** PUS02.

No exponer tokens de otras cuentas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.003 — Crear settings privados de envío

**Estado:** Completado. **Tarea superior:** PUS02.

Permitir activar o pausar backend.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.004 — Encolar eventos sociales autorizados

**Estado:** Completado. **Tarea superior:** PUS02.

Relacionar notificación y trabajo de entrega.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.005 — Crear worker send-push

**Estado:** Completado. **Tarea superior:** PUS02.

Procesar trabajos fuera del cliente Flutter.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.006 — Autenticar worker con secreto propio

**Estado:** Completado. **Tarea superior:** PUS02.

Rechazar llamadas sin autorización.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.007 — Obtener OAuth de cuenta FCM

**Estado:** Completado. **Tarea superior:** PUS02.

Usar credencial de backend para HTTP v1.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.008 — Enviar aviso mediante FCM HTTP v1

**Estado:** Completado. **Tarea superior:** PUS02.

Transportar notificación al Android registrado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.009 — Reintentar fallos de entrega

**Estado:** Completado. **Tarea superior:** PUS02.

Mantener intentos y estado de cola.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.010 — Terminar trabajos tras cinco fallos

**Estado:** Completado. **Tarea superior:** PUS02.

Evitar reintentos indefinidos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.011 — Desactivar versión reclamada de token inválido

**Estado:** Completado. **Tarea superior:** PUS02.

No afectar una renovación posterior del dispositivo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.012 — Programar mensaje tras 72 horas sin actividad

**Estado:** Completado. **Tarea superior:** PUS02.

Separar evento ocasional de actividad social.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.013 — Respetar horario 10:00 a 19:00 local

**Estado:** Completado. **Tarea superior:** PUS02.

Usar zona registrada de la cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.014 — Limitar mensajes a dos en siete días

**Estado:** Completado. **Tarea superior:** PUS02.

Mantener separación de 72 horas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.015 — Cancelar mensaje al desactivar preferencia

**Estado:** Completado. **Tarea superior:** PUS02.

Conservar bandeja sin entregar pendientes cancelados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.016 — Despertar worker desde triggers

**Estado:** Completado. **Tarea superior:** PUS02.

Ejecutar entrega inmediata y dejar cron para continuidad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

### PUS02.017 — Crear activación idempotente del scheduler

**Estado:** Completado. **Tarea superior:** PUS02.

Instalar un proceso por minuto con nombre estable.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S105, S106, S107, S101.

## PUS03 — Configuración Firebase, despliegue y distribución

Estado reconstruido por inspección del checkout al 06/10/2026 y reportes locales. La fecha de evidencia es la fecha de corte, salvo fecha individual explícita. Sin duración real registrada.

### PUS03.001 — Crear proyecto Firebase MAREA

**Estado:** Completado. **Tarea superior:** PUS03.

Registrar proyecto sin Analytics para transporte de avisos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.002 — Registrar Android com.marea.app

**Estado:** Completado. **Tarea superior:** PUS03.

Vincular aplicación con proyecto FCM.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.003 — Obtener configuración pública Firebase

**Estado:** Completado. **Tarea superior:** PUS03.

Guardar defines Android en archivo ignorado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.004 — Habilitar API FCM HTTP v1

**Estado:** Completado. **Tarea superior:** PUS03.

Preparar transporte de envío desde backend.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.005 — Crear cuenta dedicada de envío

**Estado:** Completado. **Tarea superior:** PUS03.

Asignar rol autorizado de Firebase Cloud Messaging.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.006 — Transferir credencial FCM a Supabase

**Estado:** Completado. **Tarea superior:** PUS03.

Conservar clave privada únicamente en backend.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.007 — Desactivar credencial fallida anterior

**Estado:** Completado. **Tarea superior:** PUS03.

Evitar claves duplicadas activas tras descarga fallida.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.008 — Eliminar copias temporales de credenciales

**Estado:** Completado. **Tarea superior:** PUS03.

Retirar archivos usados en la transferencia.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.009 — Aplicar migración 014 al proyecto

**Estado:** Completado. **Tarea superior:** PUS03.

Confirmar contrato remoto antes de activar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.010 — Desplegar send-push

**Estado:** Completado. **Tarea superior:** PUS03.

Configurar secretos y comprobar worker remoto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.011 — Configurar URL y secreto en Vault

**Estado:** Completado. **Tarea superior:** PUS03.

Preparar invocación privada del scheduler.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.012 — Generar recursos públicos Firebase en Gradle

**Estado:** Completado. **Tarea superior:** PUS03.

Permitir inicialización nativa al despertar proceso cerrado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.013 — Mantener auto-init bajo permiso

**Estado:** Completado. **Tarea superior:** PUS03.

No registrar avisos antes de autorización del dispositivo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.014 — Actualizar target iOS a 15

**Estado:** Completado. **Tarea superior:** PUS03.

Conservar compatibilidad de compilación con plugins Firebase.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.015 — Compilar APK con configuración Firebase

**Estado:** Completado. **Tarea superior:** PUS03.

Preparar cliente Android para pruebas reales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.016 — Instalar APK en Samsung SM-A556E

**Estado:** Completado. **Tarea superior:** PUS03.

Actualizar dispositivo autorizado para validar recepción.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.017 — Publicar Web compatible en Netlify

**Estado:** Completado. **Tarea superior:** PUS03.

El documento acredita publicación del 05/10/2026.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 05/10/2026. **Fuentes:** S101, S095, S108, S109.

**Observación:** docs/android-push.md fecha la publicación Web el 05/10/2026; no acredita duración de publicación.

### PUS03.018 — Comparar main.dart.js público y local

**Estado:** Completado. **Tarea superior:** PUS03.

Confirmar hash idéntico de la compilación publicada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.019 — Activar cron y bandera de envíos

**Estado:** Completado. **Tarea superior:** PUS03.

Habilitar procesamiento tras validar Android y Web.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

### PUS03.020 — Verificar una sola ejecución por minuto

**Estado:** Completado. **Tarea superior:** PUS03.

Comprobar cron succeeded y cola vacía.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S108, S109.

## PUS04 — Correcciones y pruebas de push ejecutadas

Estado reconstruido por inspección del checkout al 06/10/2026 y reportes locales. La fecha de evidencia es la fecha de corte, salvo fecha individual explícita. Sin duración real registrada.

### PUS04.001 — Corregir logout offline o colgado

**Estado:** Completado. **Tarea superior:** PUS04.

Evitar conservar registro de una sesión finalizada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.002 — Corregir reset tardío entre cuentas

**Estado:** Completado. **Tarea superior:** PUS04.

No borrar estado nuevo por respuesta anterior.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.003 — Corregir clasificación refresh_token_not_found

**Estado:** Completado. **Tarea superior:** PUS04.

Recuperar acceso al reconocer sesión inválida.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.004 — Corregir recuperación de diálogo de permiso

**Estado:** Completado. **Tarea superior:** PUS04.

Persistir solicitud solo después de terminar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.005 — Usar promptOnce al refrescar permiso

**Estado:** Completado. **Tarea superior:** PUS04.

Permitir recuperación sin diálogos repetidos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.006 — Corregir inicialización nativa en segundo plano

**Estado:** Completado. **Tarea superior:** PUS04.

Resolver primer aviso físico que no llegó.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.007 — Probar aviso con aplicación abierta

**Estado:** Completado. **Tarea superior:** PUS04.

Usuario confirmó un único aviso del sistema.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.008 — Probar aviso visible en segundo plano

**Estado:** Completado. **Tarea superior:** PUS04.

Reporte acredita recepción tras corregir recursos nativos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.009 — Probar aviso con proceso realmente cerrado

**Estado:** Completado. **Tarea superior:** PUS04.

Reporte acredita aviso y apertura desde arranque en frío.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.010 — Verificar apertura y read_at de avisos

**Estado:** Completado. **Tarea superior:** PUS04.

Confirmar destino Inicio y evento leído en pruebas físicas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.011 — Limpiar cinco eventos de diagnóstico

**Estado:** Completado. **Tarea superior:** PUS04.

Restaurar actividad y zona antes de activar cron.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.012 — Validar cola y worker reales

**Estado:** Completado. **Tarea superior:** PUS04.

Comprobar configuración activa y dispositivo habilitado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.013 — Registrar suite automática de push

**Estado:** Completado. **Tarea superior:** PUS04.

Reporte acredita 439 Flutter y 28 de comunidad posteriores.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

### PUS04.014 — Validar backend y gate de push

**Estado:** Completado. **Tarea superior:** PUS04.

Reporte acredita nueve pruebas backend y once del gate.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS01, PUS02, PUS03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S101, S095, S110.

## TOU01 — Diseño de recorridos y experiencia presencial

### TOU01.001 — Separar visita 360° y recorrido con cámara

**Estado:** Completado. **Tarea superior:** TOU01.

Definir experiencias diferentes sobre el mismo recorrido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.002 — Definir jerarquía espacial

**Estado:** Completado. **Tarea superior:** TOU01.

Organizar local, zonas, posiciones, puntos y contenido vinculado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.003 — Definir versiones públicas y borradores

**Estado:** Completado. **Tarea superior:** TOU01.

Separar lectura del visitante y edición privada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.004 — Definir responsabilidad del espacio

**Estado:** Completado. **Tarea superior:** TOU01.

No acreditar local por ser tipo Negocio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.005 — Definir permisos de contenido vinculado

**Estado:** Completado. **Tarea superior:** TOU01.

Separar autor del contenido y responsable del local.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.006 — Diseñar asistente de preparación

**Estado:** Completado. **Tarea superior:** TOU01.

Organizar Local, Zonas, Puntos, Conexiones, Preview y Publicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.007 — Diseñar captura desde posición fija

**Estado:** Completado. **Tarea superior:** TOU01.

Evitar prometer reconstrucción navegable 3D.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.008 — Diseñar visita sin permisos de cámara

**Estado:** Completado. **Tarea superior:** TOU01.

Permitir explorar panoramas desde casa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.009 — Diseñar alternativa de lista en AR

**Estado:** Completado. **Tarea superior:** TOU01.

Mantener lectura cuando no hay soporte o permiso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.010 — Crear seis láminas de referencia

**Estado:** Completado. **Tarea superior:** TOU01.

Conservar diseño y prompts sin tratarlos como pruebas físicas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.011 — Actualizar fichas de pantalla del recorrido

**Estado:** Completado. **Tarea superior:** TOU01.

Describir acciones, regreso y estados por flujo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

### TOU01.012 — Definir criterios de aceptación física

**Estado:** Completado. **Tarea superior:** TOU01.

Exigir captura, recuperación, procesamiento y reconocimiento reales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** INV03, PRO04, MAP01.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S111, S112.

## TOU02 — Editor del local, zonas, puntos y versiones

### TOU02.001 — Crear modelos tipados del recorrido

**Estado:** Completado. **Tarea superior:** TOU02.

Representar documento, zonas, posiciones, puntos y progreso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.002 — Crear repositorio de recorridos

**Estado:** Completado. **Tarea superior:** TOU02.

Conectar editor, publicación y lectura con RPC del servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.003 — Crear administración de recorridos

**Estado:** Completado. **Tarea superior:** TOU02.

Consultar propios, solicitudes y acciones disponibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.004 — Confirmar nombre y ubicación del local

**Estado:** Completado. **Tarea superior:** TOU02.

Recuperar datos de perfil y permitir completarlos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.005 — Capturar contexto y evidencia privada

**Estado:** Completado. **Tarea superior:** TOU02.

Separar responsabilidad del espacio de presentación pública.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.006 — Crear y editar zonas

**Estado:** Completado. **Tarea superior:** TOU02.

Agrupar varias posiciones del local.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.007 — Crear y editar posiciones 360°

**Estado:** Completado. **Tarea superior:** TOU02.

Definir nombre, panorama y orientación inicial.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.008 — Seleccionar posición de inicio

**Estado:** Completado. **Tarea superior:** TOU02.

Determinar primera vista del recorrido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.009 — Crear puntos con explicación propia

**Estado:** Completado. **Tarea superior:** TOU02.

Conservar información aunque falle un vínculo externo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.010 — Ubicar puntos mediante yaw y pitch

**Estado:** Completado. **Tarea superior:** TOU02.

Normalizar ángulos dentro del panorama.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.011 — Crear puntos solo en lista

**Estado:** Completado. **Tarea superior:** TOU02.

Permitir detalle sin posición angular.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.012 — Vincular contenido existente

**Estado:** Completado. **Tarea superior:** TOU02.

Referenciar posts, obras, productos, servicios y misiones sin duplicarlos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.013 — Solicitar permiso al autor vinculado

**Estado:** Completado. **Tarea superior:** TOU02.

Distinguir disponible, pendiente y retirado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.014 — Crear conexiones entre posiciones

**Estado:** Completado. **Tarea superior:** TOU02.

Guardar destino, nombre e indicación escrita.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.015 — Ordenar paradas del recorrido

**Estado:** Completado. **Tarea superior:** TOU02.

Definir secuencia de visita y alternativas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.016 — Configurar vigencia de versión

**Estado:** Completado. **Tarea superior:** TOU02.

Persistir inicio y fin coherentes en UTC.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.017 — Crear vista previa privada

**Estado:** Completado. **Tarea superior:** TOU02.

Revisar borrador antes del envío.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.018 — Guardar borrador inmediatamente en local

**Estado:** Completado. **Tarea superior:** TOU02.

Conservar cambios antes de sincronizar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.019 — Recuperar edición sin red

**Estado:** Completado. **Tarea superior:** TOU02.

Abrir documento local por cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.020 — Esperar guardado al salir del editor

**Estado:** Completado. **Tarea superior:** TOU02.

Evitar pérdida del último cambio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.021 — Congelar snapshot al enviar versión

**Estado:** Completado. **Tarea superior:** TOU02.

No reemplazar envío en revisión con edición posterior.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.022 — Recuperar envío tras respuesta perdida

**Estado:** Completado. **Tarea superior:** TOU02.

Consultar journal antes de repetir.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.023 — Pausar recorrido público

**Estado:** Completado. **Tarea superior:** TOU02.

Retirar descubrimiento mientras se actualiza.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

### TOU02.024 — Invalidar puntos al reemplazar panorama

**Estado:** Completado. **Tarea superior:** TOU02.

Exigir revisión de puntos y conexiones afectados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU01, PRO04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S113, S114, S115.

## TOU03 — Captura guiada y persistencia local

Implementación y pruebas de recuperación documentadas; calibración y captura óptica reales permanecen pendientes en FIS01.

### TOU03.001 — Abrir cámara principal posterior a 1×

**Estado:** Completado. **Tarea superior:** TOU03.

Mantener lente y zoom coherentes para captura.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.002 — Bloquear orientación de captura en retrato

**Estado:** Completado. **Tarea superior:** TOU03.

Conservar eje óptico esperado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.003 — Tomar JPEG de calibración

**Estado:** Completado. **Tarea superior:** TOU03.

Medir proporción real con EXIF aplicado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.004 — Excluir calibración del conteo de tomas

**Estado:** Completado. **Tarea superior:** TOU03.

No incorporarla como fotografía aceptada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.005 — Consultar FOV nativo de la cámara

**Estado:** Completado. **Tarea superior:** TOU03.

No usar apertura constante de respaldo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.006 — Crear objetivos según FOV

**Estado:** Completado. **Tarea superior:** TOU03.

Distribuir anillos con al menos 40% de solapamiento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.007 — Agregar objetivos de cenit y nadir

**Estado:** Completado. **Tarea superior:** TOU03.

Incluir techo y piso de la esfera.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.008 — Mostrar objetivo y estabilidad

**Estado:** Completado. **Tarea superior:** TOU03.

Guiar siguiente captura con orientación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.009 — Aceptar y contar tomas confirmadas

**Estado:** Completado. **Tarea superior:** TOU03.

Conservar solo imágenes válidas de la sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.010 — Repetir una toma confirmada

**Estado:** Completado. **Tarea superior:** TOU03.

Permitir corregir fotografía eliminando la previa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.011 — Guardar fotos por cuenta en dispositivo

**Estado:** Completado. **Tarea superior:** TOU03.

Separar archivos entre sesiones de usuario.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.012 — Guardar manifiesto y orientación de tomas

**Estado:** Completado. **Tarea superior:** TOU03.

Persistir dimensiones, FOV y objetivo asociado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.013 — Recuperar sesión de captura interrumpida

**Estado:** Completado. **Tarea superior:** TOU03.

Mantener tomas aceptadas al regresar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.014 — Comprobar lente y FOV al retomar

**Estado:** Completado. **Tarea superior:** TOU03.

Rechazar recuperación incompatible con la cámara original.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.015 — Realinear con primera foto al retomar

**Estado:** Completado. **Tarea superior:** TOU03.

Exigir volver a posición antes de reiniciar yaw.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.016 — Ofrecer nueva captura si cambia lente

**Estado:** Completado. **Tarea superior:** TOU03.

Conservar versión publicada mientras se repite trabajo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.017 — Detener cámara al salir o cambiar cuenta

**Estado:** Completado. **Tarea superior:** TOU03.

Evitar recursos activos en otra sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

### TOU03.018 — Separar captura y vista AR

**Estado:** Completado. **Tarea superior:** TOU03.

Liberar CameraController antes del tracking.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, INV03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S009, S116, S117.

## TOU04 — Orientación nativa Android e iOS

Las pruebas nativas no acreditan sensor, óptica ni AR físico en teléfonos.

### TOU04.001 — Registrar canal marea/tour_motion Android

**Estado:** Completado. **Tarea superior:** TOU04.

Integrar start, stop y cameraInfo sin romper notificaciones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.002 — Registrar canal de orientación en iOS

**Estado:** Completado. **Tarea superior:** TOU04.

Usar motor implícito de Flutter.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.003 — Transformar RotationVector Android

**Estado:** Completado. **Tarea superior:** TOU04.

Calcular yaw, pitch y roll desde eje óptico posterior.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.004 — Invertir quaternion CoreMotion iOS

**Estado:** Completado. **Tarea superior:** TOU04.

Transformar referencia y dispositivo en orden correcto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.005 — Normalizar yaw respecto del inicio

**Estado:** Completado. **Tarea superior:** TOU04.

Conservar pitch del horizonte y los polos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.006 — Diferir origen azimutal en inicio polar

**Estado:** Completado. **Tarea superior:** TOU04.

Evitar yaw indefinido en cenit o nadir.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.007 — Calcular FOV Android desde características

**Estado:** Completado. **Tarea superior:** TOU04.

Aplicar focal, área activa y crop real del JPEG.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.008 — Rechazar cámaras Android ambiguas

**Estado:** Completado. **Tarea superior:** TOU04.

No inferir apertura de múltiples focales incompatibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.009 — Calcular FOV iOS desde cámara identificada

**Estado:** Completado. **Tarea superior:** TOU04.

Usar activeFormat y proporción JPEG a zoom 1×.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.010 — Emitir error sin datos de cámara

**Estado:** Completado. **Tarea superior:** TOU04.

Mostrar camera_info_unavailable en lugar de constante ficticia.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.011 — Liberar sensores al pausar

**Estado:** Completado. **Tarea superior:** TOU04.

Detener canales y recursos cuando dejan de usarse.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

### TOU04.012 — Verificar matemáticas y callbacks nativos

**Estado:** Completado. **Tarea superior:** TOU04.

Reporte acredita tres pruebas Android, siete matemáticas y ocho de orden Swift.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S118, S119, S120.

## TOU05 — Importación GPano y carga privada reanudable

### TOU05.001 — Importar JPEG equirectangular GPano

**Estado:** Completado. **Tarea superior:** TOU05.

Exigir metadatos de esfera completa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.002 — Validar dimensiones y área GPano

**Estado:** Completado. **Tarea superior:** TOU05.

Rechazar relación 2:1 que no acredita proyección.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.003 — Permitir administración e importación web

**Estado:** Completado. **Tarea superior:** TOU05.

No ofrecer captura guiada ni tracking Web.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.004 — Explicar reselección de archivo Web

**Estado:** Completado. **Tarea superior:** TOU05.

No fingir persistencia de bytes tras cerrar pantalla.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.005 — Crear carga TUS de fragmentos 6 MiB

**Estado:** Completado. **Tarea superior:** TOU05.

Subir originales a bucket privado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.006 — Guardar URL y offset de carga

**Estado:** Completado. **Tarea superior:** TOU05.

Crear checkpoint durable por sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.007 — Consultar HEAD al reanudar

**Estado:** Completado. **Tarea superior:** TOU05.

Recuperar offset real del servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.008 — Validar host del endpoint TUS

**Estado:** Completado. **Tarea superior:** TOU05.

Evitar uso de destino no autorizado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.009 — Validar cuenta activa durante carga

**Estado:** Completado. **Tarea superior:** TOU05.

No continuar escritura tras cambio de sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.010 — Subir todos los archivos del manifiesto

**Estado:** Completado. **Tarea superior:** TOU05.

No iniciar procesamiento de captura incompleta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.011 — Confirmar captura enviada inmutable

**Estado:** Completado. **Tarea superior:** TOU05.

Separar edición local del envío congelado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.012 — Recuperar respuesta perdida de envío

**Estado:** Completado. **Tarea superior:** TOU05.

Consultar estado persistido antes de repetir.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.013 — Mantener cuenta original de archivos locales

**Estado:** Completado. **Tarea superior:** TOU05.

No trasladar fotos al cambiar sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

### TOU05.014 — Probar interrupción y hash de TUS

**Estado:** Completado. **Tarea superior:** TOU05.

Piloto acredita reanudación con bytes idénticos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S121, S122, S123.

## TOU06 — Backend de recorridos, permisos y limpieza

### TOU06.001 — Crear migración 015 de recorridos

**Estado:** Completado. **Tarea superior:** TOU06.

Agregar documentos, revisiones, permisos y progreso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.002 — Crear buckets tour-inputs y tour-assets

**Estado:** Completado. **Tarea superior:** TOU06.

Mantener originales, evidencias y borradores privados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.003 — Crear cola privada de procesamiento

**Estado:** Completado. **Tarea superior:** TOU06.

Separar trabajos de datos expuestos al visitante.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.004 — Crear leases transaccionales de ejecución

**Estado:** Completado. **Tarea superior:** TOU06.

Limitar reclamación concurrente de trabajos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.005 — Imponer dos trabajos activos globales

**Estado:** Completado. **Tarea superior:** TOU06.

Controlar cupo desde PostgreSQL.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.006 — Proteger escritura de resultados

**Estado:** Completado. **Tarea superior:** TOU06.

Reservar confirmaciones al backend autorizado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.007 — Crear recibo durable del lease

**Estado:** Completado. **Tarea superior:** TOU06.

Resolver respuesta perdida tras completar trabajo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.008 — Rechazar ejecución antigua o duplicada

**Estado:** Completado. **Tarea superior:** TOU06.

No sustituir una recaptura posterior.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.009 — Cancelar trabajo sin sobrescribir resultado

**Estado:** Completado. **Tarea superior:** TOU06.

Aplicar estado y guardas de ejecución.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.010 — Crear acreditación administrativa del espacio

**Estado:** Completado. **Tarea superior:** TOU06.

Autorizar responsabilidad mediante revisión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.011 — Separar revisión espacial y permiso de autor

**Estado:** Completado. **Tarea superior:** TOU06.

No conceder derechos por un vínculo de contenido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.012 — Excluir evidencia de local al revisor de vínculo

**Estado:** Completado. **Tarea superior:** TOU06.

Mantener privada documentación espacial.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.013 — Publicar versión activa atómicamente

**Estado:** Completado. **Tarea superior:** TOU06.

Conservar borrador más nuevo y snapshot aprobado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.014 — Filtrar recursos públicos por vigencia

**Estado:** Completado. **Tarea superior:** TOU06.

Servir únicamente versión disponible al visitante.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.015 — Revalidar contenido ajeno al leer

**Estado:** Completado. **Tarea superior:** TOU06.

Omitir vínculos retirados o sin permiso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.016 — Revocar responsabilidad espacial

**Estado:** Completado. **Tarea superior:** TOU06.

Impedir reanudar sin otro permiso válido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.017 — Cancelar trabajos al eliminar cuenta

**Estado:** Completado. **Tarea superior:** TOU06.

Bloquear nuevas escrituras antes de limpiar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.018 — Eliminar recursos anidados de tours

**Estado:** Completado. **Tarea superior:** TOU06.

Limpiar ambos buckets recursivamente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.019 — Renovar lease de limpieza

**Estado:** Completado. **Tarea superior:** TOU06.

Evitar que GC borre recursos con token vencido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

### TOU06.020 — Desplegar correctivo de cleanup lease

**Estado:** Completado. **Tarea superior:** TOU06.

Piloto acredita repair-cleanup-lease aplicado y comprobado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU05.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S124, S125, S126, S127.

## TOU07 — Procesador Hugin y Enblend

### TOU07.001 — Crear contenedor de procesamiento

**Estado:** Completado. **Tarea superior:** TOU07.

Empaquetar herramientas Hugin/Enblend y worker Python.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.002 — Descargar originales de captura autorizada

**Estado:** Completado. **Tarea superior:** TOU07.

Usar manifiesto y recursos privados del backend.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.003 — Generar archivo PTO

**Estado:** Completado. **Tarea superior:** TOU07.

Representar fotografías y orientación para cosido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.004 — Detectar puntos con cpfind

**Estado:** Completado. **Tarea superior:** TOU07.

Encontrar coincidencias reales entre fotografías.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.005 — Limpiar coincidencias con cpclean

**Estado:** Completado. **Tarea superior:** TOU07.

Eliminar puntos inconsistentes antes de optimizar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.006 — Comprobar grafo conectado

**Estado:** Completado. **Tarea superior:** TOU07.

Rechazar conjunto sin relaciones suficientes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.007 — Optimizar geometría con autooptimiser

**Estado:** Completado. **Tarea superior:** TOU07.

Ajustar alineación de las tomas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.008 — Definir canvas 360°×180° con pano_modify

**Estado:** Completado. **Tarea superior:** TOU07.

Preparar proyección equirectangular completa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.009 — Remapear fotografías con nona

**Estado:** Completado. **Tarea superior:** TOU07.

Crear contribuciones por imagen al panorama.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.010 — Comprobar cobertura alpha

**Estado:** Completado. **Tarea superior:** TOU07.

Rechazar huecos sin inventar techo o piso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.011 — Mezclar remapeos con Enblend

**Estado:** Completado. **Tarea superior:** TOU07.

Unir exposición y costuras del conjunto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.012 — Generar panorama 4096×2048

**Estado:** Completado. **Tarea superior:** TOU07.

Guardar JPEG final con GPano.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.013 — Generar preview 2048×1024

**Estado:** Completado. **Tarea superior:** TOU07.

Preparar recurso de visualización de menor tamaño.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.014 — Generar miniatura 512×256

**Estado:** Completado. **Tarea superior:** TOU07.

Preparar descubrimiento y tarjetas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.015 — Clasificar errores transitorios

**Estado:** Completado. **Tarea superior:** TOU07.

Reintentar solo fallos recuperables y con límite.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.016 — Confirmar resultado con recibo persistido

**Estado:** Completado. **Tarea superior:** TOU07.

No interpretar exit0 como ready sin aceptación del servidor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.017 — Corregir SIGSEGV de Enblend 4.2

**Estado:** Completado. **Tarea superior:** TOU07.

Usar --no-optimize conservando mezcla y cobertura estricta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.018 — Corregir respuesta PostgREST 204

**Estado:** Completado. **Tarea superior:** TOU07.

No intentar decodificar JSON inexistente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

### TOU07.019 — Corregir descargas parciales interrumpidas

**Estado:** Completado. **Tarea superior:** TOU07.

Cerrar respuesta y clasificar fallo transitorio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S010, S128, S129, S127.

## TOU08 — Visor 360° y navegación del recorrido

### TOU08.001 — Mostrar presentación pública del recorrido

**Estado:** Completado. **Tarea superior:** TOU08.

Cargar versión vigente desde perfil o enlace.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.002 — Renderizar panorama por arrastre

**Estado:** Completado. **Tarea superior:** TOU08.

Permitir mirar alrededor sin solicitar cámara.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.003 — Normalizar costura angular y polos

**Estado:** Completado. **Tarea superior:** TOU08.

Evitar bordes de fotografía plana en la esfera.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.004 — Mostrar conexiones sobre panorama

**Estado:** Completado. **Tarea superior:** TOU08.

Permitir cambiar de posición con indicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.005 — Mostrar lista alternativa de posiciones

**Estado:** Completado. **Tarea superior:** TOU08.

Ofrecer navegación sin gesto espacial.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.006 — Mostrar puntos angulares en panorama

**Estado:** Completado. **Tarea superior:** TOU08.

Abrir explicación de la parada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.007 — Mostrar puntos solo en lista

**Estado:** Completado. **Tarea superior:** TOU08.

Mantener contenido sin anclaje en esfera.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.008 — Abrir detalle del punto

**Estado:** Completado. **Tarea superior:** TOU08.

Conservar texto independiente y vínculo disponible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.009 — Abrir detalle existente del contenido

**Estado:** Completado. **Tarea superior:** TOU08.

Reutilizar rutas de publicaciones y fichas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.010 — Volver al panorama de origen

**Estado:** Completado. **Tarea superior:** TOU08.

Conservar posición y contexto tras consultar detalle.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.011 — Informar contenido retirado o vencido

**Estado:** Completado. **Tarea superior:** TOU08.

No dejar enlaces activos hacia recursos inaccesibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.012 — Dar regreso explícito en enlaces directos

**Estado:** Completado. **Tarea superior:** TOU08.

Mantener salida de visita y editor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

### TOU08.013 — Revisar visor a 320 px

**Estado:** Completado. **Tarea superior:** TOU08.

Reporte acredita interfaz real y navegación A→B→A.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU07.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S130, S131, S132.

## AR01 — Implementación AR nativa y recuperación — WIP

Código presente y compilaciones reportadas. Estado WIP por validación física/aceptación pendiente; no se afirma que falta escribir toda la implementación.

### AR01.001 — Consultar soporte AR del dispositivo

**Estado:** WIP. **Tarea superior:** AR01.

Código incorpora supported; falta aceptación en hardware real.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.002 — Preparar referencia JPEG de activador

**Estado:** WIP. **Tarea superior:** AR01.

Código usa archivo local identificable; falta reconocimiento físico.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.003 — Validar ancho físico positivo

**Estado:** WIP. **Tarea superior:** AR01.

La referencia requiere widthMeters; falta comprobar medidas en local.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.004 — Invalidar prueba al cambiar referencia

**Estado:** WIP. **Tarea superior:** AR01.

Cambiar ancho o versión exige otra prueba física.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.005 — Crear PlatformView Android ARCore

**Estado:** WIP. **Tarea superior:** AR01.

Vista nativa implementada; falta validar en Android compatible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.006 — Crear AugmentedImageDatabase

**Estado:** WIP. **Tarea superior:** AR01.

Referencia incorporada a base de reconocimiento de ARCore.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.007 — Renderizar cámara Android con textura OES

**Estado:** WIP. **Tarea superior:** AR01.

Render implementado; falta validar imagen y lifecycle físicos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.008 — Crear anchor de imagen reconocida

**Estado:** WIP. **Tarea superior:** AR01.

Señal depende de anclaje real de ARCore.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.009 — Confirmar FULL_TRACKING y cámara TRACKING

**Estado:** WIP. **Tarea superior:** AR01.

No tratar última pose conocida como reconocimiento vigente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.010 — Crear configuración ARKit de imágenes

**Estado:** WIP. **Tarea superior:** AR01.

Implementación usa ARReferenceImage de ancho conocido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.011 — Crear vista ARSCNView iOS

**Estado:** WIP. **Tarea superior:** AR01.

Cámara y escena preparadas; falta prueba en iPhone firmado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.012 — Vincular señal con ARImageAnchor

**Estado:** WIP. **Tarea superior:** AR01.

Confirmar isTracked y estado de cámara en hardware.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.013 — Emitir eventos tracking, lost y error

**Estado:** WIP. **Tarea superior:** AR01.

Canal nativo definido para estado de referencia.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.014 — Retirar señal al perder tracking

**Estado:** WIP. **Tarea superior:** AR01.

Ficha conserva lectura mientras desaparece anclaje.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.015 — Mantener una sola vista AR activa

**Estado:** WIP. **Tarea superior:** AR01.

Evitar sesiones simultáneas de cámara.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.016 — Cancelar descargas tardías de referencias

**Estado:** WIP. **Tarea superior:** AR01.

No reactivar una sesión abandonada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.017 — Detener AR al abrir detalle o cambiar parada

**Estado:** WIP. **Tarea superior:** AR01.

Conservar lectura sin cámara residual.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.018 — Detener AR al ir a segundo plano

**Estado:** WIP. **Tarea superior:** AR01.

Liberar sesión y recursos al pausar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.019 — Liberar EGL, anchors y Session Android

**Estado:** WIP. **Tarea superior:** AR01.

Implementación de cierre pendiente de aceptación física.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.020 — Pausar escena y delegado ARKit

**Estado:** WIP. **Tarea superior:** AR01.

Implementación de liberación pendiente de aceptación física.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.021 — Ofrecer lista sin cámara ante fallo

**Estado:** WIP. **Tarea superior:** AR01.

Mantener alternativa ante permiso, soporte o referencia ilegible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

### AR01.022 — Probar recuperación automática de AR

**Estado:** WIP. **Tarea superior:** AR01.

Pruebas de código disponibles; no acreditan reconocimiento físico.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 21/10/2026 (OCT-3) | 3 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU04, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S009, S008, S133, S134.

**Para cerrar o completar el registro:** Validación física/aceptación del módulo pendiente.

## TOU09 — Progreso e integración de recorridos

### TOU09.001 — Guardar progreso privado por cuenta y versión

**Estado:** Completado. **Tarea superior:** TOU09.

Persistir posición y estado de paradas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.002 — Distinguir visitadas y saltadas

**Estado:** Completado. **Tarea superior:** TOU09.

No considerar salto como visita.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.003 — Crear outbox local de progreso

**Estado:** Completado. **Tarea superior:** TOU09.

Guardar antes de enviar RPC.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.004 — Sincronizar progreso pendiente al volver

**Estado:** Completado. **Tarea superior:** TOU09.

Recuperar cambios tras error o falta de red.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.005 — Informar nueva versión del recorrido

**Estado:** Completado. **Tarea superior:** TOU09.

Pedir reinicio sin copiar IDs antiguos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.006 — Integrar entrada desde Crear

**Estado:** Completado. **Tarea superior:** TOU09.

Ofrecer administración a perfiles profesionales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.007 — Integrar recorridos en herramientas propias

**Estado:** Completado. **Tarea superior:** TOU09.

Abrir solicitudes y contenido del responsable.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.008 — Integrar tarjeta en perfil público

**Estado:** Completado. **Tarea superior:** TOU09.

Mostrar Explorar el local 360° cuando está disponible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.009 — Integrar revisión en moderación

**Estado:** Completado. **Tarea superior:** TOU09.

Agregar Espacios y recorridos con controles privados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.010 — Agregar capa de recorridos al mapa

**Estado:** Completado. **Tarea superior:** TOU09.

Mantener filtros y consultas de misiones separados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.011 — Crear descubrimiento de recorridos vigentes

**Estado:** Completado. **Tarea superior:** TOU09.

Consultar experiencias y ubicación aproximada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.012 — Crear enlaces /tours/:id y punto

**Estado:** Completado. **Tarea superior:** TOU09.

Conservar destino tras autenticación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

### TOU09.013 — Crear enlace de entrada AR

**Estado:** Completado. **Tarea superior:** TOU09.

Resolver /tours/:id/ar?point sin prometer posicionamiento por QR.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU08, SOC04.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S008, S135, S136, S113.

## PIL01 — Piloto Docker local con Supabase real

### PIL01.001 — Preparar Python y configuración local del procesador

**Estado:** Completado. **Tarea superior:** PIL01.

Separar credenciales de servicio de la configuración Flutter.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.002 — Construir imagen linux/amd64 validada

**Estado:** Completado. **Tarea superior:** PIL01.

Registrar digest y herramientas en pilot-image.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.003 — Crear fixtures geométricos de 26 fotografías

**Estado:** Completado. **Tarea superior:** PIL01.

Probar pipeline sin atribuirles captura óptica real.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.004 — Ejecutar herramientas Hugin realmente

**Estado:** Completado. **Tarea superior:** PIL01.

Piloto acredita cpfind, cpclean, autooptimiser, pano_modify y nona.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.005 — Ejecutar Enblend sobre fixture completo

**Estado:** Completado. **Tarea superior:** PIL01.

Generar esfera válida sin huecos sintéticos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.006 — Confirmar ready en Supabase

**Estado:** Completado. **Tarea superior:** PIL01.

Comprobar recibo después de procesamiento local.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.007 — Medir runtime de worker y ejecución local

**Estado:** Completado. **Tarea superior:** PIL01.

Reporte registra 162.279 s y 166.751 s; no son tiempo laboral de tarea.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.008 — Rechazar fixture sin techo

**Estado:** Completado. **Tarea superior:** PIL01.

Comprobar incomplete_sphere_coverage.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.009 — Rechazar fixture sin coincidencias

**Estado:** Completado. **Tarea superior:** PIL01.

Comprobar disconnected_control_points.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.010 — Rechazar JPEG 2:1 sin GPano

**Estado:** Completado. **Tarea superior:** PIL01.

Comprobar gpano_full_sphere_required contra backend real.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.011 — Aplicar migración 015 exclusivamente

**Estado:** Completado. **Tarea superior:** PIL01.

Verificar historial 001–015 y buckets privados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.012 — Desplegar tour-dispatch autenticado

**Estado:** Completado. **Tarea superior:** PIL01.

Validar 401 sin secreto y 503 mientras falta Google.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.013 — Volver a desplegar limpieza anidada de cuenta

**Estado:** Completado. **Tarea superior:** PIL01.

Recuperar fuente remota y verificar versión correcta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.014 — Probar dos leases y contenedores concurrentes

**Estado:** Completado. **Tarea superior:** PIL01.

Comprobar límite global real del backend.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.015 — Probar cancelación y recaptura durante trabajo

**Estado:** Completado. **Tarea superior:** PIL01.

No sustituir captura posterior por ejecución antigua.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.016 — Probar respuesta duplicada o perdida

**Estado:** Completado. **Tarea superior:** PIL01.

Reconciliar estado con recibo persistido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.017 — Probar borrado durante escritura

**Estado:** Completado. **Tarea superior:** PIL01.

Bloquear cuenta y limpiar recursos anidados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.018 — Probar publicación y recursos de visitante

**Estado:** Completado. **Tarea superior:** PIL01.

Verificar HTTP autorizado y disponibilidad antes de limpiar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.019 — Probar progreso privado contra Supabase

**Estado:** Completado. **Tarea superior:** PIL01.

Separar lectura y escritura entre cuentas temporales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.020 — Probar renovación de cleanup lease

**Estado:** Completado. **Tarea superior:** PIL01.

Reporte acredita ocho comprobaciones reales del correctivo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.021 — Crear runner --once y --watch

**Estado:** Completado. **Tarea superior:** PIL01.

Controlar contenedores, plazo y confirmación backend.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.022 — Rechazar upload futuro de imagen distinta

**Estado:** Completado. **Tarea superior:** PIL01.

Verificar ID de la imagen validada antes de llamar a Google.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.023 — Limpiar recursos propios del piloto

**Estado:** Completado. **Tarea superior:** PIL01.

Confirmar cero cuentas, trabajos, recorridos y objetos temporales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.024 — Limpiar 175 objetos de checkpoints antiguos

**Estado:** Completado. **Tarea superior:** PIL01.

Restringir limpieza a recursos de pruebas identificados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

### PIL01.025 — Mostrar panorama final en widgets reales

**Estado:** Completado. **Tarea superior:** PIL01.

Revisar navegación y detalle con copia offline del fixture.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU05, TOU06, TOU07, TOU08.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S137, S138, S139.

## TOU10 — Verificación automática de recorridos

### TOU10.001 — Probar recuperación offline del editor

**Estado:** Completado. **Tarea superior:** TOU10.

Cubrir conservación local y salida tras escritura.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.002 — Probar cambios de lente al retomar

**Estado:** Completado. **Tarea superior:** TOU10.

Mantener coherencia de la captura local.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.003 — Probar checkpoint y recuperación TUS

**Estado:** Completado. **Tarea superior:** TOU10.

Cubrir offset y errores de sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.004 — Probar progreso durable y sincronización

**Estado:** Completado. **Tarea superior:** TOU10.

No perder paradas tras fallo remoto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.005 — Probar descargas AR invalidadas

**Estado:** Completado. **Tarea superior:** TOU10.

Impedir reactivación después de abandonar sesión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.006 — Validar contratos SQL de recorridos

**Estado:** Completado. **Tarea superior:** TOU10.

Piloto acredita 90 contratos y 17 flags del catálogo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.007 — Validar dispatcher y limpieza recursiva

**Estado:** Completado. **Tarea superior:** TOU10.

Piloto acredita seis pruebas dispatcher y tres de limpieza.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.008 — Validar worker y runner Python

**Estado:** Completado. **Tarea superior:** TOU10.

Piloto acredita 25 pruebas Python.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.009 — Registrar suite Flutter completa

**Estado:** Completado. **Tarea superior:** TOU10.

Piloto acredita 459 tests y análisis sin incidencias.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.010 — Validar backend real del piloto

**Estado:** Completado. **Tarea superior:** TOU10.

Reporte acredita 57 comprobaciones Supabase más ocho de lease.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.011 — Compilar APK, Web e iOS sin firma

**Estado:** Completado. **Tarea superior:** TOU10.

Piloto acredita compilaciones locales del proyecto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

### TOU10.012 — Conservar límites de validación automática

**Estado:** Completado. **Tarea superior:** TOU10.

No marcar referencia AR como probada físicamente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/10/2026 (OCT-1) | 07/10/2026 (OCT-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU02, TOU03, TOU05, TOU06, TOU07, TOU08, TOU09.

**Fecha de evidencia:** 06/10/2026. **Fuentes:** S127, S140, S141, S142.

## FIS01 — Captura óptica real y calibración de panoramas

Plan propuesto después del corte 06/10/2026; ninguna ejecución futura se considera realizada. Responsables y tiempos reales pendientes de captura.

### FIS01.001 — Preparar local autorizado para prueba

**Estado:** Pendiente. **Tarea superior:** FIS01.

Seleccionar posiciones reales con permiso del responsable.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.002 — Preparar Android de captura

**Estado:** Pendiente. **Tarea superior:** FIS01.

Conectar dispositivo y verificar cámara posterior principal.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.003 — Preparar iPhone de captura

**Estado:** Bloqueado. **Tarea superior:** FIS01.

Configurar firma y equipo Apple antes de instalar.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Resolver credenciales, permisos o firma indicados en el resultado.

### FIS01.004 — Validar FOV frente al JPEG real

**Estado:** Pendiente. **Tarea superior:** FIS01.

Comprobar crop y posibles correcciones del ISP.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.005 — Validar signo yaw y pitch en teléfono

**Estado:** Pendiente. **Tarea superior:** FIS01.

Comparar horizonte y giros con orientación esperada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.006 — Validar cenit y nadir

**Estado:** Pendiente. **Tarea superior:** FIS01.

Comprobar lectura de sensores apuntando a techo y piso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.007 — Validar orientación al reabrir captura

**Estado:** Pendiente. **Tarea superior:** FIS01.

Recuperar sesión tras detener cámara.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.008 — Capturar esfera interior con techo y piso

**Estado:** Pendiente. **Tarea superior:** FIS01.

Mantener posición de lente y solapamiento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.009 — Capturar escena con ventanas

**Estado:** Pendiente. **Tarea superior:** FIS01.

Evaluar contraste y reflejos del panorama.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.010 — Capturar escena de poca textura

**Estado:** Pendiente. **Tarea superior:** FIS01.

Comprobar suficiencia de coincidencias entre tomas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.011 — Capturar objetos próximos

**Estado:** Pendiente. **Tarea superior:** FIS01.

Evaluar paralaje y errores de alineación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.012 — Capturar patrones repetidos

**Estado:** Pendiente. **Tarea superior:** FIS01.

Detectar coincidencias geométricas incorrectas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.013 — Interrumpir captura y retomar

**Estado:** Pendiente. **Tarea superior:** FIS01.

Comprobar persistencia y realineación en el dispositivo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.014 — Cambiar lente durante recuperación

**Estado:** Pendiente. **Tarea superior:** FIS01.

Verificar rechazo o nueva captura sin pérdida de versión publicada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.015 — Subir fotografías reales y procesarlas

**Estado:** Pendiente. **Tarea superior:** FIS01.

Ejecutar cadena completa contra Supabase y Docker.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.016 — Revisar cierre y costura ±180°

**Estado:** Pendiente. **Tarea superior:** FIS01.

Comprobar continuidad del resultado físico.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.017 — Revisar techo, piso y huecos

**Estado:** Pendiente. **Tarea superior:** FIS01.

Rechazar esferas con cobertura incompleta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.018 — Medir tiempo y memoria con fotos reales

**Estado:** Pendiente. **Tarea superior:** FIS01.

Registrar consumo operativo separado del tiempo de trabajo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS01.019 — Registrar recapturas necesarias

**Estado:** Pendiente. **Tarea superior:** FIS01.

Documentar defectos observados sin inventar resultados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 14/10/2026 (OCT-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** TOU03, TOU04, PIL01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

## FIS02 — Aceptación física de reconocimiento AR

Plan propuesto después del corte 06/10/2026; ninguna ejecución futura se considera realizada. Responsables y tiempos reales pendientes de captura.

### FIS02.001 — Medir activador físico del local

**Estado:** Pendiente. **Tarea superior:** FIS02.

Registrar ancho real utilizado por la referencia AR.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.002 — Probar reconocimiento ARCore en Android

**Estado:** Pendiente. **Tarea superior:** FIS02.

Confirmar identificación sostenida de imagen física.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.003 — Probar reconocimiento ARKit en iPhone

**Estado:** Bloqueado. **Tarea superior:** FIS02.

Depende de equipo Apple, firma y dispositivo compatible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Resolver credenciales, permisos o firma indicados en el resultado.

### FIS02.004 — Probar rechazo del permiso de cámara

**Estado:** Pendiente. **Tarea superior:** FIS02.

Mantener lista y detalle operables.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.005 — Probar dispositivo sin soporte AR

**Estado:** Pendiente. **Tarea superior:** FIS02.

Mostrar alternativa sin iniciar sesión incompatible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.006 — Probar referencia ilegible

**Estado:** Pendiente. **Tarea superior:** FIS02.

Explicar fallo sin fabricar reconocimiento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.007 — Probar activador con reflejos

**Estado:** Pendiente. **Tarea superior:** FIS02.

Observar estabilidad en condiciones reales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.008 — Retirar activador del encuadre

**Estado:** Pendiente. **Tarea superior:** FIS02.

Verificar pérdida de tracking y retiro de señal.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.009 — Recuperar tracking al reencuadrar

**Estado:** Pendiente. **Tarea superior:** FIS02.

Mantener ficha y recuperar señal solo con reconocimiento.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.010 — Enviar aplicación a segundo plano

**Estado:** Pendiente. **Tarea superior:** FIS02.

Comprobar liberación física de cámara.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.011 — Apagar y reanudar pantalla

**Estado:** Pendiente. **Tarea superior:** FIS02.

Validar continuidad de sesión y recursos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.012 — Abrir contenido y regresar durante AR

**Estado:** Pendiente. **Tarea superior:** FIS02.

No conservar cámara activa fuera de la vista.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.013 — Cambiar de parada durante descarga

**Estado:** Pendiente. **Tarea superior:** FIS02.

No reactivar referencia anterior por respuesta tardía.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.014 — Cambiar cuenta durante AR

**Estado:** Pendiente. **Tarea superior:** FIS02.

Detener cámara, sensores y operaciones de la sesión anterior.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.015 — Cambiar mobiliario del espacio

**Estado:** Pendiente. **Tarea superior:** FIS02.

Identificar referencias y conexiones que requieren revisión.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.016 — Comprobar ancho y colocación de señal

**Estado:** Pendiente. **Tarea superior:** FIS02.

Validar escala y anclaje sobre referencia reconocida.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.017 — Guardar prueba física de versión de activador

**Estado:** Pendiente. **Tarea superior:** FIS02.

Acreditar tested_version solo tras prueba real satisfactoria.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### FIS02.018 — Cerrar aceptación del módulo AR

**Estado:** Pendiente. **Tarea superior:** FIS02.

Cambiar WIP únicamente cuando criterios físicos estén cubiertos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/10/2026 (OCT-2) | 21/10/2026 (OCT-3) | 2 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** AR01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S009, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

## COR01 — Correcciones posteriores a pruebas físicas

Plan propuesto después del corte 06/10/2026; ninguna ejecución futura se considera realizada. Responsables y tiempos reales pendientes de captura. Correcciones condicionales: no se afirma que esos defectos existan hoy.

### COR01.001 — Clasificar fallos de calibración observados

**Estado:** Pendiente. **Tarea superior:** COR01.

Crear incidencias solo a partir de resultados de la prueba.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/10/2026 (OCT-3) | 21/10/2026 (OCT-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### COR01.002 — Corregir FOV o crop si se detecta error

**Estado:** Pendiente. **Tarea superior:** COR01.

Ajustar implementación únicamente con evidencia óptica.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/10/2026 (OCT-3) | 21/10/2026 (OCT-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### COR01.003 — Corregir recuperación de captura si falla

**Estado:** Pendiente. **Tarea superior:** COR01.

Conservar tomas y contexto de cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/10/2026 (OCT-3) | 21/10/2026 (OCT-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### COR01.004 — Corregir costura si la prueba lo exige

**Estado:** Pendiente. **Tarea superior:** COR01.

Ajustar pipeline sin rellenar regiones ausentes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/10/2026 (OCT-3) | 21/10/2026 (OCT-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### COR01.005 — Corregir reconocimiento AR si falla

**Estado:** Pendiente. **Tarea superior:** COR01.

Distinguir calidad de activador, soporte y código.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/10/2026 (OCT-3) | 21/10/2026 (OCT-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### COR01.006 — Corregir lifecycle si quedan recursos activos

**Estado:** Pendiente. **Tarea superior:** COR01.

Resolver cierre de cámara, sensores y escenas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/10/2026 (OCT-3) | 21/10/2026 (OCT-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### COR01.007 — Añadir regresión para cada fallo confirmado

**Estado:** Pendiente. **Tarea superior:** COR01.

Probar comportamiento afectado y límites pertinentes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/10/2026 (OCT-3) | 21/10/2026 (OCT-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### COR01.008 — Repetir escenarios físicos afectados

**Estado:** Pendiente. **Tarea superior:** COR01.

Confirmar solución en el dispositivo que falló.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/10/2026 (OCT-3) | 21/10/2026 (OCT-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### COR01.009 — Actualizar límites conocidos del módulo

**Estado:** Pendiente. **Tarea superior:** COR01.

Conservar pendientes que aún no cumplen aceptación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/10/2026 (OCT-3) | 21/10/2026 (OCT-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S008.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

## CLO01 — Traspaso del procesador a Cloud Run

Plan propuesto después del corte 06/10/2026; ninguna ejecución futura se considera realizada. Responsables y tiempos reales pendientes de captura. El despliegue está preparado por scripts, pero Cloud Run no se considera desplegado.

### CLO01.001 — Resolver verificación de facturación Google

**Estado:** Bloqueado. **Tarea superior:** CLO01.

Requisito externo pendiente para Cloud Run.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Resolver credenciales, permisos o firma indicados en el resultado.

### CLO01.002 — Instalar y autenticar gcloud

**Estado:** Bloqueado. **Tarea superior:** CLO01.

Requiere acceso autorizado al proyecto y cuenta.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Resolver credenciales, permisos o firma indicados en el resultado.

### CLO01.003 — Verificar permisos del proyecto Google

**Estado:** Bloqueado. **Tarea superior:** CLO01.

Comprobar IAM antes de ejecutar scripts de despliegue.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Resolver credenciales, permisos o firma indicados en el resultado.

### CLO01.004 — Definir presupuesto de procesamiento

**Estado:** Pendiente. **Tarea superior:** CLO01.

Registrar coste permitido antes de operación continua.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.005 — Crear Artifact Registry autorizado

**Estado:** Pendiente. **Tarea superior:** CLO01.

Preparar destino de la imagen ya validada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.006 — Subir la misma imagen validada

**Estado:** Pendiente. **Tarea superior:** CLO01.

Comprobar digest antes de publicar contenedor.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.007 — Crear cuentas de servicio del procesador

**Estado:** Pendiente. **Tarea superior:** CLO01.

Separar ejecución de jobs y despacho.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.008 — Configurar secretos de servidor

**Estado:** Pendiente. **Tarea superior:** CLO01.

Guardar credenciales en Secret Manager y backend.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.009 — Desplegar Cloud Run Job

**Estado:** Pendiente. **Tarea superior:** CLO01.

Usar 4 vCPU, 8 GiB y plazo 900 s del plan existente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.010 — Autorizar dispatcher para ejecutar jobs

**Estado:** Pendiente. **Tarea superior:** CLO01.

Configurar OAuth e IAM de ejecución con overrides.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.011 — Probar trabajo remoto con recibo

**Estado:** Pendiente. **Tarea superior:** CLO01.

Exigir resultado confirmado en Supabase.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.012 — Probar concurrencia de dos jobs

**Estado:** Pendiente. **Tarea superior:** CLO01.

Verificar límite global y recursos reales.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.013 — Probar cancelación y respuesta perdida remotas

**Estado:** Pendiente. **Tarea superior:** CLO01.

No aceptar resultado antiguo ni duplicado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.014 — Configurar canales de alerta

**Estado:** Pendiente. **Tarea superior:** CLO01.

Verificar entrega real de una alerta operativa.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.015 — Detener runner local antes de traspaso

**Estado:** Pendiente. **Tarea superior:** CLO01.

Evitar operación paralela no prevista del procesador.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.016 — Activar Vault y cron de tours

**Estado:** Pendiente. **Tarea superior:** CLO01.

Habilitar solo después del job remoto satisfactorio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.017 — Comprobar primera ejecución programada

**Estado:** Pendiente. **Tarea superior:** CLO01.

Registrar estado, cola y logs del scheduler.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### CLO01.018 — Medir coste del procesamiento remoto

**Estado:** Pendiente. **Tarea superior:** CLO01.

Comparar consumo y presupuesto del piloto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 22/10/2026 (OCT-4) | 31/10/2026 (OCT-4) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL01, FIS01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S127, S010, S143, S144.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

## QA02 — Pruebas reales pendientes de acceso, medios y ubicación

Plan propuesto después del corte 06/10/2026; ninguna ejecución futura se considera realizada. Responsables y tiempos reales pendientes de captura.

### QA02.001 — Registrar cuenta con un correo nuevo propio

**Estado:** Pendiente. **Tarea superior:** QA02.

Comprobar entrega de OTP además de respuesta aceptada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA02.002 — Completar confirmación con OTP recibido

**Estado:** Pendiente. **Tarea superior:** QA02.

Verificar acceso desde el código real.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA02.003 — Solicitar y recibir recuperación real

**Estado:** Pendiente. **Tarea superior:** QA02.

Probar entrega de código nuevo por SMTP.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA02.004 — Cambiar contraseña con código recuperado

**Estado:** Pendiente. **Tarea superior:** QA02.

Comprobar login posterior con nueva contraseña.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA02.005 — Probar código incorrecto y reutilizado

**Estado:** Pendiente. **Tarea superior:** QA02.

No conceder acceso fuera del flujo válido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA02.006 — Probar selección nativa de avatar y portada

**Estado:** Pendiente. **Tarea superior:** QA02.

Comprobar galería física, vista previa y persistencia.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA02.007 — Probar selección nativa de foto de post

**Estado:** Pendiente. **Tarea superior:** QA02.

Validar permiso y upload desde teléfono.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA02.008 — Probar GPS y permiso en mapa físico

**Estado:** Pendiente. **Tarea superior:** QA02.

Comprobar exactitud, rechazo y servicios desactivados.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA02.009 — Probar teclado físico en registro y compositor

**Estado:** Pendiente. **Tarea superior:** QA02.

Verificar controles visibles con teclado real.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA02.010 — Probar lector de pantalla en destinos principales

**Estado:** Pendiente. **Tarea superior:** QA02.

Comprobar etiquetas y orden de foco del dispositivo.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** ACC04, MAP01, PUS04.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S054, S026, S007, S050.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

## QA03 — Matriz física adicional de push y regresión integrada

Plan propuesto después del corte 06/10/2026; ninguna ejecución futura se considera realizada. Responsables y tiempos reales pendientes de captura.

### QA03.001 — Probar permiso push denegado físicamente

**Estado:** Pendiente. **Tarea superior:** QA03.

Mantener bandeja y ajustes disponibles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.002 — Probar recuperación de permiso desde ajustes

**Estado:** Pendiente. **Tarea superior:** QA03.

Registrar dispositivo solo cuando permiso sea válido.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.003 — Probar cambio de cuenta con push físico

**Estado:** Pendiente. **Tarea superior:** QA03.

No abrir contenido ni registrar token en cuenta anterior.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.004 — Probar renovación real del token

**Estado:** Pendiente. **Tarea superior:** QA03.

Comprobar versión nueva sin desactivar registro vigente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.005 — Probar logout sin conexión en teléfono

**Estado:** Pendiente. **Tarea superior:** QA03.

Verificar recuperación y separación de identidad.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.006 — Probar contenido eliminado desde aviso

**Estado:** Pendiente. **Tarea superior:** QA03.

Abrir estado explicativo y conservar navegación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.007 — Probar preferencias de mensajes ocasionales

**Estado:** Pendiente. **Tarea superior:** QA03.

Comprobar horario y cancelación con condiciones controladas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.008 — Ejecutar regresión automática integrada

**Estado:** Pendiente. **Tarea superior:** QA03.

Validar módulos afectados por correcciones nuevas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.009 — Verificar contratos de backend al cierre

**Estado:** Pendiente. **Tarea superior:** QA03.

Comparar migraciones, permisos y funciones desplegadas.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.010 — Probar rutas directas del build final

**Estado:** Pendiente. **Tarea superior:** QA03.

Cubrir posts, misiones, fichas y recorridos tras acceso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.011 — Probar aislamiento entre dos cuentas reales

**Estado:** Pendiente. **Tarea superior:** QA03.

Cubrir preferencias, muestras, borradores y progreso.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### QA03.012 — Revisar interfaz móvil y escritorio final

**Estado:** Pendiente. **Tarea superior:** QA03.

Comprobar texto ampliado, teclado y paneles.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 01/11/2026 (NOV-1) | 07/11/2026 (NOV-1) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PUS04, COR01, CLO01.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S101, S127, S069.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

## PIL02 — Piloto de aceptación en un local real

Plan propuesto después del corte 06/10/2026; ninguna ejecución futura se considera realizada. Responsables y tiempos reales pendientes de captura.

### PIL02.001 — Acreditar responsabilidad del local piloto

**Estado:** Pendiente. **Tarea superior:** PIL02.

Registrar permiso administrativo real del espacio.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.002 — Capturar varias posiciones del local

**Estado:** Pendiente. **Tarea superior:** PIL02.

Preparar contenido real autorizado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.003 — Procesar y revisar panoramas del piloto

**Estado:** Pendiente. **Tarea superior:** PIL02.

Aceptar cobertura y calidad óptica del conjunto.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.004 — Configurar puntos y conexiones reales

**Estado:** Pendiente. **Tarea superior:** PIL02.

Comprobar nombres e indicaciones entre posiciones.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.005 — Solicitar permisos de contenido vinculado

**Estado:** Pendiente. **Tarea superior:** PIL02.

Excluir recursos no autorizados del envío.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.006 — Preparar y validar activadores reales

**Estado:** Pendiente. **Tarea superior:** PIL02.

Asociar prueba física a referencia y ancho exactos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.007 — Enviar snapshot del recorrido piloto

**Estado:** Pendiente. **Tarea superior:** PIL02.

Mantener versión de revisión congelada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.008 — Aprobar y publicar recorrido piloto

**Estado:** Pendiente. **Tarea superior:** PIL02.

Cambiar versión activa con permisos válidos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.009 — Explorar recorrido desde otro usuario

**Estado:** Pendiente. **Tarea superior:** PIL02.

Comprobar lectura pública autorizada y contenido vigente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.010 — Recorrer paradas físicamente con AR

**Estado:** Pendiente. **Tarea superior:** PIL02.

Validar reconocimiento y alternativa sin cámara.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.011 — Interrumpir subida y visita durante aceptación

**Estado:** Pendiente. **Tarea superior:** PIL02.

Confirmar recuperación y progreso real.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.012 — Registrar fallos y resultados del piloto

**Estado:** Pendiente. **Tarea superior:** PIL02.

Separar evidencia observada de criterios aún pendientes.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.013 — Corregir incidencias del piloto si aparecen

**Estado:** Pendiente. **Tarea superior:** PIL02.

No ampliar alcance sin necesidad demostrada.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### PIL02.014 — Repetir criterios afectados

**Estado:** Pendiente. **Tarea superior:** PIL02.

Aceptar únicamente funciones verificadas tras corrección.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 08/11/2026 (NOV-2) | 14/11/2026 (NOV-2) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** FIS01, FIS02, COR01, CLO01, QA02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S008, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

## ENT01 — Estabilización y entrega técnica de la aplicación

Plan propuesto después del corte 06/10/2026; ninguna ejecución futura se considera realizada. Responsables y tiempos reales pendientes de captura.

### ENT01.001 — Revisar pendientes antes de cierre

**Estado:** Pendiente. **Tarea superior:** ENT01.

No declarar terminado AR si falta aceptación física.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.002 — Ejecutar análisis y pruebas finales

**Estado:** Pendiente. **Tarea superior:** ENT01.

Validar versión exacta que se entregará.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.003 — Confirmar contrato del backend final

**Estado:** Pendiente. **Tarea superior:** ENT01.

Verificar funciones y migraciones requeridas por el cliente.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.004 — Compilar Web de entrega

**Estado:** Pendiente. **Tarea superior:** ENT01.

Usar configuración pública correspondiente al entorno.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.005 — Preparar APK de entrega

**Estado:** Pendiente. **Tarea superior:** ENT01.

Definir artefacto de prueba o distribución según firma disponible.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.006 — Preparar iOS si existe firma y dispositivo

**Estado:** Bloqueado. **Tarea superior:** ENT01.

Condicionar entrega iOS al equipo Apple y validación física.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Resolver credenciales, permisos o firma indicados en el resultado.

### ENT01.007 — Publicar actualización Web acordada

**Estado:** Pendiente. **Tarea superior:** ENT01.

Verificar recursos servidos y rutas después del despliegue.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.008 — Verificar instalación y arranque Android

**Estado:** Pendiente. **Tarea superior:** ENT01.

Comprobar acceso y funciones principales del build entregado.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.009 — Verificar operación de push y tours

**Estado:** Pendiente. **Tarea superior:** ENT01.

Comprobar schedulers, colas y procesadores activos.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.010 — Actualizar instrucciones técnicas

**Estado:** Pendiente. **Tarea superior:** ENT01.

Documentar ejecución, límites y recuperación de la aplicación.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.011 — Registrar versión y archivos entregados

**Estado:** Pendiente. **Tarea superior:** ENT01.

Relacionar artefactos con commit o snapshot verificable.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

### ENT01.012 — Cerrar aceptación técnica el 18 de noviembre

**Estado:** Pendiente. **Tarea superior:** ENT01.

Registrar responsable, resultado y pendientes que permanezcan.

| Tiempo | Inicio | Fin | Duración en bloques |
|---|---|---|---:|
| E — Estimado | 15/11/2026 (NOV-3) | 18/11/2026 (NOV-3) | 1 |
| R — Real |  |  |  |

**Responsable asignado:** ____________________. **Realizado por:** ____________________.

**Dependencias técnicas:** PIL02, QA03.

**Fecha de evidencia:** Sin fecha individual comprobada. **Fuentes:** S001, S145, S127.

**Para cerrar o completar el registro:** Ejecutar la actividad y registrar resultado, responsables y duración real.

## Referencias verificables

Las referencias siguientes identifican archivos realmente presentes o archivos disponibles en el commit indicado. Las fuentes compartidas describen el grupo y sus subtareas; una fecha de evidencia no se convierte en inicio o duración real.

- **S001:** [README.md](/Users/crisis/Proyectos/marea/README.md).
- **S002:** [docs/design-experiments/mobile-social-ui-product.md](/Users/crisis/Proyectos/marea/docs/design-experiments/mobile-social-ui-product.md).
- **S003:** [docs/design-experiments/social-mobile-redesign-product.md](/Users/crisis/Proyectos/marea/docs/design-experiments/social-mobile-redesign-product.md).
- **S004:** [docs/design-system.md](/Users/crisis/Proyectos/marea/docs/design-system.md).
- **S005:** [docs/account-completion.md](/Users/crisis/Proyectos/marea/docs/account-completion.md).
- **S006:** [supabase/migrations/001_initial_schema.sql](/Users/crisis/Proyectos/marea/supabase/migrations/001_initial_schema.sql).
- **S007:** [docs/map.md](/Users/crisis/Proyectos/marea/docs/map.md).
- **S008:** [docs/ar-experience-design.md](/Users/crisis/Proyectos/marea/docs/ar-experience-design.md).
- **S009:** [docs/implementation/tours-native.md](/Users/crisis/Proyectos/marea/docs/implementation/tours-native.md).
- **S010:** [processing/tours/README.md](/Users/crisis/Proyectos/marea/processing/tours/README.md).
- **S011:** commit `b92a237`, archivo `README.md`. Consulta exacta: `git show b92a237:README.md`.
- **S012:** commit `b92a237`, archivo `pubspec.yaml`. Consulta exacta: `git show b92a237:pubspec.yaml`.
- **S013:** commit `b92a237`, archivo `lib/main.dart`. Consulta exacta: `git show b92a237:lib/main.dart`.
- **S014:** commit `b92a237`, archivo `lib/core/config/app_config.dart`. Consulta exacta: `git show b92a237:lib/core/config/app_config.dart`.
- **S015:** commit `b92a237`, archivo `docs/design-system.md`. Consulta exacta: `git show b92a237:docs/design-system.md`.
- **S016:** commit `b92a237`, archivo `lib/core/theme/app_theme.dart`. Consulta exacta: `git show b92a237:lib/core/theme/app_theme.dart`.
- **S017:** commit `b92a237`, archivo `lib/features/shell/presentation/app_shell.dart`. Consulta exacta: `git show b92a237:lib/features/shell/presentation/app_shell.dart`.
- **S018:** commit `b92a237`, archivo `lib/features/auth/data/auth_repository.dart`. Consulta exacta: `git show b92a237:lib/features/auth/data/auth_repository.dart`.
- **S019:** commit `b92a237`, archivo `lib/features/auth/presentation/register_screen.dart`. Consulta exacta: `git show b92a237:lib/features/auth/presentation/register_screen.dart`.
- **S020:** commit `b92a237`, archivo `lib/core/session/app_session_controller.dart`. Consulta exacta: `git show b92a237:lib/core/session/app_session_controller.dart`.
- **S021:** commit `b92a237`, archivo `supabase/migrations/001_initial_schema.sql`. Consulta exacta: `git show b92a237:supabase/migrations/001_initial_schema.sql`.
- **S022:** commit `b92a237`, archivo `supabase/functions/delete-account/index.ts`. Consulta exacta: `git show b92a237:supabase/functions/delete-account/index.ts`.
- **S023:** commit `b92a237`, archivo `lib/features/profile/data/profile_repository.dart`. Consulta exacta: `git show b92a237:lib/features/profile/data/profile_repository.dart`.
- **S024:** commit `b92a237`, archivo `test/core/session/app_session_controller_test.dart`. Consulta exacta: `git show b92a237:test/core/session/app_session_controller_test.dart`.
- **S025:** commit `b92a237`, archivo `test/features/presentation/screens_test.dart`. Consulta exacta: `git show b92a237:test/features/presentation/screens_test.dart`.
- **S026:** [docs/deployment-status.md](/Users/crisis/Proyectos/marea/docs/deployment-status.md).
- **S027:** [docs/superpowers/plans/2026-09-14-account-completion.md](/Users/crisis/Proyectos/marea/docs/superpowers/plans/2026-09-14-account-completion.md).
- **S028:** [supabase/migrations/002_account_completion.sql](/Users/crisis/Proyectos/marea/supabase/migrations/002_account_completion.sql).
- **S029:** [lib/features/profile/data/profile_media_repository.dart](/Users/crisis/Proyectos/marea/lib/features/profile/data/profile_media_repository.dart).
- **S030:** [supabase/functions/profile-media/index.ts](/Users/crisis/Proyectos/marea/supabase/functions/profile-media/index.ts).
- **S031:** [supabase/functions/profile-media/image.ts](/Users/crisis/Proyectos/marea/supabase/functions/profile-media/image.ts).
- **S032:** [docs/community.md](/Users/crisis/Proyectos/marea/docs/community.md).
- **S033:** [supabase/migrations/003_community.sql](/Users/crisis/Proyectos/marea/supabase/migrations/003_community.sql).
- **S034:** [lib/features/community/data/community_repository.dart](/Users/crisis/Proyectos/marea/lib/features/community/data/community_repository.dart).
- **S035:** [test/features/profile/data/profile_image_picker_test.dart](/Users/crisis/Proyectos/marea/test/features/profile/data/profile_image_picker_test.dart).
- **S036:** [tool/check_database.mjs](/Users/crisis/Proyectos/marea/tool/check_database.mjs).
- **S037:** [tool/check_community_database.mjs](/Users/crisis/Proyectos/marea/tool/check_community_database.mjs).
- **S038:** [supabase/migrations/004_post_locations.sql](/Users/crisis/Proyectos/marea/supabase/migrations/004_post_locations.sql).
- **S039:** [lib/features/community/presentation/post_location_picker.dart](/Users/crisis/Proyectos/marea/lib/features/community/presentation/post_location_picker.dart).
- **S040:** commit `b321100`, archivo `README.md`. Consulta exacta: `git show b321100:README.md`.
- **S041:** [supabase/migrations/005_mission_lifecycle.sql](/Users/crisis/Proyectos/marea/supabase/migrations/005_mission_lifecycle.sql).
- **S042:** [test/features/community/mission_repository_test.dart](/Users/crisis/Proyectos/marea/test/features/community/mission_repository_test.dart).
- **S043:** [supabase/functions/delete-account/index.ts](/Users/crisis/Proyectos/marea/supabase/functions/delete-account/index.ts).
- **S044:** [lib/features/community/presentation/moderation_screen.dart](/Users/crisis/Proyectos/marea/lib/features/community/presentation/moderation_screen.dart).
- **S045:** commit `1c7a5d0`, archivo `README.md`. Consulta exacta: `git show 1c7a5d0:README.md`.
- **S046:** [.gitignore](/Users/crisis/Proyectos/marea/.gitignore).
- **S047:** [supabase/migrations/006_profile_experience.sql](/Users/crisis/Proyectos/marea/supabase/migrations/006_profile_experience.sql).
- **S048:** [lib/features/showcase/data/showcase_repository.dart](/Users/crisis/Proyectos/marea/lib/features/showcase/data/showcase_repository.dart).
- **S049:** [lib/features/showcase/presentation/showcase_composer_screen.dart](/Users/crisis/Proyectos/marea/lib/features/showcase/presentation/showcase_composer_screen.dart).
- **S050:** [docs/access-redesign.md](/Users/crisis/Proyectos/marea/docs/access-redesign.md).
- **S051:** [output/access-redesign-progress.md](/Users/crisis/Proyectos/marea/output/access-redesign-progress.md).
- **S052:** [supabase/migrations/007_minimal_registration.sql](/Users/crisis/Proyectos/marea/supabase/migrations/007_minimal_registration.sql).
- **S053:** [output/account-repair-progress.md](/Users/crisis/Proyectos/marea/output/account-repair-progress.md).
- **S054:** [docs/email-setup.md](/Users/crisis/Proyectos/marea/docs/email-setup.md).
- **S055:** [supabase/migrations/008_recover_minimal_registration.sql](/Users/crisis/Proyectos/marea/supabase/migrations/008_recover_minimal_registration.sql).
- **S056:** [output/ux-permissions-progress.md](/Users/crisis/Proyectos/marea/output/ux-permissions-progress.md).
- **S057:** [lib/features/profile/presentation/profile_tools_sheet.dart](/Users/crisis/Proyectos/marea/lib/features/profile/presentation/profile_tools_sheet.dart).
- **S058:** [output/profile-redesign-progress.md](/Users/crisis/Proyectos/marea/output/profile-redesign-progress.md).
- **S059:** commit `84f3151`, archivo `lib/features/profile/presentation/profile_experience.dart`. Consulta exacta: `git show 84f3151:lib/features/profile/presentation/profile_experience.dart`.
- **S060:** [output/imagegen/marea-home-hybrid.prompt.txt](/Users/crisis/Proyectos/marea/output/imagegen/marea-home-hybrid.prompt.txt).
- **S061:** [output/imagegen/marea-home-editorial-v2.prompt.txt](/Users/crisis/Proyectos/marea/output/imagegen/marea-home-editorial-v2.prompt.txt).
- **S062:** [docs/home-social-ui-v3.md](/Users/crisis/Proyectos/marea/docs/home-social-ui-v3.md).
- **S063:** [docs/home-vertical-ui-v4.md](/Users/crisis/Proyectos/marea/docs/home-vertical-ui-v4.md).
- **S064:** [docs/home-brand-ui-v5.md](/Users/crisis/Proyectos/marea/docs/home-brand-ui-v5.md).
- **S065:** [docs/home-final-ui-v6.md](/Users/crisis/Proyectos/marea/docs/home-final-ui-v6.md).
- **S066:** [docs/design-experiments/README.md](/Users/crisis/Proyectos/marea/docs/design-experiments/README.md).
- **S067:** [docs/home-polished-ui-v7.md](/Users/crisis/Proyectos/marea/docs/home-polished-ui-v7.md).
- **S068:** commit `37d4c23`, archivo `README.md`. Consulta exacta: `git show 37d4c23:README.md`.
- **S069:** [docs/home-social-v7-integration.md](/Users/crisis/Proyectos/marea/docs/home-social-v7-integration.md).
- **S070:** commit `9f2f91d`, archivo `lib/features/community/presentation/posts_feed.dart`. Consulta exacta: `git show 9f2f91d:lib/features/community/presentation/posts_feed.dart`.
- **S071:** commit `9c551ab`, archivo `README.md`. Consulta exacta: `git show 9c551ab:README.md`.
- **S072:** [supabase/migrations/009_post_reactions.sql](/Users/crisis/Proyectos/marea/supabase/migrations/009_post_reactions.sql).
- **S073:** [supabase/migrations/010_post_comments.sql](/Users/crisis/Proyectos/marea/supabase/migrations/010_post_comments.sql).
- **S074:** [lib/features/community/data/social_repository.dart](/Users/crisis/Proyectos/marea/lib/features/community/data/social_repository.dart).
- **S075:** [supabase/migrations/011_post_collaboration.sql](/Users/crisis/Proyectos/marea/supabase/migrations/011_post_collaboration.sql).
- **S076:** [lib/features/community/presentation/social_panels.dart](/Users/crisis/Proyectos/marea/lib/features/community/presentation/social_panels.dart).
- **S077:** [lib/features/community/data/notifications_controller.dart](/Users/crisis/Proyectos/marea/lib/features/community/data/notifications_controller.dart).
- **S078:** [docs/implementation/home-social-v7-progress.md](/Users/crisis/Proyectos/marea/docs/implementation/home-social-v7-progress.md).
- **S079:** [tool/check_live_social_flow.mjs](/Users/crisis/Proyectos/marea/tool/check_live_social_flow.mjs).
- **S080:** commit `b565ef0`, archivo `lib/features/shell/presentation/app_shell.dart`. Consulta exacta: `git show b565ef0:lib/features/shell/presentation/app_shell.dart`.
- **S081:** commit `d54f4e5`, archivo `lib/features/shell/presentation/app_shell.dart`. Consulta exacta: `git show d54f4e5:lib/features/shell/presentation/app_shell.dart`.
- **S082:** [docs/design-experiments/mobile-social-ui-design.md](/Users/crisis/Proyectos/marea/docs/design-experiments/mobile-social-ui-design.md).
- **S083:** [docs/design-experiments/social-mobile-redesign-design.md](/Users/crisis/Proyectos/marea/docs/design-experiments/social-mobile-redesign-design.md).
- **S084:** [docs/missions-redesign.md](/Users/crisis/Proyectos/marea/docs/missions-redesign.md).
- **S085:** [docs/implementation/missions-redesign-progress.md](/Users/crisis/Proyectos/marea/docs/implementation/missions-redesign-progress.md).
- **S086:** [supabase/migrations/013_missions_redesign.sql](/Users/crisis/Proyectos/marea/supabase/migrations/013_missions_redesign.sql).
- **S087:** [lib/features/community/presentation/mission_application_screen.dart](/Users/crisis/Proyectos/marea/lib/features/community/presentation/mission_application_screen.dart).
- **S088:** [lib/features/community/presentation/mission_management_screen.dart](/Users/crisis/Proyectos/marea/lib/features/community/presentation/mission_management_screen.dart).
- **S089:** [tool/check_live_missions_flow.mjs](/Users/crisis/Proyectos/marea/tool/check_live_missions_flow.mjs).
- **S090:** [supabase/migrations/012_mission_map.sql](/Users/crisis/Proyectos/marea/supabase/migrations/012_mission_map.sql).
- **S091:** commit `ffd8990`, archivo `lib/features/map/presentation/mission_map_screen.dart`. Consulta exacta: `git show ffd8990:lib/features/map/presentation/mission_map_screen.dart`.
- **S092:** commit `ffd8990`, archivo `assets/brand/marea_app.png`. Consulta exacta: `git show ffd8990:assets/brand/marea_app.png`.
- **S093:** commit `ffd8990`, archivo `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`. Consulta exacta: `git show ffd8990:android/app/src/main/res/mipmap-hdpi/ic_launcher.png`.
- **S094:** commit `ffd8990`, archivo `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`. Consulta exacta: `git show ffd8990:ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`.
- **S095:** [docs/implementation/modern-interactions-push-progress.md](/Users/crisis/Proyectos/marea/docs/implementation/modern-interactions-push-progress.md).
- **S096:** [lib/features/community/presentation/reaction_button.dart](/Users/crisis/Proyectos/marea/lib/features/community/presentation/reaction_button.dart).
- **S097:** [test/features/community/social_ui_test.dart](/Users/crisis/Proyectos/marea/test/features/community/social_ui_test.dart).
- **S098:** [lib/shared/widgets/marea_action_button.dart](/Users/crisis/Proyectos/marea/lib/shared/widgets/marea_action_button.dart).
- **S099:** [lib/shared/widgets/marea_panel.dart](/Users/crisis/Proyectos/marea/lib/shared/widgets/marea_panel.dart).
- **S100:** [lib/shared/widgets/marea_skeleton.dart](/Users/crisis/Proyectos/marea/lib/shared/widgets/marea_skeleton.dart).
- **S101:** [docs/android-push.md](/Users/crisis/Proyectos/marea/docs/android-push.md).
- **S102:** [lib/features/notifications/data/push_controller.dart](/Users/crisis/Proyectos/marea/lib/features/notifications/data/push_controller.dart).
- **S103:** [lib/features/notifications/data/android_push_gateway.dart](/Users/crisis/Proyectos/marea/lib/features/notifications/data/android_push_gateway.dart).
- **S104:** [lib/features/notifications/presentation/notification_settings.dart](/Users/crisis/Proyectos/marea/lib/features/notifications/presentation/notification_settings.dart).
- **S105:** [supabase/migrations/014_android_push.sql](/Users/crisis/Proyectos/marea/supabase/migrations/014_android_push.sql).
- **S106:** [supabase/functions/send-push/index.ts](/Users/crisis/Proyectos/marea/supabase/functions/send-push/index.ts).
- **S107:** [supabase/functions/send-push/delivery.ts](/Users/crisis/Proyectos/marea/supabase/functions/send-push/delivery.ts).
- **S108:** [supabase/push/activate.sql](/Users/crisis/Proyectos/marea/supabase/push/activate.sql).
- **S109:** [android/app/build.gradle.kts](/Users/crisis/Proyectos/marea/android/app/build.gradle.kts).
- **S110:** [test/features/notifications/push_controller_test.dart](/Users/crisis/Proyectos/marea/test/features/notifications/push_controller_test.dart).
- **S111:** [docs/implementation/tours-360-plan.md](/Users/crisis/Proyectos/marea/docs/implementation/tours-360-plan.md).
- **S112:** [output/imagegen/ar/README.md](/Users/crisis/Proyectos/marea/output/imagegen/ar/README.md).
- **S113:** [docs/implementation/tours-360-delivery.md](/Users/crisis/Proyectos/marea/docs/implementation/tours-360-delivery.md).
- **S114:** [lib/features/tours/presentation/tour_editor_screen.dart](/Users/crisis/Proyectos/marea/lib/features/tours/presentation/tour_editor_screen.dart).
- **S115:** [lib/features/tours/models/tour_models.dart](/Users/crisis/Proyectos/marea/lib/features/tours/models/tour_models.dart).
- **S116:** [lib/features/tours/capture/tour_capture_screen.dart](/Users/crisis/Proyectos/marea/lib/features/tours/capture/tour_capture_screen.dart).
- **S117:** [lib/features/tours/capture/capture_plan.dart](/Users/crisis/Proyectos/marea/lib/features/tours/capture/capture_plan.dart).
- **S118:** [android/app/src/main/kotlin/com/marea/app/TourNative.kt](/Users/crisis/Proyectos/marea/android/app/src/main/kotlin/com/marea/app/TourNative.kt).
- **S119:** [ios/Runner/TourOrientation.swift](/Users/crisis/Proyectos/marea/ios/Runner/TourOrientation.swift).
- **S120:** [ios/NativeTests/orientation.swift](/Users/crisis/Proyectos/marea/ios/NativeTests/orientation.swift).
- **S121:** [lib/features/tours/data/tus_uploader.dart](/Users/crisis/Proyectos/marea/lib/features/tours/data/tus_uploader.dart).
- **S122:** [lib/features/tours/data/tour_local_store_io.dart](/Users/crisis/Proyectos/marea/lib/features/tours/data/tour_local_store_io.dart).
- **S123:** [lib/features/tours/data/tour_local_store_web.dart](/Users/crisis/Proyectos/marea/lib/features/tours/data/tour_local_store_web.dart).
- **S124:** [supabase/migrations/015_tours.sql](/Users/crisis/Proyectos/marea/supabase/migrations/015_tours.sql).
- **S125:** [supabase/functions/delete-account/tour-storage.ts](/Users/crisis/Proyectos/marea/supabase/functions/delete-account/tour-storage.ts).
- **S126:** [supabase/tours/repair-cleanup-lease.sql](/Users/crisis/Proyectos/marea/supabase/tours/repair-cleanup-lease.sql).
- **S127:** [docs/implementation/tours-local-pilot-report.md](/Users/crisis/Proyectos/marea/docs/implementation/tours-local-pilot-report.md).
- **S128:** [processing/tours/worker.py](/Users/crisis/Proyectos/marea/processing/tours/worker.py).
- **S129:** [processing/tours/Dockerfile](/Users/crisis/Proyectos/marea/processing/tours/Dockerfile).
- **S130:** [lib/features/tours/presentation/tour_panorama.dart](/Users/crisis/Proyectos/marea/lib/features/tours/presentation/tour_panorama.dart).
- **S131:** [lib/features/tours/presentation/tour_visit_screen.dart](/Users/crisis/Proyectos/marea/lib/features/tours/presentation/tour_visit_screen.dart).
- **S132:** [test/features/tours/tour_ui_test.dart](/Users/crisis/Proyectos/marea/test/features/tours/tour_ui_test.dart).
- **S133:** [android/app/src/main/kotlin/com/marea/app/TourAR.kt](/Users/crisis/Proyectos/marea/android/app/src/main/kotlin/com/marea/app/TourAR.kt).
- **S134:** [ios/Runner/AppDelegate.swift](/Users/crisis/Proyectos/marea/ios/Runner/AppDelegate.swift).
- **S135:** [lib/features/tours/data/tour_progress_store.dart](/Users/crisis/Proyectos/marea/lib/features/tours/data/tour_progress_store.dart).
- **S136:** [lib/core/router/app_router.dart](/Users/crisis/Proyectos/marea/lib/core/router/app_router.dart).
- **S137:** [processing/tours/pilot-image.json](/Users/crisis/Proyectos/marea/processing/tours/pilot-image.json).
- **S138:** [processing/tours/local_runner.py](/Users/crisis/Proyectos/marea/processing/tours/local_runner.py).
- **S139:** [processing/tours/check_live.py](/Users/crisis/Proyectos/marea/processing/tours/check_live.py).
- **S140:** [test/features/tours/tour_editor_recovery_test.dart](/Users/crisis/Proyectos/marea/test/features/tours/tour_editor_recovery_test.dart).
- **S141:** [test/features/tours/tour_ar_recovery_test.dart](/Users/crisis/Proyectos/marea/test/features/tours/tour_ar_recovery_test.dart).
- **S142:** [tool/check_tours_migrations.mjs](/Users/crisis/Proyectos/marea/tool/check_tours_migrations.mjs).
- **S143:** [processing/tours/bootstrap.sh](/Users/crisis/Proyectos/marea/processing/tours/bootstrap.sh).
- **S144:** [processing/tours/deploy.sh](/Users/crisis/Proyectos/marea/processing/tours/deploy.sh).
- **S145:** [tool/README.md](/Users/crisis/Proyectos/marea/tool/README.md).
