import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import {Workbook,SpreadsheetFile} from '@oai/artifact-tool';
import {tasks,stages,blocks,metadata,team,shortModules} from './data.mjs';
const support=import.meta.dirname,out=path.resolve(support,'..'),repo='/Users/crisis/Proyectos/marea';
const C={navy:'#0B255E',blue:'#0D4397',aqua:'#22C5C1',mint:'#DDF5EF',paper:'#FAF9F6',text:'#102149',border:'#D9E5F0',white:'#FFFFFF',mist:'#EAF6FD',peach:'#FFF0DF'};
const date=s=>s?new Date(s+'T00:00:00Z'):null;
const nice=s=>s?s.split('-').reverse().join('/'):'Sin fecha individual documentada';
const cols=['G','H','I','J','K','L','M','N','O','P','Q','R'];
const sources=[...new Set(tasks.flatMap(t=>t.sources))];
assert.equal(tasks.length,142);assert.equal(new Set(tasks.map(t=>t.id)).size,142);
assert.equal(new Set(tasks.map(t=>t.title)).size,142);
for(const s of sources){
 if(s.startsWith('git:')){const [,rev,...p]=s.split(':');execFileSync('git',['cat-file','-e',rev+':'+p.join(':')],{cwd:repo,stdio:'ignore'});}
 else await fs.access(path.join(repo,s));
}
for(const t of tasks){
 assert.ok(t.start>=1&&t.end<=11&&t.start<=t.end);
 assert.ok(team[t.assigned]);assert.equal(t.performed,'');
 if(t.deps)assert.ok(tasks.find(p=>p.id===t.deps&&p.end<=t.start));
 assert.equal(t.real,t.state==='Completado'?t.estimated:null);
}
await fs.writeFile(path.join(support,'inventory.json'),JSON.stringify({metadata,team,stages,tasks,blocks},null,2));
const md=['# MAREA — cronograma compacto','',`**Periodo:** ${metadata.period}. **Corte de estados:** 6 de octubre de 2026.`,`**Contenido:** 142 tareas, seis etapas, nueve módulos y tareas transversales. El cronograma de Excel ocupa 299 filas.`, '',
 '## Lectura del cronograma','',
 '**E:** tiempo estimado en bloques semanales. **R:** tareas completadas alineadas en los mismos bloques que E, conforme al criterio solicitado. Las tareas WIP y pendientes tienen solo E. Esta alineación no es una medición de horas ni de duración efectiva de trabajo.',
 metadata.planning,metadata.roster,'La investigación está completada según la confirmación general del usuario. Su distribución semanal se propone retrospectivamente. No se incluyen informe ni presentación académicos.','',
 '## Equipo y responsabilidades','', '| Persona | Especialidad indicada |','|---|---|',...Object.entries(team).map(([n,r])=>`| ${n} | ${r} |`),'',
 'El reparto de actividades es una propuesta por especialidad. Fatima cubre interfaces del cliente; Cristopher cubre acceso, servicios y despliegues; Alan cubre datos y contratos SQL. Santiago y Ximena cubren coordinación, captura y validación AR. Josefina cubre investigación, planeación y consolidación técnica.','',
 '## Bloques del calendario','', '| Bloque | Fechas |','|---|---|',...blocks.map(b=>`| ${b[0]} | ${b[3]} |`),''];
