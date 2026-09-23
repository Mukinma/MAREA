# Funciones por tipo de usuario — MAREA

Objetivo: sustituir las secciones próximas por publicaciones, descubrimiento y misiones persistentes, con diferencias visibles por perfil. Sin ninguna funcionalidad AR.

Arquitectura: conservar Flutter, Supabase, sesión y tema existentes. Nuevo módulo community con modelos, repositorio inyectable y pantallas; migración incremental 003. No descartar cambios previos del workspace.

## Alcance
- General: publicaciones de comunidad, descubrir perfiles, guardar publicaciones y participar en misiones.
- Artista: además publicar proyectos y construir su portafolio.
- Emprendedor: además catálogo de productos y servicios con precio opcional.
- Negocio: además espacios y eventos con ubicación.
- Todos pueden proponer misiones; cada convocatoria puede seleccionar el perfil buscado. Postulación, retiro, revisión, selección con cupo, cierre y reapertura antes de fecha.
- Administrador: acceso adicional a reportes y ocultar/restaurar contenido, sin promover usuarios desde el cliente.
- Fotos opcionales en posts, editar/eliminar contenido propio, búsqueda y filtros, perfiles públicos limitados a datos de presentación.

## Ejecución y comprobación
- [x] Backend: tablas, permisos por columna, RLS, RPCs, Storage y limpieza de cuenta. Pruebas PostgreSQL aisladas con usuarios y roles distintos.
- [x] Dominio y repositorio: capacidades por perfil, validación, mapeo de datos, consultas paginadas, errores útiles y pruebas de modelos.
- [x] Interfaz: inicio, explorar, formularios, perfiles, misiones/postulaciones y reportes. Reutilizar diseño responsive y mostrar carga, vacío, error y reintento.
- [x] Integración: rutas protegidas, inyección real desde main, actualizar perfil propio y documentación.
- [x] Verificación: pruebas de widgets y permisos, flutter analyze, flutter test y compilación Web. Revisar cambios y documentar estado de migración remota sin afirmar despliegue no realizado.

Resultado: backend desplegado, permisos remotos sin sesión comprobados, 133 pruebas Flutter y 100 comprobaciones de comunidad en PostgreSQL aislado. Los fixtures no se publicaron. Sin funciones AR.
