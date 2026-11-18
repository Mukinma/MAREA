# Regeneración del manual MAREA

`manual-tecnico.md` es la fuente de texto. `diagramas/*.dot` son las fuentes de figuras. La edición PDF toma ambos conjuntos y actualiza los SVG con Graphviz. Las dependencias de edición son independientes de Flutter y Supabase.

## Compilación local

Desde la raíz de MAREA, con Node.js 24 y Python 3.12 disponibles, preparar las dependencias en una carpeta temporal. Las versiones Node son las usadas para producir esta edición.

```sh
marea_edicion=$(mktemp -d)
npm install --prefix "$marea_edicion" --no-save marked@17.0.5 @viz-js/viz@3.25.0
python3 -m venv "$marea_edicion/venv"
"$marea_edicion/venv/bin/pip" install 'reportlab==4.4.9'
NODE_PATH="$marea_edicion/node_modules" \
  "$marea_edicion/venv/bin/python" docs/manual-tecnico/edicion/compilar.py
```

Si las dependencias ya están instaladas, basta ejecutar `python3 docs/manual-tecnico/edicion/compilar.py` con el directorio de módulos Node en `NODE_PATH`. El compilador utiliza las fuentes Nunito Sans de `assets/fonts/` y no necesita un navegador, backend ni credenciales. El documento admite encabezados, párrafos, tablas, listas simples, bloques de código y figuras enlazadas a SVG generado desde DOT. Conservar los anclajes `cap-NN` y el bloque de índice del Markdown. El PDF genera su propio índice con los números de página finales.

## Comprobar la edición

```sh
marea_previa=$(mktemp -d)
pdfinfo docs/manual-tecnico/manual-tecnico.pdf
pdftoppm -r 120 -png docs/manual-tecnico/manual-tecnico.pdf "$marea_previa/pagina"
```

Revisar los destinos del índice y los marcadores, las tablas partidas y los pies de figura. Al añadir una figura, conservar su fuente DOT, usar un SVG con el mismo nombre base y colocar su pie inmediatamente después de la imagen en Markdown.