const escape=v=>String(v??'').replaceAll('|','\\|').replaceAll('\n','; ');
for(const s of stages){
 md.push(`## ${s.id} — ${s.name}`,'');
 for(const t of tasks.filter(t=>t.stage===s.id)){
  md.push(`### ${t.id} — ${t.title}`,'',`**Módulo:** ${t.moduleName}. **Estado:** ${t.state}.`,
   `**Responsable asignado:** ${t.assigned}. **Especialidad:** ${t.role}. **Realizado por:** ____________________.`,
   `**Resultado:** ${t.result}`,'',
   '| Fila | Tiempo (bloques) | '+blocks.map(b=>b[0]).join(' | ')+' |',
   '|---|---:|'+blocks.map(()=>'---').join('|')+'|',
   '| E | '+t.estimated+' | '+blocks.map((b,i)=>i===11?'Deshabilitada':i>=t.start-1&&i<=t.end-1?'■':'').join(' | ')+' |',
   '| R | '+(t.real??'')+' | '+blocks.map((b,i)=>i===11?'Deshabilitada':t.state==='Completado'&&i>=t.start-1&&i<=t.end-1?'■':'').join(' | ')+' |','',
   `**E inicio:** ${nice(blocks[t.start-1][4])}. **E fin:** ${nice(blocks[t.end-1][5])}.`,
   `**Fecha de evidencia:** ${nice(t.date)}. **Dependencia:** ${t.deps||'Sin dependencia previa especificada'}.`,
   `**Para cerrar:** ${t.close}`,`**Observación:** ${t.note}`,
   `**Fuentes:** ${t.sources.map(s=>s.startsWith('git:')?'`'+s+'`':`[${s}](${path.join(repo,s).replaceAll(' ','%20')})`).join('; ')}.`,'');
 }
}
await fs.writeFile(path.join(out,'cronograma-marea-compacto.md'),md.join('\n')+'\n');
const wb=Workbook.create(),schedule=wb.worksheets.add('Cronograma'),detail=wb.worksheets.add('Detalle');
const totalRows=9+stages.length+2*tasks.length,detailLast=8+tasks.length;
const merged=(sh,r,v,f={})=>{sh.mergeCells(r);sh.getRange(r).values=[[v]];sh.getRange(r).format={verticalAlignment:'center',...f};};
for(const[sh,last,end]of[[schedule,totalRows,'T'],[detail,detailLast,'R']]){
 sh.showGridLines=false;sh.tabColor=C.navy;
 sh.getRange(`A1:${end}${last}`).format={font:{name:'Arial',size:10,color:C.text},fill:C.white,verticalAlignment:'center',wrapText:true};
}
merged(schedule,'A2:T2','MAREA — Cronograma por etapas y responsables',{font:{name:'Arial',size:16,bold:true,color:C.navy}});
merged(schedule,'A3:T3','01 septiembre–18 noviembre 2026. Estado al 06 octubre. 142 tareas. 299 filas.',{font:{name:'Arial',size:10,color:C.text}});
merged(schedule,'A4:T4','R = completado en los mismos bloques que E. Alineación semanal solicitada; no es duración de esfuerzo medida. WIP y Pendiente: solo E.',{font:{name:'Arial',size:10,color:C.text}});
merged(schedule,'A5:F5','Responsables propuestos. Nombres y estados editables en Detalle.',{fill:C.peach,font:{name:'Arial',size:10,color:C.text}});
merged(schedule,'G5:J5','E — Tiempo estimado',{fill:C.blue,font:{name:'Arial',size:10,color:C.white,bold:true},horizontalAlignment:'center'});
merged(schedule,'K5:N5','R — Tiempo real',{fill:C.aqua,font:{name:'Arial',size:10,color:C.text,bold:true},horizontalAlignment:'center'});
merged(schedule,'O5:T5','AR en WIP. Cloud Run pendiente.',{fill:C.mint,font:{name:'Arial',size:10,color:C.text},horizontalAlignment:'center'});
for(const[r,v]of[['A6:A9','ID'],['B6:B9','Módulo'],['C6:C9','Actividad'],['D6:D9','E/R'],['E6:E9','Tiempo\n(bloques)'],['F6:F9','Estado'],['S6:S9','Responsable\nasignado'],['T6:T9','Realizado\npor']])merged(schedule,r,v,{fill:C.navy,font:{name:'Arial',size:10,color:C.white,bold:true},horizontalAlignment:'center'});
for(const[r,v]of[['G6:J6','SEPTIEMBRE'],['K6:N6','OCTUBRE'],['O6:R6','NOVIEMBRE']])merged(schedule,r,v,{fill:C.navy,font:{name:'Arial',size:10,color:C.white,bold:true},horizontalAlignment:'center'});
schedule.getRange('G7:R7').values=[blocks.map(b=>b[2])];
schedule.getRange('G8:R8').values=[blocks.map(b=>date(b[4]))];schedule.getRange('G9:R9').values=[blocks.map(b=>date(b[5]))];
schedule.getRange('G7:R9').format={fill:C.mist,horizontalAlignment:'center'};
schedule.getRange('G8:R8').setNumberFormat('dd');schedule.getRange('G9:R9').setNumberFormat('dd mmm');
schedule.getRange('R8:R9').values=[['Fuera'],['de plazo']];
schedule.getRange(`A6:T${totalRows}`).format.borders={preset:'all',style:'thin',color:C.border};
schedule.getRange(`A10:T${totalRows}`).format.rowHeight=17;
for(const[r,h]of[['A1:T1',8],['A2:T2',28],['A3:T3',20],['A4:T4',27],['A5:T5',27],['A6:T6',23],['A7:T9',17]])schedule.getRange(r).format.rowHeight=h;
for(const[c,w]of Object.entries({A:10,B:20,C:49,D:4,E:9,F:14,G:6,H:6,I:6,J:6,K:6,L:6,M:6,N:6,O:6,P:6,Q:6,R:6,S:18,T:18}))schedule.getRange(`${c}1:${c}${totalRows}`).format.columnWidth=w;
schedule.getRange(`G10:Q${totalRows}`).setNumberFormat(';;;');
merged(detail,'A2:R2','MAREA — Detalle de tareas, responsables y evidencia',{font:{name:'Arial',size:16,bold:true,color:C.navy}});
merged(detail,'A3:R3',metadata.realRule,{font:{name:'Arial',size:10,color:C.text}});
merged(detail,'A4:R4','Editar Estado, E inicio, E fin y nombres aquí. E/R y barras se actualizan en Cronograma. Realizado por admite el nombre confirmado.',{font:{name:'Arial',size:10,color:C.text}});
merged(detail,'A5:R5',metadata.planning+' '+metadata.roster,{font:{name:'Arial',size:10,color:C.text}});
merged(detail,'A6:R6','Equipo: '+Object.entries(team).map(([n,r])=>n+' ('+r+')').join('; '),{font:{name:'Arial',size:10,color:C.text}});
const heads=['ID','Etapa','Módulo','Actividad','Resultado / entregable','Estado','E inicio','E fin','E bloques','R bloques','Especialidad','Responsable asignado','Realizado por','Fecha de evidencia','Dependencias','Para cerrar','Observaciones','Fuentes verificables'];
detail.getRange('A8:R8').values=[heads];detail.getRange('A8:R8').format={fill:C.navy,font:{name:'Arial',size:10,bold:true,color:C.white},rowHeight:35,horizontalAlignment:'center'};
detail.getRange(`A9:R${detailLast}`).values=tasks.map(t=>[t.id,t.stageName,t.moduleName,t.title,t.result,t.state,date(blocks[t.start-1][4]),date(blocks[t.end-1][5]),null,null,t.role,t.assigned,t.performed,date(t.date),t.deps||'',t.close,t.note,t.sources.join('\n')]);
detail.getRange(`A8:R${detailLast}`).format.borders={preset:'all',style:'thin',color:C.border};
detail.getRange(`A9:D${detailLast}`).format.fill=C.mint;detail.getRange(`G9:J${detailLast}`).format.fill=C.mist;detail.getRange(`L9:M${detailLast}`).format.fill=C.peach;
for(const c of['G','H','N'])detail.getRange(`${c}9:${c}${detailLast}`).setNumberFormat('dd/mm/yyyy');
detail.getRange(`I9:J${detailLast}`).setNumberFormat('0');
detail.getRange(`F9:F${detailLast}`).dataValidation={rule:{type:'list',values:['Completado','WIP','Pendiente']}};
for(const c of['L','M'])detail.getRange(`${c}9:${c}${detailLast}`).dataValidation={rule:{type:'list',values:Object.keys(team)}};
const widths={A:10,B:38,C:30,D:52,E:68,F:14,G:13,H:13,I:10,J:10,K:26,L:21,M:21,N:17,O:16,P:68,Q:85,R:90};
for(const[c,w]of Object.entries(widths))detail.getRange(`${c}1:${c}${detailLast}`).format.columnWidth=w;
detail.getRange(`A9:R${detailLast}`).format.verticalAlignment='top';
for(let i=0;i<tasks.length;i++){
 const t=tasks[i],lines=Math.max(t.sources.length,t.sources.reduce((a,s)=>a+Math.ceil(s.length/75),0),Math.ceil(t.note.length/70),3);
 detail.getRange(`A${i+9}:R${i+9}`).format.rowHeight=Math.max(46,lines*12+8);
}
detail.getRange('A1:R1').format.rowHeight=8;detail.getRange('A2:R2').format.rowHeight=28;detail.getRange('A3:R6').format.rowHeight=23;
detail.getRange(`I9:I${detailLast}`).formulas=tasks.map((_,i)=>{const r=i+9;return[`=IF(OR(G${r}="",H${r}=""),"",SUMPRODUCT(('Cronograma'!$G$8:$Q$8<=H${r})*('Cronograma'!$G$9:$Q$9>=G${r})))`];});
detail.getRange(`J9:J${detailLast}`).formulas=tasks.map((_,i)=>{const r=i+9;return[`=IF(F${r}="Completado",I${r},"")`];});
const table=detail.tables.add(`A8:R${detailLast}`,true,'MareaCompactTasks');table.showFilterButton=true;table.style='TableStyleLight1';
const scheduleMap=[],stageRows=[],pageBreaks=[];let row=10,onPage=0;
for(const s of stages){
 if(onPage+3>34){pageBreaks.push(row-1);onPage=0;}
 const band=row++;merged(schedule,`A${band}:T${band}`,s.id+' — '+s.name,{fill:C.navy,font:{name:'Arial',size:11,bold:true,color:C.white}});schedule.getRange(`A${band}:T${band}`).format.rowHeight=23;onPage++;
 for(const t of tasks.filter(t=>t.stage===s.id)){
  if(onPage+2>34){pageBreaks.push(row-1);onPage=0;}
  const e=row,r=row+1,d=tasks.indexOf(t)+9;
  for(const[c,v]of[['A',t.id],['B',shortModules[t.module]],['C',t.title]])merged(schedule,`${c}${e}:${c}${r}`,v,{fill:C.mint,font:{name:'Arial',size:10,color:C.text}});
  for(const[c,dc]of[['F','F'],['S','L'],['T','M']]){merged(schedule,`${c}${e}:${c}${r}`,'',{fill:c==='F'?C.paper:C.peach});schedule.getRange(`${c}${e}`).formulas=[[`=IF('Detalle'!${dc}${d}="","",'Detalle'!${dc}${d})`]];}
  schedule.getRange(`D${e}:D${r}`).values=[['E'],['R']];schedule.getRange(`D${e}:E${r}`).format.horizontalAlignment='center';
  schedule.getRange(`D${e}`).format.font={name:'Arial',size:10,bold:true,color:C.blue};schedule.getRange(`D${r}`).format.font={name:'Arial',size:10,bold:true,color:C.aqua};
  schedule.getRange(`E${e}`).formulas=[[`=IF('Detalle'!I${d}="","",'Detalle'!I${d})`]];schedule.getRange(`E${r}`).formulas=[[`=IF('Detalle'!J${d}="","",'Detalle'!J${d})`]];
  schedule.getRange(`E${e}:E${r}`).setNumberFormat('0');
  schedule.getRange(`G${e}:Q${e}`).formulas=[cols.slice(0,11).map(c=>`=IF(OR('Detalle'!$G${d}="",'Detalle'!$H${d}=""),"",IF(AND(${c}$8<='Detalle'!$H${d},${c}$9>='Detalle'!$G${d}),1,""))`)];
  schedule.getRange(`G${r}:Q${r}`).formulas=[cols.slice(0,11).map(c=>`=IF(AND('Detalle'!$F${d}="Completado",${c}${e}=1),1,"")`)];
  schedule.getRange(`R${e}:R${r}`).format.fill=C.border;
  scheduleMap.push({id:t.id,e,r,detailRow:d});row+=2;onPage+=2;
 }
 stageRows.push({id:s.id,band,last:row-1});
}
assert.equal(row-1,299);
schedule.getRange(`G10:Q${totalRows}`).conditionalFormats.addCustom('AND($D10="E",G10=1)',{fill:C.blue});
schedule.getRange(`G10:Q${totalRows}`).conditionalFormats.addCustom('AND($D10="R",G10=1)',{fill:C.aqua});
schedule.freezePanes.freezeRows(9);schedule.freezePanes.freezeColumns(3);detail.freezePanes.freezeRows(8);detail.freezePanes.freezeColumns(4);
wb.recalculate();
const check=()=>{
 const ds=detail.getRange(`A9:R${detailLast}`).values,gs=schedule.getRange(`A10:T${totalRows}`).values;
 for(let i=0;i<tasks.length;i++){
  const t=tasks[i],m=scheduleMap[i],d=ds[i],e=gs[m.e-10],r=gs[m.r-10];
  assert.equal(d[0],t.id);assert.equal(d[3],t.title);assert.equal(d[4],t.result);assert.equal(d[5],t.state);assert.equal(d[8],t.estimated);assert.equal(d[11],t.assigned);assert.ok(!d[12]);
  assert.equal(e[4],t.estimated);assert.equal(e[18],t.assigned);assert.equal(e[5],t.state);
  if(t.state==='Completado'){assert.equal(d[9],t.estimated);assert.equal(r[4],t.estimated);}else{assert.ok(!d[9]);assert.ok(!r[4]);}
  for(let j=0;j<11;j++){assert.equal(e[j+6]===1,j>=t.start-1&&j<=t.end-1);assert.equal(r[j+6]===1,t.state==='Completado'&&j>=t.start-1&&j<=t.end-1);}
 }
};check();
// Comprobar el flujo editable de estado, fechas y responsable; restaurar todos los datos temporales.
const m=scheduleMap[0];detail.getRange('F9').values=[['WIP']];detail.getRange('L9:M9').values=[['Santiago','Nombre temporal']];wb.recalculate();
assert.ok(!schedule.getRange(`G${m.r}`).values[0][0]);assert.ok(!schedule.getRange(`E${m.r}`).values[0][0]);assert.equal(schedule.getRange(`S${m.e}`).values[0][0],'Santiago');assert.equal(schedule.getRange(`T${m.e}`).values[0][0],'Nombre temporal');
detail.getRange('F9').values=[['Completado']];detail.getRange('G9:H9').values=[[date('2026-09-08'),date('2026-09-21')]];wb.recalculate();assert.equal(schedule.getRange(`E${m.e}`).values[0][0],2);assert.equal(schedule.getRange(`E${m.r}`).values[0][0],2);assert.equal(schedule.getRange(`H${m.r}`).values[0][0],1);assert.ok(!schedule.getRange(`G${m.e}`).values[0][0]);
detail.getRange('G9:H9').values=[[null,null]];wb.recalculate();assert.ok(!schedule.getRange(`E${m.e}`).values[0][0]);assert.ok(!schedule.getRange(`G${m.r}`).values[0][0]);
detail.getRange('G9:H9').values=[[date('2026-09-01'),date('2026-09-07')]];detail.getRange('L9:M9').values=[[tasks[0].assigned,'']];wb.recalculate();check();
console.log((await wb.inspect({kind:'region',sheetId:'Cronograma',range:'D11:K14',maxChars:1400,tableMaxRows:4,tableMaxCols:8})).ndjson);
console.log((await wb.inspect({kind:'match',searchTerm:'#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!',options:{useRegex:true,maxResults:50},maxChars:1400})).ndjson);
await SpreadsheetFile.exportXlsx(wb).then(f=>f.save(path.join(out,'cronograma-marea-compacto.xlsx')));
await fs.writeFile(path.join(support,'layout.json'),JSON.stringify({totalRows,detailLast,scheduleMap,stageRows,pageBreaks},null,2));
await fs.mkdir(path.join(support,'previews'),{recursive:true});
let start=10,pages=0;
for(const end of [...pageBreaks,totalRows]){const blob=await wb.render({sheetName:'Cronograma',range:`A${start}:T${end}`,scale:1.2,format:'png'});await fs.writeFile(path.join(support,'previews',`pagina-${++pages}.png`),new Uint8Array(await blob.arrayBuffer()));start=end+1;}
for(const[name,sheet,range]of[['encabezado','Cronograma','A1:T18'],['detalle-tareas','Detalle','A8:F13'],['detalle-responsables','Detalle','G8:N13'],['detalle-evidencia','Detalle','O8:R11']]){const blob=await wb.render({sheetName:sheet,range,scale:1.2,format:'png'});await fs.writeFile(path.join(support,'previews',name+'.png'),new Uint8Array(await blob.arrayBuffer()));}
const text=await fs.readFile(path.join(out,'cronograma-marea-compacto.md'),'utf8');assert.deepEqual([...text.matchAll(/^### ([A-Z]+-\d{2}) — /gm)].map(m=>m[1]),tasks.map(t=>t.id));
const report={tasks:142,scheduleRows:299,stages:6,modules:9,statuses:tasks.reduce((a,t)=>(a[t.state]=(a[t.state]||0)+1,a),{}),tasksByPerson:tasks.reduce((a,t)=>(a[t.assigned]=(a[t.assigned]||0)+1,a),{}),sourcesVerified:sources.length,allBarsVerified:true,completedRowsAligned:true,openRealRowsBlank:true,editablePropagationVerified:true,markdownMatches:true,pagesRendered:pages};
await fs.writeFile(path.join(support,'verification.json'),JSON.stringify(report,null,2));console.log(JSON.stringify(report));
