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

const supportedLanguages = new Set(["es", "en"]);

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  if (request.method !== "POST") return json(405, { error: "method_not_allowed" });

  try {
    const body = await request.json();
    const text = typeof body.text === "string" ? body.text.trim() : "";
    const sourceLanguage =
      typeof body.sourceLanguage === "string" ? body.sourceLanguage : "";
    const targetLanguage =
      typeof body.targetLanguage === "string" ? body.targetLanguage : "";

    if (
      text.length === 0 ||
      text.length > 5000 ||
      !supportedLanguages.has(sourceLanguage) ||
      !supportedLanguages.has(targetLanguage)
    ) {
      return json(400, { error: "invalid_translation_request" });
    }
    if (sourceLanguage === targetLanguage) return json(200, { text });

    const apiKey = Deno.env.get("GOOGLE_TRANSLATE_API_KEY");
    if (!apiKey) return json(503, { error: "translation_not_configured" });

    const upstream = await fetch(
      `https://translation.googleapis.com/language/translate/v2?key=${encodeURIComponent(apiKey)}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          q: text,
          source: sourceLanguage,
          target: targetLanguage,
          format: "text",
        }),
        signal: AbortSignal.timeout(10000),
      },
    );
    if (!upstream.ok) return json(502, { error: "translation_provider_failed" });
    const payload = await upstream.json();
    const translated = payload?.data?.translations?.[0]?.translatedText;
    if (typeof translated !== "string" || translated.trim().length === 0) {
      return json(502, { error: "translation_provider_invalid_response" });
    }
    return json(200, { text: translated });
  } catch (error) {
    console.error("translate-content failed", error);
    return json(500, { error: "translation_failed" });
  }
});
