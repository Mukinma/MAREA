# Ledger E2-A R7

- Preservar todos los intentos fallidos.
- R6: A DDL rollback/commit validado en ambas fuentes; GREEN incompleto por parseo de booleano del observador de lock.
- Corrección sólo observador: SELECT to_jsonb(EXISTS(...)); sin relajar timeout ni omitir concurrencia.
- SQL A idéntico al validado transaccionalmente en R6.
