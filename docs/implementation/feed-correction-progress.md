# Corrección fiel del feed y de Bienvenida — registro

Plan: instrucciones del usuario del 7 de octubre de 2026, «Corrección fiel del feed y de Bienvenida».

Trabajo autorizado sobre /Users/crisis/Proyectos/marea y sus cambios pendientes; sin commits, frontend ni tiendas. Copia del estado inicial: /Users/crisis/Documents/Codex/2026-10-07/r/work/feed-correction-baseline.

Bloques: (1) raíz: tarjetas, Bienvenida, integración y entrega; (2) city_location: geocodificación/persistencia/selector; (3) mission_social: repositorio social, migración, conversación, notificaciones y ranking. Archivos compartidos reservados por responsable.

Interfaces: location_city opcional con LocationCity y LocationRepository; MissionSocialStats + MissionSocialActions reutilizan reacción y panel existentes; AppSessionController añade ambas dependencias opcionales. Raíz integra por lote en Home.

Verificaciones pendientes: pruebas de comportamiento de cada bloque; SQL aislado y contrato previo a activación; revisión independiente; análisis, pruebas completas, build web/Android secuencial; capturas ocho tamaños/escalas por pantalla; informe y APK.

Verificación intermedia: Bienvenida8 y UI/reacciones25 + foto en carga3 + misiones9 pasan. FullFlutter543pasadas/2omitidas antes de añadir9verificaciones de imagen; análisis limpio. SQLsocial40, ciudad13, Edge7 pasan. Deno check geocoding compila. Dryrun solo020/021. Edgegeocoding desplegado; migraciones aún pendientes de revisión independiente. Fallo real encontrado en navegador: IntrinsicHeight con LayoutBuilder del indicador y descripción; sustituido por altura medida para la columna fotográfica, regresión RED→GREEN. CompatibilidadPostInput sincity/punto recuperada,46pruebas del bloque pasan.
