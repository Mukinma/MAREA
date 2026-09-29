import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(status: number, body: Record<string, string>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "method_not_allowed" });
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    return jsonResponse(500, { error: "server_not_configured" });
  }

  const userClient = createClient(supabaseUrl, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data, error: userError } = await userClient.auth.getUser();
  if (userError || !data.user) {
    return jsonResponse(401, { error: "unauthorized" });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: ready, error: requestError } = await adminClient.rpc('request_account_deletion', {owner_id: data.user.id});
  if (requestError) return jsonResponse(500, {error: 'account_deletion_failed'});
  if (!ready) return jsonResponse(409, {error: 'media_operation_in_progress_retry_deletion'});
  // All uploads are now blocked. Failed attempts resume from this marker.
  for (const bucketName of ['profile-media', 'post-images', 'mission-images', 'showcase-media']) {
    const bucket = adminClient.storage.from(bucketName);
    for (let batch = 0; batch < 100; batch++) {
      const {data: files, error: listError} = await bucket.list(data.user.id, {limit: 100});
      if (listError) return jsonResponse(500, {error: 'storage_cleanup_failed_retry_deletion'});
      if (!files?.length) break;
      const {error: removeError} = await bucket.remove(files.map(file => `${data.user.id}/${file.name}`));
      if (removeError) return jsonResponse(500, {error: 'storage_cleanup_failed_retry_deletion'});
      if (batch === 99) return jsonResponse(503, {error: 'storage_cleanup_incomplete_retry_deletion'});
    }
  }
  const { error: deleteError } = await adminClient.auth.admin.deleteUser(
    data.user.id,
  );
  if (deleteError) {
    console.error("delete-account failed");
    return jsonResponse(500, { error: "account_deletion_failed" });
  }

  return new Response(null, { status: 204, headers: corsHeaders });
});
