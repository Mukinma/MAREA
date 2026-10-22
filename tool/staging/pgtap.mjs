import {readFileSync,writeFileSync,readdirSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {database} from './replay.mjs';
const quote=x=>"'"+x.replaceAll("'","''")+"'";
export function test(path){
 const {m,sql}=database(path),f=JSON.parse(readFileSync(join(path,'fixtures-private.json')));
 const inv=JSON.parse(readFileSync(join(path,readdirSync(path).filter(x=>x.startsWith('db-inventory-')).sort().at(-1))));
 const specs=JSON.parse(readFileSync('tool/staging/matrix.json')).cases;const tests=[];
 function add(scenario_id,subcase,assertion,modality='real'){tests.push({scenario_id,subcase,assertion,modality});}
 for(const t of inv.tables){const table=t.schema+'.'+t.name,sid='T001-RLS-'+t.schema+'-'+t.name;
  add(sid,'effective RLS enabled',`ok((select relrowsecurity from pg_class where oid='${table}'::regclass), 'RLS ${table}')`,'inspeccion');
  for(const [op,q] of [['SELECT',`select * from ${table}`],['INSERT',`insert into ${table} default values`],['UPDATE',`update ${table} set ${t.name==='registration_settings'?'id':t.name==='push_settings'?'singleton':(inv.column_grants.find(c=>c.table_schema===t.schema&&c.table_name===t.name)?.column_name||'id')} = null where false`],['DELETE',`delete from ${table}`]]) {
   // SQL permission checks precede query/data evaluation. Unknown update column is avoided below.
   const actual=op==='UPDATE'?`update ${table} set `+`(PLACEHOLDER)` :q;
   add(sid,'anonymous '+op+' denied',`pg_temp.denied_as_anon(${quote(op)},${quote(table)})`);
  }
 }
 const workers=new Set(['begin_profile_media_operation','request_account_deletion','claim_push_jobs','finish_push_job','push_job_is_current','story_cleanup_images','dispatch_story_cleanup','claim_geocoding_request','finish_geocoding_request','tours_claim_jobs','tours_job_is_current','tours_finish_job','tours_begin_output_write','tours_end_output_write','tours_job_context','tours_claim_cleanup','tours_finish_cleanup','tours_completion_receipt','tours_renew_cleanup']);
 for(const fn of inv.functions){if(workers.has(fn.name)||fn.schema==='private'&&!['tour_input_write','tour_asset_read','tour_reference_write','tour_input_read','tour_review_asset'].includes(fn.name)){
  add('T001-RPC-ALL','worker/internal grant denied to user: '+fn.signature,`ok(not has_function_privilege('authenticated',${quote(fn.signature)},'EXECUTE'),'user grant ${fn.signature}')`,'inspeccion');
  add('T001-RPC-ALL','worker/internal grant denied to visitor: '+fn.signature,`ok(not has_function_privilege('anon',${quote(fn.signature)},'EXECUTE'),'anon grant ${fn.signature}')`,'inspeccion');
 }}
 // SQL roles/JWT claims against existing fixtures; no service-role authorization assertions.
 const uid=f.users.owner.id,tid=f.users.third.id;
 let script=`BEGIN;
create extension if not exists pgtap with schema extensions;
set local search_path=public,extensions;
create function pg_temp.denied_as_anon(op text,target text) returns text language plpgsql security invoker as $$
declare statement text;col text;denied boolean:=false;begin
 select attname into col from pg_attribute where attrelid=target::regclass and attnum>0 and not attisdropped order by attnum limit 1;
 statement:=case op when 'SELECT' then 'select * from '||target when 'INSERT' then 'insert into '||target||' default values' when 'DELETE' then 'delete from '||target when 'UPDATE' then 'update '||target||' set '||quote_ident(col)||'=DEFAULT where false' end;
 begin set local role anon;execute statement;exception when insufficient_privilege then denied:=true;end;
 reset role;return extensions.ok(denied,'anonymous '||op||' denied '||target);
end;$$;
select plan(${tests.length+6});
`;
 for(const t of tests)script+='select '+t.assertion+';\n';
 script+=`set local role authenticated;
select set_config('request.jwt.claims','{"sub":"${uid}","role":"authenticated"}',true);
select is((select count(*)::int from public.profiles),1,'own profile visible');
select ok(exists(select 1 from public.profiles where id='${uid}'),'owner profile visible');
select ok(not exists(select 1 from public.profiles where id='${tid}'),'foreign profile hidden');
select throws_ok($q$update public.profiles set role='admin' where id='${uid}'$q$,'42501',NULL,'role update denied');
select throws_ok($q$select public.request_account_deletion('${tid}'::uuid)$q$,'42501',NULL,'service-only deletion denied');
select ok(not public.community_is_admin(),'metadata cannot elevate role');
reset role;
select * from finish();
ROLLBACK;
`;
 for(const label of ['own profile visible','owner profile visible','foreign profile hidden','role update denied','service-only deletion denied','metadata cannot elevate role'])tests.push({scenario_id:label.includes('deletion')?'T001-ID-03':label.includes('role')?'T001-ID-02':'T001-RLS-public-profiles',subcase:label,modality:'real'});
 const stamp=Date.now();writeFileSync(join(path,'pgtap-input-'+stamp+'.sql'),script,{flag:'wx',mode:0o600});
 const r=sql(script,true);writeFileSync(join(path,'pgtap-private-'+stamp+'.log'),r.stdout+r.stderr,{flag:'wx',mode:0o600});
 const taps=r.stdout.split('\n').filter(x=>/^(not )?ok \d+/.test(x));const results=tests.map((t,i)=>({...t,assertion:undefined,result:taps[i]?.startsWith('ok ')?'PASS':taps[i]?.startsWith('not ok ')?'FAIL':'BLOQUEADO',tap:taps[i]||'No assertion reached'}));
 const data={id:'E-TASK001-PGTAP-'+m.project_id+'-'+stamp,at:new Date().toISOString(),modality:'mixed: real role permission queries and inspection of effective metadata',results,exit_code:r.status,complete_requirement_validation:false,remote_modified:false,limits:['Anonymous DML permission denials are executed on actual local tables; most tables still require fixture-specific positive/foreign-user action coverage. Catalog assertions do not attest runtime state/action contracts. Test transaction rolled back including test extension/helpers.']};
 writeFileSync(join(path,'pgtap-results-'+stamp+'.json'),JSON.stringify(data,null,2)+'\n',{flag:'wx',mode:0o600});return {result:r.status===0&&results.every(t=>t.result==='PASS')?'PASS':'FAIL',subcases_executed:taps.length,counts:Object.fromEntries(['PASS','FAIL','BLOQUEADO'].map(k=>[k,results.filter(r=>r.result===k).length])),receipt:'pgtap-results-'+stamp+'.json'};
}
if(process.argv[1]===new URL(import.meta.url).pathname){try{console.log(JSON.stringify(test(resolve(process.argv[2]||''))));}catch(e){console.error('pgTAP infrastructure failure; private diagnostics retained');process.exitCode=1;}}
