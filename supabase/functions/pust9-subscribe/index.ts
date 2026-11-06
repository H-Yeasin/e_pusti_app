// POST /functions/v1/pust9-subscribe  (signed-in users; JWT verified)
// Body: { action: "status" | "request_otp" | "verify_otp" | "unsubscribe", phone?, code? }

import { createClient } from "jsr:@supabase/supabase-js@2";
import { BdappsClient, bdappsConfigFromEnv } from "../_shared/bdapps.ts";
import { json } from "../_shared/http.ts";
import { SupabaseStore } from "../_shared/store.ts";
import { handleSubscribe, type SubscribeBody } from "./handler.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "bad_request" }, 405);

  const auth = req.headers.get("Authorization");
  if (!auth) return json({ error: "unauthorized" }, 401);
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: auth } }, auth: { persistSession: false } },
  );
  const { data, error } = await userClient.auth.getUser();
  if (error || !data.user) return json({ error: "unauthorized" }, 401);

  let body: SubscribeBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad_request" }, 400);
  }

  const result = await handleSubscribe(
    {
      bdapps: new BdappsClient(bdappsConfigFromEnv()),
      store: SupabaseStore.fromEnv(),
      log: (msg, extra) => console.error(msg, extra),
    },
    data.user.id,
    body,
  );
  return json(result, "error" in result && result.error === "bad_request" ? 400 : 200);
});
