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
Deno.test("grouped chat uses high priority and the activity channel", () => {
  const result = buildFcmMessage({
    notificationId: "n",
    recipientId: "u",
    token: "t",
    kind: "marea_message",
    category: "chat",
    eventVersion: "v",
    title: "MAREA",
    body: "Nuevo mensaje",
  });
  assertEquals(result.message.data.category, "chat");
  assertEquals(result.message.android.priority, "high");
  assertEquals(
    result.message.android.notification.channel_id,
    "marea_activity",
  );
  assertEquals(result.message.android.notification.default_sound, true);
  assertEquals(result.message.android.ttl, "86400s");
  assertEquals(result.message.apns.headers["apns-push-type"], "alert");
  assertEquals(result.message.apns.headers["apns-collapse-id"], "n");
  assertEquals(result.message.apns.payload.aps.alert.body, "Nuevo mensaje");
  assertEquals(result.message.apns.payload.aps.sound, "default");
  assertEquals(result.message.webpush.headers.Urgency, "high");
  assertEquals(result.message.webpush.data, {
    ...result.message.data, title: "MAREA", body: "Nuevo mensaje",
  });
  assertEquals("notification" in result.message, false);
});
Deno.test("editorial reminders retain their existing quiet channel", () => {
  const result = buildFcmMessage({
    notificationId: "n",
    recipientId: "u",
    token: "t",
    kind: "marea_message",
    category: "reminders",
    eventVersion: "v",
    title: "MAREA",
    body: "Un recordatorio",
    ttlSeconds: 42,
  }, 1000000);
  assertEquals(result.message.data.category, "reminders");
  assertEquals(result.message.android.priority, "normal");
  assertEquals(
    result.message.android.notification.channel_id,
    "marea_messages",
  );
  assertEquals(result.message.android.notification.default_sound, false);
  assertEquals(result.message.android.ttl, "42s");
  assertEquals(result.message.apns.headers["apns-expiration"], "1042");
  assertEquals(result.message.apns.payload.aps["interruption-level"], "passive");
  assertEquals(result.message.apns.payload.aps.sound, undefined);
  assertEquals(result.message.webpush.headers, { TTL: "42", Urgency: "low" });
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
