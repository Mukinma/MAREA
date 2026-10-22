import fs from 'node:fs/promises';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import assert from 'node:assert/strict';
import {Workbook,SpreadsheetFile} from '@oai/artifact-tool';
import {tasks,groups,blocks,metadata} from './data.mjs';

const repo='/Users/crisis/Proyectos/marea';
const out=path.resolve(import.meta.dirname,'..');
const support=import.meta.dirname;
const colors={navy:'#0B255E',blue:'#0D4397',aqua:'#22C5C1',mint:'#DDF5EF',paper:'#FAF9F6',white:'#FFFFFF',text:'#102149',secondary:'#66738B',border:'#D9E5F0',mist:'#EAF6FD',peach:'#FFF0DF'};
const states=['Completado','WIP','Pendiente','Bloqueado','Sustituido'];
const cols=['F','G','H','I','J','K','L','M','N','O','P','Q'];
const date=s=>s?new Date(`${s}T00:00:00Z`):null;
const nice=s=>s?s.split('-').reverse().join('/'):'Sin fecha individual comprobada';
const srcAll=[...new Set(tasks.flatMap(t=>t.sources))];
const sourceMap=new Map(srcAll.map((s,i)=>[s,`S${String(i+1).padStart(3,'0')}`]));
const ids=new Set(tasks.map(t=>t.id));
assert.equal(ids.size,tasks.length,'IDs duplicados');
assert.equal(new Set(groups.map(g=>g.id)).size,groups.length,'Grupos duplicados');
const groupIds=new Set(groups.map(g=>g.id));
const missing=[];
for(const src of srcAll){
  if(src.startsWith('git:')){
    const [,commit,...file]=src.split(':');
    try{execFileSync('git',['cat-file','-e',`${commit}:${file.join(':')}`],{cwd:repo,stdio:'ignore'});}catch{missing.push(src);}
  }else{try{await fs.access(path.join(repo,src));}catch{missing.push(src);}}
}
assert.deepEqual(missing,[],'Fuentes inexistentes');
for(const t of tasks){
  assert.ok(t.title&&t.result&&states.includes(t.state));
  assert.ok(t.start>=1&&t.end<=11&&t.start<=t.end);
  assert.equal(t.estimated,t.end-t.start+1);
  assert.ok(!t.assigned&&!t.performed,'Nombre asignado sin autorización');
  assert.equal(t.real,null); assert.equal(t.realStart,null);assert.equal(t.realEnd,null);
  for(const dep of t.deps.split(',').map(x=>x.trim()).filter(Boolean)) assert.ok(groupIds.has(dep)||ids.has(dep),`Dependencia inexistente ${dep}`);
}

