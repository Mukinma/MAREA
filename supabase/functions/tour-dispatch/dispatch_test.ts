import { strict as assert } from "node:assert";
import { createHmac } from "node:crypto";
import { authorized, dispatchFailure, runOverrides } from "./dispatch.ts";
const secret = "test".repeat(16),
  job = {
    id: "11111111-1111-4111-8111-111111111111",
    lease_id: "22222222-2222-4222-8222-222222222222",
  };
assert.equal(
  authorized(
    new Request("https://example.test", {
      headers: { Authorization: `Bearer ${secret}` },
    }),
    secret,
  ),
  true,
);
assert.equal(
  authorized(
    new Request("https://example.test", {
      headers: { Authorization: "Bearer " + secret.slice(1) },
    }),
    secret,
  ),
  false,
);
assert.equal(authorized(new Request("https://example.test"), ""), false);
const body = await runOverrides(job, secret);
assert.equal(
  body.overrides.containerOverrides[0].args[5],
  createHmac("sha256", secret).update(`${job.id}:${job.lease_id}`).digest(
    "hex",
  ),
  "dispatch proof binds identity to exact lease",
);
assert.equal(dispatchFailure(503), "dispatch_unavailable");
assert.equal(dispatchFailure(403), "dispatch_rejected");
console.log("6 dispatcher auth/lease assertions passed.");
