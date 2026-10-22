# Ledger — E2-A, misma autorización de dos etapas

- Stage 1 PAX PASS en run R3/pax. DB/Storage restore R3 PASS, después parada por probe de namespace obsoleto al reiniciar PG.
- Corrección: crear probe efímero nuevo por comprobación; nunca tolerar mismatch. Regresión real con contenedores vacíos: detecta probe obsoleto y acepta sólo nuevo namespace coincidente.
- Nuevo ejecutor/copies R4; históricos intactos. Sin otro incremento ni commits.
