# MAREA: acceso y registro guiado

Implementación del plan aprobado el 28 de septiembre de 2026. [Referencias de imagegen](../output/imagegen/README-access.md).

## Recorrido mínimo

Bienvenida → elegir perfil → nombre y @ → correo y contraseña → verificar correo → Inicio.

Cada cuenta tiene un perfil. El registro solicita una elección explícita entre Persona, Artista / creador, Emprendimiento y Negocio. Adapta la etiqueta del nombre, muestra el tipo elegido con **Cambiar** y avisa que queda fijo antes de crear la cuenta. Regresar conserva los campos, incluido el botón de regreso del sistema. Username ocupado se muestra junto al campo.

Contraseña única con mostrar/ocultar. Se conservan las dos casillas separadas, inicialmente vacías: aceptación de documentos y declaración de mayoría de edad. Verificación y recuperación permiten pegar el código completo y usan autofill; reenvío con espera de 60 segundos. La recuperación termina en una confirmación y permite entrar a Inicio.

Las cuentas pendientes anteriores confirman únicamente el tipo, conservando su contenido y preferencias. No se vuelve a pedir esa confirmación a los perfiles ya confirmados.

## Guías opcionales

Acceso desde **Completar perfil** / **Guía de perfil** en el perfil propio. Cada paso guarda sus datos y avance antes de continuar. **Ahora no** permite salir; reabrir retoma el avance guardado. Los campos profesionales, fotos, preferencias y creación de fichas son opcionales.

| Perfil | Pasos |
|---|---|
| Persona | Imagen/nombre/bio → intereses y objetivos opcionales |
| Artista / creador | Imagen/identidad → bio/contacto/colaboración → acceso a primera obra |
| Emprendimiento | Imagen/identidad de marca → contacto → acceso a primera ficha |
| Negocio | Imagen/identidad → contacto → ubicación y horarios → acceso a primer servicio |

El último paso profesional ofrece crear una ficha mediante el editor existente o terminar sin publicar. Preferencias privadas editables desde Configuración → Intereses y objetivos. Las guías no cambian el tipo. Los datos sin guardar duran mientras la pantalla permanece abierta; para conservarlos al salir se usa **Guardar y continuar**.

La pantalla se reinicia cuando cambia la cuenta. Los selectores y subidas en curso comprueban la cuenta antes de guardar; cerrar sesión no inicializa campos durante la eliminación de la pantalla.

## Diseño y accesibilidad

Logo original, Nunito Sans local, azul marino/aqua y Paper cálido. Superficies elevadas, campos con relieve interior, botón principal azul sólido y selección con borde además de color. Bienvenida con ilustración vectorial protagonista; formulario compacto y decoración lateral discreta en escritorio desde 1024 px.

En móvil los formularios son desplazables dentro de SafeArea y respetan el teclado. La selección usa RadioGroup, etiquetas accesibles y una columna cuando aumenta el texto. Contraseñas tienen acción accesible de mostrar/ocultar; los errores y estados del código conservan anuncios semánticos. Las láminas generadas son referencias: los controles Flutter son nativos, no imágenes de formularios.

## Contrato de servidor

Aplicar **`supabase/migrations/007_minimal_registration.sql`** después de 001–006, antes de publicar este cliente.

- Signup envía `user_type` y `registration_flow: minimal-v1`. El trigger valida los cuatro tipos y los consentimientos vigentes; crea un perfil confirmado con preferencias vacías. El rol siempre lo determina el servidor y sigue separado del tipo.
- Sin el marcador, los clientes anteriores conservan el flujo de confirmación mínima mediante `complete_initial_profile`. No se modifican los perfiles históricos.
- `setup_step` guarda avance privado limitado según tipo. Intereses y objetivos pueden estar vacíos y editarse después bajo RLS.
- El tipo y la confirmación inicial siguen protegidos contra cambios directos y confirmaciones repetidas.
- La verificación real de correo sigue controlada por Supabase Auth. Un perfil confirmado significa que eligió su tipo; no equivale a correo verificado.

Esta tarea no aplicó la migración a un proyecto remoto ni modificó SMTP. El archivo `config/supabase.local.json` no está en este checkout; la validación remota de envío, códigos y persistencia entre dispositivos requiere ese entorno.

## Verificación reproducible

```sh
flutter analyze
flutter test
MAREA_PGLITE_MODULE=/ruta/temporal/node_modules/@electric-sql/pglite/dist/index.js node tool/check_access_database.mjs
flutter build web --dart-define=SUPABASE_URL=https://example.supabase.co --dart-define=SUPABASE_ANON_KEY=example-public-key
```

Las comprobaciones PostgreSQL aisladas cubren tipos, rol, consentimientos, preferencias vacías/editables, confirmación única, límites de avance, RLS y conservación de perfiles existentes. No ejecutan la API de Auth ni el transporte real de correo.

Para inspeccionar las pantallas con datos de prueba:

```sh
flutter run -d web-server -t test/browser/access_experience_probe.dart --web-port 7365
```

Parámetros de la vista de prueba: `?screen=welcome`, `login`, `register`, `check-email`, `recover-password`, `reset-password`, `password-updated`, `profile/setup` o `profile/preferences`; `type=general|creator|entrepreneur|business` y `step=0..3`. Este entrypoint pertenece a pruebas; producción sigue usando `lib/main.dart`.

### Resultado local — 28 de septiembre de 2026

- `flutter test`: **239 pruebas aprobadas** (base anterior: 216).
- `flutter analyze`: sin incidencias.
- `check_access_database.mjs`: **35 comprobaciones aprobadas** en PostgreSQL aislado.
- `flutter build web`: completado; compilación con valores de configuración de ejemplo. Aviso de fuente CupertinoIcons opcional, ya presente en el proyecto, sin bloquear el build.
- Inspección en navegador: bienvenida/escritorio, registro móvil, login, guía de ubicación/horarios de negocio, recuperación y éxito. Árbol accesible con nombres de controles comprobado. Pruebas de registro y guías a 320 × 700, texto al doble y teclado de 260 px; sin desbordamientos y acciones alcanzables.
- Revisión independiente: corregidos borrador al cambiar de cuenta y disposición de controladores tras cerrar sesión; pruebas fallaron antes del arreglo y pasaron después.
- `git diff --check`: sin errores. Se conservaron los cambios previos del checkout.

Pendiente de entorno real: aplicar 007 y probar entrega/verificación de correo, persistencia entre dispositivos y lector de pantalla en dispositivo. No se desplegó el cliente ni se probaron Android/iOS físicos en esta tarea.
