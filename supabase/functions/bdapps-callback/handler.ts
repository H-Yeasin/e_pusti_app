// Routes bdapps callbacks. Each kind has its own URL so it can be entered
// separately in the bdapps portal:
//   …/bdapps-callback/<token>/subscription   subscription notify
//   …/bdapps-callback/<token>/sms            SMS mobile-originated (MO)
//   …/bdapps-callback/<token>/sms-report     SMS delivery report
//   …/bdapps-callback/<token>/ussd           USSD mobile-originated
// <token> is BDAPPS_CALLBACK_TOKEN; bdapps signs nothing, so the secret path
// plus the applicationId check keep strangers out.

import { safeEqual } from "../_shared/http.ts";
import {
  handleSmsMo,
  handleSubscriptionNotify,
  handleUssd,
  type Pust9Context,
} from "../_shared/pust9.ts";

export type CallbackKind = "subscription" | "sms" | "sms-report" | "ussd";
const KINDS: CallbackKind[] = ["subscription", "sms", "sms-report", "ussd"];

export interface CallbackResult {
  status: number;
  body: Record<string, unknown>;
}

const OK: CallbackResult = { status: 200, body: { statusCode: "S1000", statusDetail: "Success" } };

/** Pulls `<token>/<kind>` off the end of the request path. */
export function parsePath(pathname: string): { token: string; kind: string } | null {
  const parts = pathname.split("/").filter(Boolean);
  const i = parts.indexOf("bdapps-callback");
  const rest = i >= 0 ? parts.slice(i + 1) : parts;
  if (rest.length !== 2) return null;
  return { token: rest[0], kind: rest[1] };
}

export async function handleCallback(
  ctx: Pust9Context,
  opts: { expectedToken: string; pathname: string; payload: unknown },
): Promise<CallbackResult> {
  const parsed = parsePath(opts.pathname);
  if (!parsed || !safeEqual(parsed.token, opts.expectedToken)) {
    return { status: 404, body: { statusCode: "E1001", statusDetail: "Not found" } };
  }
  const kind = parsed.kind as CallbackKind;
  if (!KINDS.includes(kind)) {
    return { status: 404, body: { statusCode: "E1001", statusDetail: "Not found" } };
  }
  const payload = (opts.payload ?? {}) as Record<string, string | undefined>;

  // Delivery reports carry no applicationId; everything else must match ours.
  if (kind !== "sms-report" && payload.applicationId !== ctx.bdapps.applicationId) {
    return { status: 403, body: { statusCode: "E1002", statusDetail: "Unknown application" } };
  }

  await ctx.store.logEvent(kind, redact(payload));

  try {
    switch (kind) {
      case "subscription":
        await handleSubscriptionNotify(ctx, payload);
        break;
      case "sms":
        await handleSmsMo(ctx, payload);
        break;
      case "ussd":
        await handleUssd(ctx, payload);
        break;
      case "sms-report":
        break; // logged above; nothing else to do yet
    }
  } catch (e) {
    // Still acknowledge: bdapps retrying won't fix our side, and the event
    // is in bdapps_events for replay.
    ctx.log?.("bdapps-callback failed", { kind, error: String(e) });
  }
  return OK;
}

function redact(payload: Record<string, unknown>): Record<string, unknown> {
  const { password: _password, ...rest } = payload;
  return rest;
}
