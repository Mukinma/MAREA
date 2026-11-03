# Integración de RA con la navegación reciente

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
