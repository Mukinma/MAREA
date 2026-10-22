# E2-A / D01 — autorización humana local

19 octubre 2026, America/Mexico_City. El usuario aprueba conceptualmente la arquitectura incremental E2, aprueba D01 y autoriza **exclusivamente implementar y validar E2-A en copias nuevas, sintéticas y aisladas**.

Autorizados: trigger transaccional AFTER INSERT Auth, creación inicial Person.id=Auth.id sin usar esa igualdad como autoridad; resolver por auth_user_id/control; conservar handle_new_user y registro/legal; fallo de principal revierte alta; reconciliación privada administrativa con dry-run, manifiesto verificable y lotes limitados; sin relink NULL, reuse de suprimidos o ON CONFLICT silencioso; privilegios mínimos; E2-T01–06/T08 y reparación de T44; fixtures INSERT declarados separados y conservación exacta del resto.

Prohibidos: T07, DELETE Auth/perfiles existentes, S0/B/C/D/M/K/F/X/R, cambios author_id/FK/candidaturas/titularidad/RPC negocio/Edge baja/Flutter, remoto/datos reales, commits y políticas definitivas de retención/supresión. Ante drift, aislamiento/privilegios inesperados o conflicto no previsto: parar sin ampliar alcance. Al finalizar A, detenerse y solicitar siguiente autorización.

E1 histórico, propuestas y evidencias permanecen intactos. La reproducción autorizada de su baseline usa archivos fríos verificados y su SQL E1 validado **sólo en destinos nuevos**, como prevé el expediente; no se montan volúmenes originales E1. Los seis created_at técnicos reproducidos pertenecen a esta nueva copia, no se presentan como timestamps idénticos al E1 histórico.
