// Laboratory S0 variant. No operational Edge sources or account purge API calls.
const cors={'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info','Access-Control-Allow-Methods':'POST, OPTIONS'};
const json = (status: number, body: unknown) => Response.json(body, {status,headers:cors});
const expected = Deno.env.get('S0_STATE_DIGEST') ?? '';
async function active() {
  try {
    const bytes = await Deno.readFile('/state/data/state.json');
    const digest = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes))).map(x=>x.toString(16).padStart(2,'0')).join('');
    const state=JSON.parse(new TextDecoder().decode(bytes));
    return digest===expected && /^[a-f0-9]{64}$/.test(expected) && state.schema_version===1 && state.status==='ACTIVE' && typeof state.epoch==='string' && state.physical_readonly===true && state.quiescence_verified===true;
  } catch {return false;}
}
Deno.serve({hostname:'127.0.0.1',port:9000},async request=>{
  if (!await active()) return json(503,{error:'s0_state_unverified',completed:false});
  const url=new URL(request.url);
  if (url.pathname.startsWith('/storage/v1/')) {
    if (!['GET','HEAD','OPTIONS'].includes(request.method)) return json(503,{error:'s0_storage_mutations_fenced'});
    try {return await fetch('http://127.0.0.1:5000'+url.pathname.slice('/storage/v1'.length)+url.search,{method:request.method,headers:request.headers,redirect:'error',signal:AbortSignal.timeout(10000)});}
    catch {return json(503,{error:'storage_unavailable'});}
  }
  if (url.pathname==='/health') return json(200,{fence:'ACTIVE'});
  if (url.pathname!=='/functions/v1/delete-account') return json(503,{error:'s0_legacy_producer_fenced',completed:false});
  if (request.method==='OPTIONS') return new Response(null,{status:204,headers:cors});
  if (request.method!=='POST') return json(405,{error:'method_not_allowed'});
  const authorization=request.headers.get('Authorization');
  if(!authorization?.startsWith('Bearer '))return json(401,{error:'unauthorized',completed:false});
  try {
    const auth=await fetch('http://127.0.0.1:9999/user',{headers:{Authorization:authorization},redirect:'error',signal:AbortSignal.timeout(5000)});
    if(!auth.ok)return json(401,{error:'unauthorized',completed:false});
    const user=await auth.json();if(typeof user.id!=='string'||!/^[-a-f0-9]{36}$/.test(user.id))return json(401,{error:'unauthorized',completed:false});
    const headers={Authorization:'Bearer '+Deno.env.get('SERVICE_ROLE_KEY'),'Content-Type':'application/json',Prefer:'resolution=ignore-duplicates,return=minimal'};
    // Existing request marker only. Do not call the legacy RPC which also clears
    // tour job results/leases. No B plan, retention or purge is implemented here.
    const result=await fetch('http://127.0.0.1:3000/account_deletion_requests?on_conflict=user_id',{method:'POST',headers,body:JSON.stringify({user_id:user.id}),redirect:'error',signal:AbortSignal.timeout(5000)});
    if(!result.ok)return json(503,{error:'request_not_confirmed',completed:false});
    const check=await fetch('http://127.0.0.1:3000/account_deletion_requests?select=user_id&user_id=eq.'+user.id,{headers,redirect:'error',signal:AbortSignal.timeout(5000)});
    if(!check.ok)return json(503,{error:'request_not_confirmed',completed:false});
    const rows=await check.json();if(!Array.isArray(rows)||rows.length!==1||rows[0].user_id!==user.id)return json(503,{error:'request_not_confirmed',completed:false});
    return json(503,{error:'account_deletion_temporarily_fenced',request_recorded:true,completed:false});
  } catch {return json(503,{error:'request_not_confirmed',completed:false});}
});