// Un solo inventario genera ambos documentos; la verificación final también lee los archivos guardados.
const md=[
  '# MAREA — cronograma detallado de actividades',
  '',
  '**Periodo:** 1 de septiembre–18 de noviembre de 2026. **Corte del estado real:** 6 de octubre de 2026, America/Mexico_City.',
  '',
  `**Contenido:** ${tasks.length} subtareas en ${groups.length} grupos. Investigación, aplicación, backend, diseños, pruebas y entrega técnica.`,
  '',
  '## Cómo leer E y R',
  '',
  '- **E — Tiempo estimado:** duración propuesta en bloques y ubicación programada. Hasta el corte es una propuesta retrospectiva; después del corte es planificación futura.',
  '- **R — Tiempo real:** duración que tomó efectivamente la tarea. No se infiere de commits, fechas de informes ni tiempos de ejecución de un procesador.',
  '- Las filas R y sus duraciones quedan vacías porque las fuentes consultadas no registran intervalos laborales de ejecución por subtarea. Completado acredita resultado, no duración conocida.',
  '- Un bloque es una de las cuatro divisiones del mes. Varios trabajos pueden coincidir en un bloque; no sumar tareas paralelas para calcular la duración del proyecto. La estimación no garantiza capacidad sin asignar responsables.',
  '- Responsable asignado y Realizado por son espacios independientes para los nombres. En Excel se editan en Detalle y se reflejan en Cronograma.',
  '- Para capturar R en Excel, registrar inicio real, fin real y duración real en bloques en Detalle. Las barras R aparecerán al completar los tres datos. No sustituir la duración efectiva por el mero número de semanas con un commit.',
  '',
  '## Bloques del calendario',
  '',
  '| Mes | S1 | S2 | S3 | S4 |',
  '|---|---|---|---|---|',
  '| Septiembre | 1–7 | 8–14 | 15–21 | 22–30 |',
  '| Octubre | 1–7 | 8–14 | 15–21 | 22–31 |',
  '| Noviembre | 1–7 | 8–14 | 15–18 | Fuera del periodo |',
  '',
  '## Criterios de reconstrucción',
  '',
  'El primer commit conservado es b92a237 del 11/09; b321100 del 17/09 contiene un checkpoint WIP. La raíz pública 1c7a5d0 del 22/09 no es el inicio del desarrollo. Se revisaron ramas y cambios actuales sin commit. Los merges y checkpoints no se cuentan como nuevas funciones.',
  '',
  metadata.researchPolicy,
  '',
  'Los estados describen el resultado al corte. Completado puede significar código implementado, diseño entregado o prueba reportada, según el resultado y la fuente. Los reportes históricos se contrastaron con el piloto más reciente: push Android está activo; el piloto Docker/Supabase está verificado con fixtures sintéticos; Cloud Run y AR físico siguen pendientes. AR se conserva como WIP.',
  '',
  'Las verificaciones del desarrollo se citan como resultados documentados: esta extracción no vuelve a ejecutar pruebas de la aplicación ni cambia servicios. Las correcciones futuras son condicionales a fallos observados. Firma iOS y facturación Google conservan sus dependencias externas. No se incluye informe ni presentación académicos.',
  '',
  'Paleta del Excel: navy #0B255E, E azul #0D4397, R aqua #22C5C1, actividades mint #DDF5EF, blanco/Paper #FAF9F6 y cuadrícula #D9E5F0.',
  '',
  '## Índice de etapas',
  '',
  '| ID | Grupo | Subtareas | Bloques E |',
  '|---|---|---:|---|',
  ...groups.map(g=>`| ${g.id} | ${g.name} | ${tasks.filter(t=>t.parent===g.id).length} | ${blocks[g.start-1][0]}${g.end!==g.start?' a '+blocks[g.end-1][0]:''} |`),
  '',
];
for(const g of groups){
  md.push(`## ${g.id} — ${g.name}`,'');
  if(g.note)md.push(g.note,'');
  for(const t of tasks.filter(x=>x.parent===g.id)){
    const a=blocks[t.start-1],b=blocks[t.end-1];
    md.push(`### ${t.id} — ${t.title}`,'',
      `**Estado:** ${t.state}. **Tarea superior:** ${t.parent}.`,
      '',t.result,'',
      '| Tiempo | Inicio | Fin | Duración en bloques |',
      '|---|---|---|---:|',
      `| E — Estimado | ${nice(a[4])} (${a[0]}) | ${nice(b[5])} (${b[0]}) | ${t.estimated} |`,
      '| R — Real |  |  |  |','',
      '**Responsable asignado:** ____________________. **Realizado por:** ____________________.','',
      `**Dependencias técnicas:** ${t.deps||'Sin dependencia identificada'}.`,
      '',`**Fecha de evidencia:** ${nice(t.date)}. **Fuentes:** ${t.sources.map(s=>sourceMap.get(s)).join(', ')}.`,
      '');
    if(t.pending)md.push(`**Para cerrar o completar el registro:** ${t.pending}`,'');
    if(t.note&&t.note!==g.note)md.push(`**Observación:** ${t.note}`,'');
  }
}
md.push('## Referencias verificables','',
  'Las referencias siguientes identifican archivos realmente presentes o archivos disponibles en el commit indicado. Las fuentes compartidas describen el grupo y sus subtareas; una fecha de evidencia no se convierte en inicio o duración real.','');
