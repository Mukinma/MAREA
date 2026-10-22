# ORG-0 / C — intento 1 detenido e invalidado

ORG-0 pasó las comprobaciones iniciales pero su aceptación 12 queda INVALIDADA por 12b. C no está aceptado: fixtures parciales sólo A, antes de completar C B.

C detectó que una identidad sintética B tenía marcador legado account_deletion_requests con controles privados abiertos. El resolver nuevo omitía ese marcador, mientras la guarda B correctamente impedía la misión. No es drift ni pérdida de datos: es una omisión de elegibilidad de ORG-0 y de selección del fixture.

13a reproduce autorización incorrecta con el marcador real; 13b demuestra la corrección mínima dentro de rollback exacto. Se incorporó la misma comprobación a titular vigente y delegador de invitación. No se modifica B ni se relaja su rechazo.

Las evidencias anteriores, SQL inicial, fuentes previas y volúmenes de esta corrida quedan conservados y detenidos. La aceptación inicial y el backup no certifican esta corrección. Se necesita corrida nueva desde B, con SQL corregido y sin reutilizar estos volúmenes. No se ejecutó purga, cambio de FK, contrato, remoto ni commit.
