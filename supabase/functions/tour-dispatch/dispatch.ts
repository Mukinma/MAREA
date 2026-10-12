export type Job = { id: string; lease_id: string };
export function authorized(request: Request, secret: string): boolean {
  const bearer = request.headers.get("Authorization") ?? "";
  const expected = `Bearer ${secret}`;
  if (secret.length < 32 || bearer.length !== expected.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) {
    diff |= bearer.charCodeAt(i) ^ expected.charCodeAt(i);
  }
  return diff === 0;
}
export async function runOverrides(job: Job, secret: string) {
  if (
    !/^[0-9a-f-]{36}$/.test(job.id) || !/^[0-9a-f-]{36}$/.test(job.lease_id)
  ) throw new Error("invalid_job");
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${job.id}:${job.lease_id}`),
  );
  const proof = [...new Uint8Array(signature)].map((b) =>
    b.toString(16).padStart(2, "0")
  ).join("");
  return {
    overrides: {
      containerOverrides: [{
        args: ["--job", job.id, "--lease", job.lease_id, "--proof", proof],
      }],
      taskCount: 1,
      timeout: "900s",
    },
  };
}
export function dispatchFailure(status: number): string {
  return [408, 429].includes(status) || status >= 500
    ? "dispatch_unavailable"
    : "dispatch_rejected";
}
