# Piloto local de recorridos 360° con Supabase real

Plan autorizado en el chat: completar pendientes automatizables conservando Flutter → Supabase → dispatcher → Cloud Run Jobs. Facturación Google pendiente de verificación del usuario; Docker ejecuta el mismo contenedor temporalmente. No instalar/ejecutar en teléfonos ni acreditar sensores/cámara/AR físico.

## Tareas

1. Verificar dry-run exclusivo de015, aplicar migración remota y gate, desplegar delete-account con JWT, comprobar buckets/RPC/historial sin tocar push existente.
2. Construir linux/amd64 y ejecutar herramientas Hugin/Enblend reales con fixtures geométricos reproducibles (no fotos de celular), casos completos/incompletos/sin coincidencias y GPano. Registrar versiones e imagen. Corregir fallos demostrados con regresiones.
3. Preparar credenciales servidor locales ignoradas/restringidas, secreto estable, ejecutor --once/--watch con RPCs existentes, max2, CPU4/RAM8Gi/900s y validación estado DB. Mismo contenedor que Cloud Run, sin otro backend.
4. Desplegar dispatcher protegido sin Google configurado; verificar401/503 sin reclamar. No activar cron/Vault de tours; conservar FCM/push existentes.
5. Verificación remota opt-in con recursos propios temporales: TUS reanudado, pipeline, leases concurrentes, cancelación/recovery/duplicados/publicación/RLS/eliminación. Limpiar solo test IDs y medios, conservar artifacts de resultado y recibos sin secretos. Abrir resultado del contenedor en visor real.
6. Análisis/tests/builds con defines del proyecto; revisión independiente final; reporte6 secciones con comandos exactos Android/iPhone y preparación de firma. Cloud Run y pruebas físicas siguen pendientes explícitos.

## Contratos y restricciones

- Supabase ref alxdipzfunbpaywmpndi. Job futuro marea-f6a92/us-central1/marea-tour-stitch. Linux/amd64. Leases y cupos de public.tours_claim_jobs/finish/context/current, cleanup/write guards existentes.
- Runner usa servicio solo en backend/config ignorada, HMAC de job:lease, sin imprimir valores. No considera exit0 éxito: consulta contexto/recibo/estado DB. No elimina outputs ambiguos.
- Sin nuevo esquema/arquitectura, sin manipulación de cuentas/datos existentes, sin activación de tours cron/Vault mientras Google bloqueado.
- Flutter Android usa config/supabase.production.json + config/firebase.android.json; iOS/Web solo Supabase. No flavors. iOS target15/com.marea.app, Team todavía no configurado.
- Dos ejecuciones locales pueden compartir memoria total limitada de Docker: medir disponibilidad y reportar recursos nominales por contenedor sin prometer memoria física independiente. Cloud máximo2 sin cambios.
- Fixtures geométricos acreditan ejecución software únicamente; no certifican costura de fotos de celular ni AR. No marcar tested_version desde pruebas automáticas.
