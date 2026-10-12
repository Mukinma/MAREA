import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  authorized,
  dispatchFailure,
  type Job,
  runOverrides,
} from "./dispatch.ts";
const encode = (bytes: Uint8Array) =>
  btoa(String.fromCharCode(...bytes)).replace(/=/g, "").replace(/\+/g, "-")
    .replace(/\//g, "_");
const encodeJson = (input: unknown) =>
  encode(new TextEncoder().encode(JSON.stringify(input)));
let cached: { value: string; expires: number } | null = null;
async function googleToken(
  account: { client_email: string; private_key: string },
) {
  if (cached && cached.expires > Date.now() + 60000) return cached.value;
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${encodeJson({ alg: "RS256", typ: "JWT" })}.${
    encodeJson({
      iss: account.client_email,
      scope: "https://www.googleapis.com/auth/cloud-platform",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    })
  }`;
  const keyBytes = Uint8Array.from(
    atob(account.private_key.replace(/-----[^-]+-----|\s/g, "")),
    (c) => c.charCodeAt(0),
  );
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${encode(new Uint8Array(signature))}`,
    }),
    signal: AbortSignal.timeout(15000),
  });
  if (!response.ok) throw new Error("google_auth_failed");
  const result = await response.json();
  if (typeof result.access_token !== "string") {
    throw new Error("google_auth_failed");
  }
  cached = {
    value: result.access_token,
    expires: Date.now() +
      Math.min(Number(result.expires_in) || 3600, 3600) * 1000,
  };
  return cached.value;
}
const json = (status: number, data: unknown) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }
  const secret = Deno.env.get("TOUR_WORKER_SECRET") ?? "";
  if (!authorized(request, secret)) return json(401, { error: "unauthorized" });
  const url = Deno.env.get("SUPABASE_URL"),
    key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"),
    accountJson = Deno.env.get("TOUR_GOOGLE_SERVICE_ACCOUNT_JSON");
  const project = Deno.env.get("TOUR_GCP_PROJECT") ?? "marea-f6a92",
    region = Deno.env.get("TOUR_GCP_REGION") ?? "us-central1",
    name = Deno.env.get("TOUR_CLOUD_RUN_JOB") ?? "marea-tour-stitch";
  if (
    !url || !key || !accountJson ||
    ![project, region, name].every((v) => /^[a-z][a-z0-9-]{1,62}$/.test(v))
  ) return json(503, { error: "tours_not_configured" });
  const client = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: {
      fetch: (input, init) =>
        fetch(input, { ...init, signal: AbortSignal.timeout(20000) }),
    },
  });
  try {
    const account = JSON.parse(accountJson);
    if (
      account.project_id !== project || !account.client_email ||
      !account.private_key
    ) return json(503, { error: "tours_not_configured" });
    const bearer = await googleToken(account);
    const { data: cleanup, error: cleanupError } = await client.rpc(
      "tours_claim_cleanup",
    );
    if (cleanupError) return json(503, { error: "cleanup_claim_failed" });
    await Promise.all(
      (cleanup ?? []).map(
        async (item: { id: string; lease_id: string; paths: string[] }) => {
          const guard = { p_job: item.id, p_lease: item.lease_id };
          const { data: renewed, error: renewError } = await client.rpc(
            "tours_renew_cleanup",
            guard,
          );
          if (renewError) throw new Error("cleanup_renew_failed");
          if (!renewed) return;
          const { error: removeError } = await client.storage.from(
            "tour-assets",
          ).remove(item.paths);
          const { data: finished, error: finishError } = await client.rpc(
            "tours_finish_cleanup",
            {
              p_job: item.id,
              p_lease: item.lease_id,
              p_success: !removeError,
            },
          );
          if (finishError || !finished) {
            throw new Error("cleanup_finalize_failed");
          }
        },
      ),
    );
    const { data: jobs, error } = await client.rpc("tours_claim_jobs");
    if (error) return json(503, { error: "claim_failed" });
    let dispatched = 0;
    for (const job of (jobs ?? []) as Job[]) {
      const { data: current, error: currentError } = await client.rpc(
        "tours_job_is_current",
        { p_job: job.id, p_lease: job.lease_id },
      );
      if (currentError) throw new Error("check_failed");
      if (!current) continue;
      try {
        const response = await fetch(
          `https://run.googleapis.com/v2/projects/${project}/locations/${region}/jobs/${name}:run`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${bearer}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify(await runOverrides(job, secret)),
            signal: AbortSignal.timeout(15000),
          },
        );
        if (response.ok) dispatched++;
        else {
          if (response.status === 401) cached = null;
          const code = dispatchFailure(response.status);
          await client.rpc("tours_finish_job", {
            p_job: job.id,
            p_lease: job.lease_id,
            p_state: code === "dispatch_unavailable" ? "retry" : "failed",
            p_error: code,
          });
        }
      } catch {
        // An ambiguous network timeout may have launched an execution. Keep its
        // lease until expiry: retrying immediately would launch two executions.
      }
    }
    return json(200, { dispatched });
  } catch {
    return json(503, { error: "dispatch_unavailable" });
  }
});
