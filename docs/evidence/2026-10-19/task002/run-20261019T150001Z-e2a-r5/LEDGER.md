# Ledger — E2-A R5

- PAX y recuperación DB/Storage ya probados, se repiten en copias nuevas. Probe efímero por check conserva igualdad efectiva tras reinicio.
- R4 ensayo DDL revertido: SET LOCAL default_transaction_read_only no habilita transacción actual; corregir SET LOCAL transaction_read_only=off, sólo writes aprobados. No grants adicionales para superar el error.
- Misma autorización humana; históricos y failed runners intactos.
