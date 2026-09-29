// Explicit opt-in: creates five temporary, email-confirmed users, tests actual
// user JWTs/RLS/Storage/Edge Functions, and removes ONLY those users/files.
// Uses administrative credentials in memory through the logged-in CLI. Never
// sends email or prints passwords, keys, tokens, or existing user data.
import {readFile} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {randomBytes, randomUUID} from 'node:crypto';
import {deflateSync} from 'node:zlib';
import assert from 'node:assert/strict';
if (!process.argv.includes('--run')) {
  console.log('Usage: node tool/check_live_account_flow.mjs --run (temporary users; real remote writes)');
  process.exit(0);
}
const config = JSON.parse(await readFile(new URL('../config/supabase.production.json',import.meta.url),'utf8'));
const base = config.SUPABASE_URL;
const ref = new URL(base).hostname.split('.')[0];
const keysResult = spawnSync('supabase',['projects','api-keys','--project-ref',ref,'--output','json'],{encoding:'utf8'});
if (keysResult.status !== 0) throw new Error('Administrative CLI access unavailable');
const keys = JSON.parse(keysResult.stdout);
const admin = keys.find(key => key.name === 'service_role')?.api_key;
if (!admin) throw new Error('Administrative key unavailable');
const publicKey = config.SUPABASE_ANON_KEY;
const run = randomBytes(4).toString('hex');
const users = [];
const files = [];
let checks = 0;
function check(condition,label) {assert.ok(condition,label); checks++;}
async function request(path,{method='GET',body,token=admin,key=admin,binary=false,headers={}}={}) {
  return fetch(`${base}${path}`,{method,headers:{apikey:key,Authorization:`Bearer ${token}`,
    ...(body == null ? {} : {'Content-Type':binary?'image/png':'application/json'}),...headers},
    body:body == null ? undefined : binary?body:JSON.stringify(body),signal:AbortSignal.timeout(30000)});
}
async function json(path,options,label=path) {
  const response = await request(path,options);
  if (!response.ok) {
    const error = await response.json().catch(()=>({}));
    throw new Error(`${label}: HTTP ${response.status}, code ${error.code??error.error??'unknown'}`);
  }
  if (response.status === 204) return null;
  return response.json();
}
const asUser = user => ({token:user.token,key:publicKey});
const profile = user => json(`/rest/v1/profiles?id=eq.${user.id}&select=*`,asUser(user));
const update = (user,body) => json(`/rest/v1/profiles?id=eq.${user.id}`,{
  ...asUser(user),method:'PATCH',body,headers:{Prefer:'return=representation'},
});
const rpc = (user,name,body) => json(`/rest/v1/rpc/${name}`,{...asUser(user),method:'POST',body});
const signIn = async user => {
  const session = await json('/auth/v1/token?grant_type=password',{method:'POST',key:publicKey,token:publicKey,
    body:{email:user.email,password:user.password}},'temporary user sign-in');
  user.token = session.access_token;
  check(Boolean(user.token),'authenticated user session');
};
// 1 × 1 RGBA test fixture with correct PNG CRCs; no external image dependency.
function chunk(type,data) {
  const name = Buffer.from(type), crcInput = Buffer.concat([name,data]);
  let crc=0xffffffff;
  for(const byte of crcInput) {crc^=byte; for(let i=0;i<8;i++) crc=(crc>>>1)^((crc&1)?0xedb88320:0);}
  const length=Buffer.alloc(4),checksum=Buffer.alloc(4);
  length.writeUInt32BE(data.length); checksum.writeUInt32BE((crc^0xffffffff)>>>0);
  return Buffer.concat([length,name,data,checksum]);
}
const ihdr=Buffer.alloc(13); ihdr.writeUInt32BE(1,0);ihdr.writeUInt32BE(1,4);ihdr[8]=8;ihdr[9]=6;
const png=Buffer.concat([Buffer.from('89504e470d0a1a0a','hex'),chunk('IHDR',ihdr),chunk('IDAT',deflateSync(Buffer.from([0,0,170,153,255]))),chunk('IEND',Buffer.alloc(0))]);
async function uploadProfile(user) {
  const result=await json('/functions/v1/profile-media',{...asUser(user),method:'POST',body:png,binary:true},'profile upload');
  files.push({bucket:'profile-media',path:result.path});
  check(result.path.startsWith(`${user.id}/`),'image belongs to caller');
  return result.path;
}
async function signed(user,bucket,path) {
  return json(`/storage/v1/object/sign/${bucket}/${path}`,{...asUser(user),method:'POST',body:{expiresIn:60}},'signed image read');
}
async function download(user,bucket,path) {
  const {signedURL}=await signed(user,bucket,path);
  const response=await fetch(`${base}/storage/v1${signedURL}`,{signal:AbortSignal.timeout(30000)});
  check(response.ok,'signed image downloadable');
  const bytes=Buffer.from(await response.arrayBuffer());
  check(bytes.subarray(0,8).equals(png.subarray(0,8)),'download contains PNG');
}
try {
  const policy = await json('/rest/v1/rpc/registration_policy',{method:'POST',key:publicKey,token:publicKey,body:{}});
  check(policy.signup_enabled,'registration is enabled');
  const types=['Usuario general','Artista / creador','Emprendedor','Negocio'];
  for(let i=0;i<5;i++) {
    const user={email:`marea-repair-${run}-${i}@example.invalid`,password:randomBytes(24).toString('base64url')};
    const created=await json('/auth/v1/admin/users',{method:'POST',body:{email:user.email,password:user.password,email_confirm:true,
      user_metadata:{full_name:'Prueba temporal',username:`repair_${run}_${i}`,user_type:types[i%4],
        ...(i<4?{registration_flow:'minimal-v1'}:{}),accepted_terms:true,adult_confirmed:true,
        terms_version:policy.terms.version,privacy_version:policy.privacy.version}}},'create temporary account');
    user.id=created.id; users.push(user);
    await signIn(user);
    let [row]=await profile(user);
    check(row.role==='user','temporary account uses the user role');
    if(i<4) {
      check(row.user_type===types[i] && row.initial_profile_completed_at!==null,'type preserved without repeated onboarding');
    } else {
      check(row.initial_profile_completed_at===null,'legacy account is pending');
      row=await rpc(user,'complete_initial_profile',{profile_type:'Artista / creador',selected_interests:[],selected_goals:[]});
      check(row.initial_profile_completed_at!==null && row.user_type==='Artista / creador','legacy confirmation accepts empty preferences');
      const repeated=await request('/rest/v1/rpc/complete_initial_profile',{...asUser(user),method:'POST',body:{profile_type:'Negocio',selected_interests:[],selected_goals:[]}});
      check(!repeated.ok,'second confirmation rejected');
    }
    await update(user,{full_name:'Nombre persistente',bio:'Guía guardada',setup_step:1,interests:[],goals:[]});
    await json('/auth/v1/logout',{...asUser(user),method:'POST'},'temporary sign-out');
    await signIn(user);
    [row]=await profile(user);
    check(row.full_name==='Nombre persistente' && row.setup_step===1,'guide and name survive a new session');
    check(row.user_type===(i<4?types[i]:'Artista / creador'),'type survives new session');
  }
  const [owner,visitor]=users;
  let avatar=await uploadProfile(owner),cover=await uploadProfile(owner);
  const forbiddenDraft=await request(`/storage/v1/object/sign/profile-media/${avatar}`,{...asUser(visitor),method:'POST',body:{expiresIn:60}});
  check(!forbiddenDraft.ok,'another user cannot read an unreferenced image');
  await update(owner,{avatar_path:avatar,cover_path:cover});
  await download(owner,'profile-media',avatar); await download(owner,'profile-media',cover);
  const foreign=await json(`/rest/v1/profiles?id=eq.${owner.id}&select=id`,asUser(visitor));
  check(foreign.length===0,'another user cannot read private profile');
  const foreignWrite=await json(`/rest/v1/profiles?id=eq.${owner.id}`,{...asUser(visitor),method:'PATCH',body:{bio:'Forbidden'},headers:{Prefer:'return=representation'}});
  check(foreignWrite.length===0 && (await profile(owner))[0].bio==='Guía guardada','another user cannot update profile');
  const replacement=await uploadProfile(owner);
  await update(owner,{avatar_path:replacement});
  await json('/functions/v1/profile-media',{...asUser(owner),method:'DELETE',body:{path:avatar}},'remove old avatar');
  await download(owner,'profile-media',replacement);
  const foreignDelete=await request('/functions/v1/profile-media',{...asUser(visitor),method:'DELETE',body:{path:replacement}});
  check(!foreignDelete.ok,'another user cannot remove profile image');
  await update(owner,{avatar_path:null,cover_path:null});
  for(const path of [replacement,cover]) await json('/functions/v1/profile-media',{...asUser(owner),method:'DELETE',body:{path}},'remove unlinked image');
  check((await profile(owner))[0].avatar_path===null,'profile image removal persists');
  const postPath=`${owner.id}/${randomUUID()}.png`; files.push({bucket:'post-images',path:postPath});
  await json(`/storage/v1/object/post-images/${postPath}`,{...asUser(owner),method:'POST',body:png,binary:true},'post image upload');
  const [post]=await json('/rest/v1/posts',{...asUser(owner),method:'POST',body:{kind:'community',title:'Prueba temporal',body:'Publicación temporal con fotografía',category:'arte',image_path:postPath},headers:{Prefer:'return=representation'}});
  check(Boolean(post.id),'post with image persists');
  await download(visitor,'post-images',postPath);
  const foreignUpload=await request(`/storage/v1/object/post-images/${owner.id}/${randomUUID()}.png`,{...asUser(visitor),method:'POST',body:png,binary:true});
  check(!foreignUpload.ok,'cannot upload into another user folder');
  await json(`/rest/v1/posts?id=eq.${post.id}`,{...asUser(owner),method:'DELETE'},'remove temporary post');
  for(const user of users) {
    const deleted=await request('/functions/v1/delete-account',{...asUser(user),method:'POST'});
    check(deleted.status===204,'account endpoint removes temporary account');
    user.deleted=true;
    check((await json(`/rest/v1/profiles?id=eq.${user.id}&select=id`)).length===0,'deleted profile is gone');
  }
  console.log(`${checks} live account checks passed: 4 signup types, legacy confirmation, guide, profile images, post images and isolation. Email delivery is not exercised.`);
} finally {
  let cleanupFailed=false;
  for(const bucket of ['profile-media','post-images']) {
    const prefixes=files.filter(file=>file.bucket===bucket).map(file=>file.path);
    if(prefixes.length) {
      const response=await request(`/storage/v1/object/${bucket}`,{method:'DELETE',body:{prefixes}}).catch(()=>null);
      if(!response?.ok) cleanupFailed=true;
    }
  }
  for(const user of users) {
    if(!user.deleted) {
      const response=await request(`/auth/v1/admin/users/${user.id}`,{method:'DELETE'}).catch(()=>null);
      if(!response?.ok) cleanupFailed=true;
    }
  }
  if(cleanupFailed) throw new Error(`Temporary test cleanup needs attention (run ${run}).`);
  console.log('Temporary accounts and files cleaned up; existing accounts were untouched.');
}
