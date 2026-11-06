import { assert, assertEquals, assertRejects } from "jsr:@std/assert@1";
import {
  BdappsClient,
  BdappsError,
  isRobiOrAirtel,
  parseSubscriptionStatus,
  toTel,
} from "../_shared/bdapps.ts";
import { dailySend, dhakaDate, handleUssd, onRegistered, USSD } from "../_shared/pust9.ts";
import { handleCallback, parsePath } from "../bdapps-callback/handler.ts";
import { handleSubscribe, OTP_MAX_PER_HOUR } from "../pust9-subscribe/handler.ts";
import { setup } from "./fake_bdapps.ts";

const USER = "00000000-0000-0000-0000-000000000001";
const ROBI = "+8801812345678";

// --- bdapps client -----------------------------------------------------------

Deno.test("toTel normalises numbers and passes masked ids", () => {
  assertEquals(toTel("+8801812345678"), "tel:8801812345678");
  assertEquals(toTel("01812345678"), "tel:8801812345678");
  assertEquals(toTel("1812345678"), "tel:8801812345678");
  assertEquals(toTel("tel:abcMASKED"), "tel:abcMASKED");
});

Deno.test("only Robi (018) and Airtel (016) are eligible", () => {
  assert(isRobiOrAirtel("+8801812345678"));
  assert(isRobiOrAirtel("01612345678"));
  assert(!isRobiOrAirtel("01712345678"));
  assert(!isRobiOrAirtel("01912345678"));
});

Deno.test("subscription status tolerates bdapps' trailing dots", () => {
  assertEquals(parseSubscriptionStatus("UNREGISTERED."), "UNREGISTERED");
  assertEquals(parseSubscriptionStatus("REGISTERED"), "REGISTERED");
  assertEquals(parseSubscriptionStatus(undefined), "UNREGISTERED");
});

Deno.test("client sends credentials and maps non-S1000 to BdappsError", async () => {
  const { fake, ctx } = setup();
  await ctx.bdapps.sendSms([ROBI], "hi");
  assertEquals(fake.calls[0].body.applicationId, "APP_000001");
  assertEquals(fake.calls[0].body.password, "secret");
  assertEquals(fake.calls[0].body.destinationAddresses, ["tel:8801812345678"]);

  fake.failPaths.add("/sms/send");
  const err = await assertRejects(() => ctx.bdapps.sendSms([ROBI], "hi"), BdappsError);
  assertEquals(err.statusCode, "E1308");
});

Deno.test("client reports HTTP and network failures as transport errors", async () => {
  const http = new BdappsClient(
    { baseUrl: "https://x", applicationId: "A", password: "p" },
    () => Promise.resolve(new Response("down", { status: 503 })),
  );
  const e1 = await assertRejects(() => http.queryBase(), BdappsError);
  assert(e1.isTransport);
  const net = new BdappsClient(
    { baseUrl: "https://x", applicationId: "A", password: "p" },
    () => Promise.reject(new TypeError("offline")),
  );
  const e2 = await assertRejects(() => net.queryBase(), BdappsError);
  assert(e2.isTransport);
});

// --- in-app subscription ----------------------------------------------------

Deno.test("OTP flow subscribes, sends welcome + day 1, keeps reference server-side", async () => {
  const { fake, store, ctx } = setup();
  const sent = await handleSubscribe(ctx, USER, { action: "request_otp", phone: ROBI });
  assertEquals(sent, { state: "otp_sent" });
  assertEquals(JSON.stringify(sent).includes("REF-"), false);

  const ok = await handleSubscribe(ctx, USER, { action: "verify_otp", code: "123456" });
  assert("state" in ok && ok.state === "subscribed");
  assertEquals(ok.day, 1);
  assertEquals(ok.courseDays, 60);

  const sms = fake.sms().map((c) => String(c.body.message));
  assertEquals(sms.length, 2);
  assert(sms[0].includes("স্বাগতম"));
  assert(sms[1].includes("টিপ 1"));

  const row = await store.getSubscription(USER);
  assertEquals(row?.status, "registered");
  assertEquals(row?.otp_reference, null);
  assertEquals(row?.phone, ROBI);
  assertEquals((await store.getMember("tel:8801812345678"))?.user_id, USER);
});

