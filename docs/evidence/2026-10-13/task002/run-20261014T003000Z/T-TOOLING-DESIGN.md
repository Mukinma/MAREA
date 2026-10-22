# T — modificación de herramientas, previa a implementación

Se conserva schema_version 1 como lector histórico. Schema_version 2 añade normative_versions, normative_context, clause_anchors, evidencia de autorización, preservación y correspondencia por fragmento, y test_cases independientes. baseline permanece byte-equivalente semánticamente; no se sustituye por la nueva fuente.

El catálogo expandido incluye §§0, 0.1, 0.2, 3.6–3.11, 9.3 y decisiones/pruebas explícitas. Los IDs AUX existentes se conservan por correspondencia de entidad, acción o invariante; nuevas cláusulas obtienen IDs no usados. Cada ancla liga ID, sección y SHA256. No se reenumera el YAML desde posiciones del extractor.

Los registros previos conservan dimensiones, criterios e historial. Se agrega source_history y evento de revisión normativa con snapshot idéntico, nuevo source y assessment_normative_version histórico. Lo cambiado queda PENDIENTE_REAUDITORIA; no se declara comportamiento nuevo implementado. Toda validación vigente en schema 2 exige fuente de diseño adoptada y evidencia ligada expresamente a esa norma; compatibilidad pendiente impide validación vigente. Evidencias previas no se reconfirman en bloque.

DECISION-51 se registra como decisiones con alcance de autorización condicionado; TC-51 como test_cases PENDIENTE, sin sumar RF. Se valida integridad del histórico desde snapshot canónico, IDs, hashes, dependencias y pérdida/manipulación de registros. Las vistas muestran fuente de diseño, baseline efectiva e integración documental separadas, así como historial y casos pendientes.

Se documenta esta evolución antes de editar implementación de herramientas. No se toca tool/staging, SQL de producto, lib ni Edge Functions.
