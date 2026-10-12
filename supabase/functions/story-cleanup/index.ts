import {createClient} from 'jsr:@supabase/supabase-js@2';
import {cleanupBatch,workerAuthorized} from './cleanup.ts';
Deno.serve(async request => {
 if(!workerAuthorized(request,Deno.env.get('STORY_WORKER_SECRET') ?? '')) return new Response('Forbidden',{status:403});
 const url=Deno.env.get('SUPABASE_URL'),key=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
 if(!url || !key) return new Response('Unavailable',{status:503});
 const client=createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
 let removed=0;
 const remove=async(paths:string[]) => {const {error}=await client.storage.from('story-images').remove(paths);if(error)throw error;};
 try {
  for(let batch=0;batch<25;batch++) {
   const {data,error}=await client.from('stories').select('id,image_path').or(`expires_at.lte.${new Date().toISOString()},deleted_at.not.is.null`).limit(200);
   if(error)throw error;
   if(!data?.length)break;
   await cleanupBatch(data,remove,async ids => {const {error}=await client.from('stories').delete().in('id',ids);if(error)throw error;});
   removed+=data.length;
  }
  for(let batch=0;batch<25;batch++) {
   const {data,error}=await client.rpc('story_cleanup_images');
   if(error)throw error;
   if(!data?.length)break;
   await remove(data);
  }
  const {error}=await client.from('home_feed_snapshots').delete().lte('expires_at',new Date().toISOString());
  if(error)throw error;
  return Response.json({removed});
 } catch { return Response.json({error:'cleanup_failed_retry_next_run'},{status:503}); }
});
