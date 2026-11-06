// Daily PUST9 tip run, called by pg_cron (see the pust9_bdapps migration).
// Requires header x-cron-token = PUST9_CRON_TOKEN. Safe to call twice a day.

import { BdappsClient, bdappsConfigFromEnv } from "../_shared/bdapps.ts";
import { json, safeEqual } from "../_shared/http.ts";
import { dailySend } from "../_shared/pust9.ts";
import { SupabaseStore } from "../_shared/store.ts";

Deno.serve(async (req) => {
  const expected = Deno.env.get("PUST9_CRON_TOKEN");
  const given = req.headers.get("x-cron-token") ?? "";
  if (!expected || !safeEqual(given, expected)) return json({ error: "forbidden" }, 403);

  const result = await dailySend({
    bdapps: new BdappsClient(bdappsConfigFromEnv()),
    store: SupabaseStore.fromEnv(),
    autoStop: Deno.env.get("PUST9_AUTO_STOP") !== "false",
    log: (msg, extra) => console.error(msg, extra),
  });
  if (result.missingTips.length) {
    console.error("pust9: tips missing for days", result.missingTips);
  }
  return json(result);
});
