# Recuperar la edición 1.0

`manual-tecnico-v1.0.zip` conserva los 29 entregables previos y el archivo auxiliar `.DS_Store` encontrado, sin modificar sus bytes. Las entradas mantienen la ruta `docs/manual-tecnico/` desde la raíz del repositorio. `SHA256SUMS` verifica el ZIP; `../evidencias/linea-base.json` contiene además el hash de cada archivo original y la revisión del producto.

Desde este directorio, verificar con `shasum -a 256 -c SHA256SUMS`. Para inspeccionar la edición sin sobrescribir la v1.1:

```sh
marea_recuperacion=$(mktemp -d)
unzip manual-tecnico-v1.0.zip -d "$marea_recuperacion"
```

El PDF es autónomo. Las referencias Markdown al código requieren un checkout de la revisión y cambios locales descritos en la línea base. Para restaurar sobre una copia de ese checkout, extraer desde su raíz después de preservar cualquier edición posterior. El ZIP no contiene el código del producto ni credenciales; no sustituye conservar el árbol local de Mapbox.