Deno.test("masked subscriber ids become the member key", async () => {
  const { fake, store, ctx } = setup();
  fake.maskedId = "tel:MASKED123";
  await handleSubscribe(ctx, USER, { action: "request_otp", phone: ROBI });
  await handleSubscribe(ctx, USER, { action: "verify_otp", code: "123456" });
  assertEquals((await store.getSubscription(USER))?.subscriber_id, "tel:MASKED123");
  assert(await store.getMember("tel:MASKED123"));
});

Deno.test("wrong, expired and missing codes are reported", async () => {
  const { ctx, advanceDays } = setup();
  assertEquals(
    await handleSubscribe(ctx, USER, { action: "verify_otp", code: "123456" }),
    { error: "code_expired" },
  );
  await handleSubscribe(ctx, USER, { action: "request_otp", phone: ROBI });
  assertEquals(
    await handleSubscribe(ctx, USER, { action: "verify_otp", code: "000000" }),
    { error: "invalid_code" },
  );
  advanceDays(1);
  assertEquals(
    await handleSubscribe(ctx, USER, { action: "verify_otp", code: "123456" }),
    { error: "code_expired" },
  );
});

Deno.test("non-Robi/Airtel numbers are refused before calling bdapps", async () => {
  const { fake, ctx } = setup();
  assertEquals(
    await handleSubscribe(ctx, USER, { action: "request_otp", phone: "+8801712345678" }),
    { error: "not_eligible" },
  );
  assertEquals(fake.calls.length, 0);
});

Deno.test("OTP requests are rate limited per user per hour", async () => {
  const { ctx, advanceDays } = setup();
  for (let i = 0; i < OTP_MAX_PER_HOUR; i++) {
    assertEquals(
      await handleSubscribe(ctx, USER, { action: "request_otp", phone: ROBI }),
      { state: "otp_sent" },
    );
  }
  assertEquals(
    await handleSubscribe(ctx, USER, { action: "request_otp", phone: ROBI }),
    { error: "rate_limited" },
  );
  advanceDays(1);
  assertEquals(
    await handleSubscribe(ctx, USER, { action: "request_otp", phone: ROBI }),
    { state: "otp_sent" },
  );
});

Deno.test("status follows bdapps; unsubscribe stops it", async () => {
  const { fake, ctx } = setup();
  assertEquals(await handleSubscribe(ctx, USER, { action: "status" }), { state: "not_subscribed" });
  await handleSubscribe(ctx, USER, { action: "request_otp", phone: ROBI });
  assertEquals(
    (await handleSubscribe(ctx, USER, { action: "status" }) as { state: string }).state,
    "otp_sent",
  );
  await handleSubscribe(ctx, USER, { action: "verify_otp", code: "123456" });
  assertEquals(
    (await handleSubscribe(ctx, USER, { action: "status" }) as { state: string }).state,
    "subscribed",
  );

  const stop = await handleSubscribe(ctx, USER, { action: "unsubscribe" });
  assertEquals((stop as { state: string }).state, "unsubscribed");
  assertEquals(fake.status.get("tel:8801812345678"), "UNREGISTERED");
  assertEquals(
    (await handleSubscribe(ctx, USER, { action: "status" }) as { state: string }).state,
    "unsubscribed",
  );
});

Deno.test("status picks up a stop made outside the app (SMS/USSD)", async () => {
  const { fake, ctx } = setup();
  await handleSubscribe(ctx, USER, { action: "request_otp", phone: ROBI });
  await handleSubscribe(ctx, USER, { action: "verify_otp", code: "123456" });
  fake.status.set("tel:8801812345678", "UNREGISTERED");
  assertEquals(
    (await handleSubscribe(ctx, USER, { action: "status" }) as { state: string }).state,
    "unsubscribed",
  );
});

Deno.test("bdapps outages become 'upstream' and keep the cached status", async () => {
  const { fake, ctx } = setup();
  await handleSubscribe(ctx, USER, { action: "request_otp", phone: ROBI });
  await handleSubscribe(ctx, USER, { action: "verify_otp", code: "123456" });
  fake.failPaths.add("/subscription/getStatus");
  fake.failPaths.add("/otp/request");
  assertEquals(
    (await handleSubscribe(ctx, USER, { action: "status" }) as { state: string }).state,
    "subscribed",
  );
  const res = await handleSubscribe(ctx, "other-user", { action: "request_otp", phone: ROBI });
  assertEquals((res as { error: string }).error, "upstream");
});

// --- callbacks --------------------------------------------------------------

const TOKEN = "tok-123";
const path = (kind: string) => `/functions/v1/bdapps-callback/${TOKEN}/${kind}`;

