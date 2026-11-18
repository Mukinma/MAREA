const { readFileSync, writeFileSync, readdirSync } = require('node:fs');
const { join } = require('node:path');
const { marked } = require('marked');
const { instance } = require('@viz-js/viz');

async function main() {
  const root = join(__dirname, '..');
  const diagrams = join(root, 'diagramas');
  const graphviz = await instance();
  const graphs = {};
  for (const name of readdirSync(diagrams).filter((file) => file.endsWith('.dot')).sort()) {
    const svgName = name.replace(/\.dot$/, '.svg');
    const source = readFileSync(join(diagrams, name), 'utf8');
    const svg = graphviz.render(source, { format: 'svg' });
    if (svg.status !== 'success') throw new Error(JSON.stringify(svg.errors));
    writeFileSync(join(diagrams, svgName), svg.output);
    graphs[svgName] = JSON.parse(graphviz.renderString(source, { format: 'json' }));
  }
  const markdown = readFileSync(join(root, 'manual-tecnico.md'), 'utf8');
  const tokens = marked.lexer(markdown);
  process.stdout.write(JSON.stringify({ tokens, graphs }));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
