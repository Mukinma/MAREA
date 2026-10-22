# Ledger E2-A R6

- R3, R4 y R5 quedan fallidos e intactos; ninguna corrida se desbloquea.
- R5: ensayo real de reparación falló por RLS de auth.users; toda la transacción fue revertida.
- A incorpora únicamente lectura técnica de estado Auth mediante política de rol privado ya autorizado. No se relaja aislamiento ni se otorga BYPASSRLS.
- Se incorpora colisión no nula auténtica señalada por revisión estática.
