import { createClient } from "jsr:@supabase/supabase-js@2";
import { normalizePlace } from "./geocoding.ts";
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
Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  if (request.method !== "POST") {
    return json(405, { error: "method_not_allowed" });
  }
  let stage = "request";
  let upstreamStatus: number | undefined;
  try {
    const url = Deno.env.get("SUPABASE_URL")!,
      key = Deno.env.get("SUPABASE_ANON_KEY")!,
      secret = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    if (!url || !key || !secret) {
      return json(500, { error: "server_not_configured" });
    }
    // Anonymous signup pickers can use this read-only endpoint. Content lookups
    // require a valid user and a successful RLS select before privileged writes.
    const admin = createClient(url, secret, {
      auth: { persistSession: false },
    });
    const body = await request.text();
    if (body.length > 2048) return json(413, { error: "input_too_large" });
    const input = JSON.parse(body);
    const mode = input.mode;
    if (!["search", "reverse", "content_city"].includes(mode)) {
      return json(400, { error: "invalid_mode" });
    }
    let latitude = Number(input.latitude), longitude = Number(input.longitude);
    let content: any = null, table: string | null = null;
    if (mode === "content_city") {
      if (
        !["post", "mission"].includes(input.contentKind) ||
        typeof input.contentId !== "string"
      ) return json(400, { error: "invalid_content" });
      const authorization = request.headers.get("Authorization");
      if (!authorization?.startsWith("Bearer ")) {
        return json(401, { error: "unauthorized" });
      }
      const caller = createClient(url, key, {
        global: { headers: { Authorization: authorization } },
        auth: { persistSession: false },
      });
      const { data: user, error: authError } = await caller.auth.getUser();
      if (authError || !user.user) return json(401, { error: "unauthorized" });
      table = input.contentKind === "post" ? "posts" : "missions";
      const { data, error } = await caller.from(table).select(
        "id,location_latitude,location_longitude,location_city,location_city_resolved_at",
      ).eq("id", input.contentId).maybeSingle();
      if (error || !data) return json(404, { error: "content_unavailable" });
      content = data;
      // Always derive from stored content coordinates, never reader coordinates.
      if (
        latitude !== content.location_latitude ||
        longitude !== content.location_longitude
      ) return json(409, { error: "point_changed" });
      if (content.location_city || content.location_city_resolved_at) {
        return json(200, { city: content.location_city });
      }
    }
    if (
      mode !== "search" &&
      (!Number.isFinite(latitude) || !Number.isFinite(longitude) ||
        latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180)
    ) return json(400, { error: "invalid_point" });
    const query = typeof input.query === "string"
      ? input.query.trim().replace(/\s+/g, " ")
      : "";
    if (mode === "search" && (query.length < 3 || query.length > 180)) {
      return json(400, { error: "invalid_query" });
    }
    stage = "provider_config";
    const { data: provider, error: providerError } = await admin.from(
      "geocoding_provider",
    ).select("base_url,user_agent,enabled").eq("id", true).single();
    if (providerError || !provider?.enabled) {
      return json(503, { error: "provider_unavailable" });
    }
    const cacheKey = mode === "search"
      ? `${provider.base_url}:search:es-MX:mx:${query.toLowerCase()}`
      : `${provider.base_url}:reverse:es-MX:${latitude}:${longitude}`;
    const cached = async () => {
      stage = "cache_read";
      const { data, error } = await admin.from("geocoding_cache").select(
        "payload",
      ).eq("cache_key", cacheKey).maybeSingle();
      if (error) throw error;
      return data?.payload;
    };
    let payload = await cached();
    if (payload === undefined) {
      const lease = crypto.randomUUID();
      let claimed = false;
      let leaseRequestedAt = 0;
      const deadline = Date.now() + 10000;
      while (Date.now() < deadline) {
        payload = await cached();
        if (payload !== undefined) break;
        stage = "lease_claim";
        const claimStartedAt = performance.now();
        const { data, error } = await admin.rpc("claim_geocoding_request", {
          request_id: lease,
        });
        if (error) throw error;
        if (data === true) {
          claimed = true;
          leaseRequestedAt = claimStartedAt;
          break;
        }
        await new Promise((resolve) => setTimeout(resolve, 250));
      }
      if (claimed) {
        try {
          // Another request may have populated this key while we waited for the lease.
          payload = await cached();
          if (payload === undefined) {
            const endpoint = new URL(
              mode === "search" ? "search" : "reverse",
              provider.base_url.replace(/\/?$/, "/"),
            );
            endpoint.searchParams.set("format", "jsonv2");
            endpoint.searchParams.set("addressdetails", "1");
            endpoint.searchParams.set("accept-language", "es-MX");
            if (mode === "search") {
              endpoint.searchParams.set("q", query);
              endpoint.searchParams.set("limit", "5");
              endpoint.searchParams.set("countrycodes", "mx");
            } else {
              endpoint.searchParams.set("lat", String(latitude));
              endpoint.searchParams.set("lon", String(longitude));
              endpoint.searchParams.set("zoom", "18");
            }
            // Use a monotonic clock from BEFORE claim RPC: delayed RPC/cache reads consume the lease.
            // Start only with >=10s remaining: 8s abort budget plus 2s safety.
            // Never allow an expired worker to fetch after another acquired its lease.
            const elapsed = performance.now() - leaseRequestedAt;
            if (elapsed < 0 || elapsed >= 20000) {
              return json(429, { error: "geocoding_lease_expired" });
            }
            stage = "provider_fetch";
            const upstream = await fetch(endpoint, {
              headers: {
                "User-Agent": provider.user_agent,
                "Accept-Language": "es-MX",
              },
              signal: AbortSignal.timeout(8000),
            });
            upstreamStatus = upstream.status;
            if (!upstream.ok) throw new Error("provider_request_failed");
            stage = "provider_parse";
            const result = await upstream.json();
            payload = mode === "search"
              ? {
                places: (Array.isArray(result) ? result : []).map(
                  normalizePlace,
                ).filter(Boolean),
              }
              : { place: normalizePlace(result) };
            stage = "cache_write";
            const { error } = await admin.from("geocoding_cache").upsert({
              cache_key: cacheKey,
              payload,
            });
            if (error) throw error;
          }
        } finally {
          await admin.rpc("finish_geocoding_request", { request_id: lease });
        }
      } else if (payload === undefined) {
        return json(429, { error: "geocoding_busy" });
      }
    }
    if (mode === "content_city") {
      const resolvedCity = payload.place?.city ?? null;
      const city = resolvedCity
        ? { ...resolvedCity, point: { latitude, longitude } }
        : null;
      // Point predicate prevents an in-flight resolution from attaching to edits.
      stage = "content_city_write";
      const { data: written, error } = await admin.from(table!).update({
        location_city: city,
        location_city_resolved_at: new Date().toISOString(),
      }).eq("id", content.id).eq("location_latitude", latitude).eq(
        "location_longitude",
        longitude,
      ).is("location_city_resolved_at", null).select("id").maybeSingle();
      if (error) throw error;
      if (!written) {
        const { data: current, error: readError } = await admin.from(table!)
          .select(
            "location_latitude,location_longitude,location_city,location_city_resolved_at",
          ).eq("id", content.id).maybeSingle();
        if (readError) throw readError;
        if (
          !current || current.location_latitude !== latitude ||
          current.location_longitude !== longitude
        ) return json(409, { error: "point_changed" });
        return json(200, { city: current.location_city });
      }
      return json(200, { city });
    }
    return json(200, payload);
  } catch (error) {
    // Closed diagnostics: no URLs, coordinates, raw messages, request bodies or credentials.
    const value = error as { name?: unknown; code?: unknown };
    const errorName =
      typeof value?.name === "string" && /^[A-Za-z0-9_]{1,60}$/.test(value.name)
        ? value.name
        : "Error";
    const databaseCode =
      typeof value?.code === "string" && /^[A-Z0-9]{3,8}$/.test(value.code)
        ? value.code
        : undefined;
    console.warn(
      JSON.stringify({
        event: "geocoding_failed",
        stage,
        errorName,
        upstreamStatus,
        databaseCode,
      }),
    );
    return json(503, { error: "geocoding_unavailable" });
  }
});
