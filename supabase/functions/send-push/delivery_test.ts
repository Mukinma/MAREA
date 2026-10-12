import { assertEquals } from "jsr:@std/assert@1";
import {
  buildFcmMessage,
  deliveryResult,
  workerAuthorized,
} from "./delivery.ts";

Deno.test("FCM keeps identity and stable tags without exposing arbitrary URLs", () => {
  const result = buildFcmMessage({
    notificationId: "n",
    recipientId: "u",
    token: "t",
    kind: "comment",
    eventVersion: "v",
    title: "MAREA",
    body: "Nuevo comentario",
  });
  assertEquals(result.message.data, {
    notification_id: "n",
    recipient_id: "u",
    kind: "comment",
    event_version: "v",
  });
  assertEquals(result.message.android.notification.tag, "n");
  assertEquals(
    result.message.android.notification.channel_id,
    "marea_activity",
  );
});
Deno.test("invalid tokens are retired but temporary server failures retry", () => {
  assertEquals(
    deliveryResult(404, {
      error: { details: [{ errorCode: "UNREGISTERED" }] },
    }),
    "invalid_token",
  );
  assertEquals(deliveryResult(503, {}), "retry");
  assertEquals(deliveryResult(429, {}), "retry");
  assertEquals(deliveryResult(400, {}), "failed");
  assertEquals(deliveryResult(200, { name: "projects/p/messages/1" }), "sent");
});
Deno.test("the worker rejects missing, short and incorrect secrets", () => {
  const secret = "012345678901234567890123456789012345";
  assertEquals(
    workerAuthorized(new Request("https://example.com"), secret),
    false,
  );
  assertEquals(
    workerAuthorized(
      new Request("https://example.com", {
        headers: { "x-marea-worker-secret": secret },
      }),
      secret,
    ),
    true,
  );
  assertEquals(
    workerAuthorized(
      new Request("https://example.com", {
        headers: { "x-marea-worker-secret": "bad" },
      }),
      secret,
    ),
    false,
  );
});
