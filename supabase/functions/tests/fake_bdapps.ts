import { BdappsClient } from "../_shared/bdapps.ts";
import { MemoryStore } from "../_shared/store.ts";
import type { Pust9Context } from "../_shared/pust9.ts";

export interface Call {
  path: string;
  body: Record<string, unknown>;
}

/** A fake bdapps server: records calls, answers from per-path handlers. */
export class FakeBdapps {
  calls: Call[] = [];
  status = new Map<string, "REGISTERED" | "UNREGISTERED">();
  validOtp = "123456";
  /** subscriberId returned by OTP verify (bdapps may mask it). */
  maskedId: string | null = null;
  failPaths = new Set<string>();

  fetch: typeof fetch = (input, init) => {
    const url = new URL(String(input));
    const body = JSON.parse(String(init?.body ?? "{}"));
    this.calls.push({ path: url.pathname, body });
    if (this.failPaths.has(url.pathname)) {
      return Promise.resolve(Response.json({ statusCode: "E1308", statusDetail: "Failure" }));
    }
    return Promise.resolve(Response.json(this.answer(url.pathname, body)));
  };

  private answer(path: string, body: Record<string, unknown>) {
    const ok = { statusCode: "S1000", statusDetail: "Success", version: "1.0" };
    switch (path) {
      case "/otp/request":
        return { ...ok, referenceNo: `REF-${body.subscriberId}` };
      case "/otp/verify": {
        if (body.otp !== this.validOtp) {
          return { statusCode: "E1854", statusDetail: "Invalid OTP" };
        }
        const tel = String(body.referenceNo).replace(/^REF-/, "");
        const id = this.maskedId ?? tel;
        this.status.set(id, "REGISTERED");
        return { ...ok, subscriptionStatus: "REGISTERED", subscriberId: id };
      }
      case "/subscription/send": {
        const id = String(body.subscriberId);
        const s = body.action === "1" ? "REGISTERED" : "UNREGISTERED";
        this.status.set(id, s);
        return { ...ok, subscriptionStatus: `${s}.` };
      }
      case "/subscription/getStatus":
        return {
          ...ok,
          subscriptionStatus: `${this.status.get(String(body.subscriberId)) ?? "UNREGISTERED"}.`,
        };
      case "/sms/send":
        return { ...ok, requestId: "101901031657410007", destinationResponses: [] };
      case "/ussd/send":
        return { ...ok, requestId: "1", timeStamp: "20190103165801" };
      default:
        return { statusCode: "E1000", statusDetail: "unknown path" };
    }
  }

  sms(): Call[] {
    return this.calls.filter((c) => c.path === "/sms/send");
  }
  ussd(): Call[] {
    return this.calls.filter((c) => c.path === "/ussd/send");
  }
}

export function setup(opts: { now?: Date; tips?: number } = {}) {
  const fake = new FakeBdapps();
  const store = new MemoryStore();
  for (let d = 1; d <= (opts.tips ?? 60); d++) {
    store.tips.set(d, { day_no: d, body_bn: `টিপ ${d}`, body_en: `Tip ${d}` });
  }
  let now = opts.now ?? new Date("2026-11-07T03:00:00Z");
  const ctx: Pust9Context = {
    bdapps: new BdappsClient(
      { baseUrl: "https://bdapps.test", applicationId: "APP_000001", password: "secret" },
      fake.fetch,
    ),
    store,
    now: () => now,
  };
  return {
    fake,
    store,
    ctx,
    advanceDays(n: number) {
      now = new Date(now.getTime() + n * 86_400_000);
    },
  };
}
