export type PushJob = {
  notificationId: string;
  recipientId: string;
  token: string;
  kind: string;
  eventVersion: string;
  title: string;
  body: string;
  ttlSeconds?: number;
};
export function buildFcmMessage(job: PushJob) {
  const marea = job.kind === "marea_message";
  return {
    message: {
      token: job.token,
      notification: { title: job.title, body: job.body },
      data: {
        notification_id: job.notificationId,
        recipient_id: job.recipientId,
        kind: job.kind,
        event_version: job.eventVersion,
      },
      android: {
        priority: marea ? "normal" : "high",
        ttl: `${job.ttlSeconds ?? (marea ? 1800 : 86400)}s`,
        notification: {
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
