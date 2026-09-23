import { createClient } from 'jsr:@supabase/supabase-js@2';
import { ownsPath, validateAndNormalizePng } from './image.ts';
const cors = {'Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'authorization, apikey, content-type, x-client-info','Access-Control-Allow-Methods':'POST, DELETE, OPTIONS'};
const json = (status: number, body: Record<string, unknown>) => new Response(JSON.stringify(body), {status, headers:{...cors,'Content-Type':'application/json'}});
Deno.serve(async request => {
  if (request.method === 'OPTIONS') return new Response('ok',{headers:cors});
  if (!['POST','DELETE'].includes(request.method)) return json(405,{error:'method_not_allowed'});
  const authorization = request.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) return json(401,{error:'unauthorized'});
  const url = Deno.env.get('SUPABASE_URL'), key = Deno.env.get('SUPABASE_ANON_KEY'), secret = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !key || !secret) return json(500,{error:'server_not_configured'});
  const caller = createClient(url,key,{global:{headers:{Authorization:authorization}},auth:{persistSession:false}});
  const {data: auth, error: authError} = await caller.auth.getUser();
  if (authError || !auth.user) return json(401,{error:'unauthorized'});
  const owner = auth.user.id;
  const admin = createClient(url,secret,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data: operation, error: operationError} = await admin.rpc('begin_profile_media_operation',{owner_id:owner});
  if (operationError || !operation) return json(409,{error:'media_operation_unavailable'});
  try {
    const bucket = admin.storage.from('profile-media');
    if (request.method === 'DELETE') {
      const {path} = await request.json();
      if (!ownsPath(owner,path)) return json(400,{error:'invalid_path'});
      const {data: profile, error: profileError} = await admin.from('profiles').select('avatar_path,cover_path').eq('id',owner).single();
      if (profileError) return json(500,{error:'profile_unavailable'});
      if (profile.avatar_path === path || profile.cover_path === path) return json(409,{error:'image_still_in_use'});
      const {error} = await bucket.remove([path]);
      if (error) return json(500,{error:'media_delete_failed'});
      return json(200,{ok:true});
    }
    if (request.headers.get('Content-Type')?.split(';')[0] !== 'image/png') return json(415,{error:'png_required'});
    // Bound streaming input, including requests without Content-Length.
    const reader = request.body?.getReader();
    if (!reader) return json(400,{error:'invalid_image'});
    const chunks: Uint8Array[] = []; let length = 0;
    while (true) { const {done,value} = await reader.read(); if (done) break; length += value.length; if (length > 4194304) { await reader.cancel(); return json(413,{error:'image_size'}); } chunks.push(value); }
    const bytes = new Uint8Array(length); let offset = 0; for (const chunk of chunks) { bytes.set(chunk,offset); offset += chunk.length; }
    let png: Uint8Array;
    try { png = validateAndNormalizePng(bytes); } catch { return json(400,{error:'invalid_image'}); }
    const {data: profile, error: profileError} = await admin.from('profiles').select('avatar_path,cover_path').eq('id',owner).single();
    if (profileError) return json(500,{error:'profile_unavailable'});
    const {data: files, error: listError} = await bucket.list(owner,{limit:100});
    if (listError) return json(500,{error:'storage_unavailable'});
    // Recover abandoned drafts from interrupted edits, never active images.
    const stale = (files ?? []).filter(f => `${owner}/${f.name}` !== profile.avatar_path && `${owner}/${f.name}` !== profile.cover_path && Date.parse(f.created_at ?? '') < Date.now()-86400000).map(f => `${owner}/${f.name}`);
    if (stale.length) { const {error} = await bucket.remove(stale); if (error) return json(500,{error:'storage_unavailable'}); }
    if ((files?.length ?? 0) - stale.length >= 12) return json(429,{error:'too_many_image_drafts'});
    const path = `${owner}/${crypto.randomUUID()}.png`;
    const {error} = await bucket.upload(path,png,{contentType:'image/png',upsert:false,cacheControl:'600'});
    if (error) return json(500,{error:'upload_failed'});
    return json(201,{path});
  } catch { return json(500,{error:'media_operation_failed'}); }
  finally { await admin.from('profile_media_operations').delete().eq('id',operation); }
});
