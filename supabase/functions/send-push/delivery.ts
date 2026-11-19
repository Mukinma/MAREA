export type PushJob = {
  notificationId: string;
  recipientId: string;
  token: string;
  kind: string;
  category?: string;
  eventVersion: string;
  title: string;
  body: string;
  ttlSeconds?: number;
};
export function buildFcmMessage(job: PushJob, now = Date.now()) {
  const marea = job.category === undefined
    ? job.kind === "marea_message"
    : job.category === "reminders";
  const ttl = job.ttlSeconds ?? (marea ? 1800 : 86400);
  const data = {
    notification_id: job.notificationId,
    recipient_id: job.recipientId,
    kind: job.kind,
    ...(job.category === undefined ? {} : { category: job.category }),
    event_version: job.eventVersion,
  };
  return {
    message: {
      token: job.token,
      data,
      apns: {
        headers: {
          "apns-push-type": "alert",
          "apns-priority": marea ? "5" : "10",
          "apns-expiration": String(Math.floor(now / 1000) + ttl),
          "apns-collapse-id": job.notificationId,
        },
        payload: {
          aps: {
            alert: { title: job.title, body: job.body },
            "thread-id": job.category ?? job.kind,
            ...(marea ? { "interruption-level": "passive" } : { sound: "default" }),
          },
        },
      },
      // Web is data-only, so the service worker can own the click and display
      // precisely one notification. Platform data overrides the common data.
      webpush: {
        headers: { TTL: String(ttl), Urgency: marea ? "low" : "high" },
        data: { ...data, title: job.title, body: job.body },
      },
      android: {
        priority: marea ? "normal" : "high",
        ttl: `${ttl}s`,
        notification: {
          title: job.title,
          body: job.body,
          tag: job.notificationId,
          icon: "ic_marea_notification",
          channel_id: marea ? "marea_messages" : "marea_activity",
          default_sound: !marea,
        },
      },
    },
  };
}
export function deliveryResult(
  status: number,
  response: unknown,
): "sent" | "retry" | "invalid_token" | "failed" {
  if (status >= 200 && status < 300) return "sent";
  const details =
    (response as { error?: { details?: { errorCode?: string }[] } })?.error
      ?.details;
  if (details?.some((d) => d.errorCode === "UNREGISTERED")) {
    return "invalid_token";
  }
  if (status === 429 || status >= 500 || status === 401 || status === 403) {
    return "retry";
  }
  return "failed";
}

export function workerAuthorized(request: Request, secret: string): boolean {
  const provided = request.headers.get("x-marea-worker-secret") ?? "";
  if (secret.length < 32 || provided.length !== secret.length) return false;
  let difference = 0;
  for (let i = 0; i < secret.length; i++) {
    difference |= secret.charCodeAt(i) ^ provided.charCodeAt(i);
  }
  return difference === 0;
}