for(const [src,id]of sourceMap){
  if(src.startsWith('git:')){
    const [,commit,...file]=src.split(':');const p=file.join(':');
    md.push(`- **${id}:** commit \`${commit}\`, archivo \`${p}\`. Consulta exacta: \`git show ${commit}:${p}\`.`);
  }else md.push(`- **${id}:** [${src}](${path.join(repo,src).replaceAll(' ','%20')}).`);
}
await fs.writeFile(path.join(out,'marea-avances-detallados.md'),md.join('\n')+'\n');
await fs.writeFile(path.join(support,'inventory.json'),JSON.stringify({metadata,groups,tasks,sourceMap:[...sourceMap]},null,2));

const wb=Workbook.create();
const schedule=wb.worksheets.add('Cronograma');
const detail=wb.worksheets.add('Detalle');
schedule.showGridLines=false; detail.showGridLines=false;
schedule.tabColor=colors.navy;detail.tabColor=colors.blue;
const totalRows=9+groups.length+tasks.length*2;
const detailLast=8+tasks.length;
function base(sheet,range){
  sheet.getRange(range).format={font:{name:'Arial',size:10,color:colors.text},verticalAlignment:'center',fill:colors.white};
}
base(schedule,`A1:S${totalRows}`);base(detail,`A1:U${detailLast}`);
function merged(sheet,r,text,format={}){
  sheet.mergeCells(r);sheet.getRange(r).values=[[text]];sheet.getRange(r).format={verticalAlignment:'center',...format};
}
merged(schedule,'A2:S2','MAREA · Cronograma detallado de actividades',{font:{name:'Arial',size:15,bold:true,color:colors.navy}});
merged(schedule,'A3:S3','01 septiembre–18 noviembre 2026 | Estado al 06 octubre | Bloques de calendario, no horas',{font:{name:'Arial',size:10,color:colors.secondary}});
merged(schedule,'A4:S4','R = tiempo que tomó la tarea. Sin intervalo documentado, R queda vacía. Fechas de commits y reportes están en Detalle.',{wrapText:true,font:{name:'Arial',size:10,color:colors.text}});
merged(schedule,'A5:E5',`${tasks.length} subtareas · ${groups.length} grupos`,{font:{name:'Arial',size:10,bold:true,color:colors.navy}});
merged(schedule,'F5:I5','E · Duración estimada',{fill:colors.blue,font:{name:'Arial',size:10,color:colors.white,bold:true},horizontalAlignment:'center'});
merged(schedule,'J5:M5','R · Duración real',{fill:colors.aqua,font:{name:'Arial',size:10,color:colors.text,bold:true},horizontalAlignment:'center'});
merged(schedule,'N5:S5','Nombres editables en Detalle',{fill:colors.peach,font:{name:'Arial',size:10,color:colors.text},horizontalAlignment:'center'});
for(const [range,label]of [['A6:A9','ID'],['B6:B9','ACTIVIDAD'],['C6:C9','E/R'],['D6:D9','Tiempo\n(bloques)'],['E6:E9','Estado'],['R6:R9','Responsable\nasignado'],['S6:S9','Realizado\npor']]){
  merged(schedule,range,label,{fill:colors.navy,font:{name:'Arial',size:10,bold:true,color:colors.white},horizontalAlignment:'center',wrapText:true});
}
for(const [range,label]of [['F6:I6','SEPTIEMBRE'],['J6:M6','OCTUBRE'],['N6:Q6','NOVIEMBRE']])
  merged(schedule,range,label,{fill:colors.navy,font:{name:'Arial',size:10,bold:true,color:colors.white},horizontalAlignment:'center'});
