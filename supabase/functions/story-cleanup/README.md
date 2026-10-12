# Limpieza de historias

`story-cleanup` elimina archivos antes de borrar sus historias vencidas o retiradas. Si Storage falla, conserva las filas para reintentarlo. También retira subidas huérfanas de más de 24 horas y snapshots vencidos de Inicio. Los recibos de publicación sobreviven a esta limpieza y se eliminan junto con la cuenta.

La función solo acepta POST con `x-story-worker-secret`, comparado con `STORY_WORKER_SECRET` de Edge. El secreto debe tener al menos 32 caracteres, generarse aleatoriamente y permanecer fuera de Flutter. `verify_jwt=false` permite al cron autenticarse mediante este secreto propio.

La migración 017 programa `marea-story-cleanup` cada hora. Su dispatcher lee dos secretos de Vault: `marea_story_cleanup_url` (URL de esta función) y `marea_story_worker_secret` (mismo valor que Edge). Nunca consultar ni registrar los valores descifrados en logs de cliente.

Despliegue: aplicar migraciones 016–019, configurar los secretos con un archivo temporal protegido usando `supabase secrets set --env-file`, guardar los dos valores en Vault y ejecutar `supabase functions deploy story-cleanup --use-api`. Eliminar el archivo temporal después de configurar. La actualización de `delete-account` incorpora también el bucket privado `story-images`.

Comprobación sin revelar secretos:

```sh
node tool/check_home_feed_contract.mjs
node --experimental-strip-types --test supabase/functions/story-cleanup/cleanup_test.ts
```

La caducidad visible ocurre a las 24 horas según la hora del servidor. El cron horario retira físicamente los archivos posteriormente.
