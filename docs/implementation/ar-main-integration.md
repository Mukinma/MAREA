# Integración de RA con la navegación reciente

## Actualización del 9 de noviembre de 2026

La rama `santiago` incorpora por merge el `main` reciente (`c9b56d7`, PR #10) y la revisión de RA guardada en `87fa6f3`. Se conservan el nuevo diseño de bienvenida, perfil, barra y mapa del equipo, junto con captura automática de hasta 40 fotos, importación validada, guía superpuesta para retomar y controles de RA simplificados.

El merge no tuvo conflictos de texto. La prueba de entrada a experiencias se adaptó al mapa nuevo, que retiró los chips anteriores: ahora comprueba la consulta por ubicación, el marcador público y la navegación al recorrido. El modo normal no consulta ni muestra recorridos. Se conserva `/map?experiences=1` para abrir directamente ese modo. El indicador interno pasa a `final` al desaparecer el control que lo cambiaba; no se reintrodujeron los botones retirados por el equipo.

El archivo de dependencias conserva las versiones comprobadas con Flutter 3.47.9 / Dart 3.13.7, incluida `vector_math 2.4.3`; `xml 7.0.1` sigue como dependencia directa. Los respaldos, sesiones, firma Android, fotos y configuraciones privadas permanecen fuera de Git. La guía actualizada para el otro equipo está en [Continuar en otra laptop](continue-on-another-laptop.md).

Verificación de la integración:

- Análisis Flutter sin incidencias y compilación APK debug del piloto correctos.
- **199 pruebas aprobadas** de recorridos (126), mapa (31), rutas (20) y barra (22), contabilizadas en la suite completa.
- **79 pruebas Node del piloto aprobadas**, sin aprovisionar cuentas ni operar colas.
- Suite completa: **699 aprobadas, dos omitidas y 17 fallidas**. Los 17 fallos están en bienvenida, historias y fichas de perfil. Se ejecutaron los mismos tres módulos en un worktree de `c9b56d7`, con fuentes intactas y lock adaptado al mismo SDK: fallan exactamente los mismos nombres y rutas, sin fallos nuevos. La comparación está en `build/ar-live-pilot/sync-20261109-baseline-summary.json` y sus logs locales, ignorados por Git.

Esta comprobación no instala otra APK en el teléfono ni repite la validación óptica. La última captura física sigue documentada con 35/36 fotos y el techo pendiente.

## Integración anterior del 2 de noviembre

Integración del PR [#5](https://github.com/Mukinma/MAREA/pull/5), preparada el 2 de noviembre de 2026. Se incorporó `main` (`3ebc0ad`) en `santiago` mediante merge, conservando el historial de ambas ramas.

## Resolución

- `app_router.dart`: se conservan la ruta `/discover` y la ruta `/tours/:id/business-ar`, con su guard de autenticación y los parámetros del organizador y la referencia.
- `mission_map_screen.dart`: se conserva la nueva disposición del mapa y sus controles, área de preview, atribución y espacio para la barra móvil. La acción RA se añade a la preview de la Misión seleccionada; no al pie de atribución.
- La nueva barra móvil, la pantalla Descubrir y el shell se mantienen como en `main`.
- La entrada RA conserva la consulta de recorridos públicos del mismo organizador y exige la versión actual de la referencia probada. No se cambiaron reglas de publicación ni permisos.

Se añadieron tres pruebas del mapa combinado: entrada RA en móvil/escritorio, parámetros de navegación, regreso al mapa y referencia sin prueba oculta. Se corrigió también la preparación de `social_header_test.dart`: para exigir el botón Mensajes, el test debe proporcionar un repositorio de chat. No se cambió la interfaz para satisfacer esa prueba.

## Verificación

- Suite Flutter completa: **636 pruebas aprobadas**, dos omisiones existentes.
- Pruebas Node de los pilotos: **79 aprobadas**.
- Análisis Flutter sin incidencias y compilación APK debug del piloto real correctos.
- Las pruebas del mapa usan repositorios y mosaicos de prueba; no escriben en producción ni simulan el reconocimiento en la aplicación.
- Esta integración no añade una prueba física del nuevo diseño en el teléfono. Los resultados previos de reconocimiento y el estado pendiente de captura están en `ar-development-pilot.md`.

## Continuar cada parte desde su rama

Después de integrar el PR en `main`, cada colaborador puede actualizar su propia rama:

```sh
git status
git fetch origin
git switch NOMBRE_DE_SU_RAMA
git merge origin/main
```

Si hay cambios locales, guardarlos en un commit propio antes de integrar. Resolver cualquier conflicto conservando ambas funcionalidades y ejecutar las pruebas correspondientes. La integración del PR no actualiza automáticamente las ramas de los demás ni requiere sobrescribirlas.

Para una copia limpia de `santiago` en otra laptop, usar `git pull --ff-only origin santiago` y seguir `continue-on-another-laptop.md`. Mantener los archivos privados y la firma debug fuera de Git.