schedule.getRange('F7:Q7').values=[blocks.map(b=>b[2])];
schedule.getRange('F8:Q8').values=[blocks.map(b=>date(b[4]))];
schedule.getRange('F9:Q9').values=[blocks.map(b=>date(b[5]))];
schedule.getRange('F7:Q9').format={fill:colors.mist,font:{name:'Arial',size:10,color:colors.navy},horizontalAlignment:'center'};
schedule.getRange('F8:Q8').setNumberFormat('dd');schedule.getRange('F9:Q9').setNumberFormat('dd mmm');
schedule.getRange('Q8:Q9').values=[['Fuera'],['de plazo']];
schedule.getRange(`A6:S${totalRows}`).format.borders={preset:'all',style:'thin',color:colors.border};
schedule.getRange('A1:S1').format.rowHeight=10;
schedule.getRange('A2:S2').format.rowHeight=26;
schedule.getRange('A3:S3').format.rowHeight=20;
schedule.getRange('A4:S4').format.rowHeight=25;
schedule.getRange('A5:S5').format.rowHeight=23;
schedule.getRange('A6:S6').format.rowHeight=22;
schedule.getRange('A7:S9').format.rowHeight=17;
schedule.getRange(`A10:S${totalRows}`).format.rowHeight=16;
schedule.getRange(`A1:A${totalRows}`).format.columnWidth=11;
schedule.getRange(`B1:B${totalRows}`).format.columnWidth=56;
schedule.getRange(`C1:C${totalRows}`).format.columnWidth=4;
schedule.getRange(`D1:D${totalRows}`).format.columnWidth=9;
schedule.getRange(`E1:E${totalRows}`).format.columnWidth=14;
schedule.getRange(`F1:Q${totalRows}`).format.columnWidth=6;
schedule.getRange(`R1:S${totalRows}`).format.columnWidth=19;
schedule.getRange(`F10:P${totalRows}`).setNumberFormat(';;;');

merged(detail,'A2:U2','MAREA · Detalle de actividades y evidencia',{font:{name:'Arial',size:15,bold:true,color:colors.navy}});
merged(detail,'A3:U3',`${tasks.length} registros. Fecha de evidencia acredita avance; no determina duración real. Estados con pruebas citadas son reportados, no reejecutados.`,{font:{name:'Arial',size:10,color:colors.secondary}});
merged(detail,'A4:U4','Editar fechas E, fechas R, duración R y nombres aquí. Las barras R requieren inicio, fin y duración efectiva registrados.',{font:{name:'Arial',size:10,color:colors.text}});
merged(detail,'A5:U5','E es propuesta retrospectiva/futura. Investigación realizada según confirmación general del usuario; el desglose temático individual requiere confirmación.',{font:{name:'Arial',size:10,color:colors.text}});
merged(detail,'A6:U6','No sumar bloques de tareas paralelas como duración del proyecto. Las correcciones futuras solo se ejecutan si las pruebas revelan fallos.',{font:{name:'Arial',size:10,color:colors.text}});
const headings=['ID','Etapa / módulo','Tarea superior','Actividad','Resultado / entregable','Estado al corte','E inicio','E fin','E bloques','R inicio','R fin','R bloques','Responsable asignado','Realizado por','Fecha de evidencia','Tipo de evidencia','Dependencias técnicas','Para cerrar / completar','Observaciones','Fuentes ID','Referencias verificables'];
detail.getRange('A8:U8').values=[headings];
detail.getRange('A8:U8').format={fill:colors.navy,font:{name:'Arial',size:10,color:colors.white,bold:true},wrapText:true,horizontalAlignment:'center',rowHeight:34};
function evidenceType(t){
  if(t.parent.startsWith('INV'))return 'Confirmación general del usuario; desglose por confirmar';
  if(t.date===null)return t.start>5?'Plan propuesto, sin ejecución':'Archivo sin fecha individual explícita';
  if(t.date===metadata.cutoff)return 'Reporte/inspección del checkout al corte';
  if(t.sources.some(s=>s.startsWith('git:')))return 'Commit de integración y documentos';
  return 'Reporte fechado y código asociado';
}
const rows=tasks.map(t=>[t.id,t.group,t.parent,t.title,t.result,t.state,date(blocks[t.start-1][4]),date(blocks[t.end-1][5]),null,
  null,null,null,'','',date(t.date),evidenceType(t),t.deps||'Sin dependencia identificada',t.pending,t.note,
  t.sources.map(s=>sourceMap.get(s)).join(', '),t.sources.join('\n')]);