Deno.test("callback paths need the secret token", async () => {
  assertEquals(parsePath(path("sms")), { token: TOKEN, kind: "sms" });
  const { ctx } = setup();
  const res = await handleCallback(ctx, {
    expectedToken: TOKEN,
    pathname: "/functions/v1/bdapps-callback/wrong/sms",
    payload: { applicationId: "APP_000001" },
  });
  assertEquals(res.status, 404);
});

Deno.test("callbacks from another application are refused", async () => {
  const { ctx, store } = setup();
  const res = await handleCallback(ctx, {
    expectedToken: TOKEN,
    pathname: path("subscription"),
    payload: { applicationId: "APP_999999", subscriberId: "tel:1", status: "REGISTERED" },
  });
  assertEquals(res.status, 403);
  assertEquals(store.events.length, 0);
});

Deno.test("subscription notify registers then unregisters; log drops the password", async () => {
  const { ctx, store, fake } = setup();
  const notify = (status: string) =>
    handleCallback(ctx, {
      expectedToken: TOKEN,
      pathname: path("subscription"),
      payload: {
        timeStamp: "20261107082110",
        version: "1.0",
        applicationId: "APP_000001",
        password: "secret",
        subscriberId: "tel:8801612345678",
        frequency: "daily",
        status,
      },
    });
  const res = await notify("REGISTERED.");
  assertEquals(res.body.statusCode, "S1000");
  assertEquals((await store.getMember("tel:8801612345678"))?.status, "registered");
  assertEquals(fake.sms().length, 2);

  await notify("REGISTERED");
  assertEquals(fake.sms().length, 2, "a repeated notify sends nothing new");

  await notify("UNREGISTERED");
  assertEquals((await store.getMember("tel:8801612345678"))?.status, "unregistered");
  assertEquals(JSON.stringify(store.events).includes("secret"), false);
});

Deno.test("SMS keywords: STOP unsubscribes, START subscribes, other text gets help", async () => {
  const { ctx, store, fake } = setup();
  const mo = (message: string) =>
    handleCallback(ctx, {
      expectedToken: TOKEN,
      pathname: path("sms"),
      payload: {
        version: "1.0",
        applicationId: "APP_000001",
        sourceAddress: "tel:8801812345678",
        message,
        requestId: "1",
        encoding: "0",
      },
    });
  await mo("START PUST9");
  assertEquals((await store.getMember("tel:8801812345678"))?.status, "registered");
  await mo("stop pust9");
  assertEquals((await store.getMember("tel:8801812345678"))?.status, "unregistered");
  const before = fake.sms().length;
  await mo("what is this?");
  assertEquals(fake.sms().length, before + 1);
});

Deno.test("delivery reports are logged without an applicationId", async () => {
  const { ctx, store } = setup();
  const res = await handleCallback(ctx, {
    expectedToken: TOKEN,
    pathname: path("sms-report"),
    payload: {
      destinationAddress: "tel:8801812345678",
      timeStamp: "2611070910",
      requestId: "MSG_1",
      deliveryStatus: "DELIVERED",
    },
  });
  assertEquals(res.status, 200);
  assertEquals(store.events[0].kind, "sms-report");
});

// --- USSD ---------------------------------------------------------------------

const ussd = (
  ctx: ReturnType<typeof setup>["ctx"],
  op: string,
  message: string,
  sessionId = "S1",
) =>
  handleUssd(ctx, {
    sessionId,
    sourceAddress: "tel:8801812345678",
    message,
    ussdOperation: op,
  });

Deno.test("USSD: dial shows the menu, 1 subscribes and ends the session", async () => {
  const { ctx, store, fake } = setup();
  const first = await ussd(ctx, "mo-init", "*213*02025#");
  assertEquals(first, { message: USSD.main, final: false });
  assertEquals(fake.ussd()[0].body.ussdOperation, "mt-cont");

  const second = await ussd(ctx, "mo-cont", "1");
  assertEquals(second?.final, true);
  assertEquals(second?.message, USSD.subscribed);
  assertEquals(fake.ussd()[1].body.ussdOperation, "mt-fin");
  assertEquals((await store.getMember("tel:8801812345678"))?.status, "registered");
  assertEquals(store.ussd.size, 0);
});

