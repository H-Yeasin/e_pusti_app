// Persistence for PUST9. The functions depend on the Pust9Store interface so
// tests can use MemoryStore; production uses SupabaseStore (service role).

import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";

export type MemberStatus = "registered" | "unregistered";
export type SubscriptionRowStatus = "pending" | "registered" | "unregistered";

export interface Member {
  subscriber_id: string;
  status: MemberStatus;
  joined_at: string;
  left_at: string | null;
  last_day_sent: number;
  last_sent_on: string | null; // YYYY-MM-DD, Asia/Dhaka
  user_id: string | null;
}

export interface SubscriptionRow {
  user_id: string;
  phone: string;
  subscriber_id: string | null;
  status: SubscriptionRowStatus;
  otp_reference: string | null;
  otp_expires_at: string | null;
  otp_requests: number;
  otp_window_start: string | null;
  subscribed_at: string | null;
}

export interface Tip {
  day_no: number;
  body_bn: string;
  body_en: string | null;
}

export interface Pust9Store {
  getMember(subscriberId: string): Promise<Member | null>;
  saveMember(member: Member): Promise<void>;
  /** Registered members not yet sent today's tip. */
  dueMembers(today: string): Promise<Member[]>;

  getSubscription(userId: string): Promise<SubscriptionRow | null>;
  /** Links an in-app subscription to the member it belongs to. */
  subscriptionsForMember(subscriberId: string): Promise<SubscriptionRow[]>;
  saveSubscription(row: SubscriptionRow): Promise<void>;

  tip(day: number): Promise<Tip | null>;
  courseDays(): Promise<number>;

  logEvent(kind: string, payload: unknown): Promise<void>;

  getUssdState(sessionId: string): Promise<string | null>;
  setUssdState(sessionId: string, subscriberId: string, state: string): Promise<void>;
  endUssd(sessionId: string): Promise<void>;
}

export const DEFAULT_COURSE_DAYS = 60;

export class SupabaseStore implements Pust9Store {
  constructor(private readonly db: SupabaseClient) {}

  static fromEnv(): SupabaseStore {
    const url = Deno.env.get("SUPABASE_URL");
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !key) throw new Error("Supabase service credentials missing");
    return new SupabaseStore(
      createClient(url, key, { auth: { persistSession: false } }),
    );
  }

  private static check<T>(res: { data: T; error: { message: string } | null }): T {
    if (res.error) throw new Error(res.error.message);
    return res.data;
  }

  async getMember(subscriberId: string) {
    return SupabaseStore.check(
      await this.db.from("pust9_members").select("*")
        .eq("subscriber_id", subscriberId).maybeSingle(),
    ) as Member | null;
  }

  async saveMember(member: Member) {
    SupabaseStore.check(
      await this.db.from("pust9_members").upsert({
        ...member,
        updated_at: new Date().toISOString(),
      }),
    );
  }

  async dueMembers(today: string) {
    return SupabaseStore.check(
      await this.db.from("pust9_members").select("*")
        .eq("status", "registered")
        .or(`last_sent_on.is.null,last_sent_on.lt.${today}`)
        .limit(10000),
    ) as Member[];
  }

  async getSubscription(userId: string) {
    return SupabaseStore.check(
      await this.db.from("pust9_subscriptions").select("*")
        .eq("user_id", userId).maybeSingle(),
    ) as SubscriptionRow | null;
  }

  async subscriptionsForMember(subscriberId: string) {
    return SupabaseStore.check(
      await this.db.from("pust9_subscriptions").select("*")
        .eq("subscriber_id", subscriberId),
    ) as SubscriptionRow[];
  }

  async saveSubscription(row: SubscriptionRow) {
    SupabaseStore.check(
      await this.db.from("pust9_subscriptions").upsert({
        ...row,
        updated_at: new Date().toISOString(),
      }),
    );
  }

  async tip(day: number) {
    return SupabaseStore.check(
      await this.db.from("pust9_tips").select("*").eq("day_no", day)
        .maybeSingle(),
    ) as Tip | null;
  }

  async courseDays() {
    const row = SupabaseStore.check(
      await this.db.from("app_config").select("value").eq("key", "mobile")
        .maybeSingle(),
    ) as { value?: { pust9?: { courseDays?: number } } } | null;
    const days = row?.value?.pust9?.courseDays;
    return typeof days === "number" && days > 0 ? days : DEFAULT_COURSE_DAYS;
  }

  async logEvent(kind: string, payload: unknown) {
    SupabaseStore.check(
      await this.db.from("bdapps_events").insert({ kind, payload }),
    );
  }

  async getUssdState(sessionId: string) {
    const row = SupabaseStore.check(
      await this.db.from("ussd_sessions").select("state")
        .eq("session_id", sessionId).maybeSingle(),
    ) as { state: string } | null;
    return row?.state ?? null;
  }

  async setUssdState(sessionId: string, subscriberId: string, state: string) {
    SupabaseStore.check(
      await this.db.from("ussd_sessions").upsert({
        session_id: sessionId,
        subscriber_id: subscriberId,
        state,
        updated_at: new Date().toISOString(),
      }),
    );
  }

  async endUssd(sessionId: string) {
    SupabaseStore.check(
      await this.db.from("ussd_sessions").delete().eq("session_id", sessionId),
    );
  }
}

/** In-memory store for tests and local experiments. */
export class MemoryStore implements Pust9Store {
  members = new Map<string, Member>();
  subscriptions = new Map<string, SubscriptionRow>();
  tips = new Map<number, Tip>();
  events: { kind: string; payload: unknown }[] = [];
  ussd = new Map<string, string>();
  days = DEFAULT_COURSE_DAYS;

  getMember(id: string) {
    return Promise.resolve(this.members.get(id) ?? null);
  }
  saveMember(m: Member) {
    this.members.set(m.subscriber_id, { ...m });
    return Promise.resolve();
  }
  dueMembers(today: string) {
    return Promise.resolve(
      [...this.members.values()].filter((m) =>
        m.status === "registered" &&
        (m.last_sent_on === null || m.last_sent_on < today)
      ).map((m) => ({ ...m })),
    );
  }
  getSubscription(userId: string) {
    const row = this.subscriptions.get(userId);
    return Promise.resolve(row ? { ...row } : null);
  }
  subscriptionsForMember(id: string) {
    return Promise.resolve(
      [...this.subscriptions.values()].filter((s) => s.subscriber_id === id)
        .map((s) => ({ ...s })),
    );
  }
  saveSubscription(row: SubscriptionRow) {
    this.subscriptions.set(row.user_id, { ...row });
    return Promise.resolve();
  }
  tip(day: number) {
    return Promise.resolve(this.tips.get(day) ?? null);
  }
  courseDays() {
    return Promise.resolve(this.days);
  }
  logEvent(kind: string, payload: unknown) {
    this.events.push({ kind, payload });
    return Promise.resolve();
  }
  getUssdState(id: string) {
    return Promise.resolve(this.ussd.get(id) ?? null);
  }
  setUssdState(id: string, _sub: string, state: string) {
    this.ussd.set(id, state);
    return Promise.resolve();
  }
  endUssd(id: string) {
    this.ussd.delete(id);
    return Promise.resolve();
  }
}