detail.getRange(`A9:U${detailLast}`).values=rows;
detail.getRange(`A9:U${detailLast}`).format={rowHeight:78,wrapText:true,verticalAlignment:'top'};
detail.getRange(`A9:C${detailLast}`).format.fill=colors.mint;
detail.getRange(`G9:H${detailLast}`).format.fill=colors.mist;
detail.getRange(`J9:N${detailLast}`).format.fill=colors.peach;
for(const c of ['G','H','J','K','O'])detail.getRange(`${c}9:${c}${detailLast}`).setNumberFormat('dd/mm/yyyy');
detail.getRange(`I9:I${detailLast}`).setNumberFormat('0');
detail.getRange(`L9:L${detailLast}`).setNumberFormat('0.0');
detail.getRange(`F9:F${detailLast}`).dataValidation={rule:{type:'list',values:states}};
detail.getRange(`A8:U${detailLast}`).format.borders={preset:'all',style:'thin',color:colors.border};
const widths={A:12,B:38,C:14,D:55,E:75,F:15,G:13,H:13,I:12,J:13,K:13,L:12,M:23,N:23,O:16,P:44,Q:38,R:64,S:95,T:24,U:100};
for(const[c,w]of Object.entries(widths))detail.getRange(`${c}1:${c}${detailLast}`).format.columnWidth=w;
for(let i=0;i<rows.length;i++){
  const maxLines=Math.max(...rows[i].map((v,j)=>{
    if(typeof v!=='string'||!v)return 1;
    const width=Object.values(widths)[j];
    return v.split('\n').reduce((n,line)=>n+Math.max(1,Math.ceil(line.length/(width*0.8))),0);
  }));
  detail.getRange(`A${i+9}:U${i+9}`).format.rowHeight=Math.max(36,maxLines*12+8);
}
detail.getRange('A1:U1').format.rowHeight=10;
detail.getRange('A2:U2').format.rowHeight=26;
detail.getRange('A3:U6').format.rowHeight=20;
detail.getRange('A7:U7').format.rowHeight=8;
const detailTable=detail.tables.add(`A8:U${detailLast}`,true,'MareaActivities');
detailTable.showFilterButton=true;detailTable.style='TableStyleLight1';

const durationFormulas=tasks.map((t,i)=>{
  const r=i+9;
  return [`=IF(OR(G${r}="",H${r}=""),"",SUMPRODUCT(('Cronograma'!$F$8:$P$8<=H${r})*('Cronograma'!$F$9:$P$9>=G${r})))`];
});
detail.getRange(`I9:I${detailLast}`).formulas=durationFormulas;

