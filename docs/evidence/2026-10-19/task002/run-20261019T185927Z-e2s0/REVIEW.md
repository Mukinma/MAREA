# Revisión final independiente de S0

Revisión de sólo lectura de SQL, herramientas y recibos públicos; sin Docker, SQL, red, respaldos privados ni modificaciones por el revisor.

**Hallazgo P1:** `aa_s0_reference` omitía `space` en `public.tours` y `public.tour_revisions`. `space.evidence_paths` contiene referencias a `tour-assets` según `015_tours.sql:197–199,521`; el permiso existente de `service_role` permite UPDATE/PATCH. La guarda de `document` no interceptaba esa operación. El montaje físico RO protegía los bytes, pero no esa referencia.

**Corrección acotada:** añadir `space` a ambas guardas, en una transacción con ensayo de rollback exacto. Ningún permiso, función preexistente, FK ni fila cambia. Los SQL, manifiesto, estado y recibos anteriores se conservan; la versión corregida tiene manifiesto y controlador v3 y nuevos digests, conservando el epoch del corte.

- [RED reproducible](22-space-reference-RED.json): dos tablas × dos copias, referencias sintéticas a objetos existentes, dentro de transacciones revertidas; ninguna pérdida persistente.
- [GREEN](23-space-reference-GREEN.json): SQL privilegiado rechazado con `55000` en ambas tablas; PATCH real sobre tour existente también rechazado; Storage y recepción de solicitudes revalidados.
- [Conservación corregida](25-data-conservation-v3.json) y [recuperación corregida](26-final-recovery-v3.json), incluidas las dos guardas restauradas.

No se encontraron otros defectos concretos en el alcance revisado. El revisor consideró coherentes el corte T49 y la barrera física RO dentro de los límites locales declarados. No se extrapola este resultado a producción, S3 ni al ciclo completo de baja. No hubo segunda ronda general de diseño o revisión.
