import { createClient } from "jsr:@supabase/supabase-js@2.119.0";
import { checkAppSession } from "../_shared/app-session.ts";
import { maxPanoramaBytes, prepareSphere } from "./panorama.ts";

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

async function readBytes(
  request: Pick<Request, "body">,
  limit: number,
  size?: number,
) {
  const reader = request.body?.getReader();
  if (!reader) throw new Error("empty_body");
  const bytes = new Uint8Array(size ?? limit);
  let count = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (count + value.length > bytes.length) throw new Error("body_size");
      bytes.set(value, count);
      count += value.length;
    }
    if (size !== undefined && count !== size) throw new Error("body_size");
    return bytes.subarray(0, count);
  } finally {
    await reader.cancel().catch(() => {});
    reader.releaseLock();
  }
}

function importError(message: string) {
  if (message === "capture_owner_required") {
    return json(404, { error: "capture_not_found" });
  }
  if (message === "invalid_import") {
    return json(422, { error: "invalid_panorama" });
  }
  if (
    [
      "capture_immutable",
      "editable_capture_required",
      "import_file_required",
      "import_job_unavailable",
      "media_operation_unavailable",
    ].includes(message)
  ) {
    return json(409, { error: message });
  }
  return json(503, { error: "import_unavailable" });
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { headers: cors });
  }
  if (request.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }
  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return json(401, { error: "unauthorized" });
  }
  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key || !serviceKey) {
    return json(503, { error: "import_unavailable" });
  }

  const authOptions = { persistSession: false, autoRefreshToken: false };
  const caller = createClient(url, key, {
    global: { headers: { Authorization: authorization } },
    auth: authOptions,
  });
  const { data: identity, error: identityError } = await caller.auth.getUser();
  if (identityError || !identity.user) {
    return json(401, { error: "unauthorized" });
  }
  const denied = await checkAppSession(caller);
  if (denied) return json(denied.status, { error: denied.error });

  let selection: { capture?: unknown; frame?: unknown };
  try {
    selection = JSON.parse(
      new TextDecoder().decode(await readBytes(request, 1024)),
    );
    if (!selection || typeof selection !== "object") {
      throw new Error("invalid_import");
    }
  } catch {
    return json(400, { error: "invalid_import" });
  }
  if (
    typeof selection.capture !== "string" || !uuid.test(selection.capture) ||
    typeof selection.frame !== "string" || !uuid.test(selection.frame)
  ) {
    return json(400, { error: "invalid_import" });
  }

  const owner = identity.user.id;
  const params = {
    p_owner: owner,
    p_capture: selection.capture,
    p_frame: selection.frame,
  };
  const admin = createClient(url, serviceKey, {
    auth: authOptions,
    global: {
      fetch: (input, init) =>
        fetch(input, { ...init, signal: AbortSignal.timeout(40000) }),
    },
  });
  const { data: target, error: targetError } = await admin.rpc(
    "tours_sphere_import_target",
    params,
  );
  if (targetError || !target) return importError(targetError?.message ?? "");
  if (target.job) return json(200, target.job);

  const { data: operation, error: operationError } = await admin.rpc(
    "begin_profile_media_operation",
    { owner_id: owner },
  );
  if (operationError || !operation) {
    return json(409, { error: "media_operation_unavailable" });
  }
  try {
    // Recheck under the operation lease. This also makes retries racing an
    // earlier response reuse the existing result without another upload.
    const { data: current, error: currentError } = await admin.rpc(
      "tours_sphere_import_target",
      params,
    );
    if (currentError || !current) {
      return importError(currentError?.message ?? "");
    }
    if (current.job) return json(200, current.job);
    if (
      !Number.isInteger(current.size) || current.size < 4 ||
      current.size > maxPanoramaBytes
    ) return importError("invalid_import");

    // Read as the author. Existing Storage RLS still governs the private source.
    const source = current.source_path.split("/").map(encodeURIComponent).join(
      "/",
    );
    const response = await fetch(
      `${url}/storage/v1/object/authenticated/tour-inputs/${source}`,
      {
        headers: { Authorization: authorization, apikey: key },
        redirect: "error",
        signal: AbortSignal.timeout(40000),
      },
    );
    if (!response.ok) {
      await response.body?.cancel();
      return json(409, { error: "import_file_required" });
    }
    const bytes = await readBytes(response, maxPanoramaBytes, current.size);
    let panorama;
    try {
      panorama = prepareSphere(bytes);
    } catch (error) {
      return json(422, {
        error: error instanceof Error && error.message === "panorama_dimensions"
          ? "panorama_dimensions"
          : "invalid_panorama",
      });
    }
    if (!current.asset_exists) {
      const { error } = await admin.storage.from("tour-assets").upload(
        current.asset_path,
        panorama.bytes,
        {
          contentType: "image/jpeg",
          upsert: false,
          cacheControl: "600",
        },
      );
      if (error) return json(503, { error: "import_unavailable" });
    }
    const { data: job, error: finishError } = await admin.rpc(
      "tours_sphere_import_finish",
      {
        ...params,
        p_operation: operation,
        p_width: panorama.width,
        p_height: panorama.height,
      },
    );
    if (finishError || !job) return importError(finishError?.message ?? "");
    return json(200, job);
  } catch {
    return json(503, { error: "import_unavailable" });
  } finally {
    await admin.from("profile_media_operations").delete().eq("id", operation);
  }
});