let row=10;
const scheduleMap=[];const groupRows=[];const pageBreaks=[];let bodyOnPage=0;
for(const g of groups){
  if(bodyOnPage+3>34){pageBreaks.push(row-1);bodyOnPage=0;}
  const band=row++;
  merged(schedule,`A${band}:S${band}`,`${g.id} · ${g.name}`,{fill:colors.navy,font:{name:'Arial',size:10,bold:true,color:colors.white}});
  schedule.getRange(`A${band}:S${band}`).format.rowHeight=20;bodyOnPage++;
  const first=row;
  for(const t of tasks.filter(x=>x.parent===g.id)){
    if(bodyOnPage+2>34){pageBreaks.push(row-1);bodyOnPage=0;}
    const e=row,r=row+1;const dr=tasks.indexOf(t)+9;
    merged(schedule,`A${e}:A${r}`,t.id,{fill:colors.mint,font:{name:'Arial',size:10,color:colors.navy},horizontalAlignment:'center'});
    merged(schedule,`B${e}:B${r}`,t.title,{fill:colors.mint,font:{name:'Arial',size:10,color:colors.text},wrapText:true});
    merged(schedule,`E${e}:E${r}`,'',{fill:colors.paper,horizontalAlignment:'center',wrapText:true});
    schedule.getRange(`E${e}`).formulas=[[`='Detalle'!F${dr}`]];
    schedule.getRange(`C${e}:C${r}`).values=[['E'],['R']];
    schedule.getRange(`C${e}:D${r}`).format.horizontalAlignment='center';
    schedule.getRange(`C${e}`).format.font={name:'Arial',size:10,bold:true,color:colors.blue};
    schedule.getRange(`C${r}`).format.font={name:'Arial',size:10,bold:true,color:colors.aqua};
    schedule.getRange(`D${e}`).formulas=[[`='Detalle'!I${dr}`]];
    schedule.getRange(`D${r}`).formulas=[[`=IF('Detalle'!L${dr}="","",'Detalle'!L${dr})`]];
    schedule.getRange(`D${e}`).setNumberFormat('0');
    schedule.getRange(`D${r}`).setNumberFormat('0.0');
    for(const[c,dc]of[['R','M'],['S','N']]){
      merged(schedule,`${c}${e}:${c}${r}`,'',{fill:colors.peach,wrapText:true});
      schedule.getRange(`${c}${e}`).formulas=[[`=IF('Detalle'!${dc}${dr}="","",'Detalle'!${dc}${dr})`]];
    }
    schedule.getRange(`F${e}:P${e}`).formulas=[cols.slice(0,11).map(c=>`=IF(AND(${c}$8<='Detalle'!$H${dr},${c}$9>='Detalle'!$G${dr}),1,"")`)];
    schedule.getRange(`F${r}:P${r}`).formulas=[cols.slice(0,11).map(c=>`=IF(OR('Detalle'!$J${dr}="",'Detalle'!$K${dr}="",'Detalle'!$L${dr}=""),"",IF(AND(${c}$8<='Detalle'!$K${dr},${c}$9>='Detalle'!$J${dr}),1,""))`)];
    schedule.getRange(`Q${e}:Q${r}`).format.fill=colors.border;
    scheduleMap.push({id:t.id,e,r,detailRow:dr});row+=2;bodyOnPage+=2;
  }
  groupRows.push({id:g.id,name:g.name,band,first,last:row-1});
}
assert.equal(row-1,totalRows);
schedule.getRange(`F10:P${totalRows}`).conditionalFormats.addCustom('AND($C10="E",F10=1)',{fill:colors.blue});
schedule.getRange(`F10:P${totalRows}`).conditionalFormats.addCustom('AND($C10="R",F10=1)',{fill:colors.aqua});
schedule.freezePanes.freezeRows(9);schedule.freezePanes.freezeColumns(3);
detail.freezePanes.freezeRows(8);detail.freezePanes.freezeColumns(4);

wb.recalculate();
const firstCheck=await wb.inspect({kind:'region',sheetId:'Detalle',range:'F9:P12',maxChars:1600,tableMaxRows:4,tableMaxCols:11});
console.log(firstCheck.ndjson);
const errors=await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:50},maxChars:1400});
console.log(errors.ndjson);

