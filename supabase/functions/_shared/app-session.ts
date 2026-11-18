import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

type SessionDenial = {
  status: 401 | 403 | 503;
  error: "session_invalid" | "mfa_required" | "session_check_unavailable";
};

/** Validate the request's JWT session before using a service-role client. */
export async function checkAppSession(
  caller: SupabaseClient,
): Promise<SessionDenial | null> {
  try {
    const { error } = await caller.rpc("require_app_session");
    if (!error) return null;
    if (error.message === "session_invalid") {
      return { status: 401, error: "session_invalid" };
    }
    if (error.message === "mfa_required") {
      return { status: 403, error: "mfa_required" };
    }
  } catch {
    // Treat a failed authorization check as unavailable.
  }
  return { status: 503, error: "session_check_unavailable" };
}
