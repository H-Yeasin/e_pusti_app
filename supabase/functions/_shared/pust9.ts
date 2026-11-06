// PUST9 rules shared by the Edge Functions: what happens when someone joins
// or leaves, the daily tip, SMS keywords and the USSD menu.

import { BdappsClient, BdappsError, parseSubscriptionStatus, toTel } from "./bdapps.ts";
import type { Member, Pust9Store } from "./store.ts";

export interface Pust9Context {
  bdapps: BdappsClient;
  store: Pust9Store;
  now?: () => Date;
  /** After the last day, stop the subscription so nobody pays past the course. */
  autoStop?: boolean;
  log?: (msg: string, extra?: unknown) => void;
}

const now = (ctx: Pust9Context) => (ctx.now ?? (() => new Date()))();

/** Calendar date in Asia/Dhaka (UTC+6, no DST). */
export function dhakaDate(d: Date): string {
  return new Date(d.getTime() + 6 * 3600_000).toISOString().slice(0, 10);
}

export const SMS = {
  welcome: (days: number) =>
    `PUST9-এ স্বাগতম! আগামী ${
      toBn(days)
    } দিন প্রতিদিন একটি পুষ্টি পরামর্শ পাবেন। বন্ধ করতে STOP PUST9 লিখে 21213 নম্বরে পাঠান।`,
  tip: (day: number, body: string) => `PUST9 দিন ${toBn(day)}: ${body}`,
  completed: (days: number) =>
    `অভিনন্দন! আপনি PUST9-এর ${
      toBn(days)
    } দিনের কোর্স শেষ করেছেন। সাবস্ক্রিপশন বন্ধ করা হয়েছে, আর কোনো চার্জ কাটা হবে না।`,
  stopped: "PUST9 সাবস্ক্রিপশন বন্ধ হয়েছে। আবার শুরু করতে START PUST9 লিখে 21213 নম্বরে পাঠান।",
  help:
    "PUST9: প্রতিদিন একটি পুষ্টি পরামর্শ। শুরু: START PUST9, বন্ধ: STOP PUST9 — 21213 নম্বরে পাঠান। অথবা ডায়াল করুন *213*02025#",
};

function toBn(n: number): string {
  return String(n).replace(/\d/g, (d) => "০১২৩৪৫৬৭৮৯"[Number(d)]);
}

/**
 * Someone is now registered (OTP verify, notify callback, SMS or USSD).
 * Idempotent: a member already registered is only linked to the user.
 */
export async function onRegistered(
  ctx: Pust9Context,
  subscriberId: string,
  opts: { userId?: string } = {},
): Promise<Member> {
  const existing = await ctx.store.getMember(subscriberId);
  if (existing?.status === "registered") {
    if (opts.userId && existing.user_id !== opts.userId) {
      existing.user_id = opts.userId;
      await ctx.store.saveMember(existing);
    }
    return existing;
  }
  const member: Member = {
    subscriber_id: subscriberId,
    status: "registered",
    joined_at: now(ctx).toISOString(),
    left_at: null,
    last_day_sent: 0,
    last_sent_on: null,
    user_id: opts.userId ?? existing?.user_id ?? null,
  };
  await ctx.store.saveMember(member);
  for (const sub of await ctx.store.subscriptionsForMember(subscriberId)) {
    if (sub.status !== "registered") {
      await ctx.store.saveSubscription({
        ...sub,
        status: "registered",
        subscribed_at: member.joined_at,
      });
    }
  }
  const days = await ctx.store.courseDays();
  await safeSms(ctx, [subscriberId], SMS.welcome(days));
  // Day 1 straight away, so the first tip doesn't wait for tomorrow's run.
  return await sendNextTip(ctx, member) ?? member;
}

export async function onUnregistered(
  ctx: Pust9Context,
  subscriberId: string,
): Promise<void> {
  const existing = await ctx.store.getMember(subscriberId);
  if (existing && existing.status !== "unregistered") {
    await ctx.store.saveMember({
      ...existing,
      status: "unregistered",
      left_at: now(ctx).toISOString(),
    });
  } else if (!existing) {
    await ctx.store.saveMember({
      subscriber_id: subscriberId,
      status: "unregistered",
      joined_at: now(ctx).toISOString(),
      left_at: now(ctx).toISOString(),
      last_day_sent: 0,
      last_sent_on: null,
      user_id: null,
    });
  }
  for (const sub of await ctx.store.subscriptionsForMember(subscriberId)) {
    if (sub.status !== "unregistered") {
      await ctx.store.saveSubscription({ ...sub, status: "unregistered" });
    }
  }
}

