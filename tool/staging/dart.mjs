import {readFileSync,writeFileSync,mkdirSync,cpSync,existsSync,openSync,closeSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {spawnSync,spawn} from 'node:child_process';
import {createHash} from 'node:crypto';
import {localClient} from './http.mjs';
import {childEnvironment} from './guard.mjs';
const path=resolve(process.argv[2]||''),api=localClient(path),dir=join(path,'dart-host');if(existsSync(dir))throw Error('Host test copy already exists');mkdirSync(dir,{mode:0o700});
for(const name of ['lib','assets','pubspec.yaml','pubspec.lock'])cpSync(name,join(dir,name),{recursive:true,errorOnExist:true,force:false});
mkdirSync(join(dir,'test'),{mode:0o700});cpSync('tool/staging/dart/contract_test.dart',join(dir,'test/contract_test.dart'),{errorOnExist:true,force:false});
const version=spawnSync('flutter',['--version','--machine'],{env:childEnvironment(),encoding:'utf8'});if(version.status!==0)throw Error('Flutter unavailable; no substitution');
const fd=openSync(join(path,'dart-private.log'),'wx',0o600);
const get=spawnSync('flutter',['pub','get','--offline','--enforce-lockfile'],{cwd:dir,env:childEnvironment(),stdio:['ignore',fd,fd]});if(get.status!==0){closeSync(fd);throw Error('Locked offline Flutter dependency preparation failed');}
if(createHash('sha256').update(readFileSync(join(dir,'pubspec.lock'))).digest('hex')!==createHash('sha256').update(readFileSync('pubspec.lock')).digest('hex'))throw Error('Flutter lock drift');
const child=spawn('flutter',['test','--no-pub','--reporter','json','test/contract_test.dart'],{cwd:dir,env:{...childEnvironment(),MAREA_LOCAL_RUNTIME:path},stdio:['ignore','pipe',fd]});let stdout='';child.stdout.on('data',b=>stdout+=b);const code=await new Promise((r,j)=>{child.on('error',j);child.on('exit',r);});closeSync(fd);
writeFileSync(join(path,'dart-events-private.jsonl'),stdout,{flag:'wx',mode:0o600});
const events=stdout.split('\n').flatMap(l=>{try{return [JSON.parse(l)];}catch{return [];}});const names=new Map(events.filter(e=>e.type==='testStart').map(e=>[e.test.id,e.test.name]));
const results=events.filter(e=>e.type==='testDone'&&names.get(e.testID)?.includes('DART-')).map(e=>({id:names.get(e.testID).match(/DART-\d+/)[0],scenario_id:'T001-RPC-ALL',subcase:names.get(e.testID),result:e.result==='success'?'PASS':'FAIL',modality:'real',platform:'dart-host'}));
writeFileSync(join(path,'dart-receipt.json'),JSON.stringify({id:'E-TASK001-DART-'+api.marker.project_id,at:new Date().toISOString(),result:code===0&&results.length===6&&results.every(r=>r.result==='PASS')?'PASS':'FAIL',results,exit_code:code,flutter:JSON.parse(version.stdout),lock_sha256:createHash('sha256').update(readFileSync('pubspec.lock')).digest('hex'),test_sha256:createHash('sha256').update(readFileSync('tool/staging/dart/contract_test.dart')).digest('hex'),complete_requirement_validation:false,remote_modified:false,limits:['Host repository tests against actual local Supabase; Android/iOS and hardware QA remain pending. App bootstrap/Firebase/provider services not initialized.']},null,2)+'\n',{flag:'wx',mode:0o600});console.log(JSON.stringify({exit_code:code,subcases_executed:results.length,counts:Object.fromEntries(['PASS','FAIL'].map(k=>[k,results.filter(r=>r.result===k).length]))}));
