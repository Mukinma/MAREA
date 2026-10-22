# Ledger E2-A R8

- R7 conserva PASS funcional/negativos y FAIL de cierre por ledger de INSERTs incompleto. Todas las filas previas conservadas por hash.
- Exigir exactamente 6 AMR, 6 sesiones y 6 refresh tokens nuevos vinculados a los UUID HTTP de fixtures; 12 eventos Auth, 7 usuarios/perfiles/aceptaciones/identidades y 9 principales, con todo el resto sin delta.
- SQL A idéntico. Todas las fuentes/ejecutores fallidos intactos, sin desbloqueo.
