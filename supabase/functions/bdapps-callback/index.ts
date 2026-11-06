// Public endpoint for bdapps callbacks (verify_jwt = false). See handler.ts.

import { BdappsClient, bdappsConfigFromEnv } from "../_shared/bdapps.ts";
import { json } from "../_shared/http.ts";
import { SupabaseStore } from "../_shared/store.ts";
import { handleCallback } from "./handler.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ statusCode: "E1000" }, 405);
  let payload: unknown;
  try {
    payload = await req.json();
  } catch {
    return json({ statusCode: "E1000", statusDetail: "Bad JSON" }, 400);
  }
  const result = await handleCallback(
    {
      bdapps: new BdappsClient(bdappsConfigFromEnv()),
      store: SupabaseStore.fromEnv(),
      autoStop: Deno.env.get("PUST9_AUTO_STOP") !== "false",
      log: (msg, extra) => console.error(msg, extra),
    },
    {
      expectedToken: Deno.env.get("BDAPPS_CALLBACK_TOKEN") ?? crypto.randomUUID(),
      pathname: new URL(req.url).pathname,
      payload,
    },
  );
  return json(result.body, result.status);
});
