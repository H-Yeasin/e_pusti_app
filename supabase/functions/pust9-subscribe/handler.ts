// In-app PUST9 subscription for the signed-in user, through the bdapps OTP
// and subscription APIs. The OTP reference stays in the database.

import { BdappsError, isRobiOrAirtel, toTel } from "../_shared/bdapps.ts";
import { onRegistered, onUnregistered, type Pust9Context } from "../_shared/pust9.ts";
import type { SubscriptionRow } from "../_shared/store.ts";

export const OTP_TTL_MS = 5 * 60_000;
export const OTP_MAX_PER_HOUR = 5;

export type ApiState = "not_subscribed" | "otp_sent" | "subscribed" | "unsubscribed";
export type ApiError =
  | "bad_request"
  | "not_eligible"
  | "invalid_code"
  | "code_expired"
  | "rate_limited"
  | "upstream";

export type ApiResponse =
  | {
    state: ApiState;
    subscribedAt?: string | null;
    day?: number;
    courseDays?: number;
    phone?: string;
  }
  | { error: ApiError; detail?: string };

export interface SubscribeBody {
  action?: string;
  phone?: string;
  code?: string;
  applicationHash?: string;
  device?: string;
  os?: string;
}

export async function handleSubscribe(
  ctx: Pust9Context,
  userId: string,
  body: SubscribeBody,
): Promise<ApiResponse> {
  const now = (ctx.now ?? (() => new Date()))();
  const row = await ctx.store.getSubscription(userId);

  try {
    switch (body.action) {
      case "status":
        return await status(ctx, row);

      case "request_otp": {
        const phone = body.phone?.trim();
        if (!phone) return { error: "bad_request" };
        if (!isRobiOrAirtel(phone)) return { error: "not_eligible" };

        const windowStart = row?.otp_window_start ? new Date(row.otp_window_start) : null;
        const inWindow = windowStart !== null && now.getTime() - windowStart.getTime() < 3600_000;
        const count = inWindow ? row!.otp_requests : 0;
        if (count >= OTP_MAX_PER_HOUR) return { error: "rate_limited" };

        const reference = await ctx.bdapps.requestOtp(phone, {
          applicationHash: body.applicationHash,
          device: body.device,
          os: body.os,
        });
        await ctx.store.saveSubscription({
          user_id: userId,
          phone: `+${toTel(phone).slice(4)}`,
          subscriber_id: row?.subscriber_id ?? null,
          status: row?.status === "registered" ? "registered" : "pending",
          otp_reference: reference,
          otp_expires_at: new Date(now.getTime() + OTP_TTL_MS).toISOString(),
          otp_requests: count + 1,
          otp_window_start: inWindow ? row!.otp_window_start : now.toISOString(),
          subscribed_at: row?.subscribed_at ?? null,
        });
        return { state: "otp_sent" };
      }

      case "verify_otp": {
        const code = body.code?.trim();
        if (!code || !/^\d{4,8}$/.test(code)) return { error: "bad_request" };
        if (!row?.otp_reference) return { error: "code_expired" };
        if (row.otp_expires_at && new Date(row.otp_expires_at) < now) {
          return { error: "code_expired" };
        }
        let result;
        try {
          result = await ctx.bdapps.verifyOtp(row.otp_reference, code);
        } catch (e) {
          if (e instanceof BdappsError && !e.isTransport) return { error: "invalid_code" };
          throw e;
        }
        // bdapps may mask the number; the masked id is the key from now on.
        const subscriberId = result.subscriberId || toTel(row.phone);
        // The member row is created first: the subscription references it.
        const member = await onRegistered(ctx, subscriberId, { userId });
        await ctx.store.saveSubscription({
          ...row,
          subscriber_id: subscriberId,
          status: "registered",
          otp_reference: null,
          otp_expires_at: null,
          subscribed_at: member.joined_at,
        });
        return {
          state: "subscribed",
          subscribedAt: member.joined_at,
          day: Math.max(member.last_day_sent, 1),
          courseDays: await ctx.store.courseDays(),
          phone: row.phone,
        };
      }

      case "unsubscribe": {
        if (!row?.subscriber_id) return { state: "not_subscribed" };
        await ctx.bdapps.setSubscription(row.subscriber_id, false);
        await onUnregistered(ctx, row.subscriber_id);
        return { state: "unsubscribed", phone: row.phone };
      }

      default:
        return { error: "bad_request" };
    }
  } catch (e) {
    ctx.log?.("pust9-subscribe failed", { action: body.action, error: String(e) });
    return { error: "upstream", detail: e instanceof BdappsError ? e.statusCode : undefined };
  }
}

async function status(ctx: Pust9Context, row: SubscriptionRow | null): Promise<ApiResponse> {
  if (!row) return { state: "not_subscribed" };
  if (!row.subscriber_id) {
    const pending = row.otp_reference && row.otp_expires_at &&
      new Date(row.otp_expires_at) > (ctx.now ?? (() => new Date()))();
    return { state: pending ? "otp_sent" : "not_subscribed", phone: row.phone };
  }

  // Refresh from bdapps; the stored state is the fallback when it's down.
  try {
    const live = await ctx.bdapps.getStatus(row.subscriber_id);
    if (live === "REGISTERED" && row.status !== "registered") {
      await onRegistered(ctx, row.subscriber_id, { userId: row.user_id });
    } else if (live === "UNREGISTERED" && row.status === "registered") {
      await onUnregistered(ctx, row.subscriber_id);
    }
  } catch (e) {
    ctx.log?.("pust9 status refresh failed", { error: String(e) });
  }

  const member = await ctx.store.getMember(row.subscriber_id);
  if (member?.status === "registered") {
    return {
      state: "subscribed",
      subscribedAt: member.joined_at,
      day: Math.max(member.last_day_sent, 1),
      courseDays: await ctx.store.courseDays(),
      phone: row.phone,
    };
  }
  return { state: "unsubscribed", phone: row.phone };
}
