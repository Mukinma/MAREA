import {readFileSync,writeFileSync,existsSync} from 'node:fs';
import {join,resolve} from 'node:path';
import {randomBytes,randomUUID} from 'node:crypto';
import {localClient} from './http.mjs';
import {database} from './replay.mjs';
export async function seed(path) {
 const api=localClient(path);if(existsSync(join(path,'fixtures-private.json')))throw Error('Fixtures already exist; no silent reseeding');
 const {sql}=database(path);const run=api.marker.project_id.slice(-12);const legal='synthetic-'+run;
 sql(`insert into public.legal_documents(kind,version,title,body,published_at) select k,'${legal}','SYNTHETIC TEST ONLY',repeat('Synthetic local fixture; no legal effect. ',5),now() from unnest(array['terms','privacy']) k; update public.registration_settings set signup_enabled=true,terms_version='${legal}',privacy_version='${legal}',support_email='qa@${run}.invalid';`);
 const users={};for(const name of ['owner','candidateA','candidateB','third','admin','restricted']) {
  const user={email:name.toLowerCase()+'@'+run+'.invalid',password:randomBytes(24).toString('base64url')};
  const metadata={full_name:'Synthetic '+name,username:'qa_'+run.slice(0,6)+'_'+name.toLowerCase(),user_type:'Artista / creador',registration_flow:'minimal-v1',adult_confirmed:true,accepted_terms:true,terms_version:legal,privacy_version:legal,role:'admin'};
  const r=await api.request('/auth/v1/admin/users',{method:'POST',actor:'service',data:{...user,email_confirm:true,user_metadata:metadata}});
  if(!r.ok||!r.body.id)throw Error('Synthetic account preparation failed');user.id=r.body.id;users[name]=user;
 }
 sql(`update public.profiles set role='admin' where id='${users.admin.id}';`);
 const fixtures={run,legal,users,resource_prefix:'TASK001 '+run,ids:{post:randomUUID(),mission:randomUUID(),story:randomUUID()}};
 writeFileSync(join(path,'fixtures-private.json'),JSON.stringify(fixtures,null,2)+'\n',{flag:'wx',mode:0o600});
 writeFileSync(join(path,'seed-receipt.json'),JSON.stringify({id:'E-TASK001-FIXTURES-'+run,at:new Date().toISOString(),result:'PASS',modality:'real',accounts:6,email_domain:'.invalid',passwords:'Random; private file only',admin_uses:'Fixture preparation and explicit worker principal; authorization uses user JWT',remote_modified:false},null,2)+'\n',{flag:'wx',mode:0o600});
 return {result:'PASS',synthetic_accounts:6};
}
if(process.argv[1]===new URL(import.meta.url).pathname){try{console.log(JSON.stringify(await seed(resolve(process.argv[2]||''))));}catch(e){console.error(e.message);process.exitCode=1;}}
