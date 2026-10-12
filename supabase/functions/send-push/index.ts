import { createClient } from "jsr:@supabase/supabase-js@2";
import {
  buildFcmMessage,
  deliveryResult,
  workerAuthorized,
} from "./delivery.ts";

const encode = (input: Uint8Array) =>
  btoa(String.fromCharCode(...input))
    .replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
const encodeJson = (input: unknown) =>
  encode(new TextEncoder().encode(JSON.stringify(input)));
let cachedToken: { value: string; expiresAt: number } | null = null;

async function accessToken(
  account: { client_email: string; private_key: string },
) {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60000) {
    return cachedToken.value;
  }
  const issued = Math.floor(Date.now() / 1000);
  const unsigned = `${encodeJson({ alg: "RS256", typ: "JWT" })}.${
    encodeJson({
      iss: account.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: issued,
      exp: issued + 3600,
    })
  }`;
  const bytes = Uint8Array.from(
    atob(account.private_key.replace(/-----[^-]+-----|\s/g, "")),
    (c) => c.charCodeAt(0),
  );
  const key = await crypto.subtle.importKey(
    "pkcs8",
    bytes,
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
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${encode(new Uint8Array(signature))}`,
    }),
    signal: AbortSignal.timeout(15000),
  });
  if (!response.ok) throw new Error("fcm_auth_failed");
  const result = await response.json();
  if (typeof result.access_token !== "string") {
    throw new Error("fcm_auth_failed");
  }
  cachedToken = {
    value: result.access_token,
    expiresAt: Date.now() + Number(result.expires_in ?? 3600) * 1000,
  };
  return cachedToken.value;
}

type ClaimedJob = {
  queue_id: string;
  lease_id: string;
  notification_id: string;
  recipient_id: string;
  kind: string;
  event_version: string;
  token: string;
  title: string;
  body: string;
  ttl_seconds: number;
};
const json = (status: number, data: unknown) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }
  if (!workerAuthorized(request, Deno.env.get("PUSH_WORKER_SECRET") ?? "")) {
    return json(401, { error: "unauthorized" });
  }
  const url = Deno.env.get("SUPABASE_URL"),
    key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const accountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
  if (!url || !key || !accountJson) {
    return json(503, { error: "push_not_configured" });
  }
  try {
    const account = JSON.parse(accountJson);
    if (!account.project_id || !account.client_email || !account.private_key) {
      return json(503, { error: "push_not_configured" });
    }
    const bearer = await accessToken(account);
    const client = createClient(url, key, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data, error } = await client.rpc("claim_push_jobs", {
      batch_size: 20,
    });
    if (error) return json(503, { error: "push_claim_failed" });
    const jobs = (data ?? []) as ClaimedJob[];
    let sent = 0;
    // Four workers bound delivery duration below the two-minute lease.
    let cursor = 0;
    await Promise.all(
      Array.from({ length: Math.min(4, jobs.length) }, async () => {
        while (cursor < jobs.length) {
          const job = jobs[cursor++];
          let result: string = "retry";
          try {
            const { data: current, error: checkError } = await client.rpc(
              "push_job_is_current",
              { job: job.queue_id, lease: job.lease_id },
            );
            if (checkError) throw new Error("push_check_failed");
            if (!current) result = "canceled";
            else {
              const response = await fetch(
                `https://fcm.googleapis.com/v1/projects/${
                  encodeURIComponent(account.project_id)
                }/messages:send`,
                {
                  method: "POST",
                  headers: {
                    Authorization: `Bearer ${bearer}`,
                    "Content-Type": "application/json",
                  },
                  body: JSON.stringify(
                    buildFcmMessage({
                      notificationId: job.notification_id,
                      recipientId: job.recipient_id,
                      kind: job.kind,
                      eventVersion: job.event_version,
                      token: job.token,
                      title: job.title,
                      body: job.body,
                      ttlSeconds: job.ttl_seconds,
                    }),
                  ),
                  signal: AbortSignal.timeout(15000),
                },
              );
              result = deliveryResult(
                response.status,
                await response.json().catch(() => ({})),
              );
              if (response.status === 401) cachedToken = null;
              if (result === "sent") sent++;
            }
          } catch (_) {
            result = "retry";
          }
          const { error: finishError } = await client.rpc("finish_push_job", {
            job: job.queue_id,
            lease: job.lease_id,
            result,
          });
          if (finishError) console.error("push_finish_failed");
        }
      }),
    );
    return json(200, { processed: jobs.length, sent });
  } catch (_) {
    return json(503, { error: "push_delivery_unavailable" });
  }
});