// Verificación de valores y matriz de barras de todas las subtareas, no solo una muestra.
const gotDetail=detail.getRange(`A9:U${detailLast}`).values;
const gotGrid=schedule.getRange(`A10:S${totalRows}`).values;
let realBars=0,estimatedBars=0;
for(let i=0;i<tasks.length;i++){
  const t=tasks[i],d=gotDetail[i],m=scheduleMap[i];
  assert.equal(d[0],t.id);assert.equal(d[3],t.title);assert.equal(d[4],t.result);assert.equal(d[5],t.state);
  assert.equal(d[8],t.estimated,`Duración E ${t.id}`);
  assert.ok(d[9]===null||d[9]==='');assert.ok(d[10]===null||d[10]==='');assert.ok(d[11]===null||d[11]==='');
  assert.ok(d[12]===null||d[12]==='');assert.ok(d[13]===null||d[13]==='');
  const er=gotGrid[m.e-10],rr=gotGrid[m.r-10];
  assert.equal(er[3],t.estimated);assert.ok(rr[3]===null||rr[3]==='');
  for(let j=0;j<11;j++){
    assert.equal(er[j+5]===1,j>=t.start-1&&j<=t.end-1,`Barra E ${t.id} ${j}`);
    assert.ok(rr[j+5]===null||rr[j+5]==='',`Barra R inventada ${t.id}`);
    if(er[j+5]===1)estimatedBars++;if(rr[j+5]===1)realBars++;
  }
}
assert.equal(realBars,0);
const mdText=await fs.readFile(path.join(out,'marea-avances-detallados.md'),'utf8');
const mdIds=[...mdText.matchAll(/^### ([A-Z0-9]+\.\d{3}) — /gm)].map(m=>m[1]);
assert.deepEqual(mdIds,tasks.map(t=>t.id),'Inventarios Excel/Markdown distintos');
// Comprobar edición de nombres y R, sin conservar datos de prueba en la entrega.
detail.getRange('J9:L9').values=[[date('2026-09-01'),date('2026-09-07'),1]];
detail.getRange('M9:N9').values=[['Nombre de prueba','Ejecutor de prueba']];wb.recalculate();
const first=scheduleMap[0];
assert.equal(schedule.getRange(`F${first.r}`).values[0][0],1);
assert.equal(schedule.getRange(`D${first.r}`).values[0][0],1);
assert.equal(schedule.getRange(`R${first.e}`).values[0][0],'Nombre de prueba');
assert.equal(schedule.getRange(`S${first.e}`).values[0][0],'Ejecutor de prueba');
detail.getRange('J9:N9').values=[[null,null,null,'','']];wb.recalculate();
assert.ok(!schedule.getRange(`F${first.r}`).values[0][0]);
assert.ok(!schedule.getRange(`R${first.e}`).values[0][0]);

const workbook=await SpreadsheetFile.exportXlsx(wb);
await workbook.save(path.join(out,'marea-avances-gantt.xlsx'));
await fs.writeFile(path.join(support,'layout.json'),JSON.stringify({totalRows,detailLast,scheduleMap,groupRows,pageBreaks,blocks,colors},null,2));

// Render de todos los grupos y muestras representativas de ambas hojas.
await fs.mkdir(path.join(support,'previews'),{recursive:true});
let rendered=0;
for(const g of groupRows){
  const png=await wb.render({sheetName:'Cronograma',range:`A${g.band}:S${g.last}`,scale:1,format:'png'});
  await fs.writeFile(path.join(support,'previews',`${g.id}.png`),new Uint8Array(await png.arrayBuffer()));
  rendered++;if(rendered%10===0)console.log(`Renderizados ${rendered}/${groupRows.length} grupos`);
}
for(const [name,sheet,range]of[
  ['cronograma-inicio','Cronograma','A1:S22'],
  ['detalle-inicio','Detalle','A8:I13'],
  ['detalle-reales','Detalle','J8:P13'],
  ['detalle-evidencia','Detalle','Q8:U12'],
]){
  const png=await wb.render({sheetName:sheet,range,scale:1.3,format:'png'});
  await fs.writeFile(path.join(support,'previews',`${name}.png`),new Uint8Array(await png.arrayBuffer()));
}
const report={tasks:tasks.length,groups:groups.length,sources:srcAll.length,estimatedBars,realBars,
  statuses:tasks.reduce((a,t)=>(a[t.state]=(a[t.state]||0)+1,a),{}),
  sourceExistence:'verified',inventoryMatch:'verified',namesBlank:'verified',realTimesBlank:'verified',
  editPropagation:'verified',renderedGroups:rendered,exported:true};
await fs.writeFile(path.join(support,'verification.json'),JSON.stringify(report,null,2));
console.log(JSON.stringify(report));