/** Sends one member their next tip; null when there is nothing to send. */
async function sendNextTip(ctx: Pust9Context, member: Member): Promise<Member | null> {
  const today = dhakaDate(now(ctx));
  const day = member.last_day_sent + 1;
  const tip = await ctx.store.tip(day);
  if (!tip) {
    ctx.log?.("pust9: no tip seeded", { day });
    return null;
  }
  await ctx.bdapps.sendSms([member.subscriber_id], SMS.tip(day, tip.body_bn), {
    deliveryReport: true,
  });
  const updated = { ...member, last_day_sent: day, last_sent_on: today };
  await ctx.store.saveMember(updated);
  return updated;
}

export interface DailySendResult {
  sent: number;
  completed: number;
  missingTips: number[];
  failedBatches: number;
}

/**
 * The daily run: each registered member not yet served today gets their next
 * tip. Members on the same day share one bdapps request (batches of 100).
 * Running twice on one day sends nothing the second time.
 */
export async function dailySend(ctx: Pust9Context): Promise<DailySendResult> {
  const today = dhakaDate(now(ctx));
  const days = await ctx.store.courseDays();
  const due = await ctx.store.dueMembers(today);
  const result: DailySendResult = { sent: 0, completed: 0, missingTips: [], failedBatches: 0 };

  const byDay = new Map<number, Member[]>();
  for (const m of due) {
    if (m.last_day_sent >= days) {
      await finishCourse(ctx, m, days);
      result.completed++;
      continue;
    }
    const day = m.last_day_sent + 1;
    byDay.set(day, [...(byDay.get(day) ?? []), m]);
  }

  for (const [day, members] of [...byDay].sort((a, b) => a[0] - b[0])) {
    const tip = await ctx.store.tip(day);
    if (!tip) {
      result.missingTips.push(day);
      continue;
    }
    for (let i = 0; i < members.length; i += 100) {
      const batch = members.slice(i, i + 100);
      try {
        await ctx.bdapps.sendSms(
          batch.map((m) => m.subscriber_id),
          SMS.tip(day, tip.body_bn),
          { deliveryReport: true },
        );
      } catch (e) {
        result.failedBatches++;
        ctx.log?.("pust9: batch failed", { day, error: String(e) });
        continue; // not marked sent, so tomorrow's run retries
      }
      for (const m of batch) {
        await ctx.store.saveMember({ ...m, last_day_sent: day, last_sent_on: today });
      }
      result.sent += batch.length;
    }
  }
  return result;
}

async function finishCourse(ctx: Pust9Context, m: Member, days: number) {
  if (ctx.autoStop === false) return;
  await safeSms(ctx, [m.subscriber_id], SMS.completed(days));
  try {
    await ctx.bdapps.setSubscription(m.subscriber_id, false);
  } catch (e) {
    ctx.log?.("pust9: auto-stop failed", { error: String(e) });
    return;
  }
  await onUnregistered(ctx, m.subscriber_id);
}

async function safeSms(ctx: Pust9Context, to: string[], message: string) {
  try {
    await ctx.bdapps.sendSms(to, message);
  } catch (e) {
    ctx.log?.("pust9: sms failed", { error: String(e) });
  }
}

// --- Callbacks from bdapps --------------------------------------------------

/** subscription/notify: REGISTERED or UNREGISTERED. */
export async function handleSubscriptionNotify(
  ctx: Pust9Context,
  payload: { subscriberId?: string; status?: string },
): Promise<void> {
  if (!payload.subscriberId) return;
  const status = parseSubscriptionStatus(payload.status);
  if (status === "REGISTERED") {
    await onRegistered(ctx, payload.subscriberId);
  } else if (status === "UNREGISTERED") {
    await onUnregistered(ctx, payload.subscriberId);
  }
}

/** sms/receive: START / STOP / anything else gets help. */
export async function handleSmsMo(
  ctx: Pust9Context,
  payload: { sourceAddress?: string; message?: string },
): Promise<"subscribed" | "stopped" | "help" | "ignored"> {
  const from = payload.sourceAddress;
  if (!from) return "ignored";
  const text = (payload.message ?? "").trim().toUpperCase();
  const words = text.split(/\s+/);
  if (words.some((w) => ["STOP", "UNREG", "OFF", "CANCEL"].includes(w))) {
    await ctx.bdapps.setSubscription(from, false);
    await onUnregistered(ctx, from);
    await safeSms(ctx, [from], SMS.stopped);
    return "stopped";
  }
  if (words.some((w) => ["START", "REG", "ON", "1"].includes(w))) {
    // bdapps confirms with the charge prompt; the notify callback (or this
    // response) moves the member to registered.
    const status = await ctx.bdapps.setSubscription(from, true);
    if (status === "REGISTERED") await onRegistered(ctx, from);
    return "subscribed";
  }
  await safeSms(ctx, [from], SMS.help);
  return "help";
}

