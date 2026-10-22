import {readFileSync,writeFileSync,existsSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {parseDocument} from 'yaml';
import {validate,render,replaceGenerated,metrics} from './traceability.mjs';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'../..'),command=process.argv[2]??'check';
if(!['validate','render','check','metrics'].includes(command)){console.error('Uso: node tool/traceability/cli.mjs validate|render|check|metrics');process.exit(2);}
try{
 const yaml=parseDocument(readFileSync(resolve(root,'docs/MAREA_REQUIREMENTS_STATUS.yaml'),'utf8'),{uniqueKeys:true});if(yaml.errors.length)throw new Error(yaml.errors.map(e=>e.message).join('\n'));
 const data=yaml.toJS({maxAliasCount:0}),errors=validate(data,root);if(errors.length)throw new Error(errors.join('\n'));
 if(command==='metrics')console.log(JSON.stringify(metrics(data,root),null,2));
 else if(command==='validate')console.log(`Integridad aprobada: ${data.requirements.length} registros, ${data.evidence.length} evidencias.`);
 else{
  const pending=Object.entries(render(data,root)).map(([path,body])=>{const target=resolve(root,path),old=existsSync(target)?readFileSync(target,'utf8'):'';return {path,target,old,next:replaceGenerated(old,body)};});
  const changed=pending.filter(p=>p.old!==p.next);if(command==='check'&&changed.length)throw new Error('Documentos derivados desactualizados: '+changed.map(p=>p.path).join(', '));
  if(command==='render')for(const p of changed)writeFileSync(p.target,p.next);
  console.log(command==='check'?'Integridad y documentos consistentes.':`Generación completa: ${changed.length} archivos modificados.`);
 }
}catch(error){console.error(error.message);process.exit(1);}
