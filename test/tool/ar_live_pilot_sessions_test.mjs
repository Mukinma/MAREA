import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp,mkdir,writeFile,readFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {confirmPilotAccounts} from '../../tool/ar-live-pilot/sessions.mjs';
const origin = `https://${'b'.repeat(20)}.supabase.co`;
const id = '11111111-1111-4111-8111-111111111111';
function token(overrides={}) { return ['e30',Buffer.from(JSON.stringify({sub:id,role:'authenticated',iss:`${origin}/auth/v1`,exp:Date.now()/1000+3600,...overrides})).toString('base64url'),'sig'].join('.'); }
async function fixture(t) {
  const projectRoot=await mkdtemp(join(tmpdir(),'marea-ar-session-'));
  t.after(()=>rm(projectRoot,{recursive:true,force:true}));
  await mkdir(join(projectRoot,'config'));
  await mkdir(join(projectRoot,'.dart_tool/ar-live-pilot'),{recursive:true});
  const profile={full_name:'Prueba RA MAREA · Organizador',username:'pra_o_session',user_type:'Negocio'};
  const account={status:'created',userId:id,email:'owner+qa@example.com',password:'private-fixture',profile,
    response:{user:{id,email:'owner+qa@example.com',identities:[{provider:'email'}],user_metadata:profile}}};
  const journal={version:1,productionOrigin:origin,accounts:{owner:account}};
  const path=join(projectRoot,'.dart_tool/ar-live-pilot/accounts.json');
  await writeFile(path,JSON.stringify(journal));
  await writeFile(join(projectRoot,'config/supabase.production.json'),JSON.stringify({SUPABASE_URL:origin,SUPABASE_ANON_KEY:`sb_publishable_${'x'.repeat(24)}`}));
  return {projectRoot,path,journal,account};
}
function transport(account, {jwt=token(),role='user',confirmed=true,redirect=false}={}) {
  const calls=[];
  const fetchImpl=async (url,options)=>{
    calls.push({url:new URL(url),options});
    if(redirect)return new Response('',{status:302,headers:{Location:'https://elsewhere.invalid/'}});
    const value=new URL(url).pathname==='/auth/v1/verify'?{access_token:jwt,refresh_token:'private-refresh'}:
      new URL(url).pathname==='/auth/v1/user'?{id:account.userId,email:account.email,email_confirmed_at:confirmed?'now':null}:
      [{id:account.userId,role,user_type:account.profile.user_type,username:account.profile.username}];
    return new Response(JSON.stringify(value),{status:200});
  };
  return {calls,fetchImpl};
}
test('only explicit confirmation of the newly recorded identity can create a private session',async t=>{
  const f=await fixture(t), network=transport(f.account);
  const report=await confirmPilotAccounts({...f,...network,codes:{owner:'12345678'},confirmNewAccounts:true});
  assert.equal(report.status,'confirmed');
  assert.deepEqual(network.calls.map(c=>[c.options.method,c.url.pathname]),[['POST','/auth/v1/verify'],['GET','/auth/v1/user'],['GET','/rest/v1/profiles']]);
  assert.equal(JSON.stringify(report).includes('private-refresh'),false);
  const saved=JSON.parse(await readFile(f.path,'utf8'));
  assert.equal(saved.accounts.owner.session.refresh_token,'private-refresh');
  assert.equal(JSON.stringify(saved).includes('12345678'),false);
});
test('no opt-in or malformed code cannot send any request',async t=>{
  const f=await fixture(t), network=transport(f.account);
  assert.equal((await confirmPilotAccounts({...f,...network,codes:{owner:'12345678'}})).status,'blocked');
  assert.equal((await confirmPilotAccounts({...f,...network,codes:{owner:'not-a-code'},confirmNewAccounts:true})).status,'blocked');
  assert.equal(network.calls.length,0);
});
test('wrong origin, proposed identities and unsafe IDs fail before verification',async t=>{
  for(const kind of ['origin','id','status']){
    const f=await fixture(t), network=transport(f.account);
    if(kind==='origin')f.journal.productionOrigin='https://other.invalid';
    if(kind==='id')f.journal.accounts.owner.userId='../other';
    if(kind==='status')f.journal.accounts.owner.status='not_attempted';
    await writeFile(f.path,JSON.stringify(f.journal));
    assert.equal((await confirmPilotAccounts({...f,...network,codes:{owner:'12345678'},confirmNewAccounts:true})).status,'blocked');
    assert.equal(network.calls.length,0);
  }
});
test('foreign, expired and privileged tokens never reach a profile read',async t=>{
  for(const jwt of [token({sub:'22222222-2222-4222-8222-222222222222'}),token({exp:1}),token({role:'service_role'}),token({iss:'https://other.invalid/auth/v1'})]){
    const f=await fixture(t), network=transport(f.account,{jwt});
    assert.equal((await confirmPilotAccounts({...f,...network,codes:{owner:'12345678'},confirmNewAccounts:true})).status,'incomplete');
    assert.equal(network.calls.length,1);
  }
});
test('existing sessions are revalidated, never trusted merely because they are stored',async t=>{
  for(const [jwt,expected,count] of [[token(),'confirmed',2],[token({exp:1}),'incomplete',0]]){
    const f=await fixture(t);f.journal.accounts.owner.session={access_token:jwt};
    await writeFile(f.path,JSON.stringify(f.journal));
    const network=transport(f.account);
    const report=await confirmPilotAccounts({...f,...network,codes:{owner:'12345678'},confirmNewAccounts:true});
    assert.equal(network.calls.some(c=>c.options.method==='POST'),false);
    assert.equal(report.status,expected);
    assert.equal(network.calls.length,count);
  }
});
test('an unconfirmed identity, admin profile or redirect cannot become a usable session',async t=>{
  for(const options of [{confirmed:false},{role:'admin'},{redirect:true}]){
    const f=await fixture(t), network=transport(f.account,options);
    assert.equal((await confirmPilotAccounts({...f,...network,codes:{owner:'12345678'},confirmNewAccounts:true})).status,'incomplete');
    assert.equal(JSON.parse(await readFile(f.path,'utf8')).accounts.owner.session,undefined);
    assert.equal(network.calls.every(c=>c.options.redirect==='manual'&&c.url.origin===origin),true);
  }
});