// --- USSD menu --------------------------------------------------------------
// bdapps USSD uses encoding 440 (plain ASCII), so the menu is in English.

export const USSD = {
  main:
    "PUST9: 1 nutrition tip/day by SMS\nTk 1/day + VAT\n1. Subscribe\n2. Today's tip\n3. My status\n4. Stop\n0. Exit",
  mainSubscribed: "PUST9 (subscribed)\n2. Today's tip\n3. My status\n4. Stop\n0. Exit",
  confirmStop: "Stop PUST9? You will get no more tips.\n1. Yes, stop\n0. Back",
  subscribed: "Thank you! PUST9 has started. Your first tip comes by SMS.",
  subscribePending: "Please confirm the charge when your operator asks. Tips start after that.",
  stopped: "PUST9 is stopped. Dial again any time to restart.",
  notSubscribed: "You are not subscribed. Dial again and choose 1 to subscribe.",
  tipSent: "Today's tip has been sent to you by SMS.",
  noTip: "No tip yet. Your next tip comes by SMS.",
  status: (day: number, days: number) => `PUST9 is active. Day ${day} of ${days}.`,
  bye: "Thank you for using PUST9.",
  invalid: "Invalid choice.",
  error: "Sorry, please try again later.",
};

export interface UssdReply {
  message: string;
  final: boolean;
}

export async function handleUssd(
  ctx: Pust9Context,
  payload: { sessionId?: string; sourceAddress?: string; message?: string; ussdOperation?: string },
): Promise<UssdReply | null> {
  const sessionId = payload.sessionId;
  const from = payload.sourceAddress;
  if (!sessionId || !from) return null;
  const subscriberId = toTel(from);

  const reply = await ussdStep(ctx, sessionId, subscriberId, payload);
  if (reply.final) {
    await ctx.store.endUssd(sessionId);
  }
  await ctx.bdapps.sendUssd({
    sessionId,
    destination: subscriberId,
    message: reply.message,
    final: reply.final,
  });
  return reply;
}

async function ussdStep(
  ctx: Pust9Context,
  sessionId: string,
  subscriberId: string,
  payload: { message?: string; ussdOperation?: string },
): Promise<UssdReply> {
  const member = await ctx.store.getMember(subscriberId);
  const registered = member?.status === "registered";
  const state = payload.ussdOperation === "mo-init"
    ? null
    : await ctx.store.getUssdState(sessionId);
  const input = (payload.message ?? "").trim();

  const showMain = async (): Promise<UssdReply> => {
    await ctx.store.setUssdState(sessionId, subscriberId, "main");
    return { message: registered ? USSD.mainSubscribed : USSD.main, final: false };
  };

  if (state === null) return await showMain();

  try {
    if (state === "confirm-stop") {
      if (input === "1") {
        await ctx.bdapps.setSubscription(subscriberId, false);
        await onUnregistered(ctx, subscriberId);
        return { message: USSD.stopped, final: true };
      }
      return await showMain();
    }

    switch (input) {
      case "1": {
        if (registered) {
          return {
            message: USSD.status(member!.last_day_sent, await ctx.store.courseDays()),
            final: true,
          };
        }
        const status = await ctx.bdapps.setSubscription(subscriberId, true);
        if (status === "REGISTERED") {
          await onRegistered(ctx, subscriberId);
          return { message: USSD.subscribed, final: true };
        }
        return { message: USSD.subscribePending, final: true };
      }
      case "2": {
        if (!registered) return { message: USSD.notSubscribed, final: true };
        const day = Math.max(member!.last_day_sent, 1);
        const tip = await ctx.store.tip(day);
        if (!tip) return { message: USSD.noTip, final: true };
        await ctx.bdapps.sendSms([subscriberId], SMS.tip(day, tip.body_bn));
        return { message: USSD.tipSent, final: true };
      }
      case "3": {
        if (!registered) return { message: USSD.notSubscribed, final: true };
        return {
          message: USSD.status(Math.max(member!.last_day_sent, 1), await ctx.store.courseDays()),
          final: true,
        };
      }
      case "4": {
        if (!registered) return { message: USSD.notSubscribed, final: true };
        await ctx.store.setUssdState(sessionId, subscriberId, "confirm-stop");
        return { message: USSD.confirmStop, final: false };
      }
      case "0":
        return { message: USSD.bye, final: true };
      default:
        return {
          message: `${USSD.invalid}\n${registered ? USSD.mainSubscribed : USSD.main}`,
          final: false,
        };
    }
  } catch (e) {
    ctx.log?.("pust9: ussd failed", { error: String(e) });
    return { message: USSD.error, final: true };
  }
}

export { BdappsError };