Deno.test("USSD: stop asks for confirmation; 0 goes back", async () => {
  const { ctx, store } = setup();
  await onRegistered(ctx, "tel:8801812345678");
  assertEquals((await ussd(ctx, "mo-init", "*213*02025#"))?.message, USSD.mainSubscribed);
  assertEquals((await ussd(ctx, "mo-cont", "4"))?.message, USSD.confirmStop);
  assertEquals((await ussd(ctx, "mo-cont", "0"))?.message, USSD.mainSubscribed);
  await ussd(ctx, "mo-cont", "4");
  const done = await ussd(ctx, "mo-cont", "1");
  assertEquals(done, { message: USSD.stopped, final: true });
  assertEquals((await store.getMember("tel:8801812345678"))?.status, "unregistered");
});

Deno.test("USSD: status, tip by SMS, and invalid input", async () => {
  const { ctx, fake } = setup();
  await ussd(ctx, "mo-init", "*213*02025#");
  assertEquals((await ussd(ctx, "mo-cont", "3"))?.message, USSD.notSubscribed);

  await onRegistered(ctx, "tel:8801812345678");
  await ussd(ctx, "mo-init", "*213*02025#", "S2");
  assertEquals((await ussd(ctx, "mo-cont", "9", "S2"))?.final, false);
  assertEquals((await ussd(ctx, "mo-cont", "3", "S2"))?.message, USSD.status(1, 60));

  await ussd(ctx, "mo-init", "*213*02025#", "S3");
  const before = fake.sms().length;
  assertEquals((await ussd(ctx, "mo-cont", "2", "S3"))?.message, USSD.tipSent);
  assertEquals(fake.sms().length, before + 1);
});

Deno.test("USSD menu text is plain ASCII (encoding 440)", () => {
  for (const v of Object.values(USSD)) {
    const text = typeof v === "function" ? v(12, 60) : v;
    assert(/^[\x20-\x7E\n]*$/.test(text), text);
  }
});

// --- daily send ---------------------------------------------------------------

Deno.test("daily send: next tip per member, batched by day, once per day", async () => {
  const { ctx, store, fake, advanceDays } = setup();
  for (let i = 0; i < 150; i++) {
    await onRegistered(ctx, `tel:88016${String(i).padStart(8, "0")}`);
  }
  advanceDays(1);
  await onRegistered(ctx, "tel:8801812345678"); // joins today: already got day 1
  fake.calls = [];

  const r1 = await dailySend(ctx);
  assertEquals(r1.sent, 150);
  const batches = fake.sms();
  assertEquals(batches.length, 2, "150 members on day 2 → 2 requests");
  assertEquals((batches[0].body.destinationAddresses as string[]).length, 100);
  assert(String(batches[0].body.message).includes("টিপ 2"));

  const r2 = await dailySend(ctx);
  assertEquals(r2.sent, 0, "second run the same day sends nothing");

  advanceDays(1);
  const r3 = await dailySend(ctx);
  assertEquals(r3.sent, 151);
  assertEquals((await store.getMember("tel:8801812345678"))?.last_day_sent, 2);
});

Deno.test("daily send: missing tips and failed batches are retried tomorrow", async () => {
  const { ctx, store, fake, advanceDays } = setup({ tips: 1 });
  await onRegistered(ctx, "tel:8801812345678");
  advanceDays(1);
  const r = await dailySend(ctx);
  assertEquals(r.missingTips, [2]);
  assertEquals((await store.getMember("tel:8801812345678"))?.last_day_sent, 1);

  store.tips.set(2, { day_no: 2, body_bn: "টিপ 2", body_en: null });
  fake.failPaths.add("/sms/send");
  assertEquals((await dailySend(ctx)).failedBatches, 1);
  fake.failPaths.clear();
  assertEquals((await dailySend(ctx)).sent, 1);
});

Deno.test("daily send: after the last day the course stops itself", async () => {
  const { ctx, store, fake, advanceDays } = setup();
  store.days = 2;
  await onRegistered(ctx, "tel:8801812345678");
  advanceDays(1);
  assertEquals((await dailySend(ctx)).sent, 1);
  advanceDays(1);
  const r = await dailySend(ctx);
  assertEquals(r.completed, 1);
  assertEquals(fake.status.get("tel:8801812345678"), "UNREGISTERED");
  assertEquals((await store.getMember("tel:8801812345678"))?.status, "unregistered");
});

Deno.test("Dhaka date rolls over at 18:00 UTC", () => {
  assertEquals(dhakaDate(new Date("2026-11-07T17:59:00Z")), "2026-11-07");
  assertEquals(dhakaDate(new Date("2026-11-07T18:00:00Z")), "2026-11-08");
});
