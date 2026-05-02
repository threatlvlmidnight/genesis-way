/**
 * Contract tests: POST /api/calendar/sync/pull
 *
 * Verifies our sync/pull route can fetch real events from Google Calendar API
 * using a live access token obtained from the test account's refresh token.
 *
 * Requires: GOOGLE_OAUTH_CLIENT_ID, GOOGLE_TEST_REFRESH_TOKEN in .env.contract.
 * Optional: GOOGLE_TEST_EXTRA_CALENDAR_ID for multi-calendar fan-out test.
 *
 * Run: npm run test:contract
 */

import { describe, test, expect, beforeAll } from "vitest";
import { POST } from "@/app/api/calendar/sync/pull/route";
import { hasCredentials, acquireAccessToken } from "./_helpers";

const REQUIRED = ["GOOGLE_OAUTH_CLIENT_ID", "GOOGLE_TEST_REFRESH_TOKEN"];

// ── Validation / error handling (no credentials needed) ───────────────────────

describe("calendar sync/pull — input validation", () => {
  test("returns 401 when accessToken is missing", async () => {
    const request = new Request("http://localhost/api/calendar/sync/pull", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });

    const response = await POST(request);
    const body = (await response.json()) as { error?: string };

    expect(response.status).toBe(401);
    expect(body.error).toBeTruthy();
  });

  test("returns 401 when accessToken is blank", async () => {
    const request = new Request("http://localhost/api/calendar/sync/pull", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ accessToken: "   " }),
    });

    const response = await POST(request);
    expect(response.status).toBe(401);
  });
});

// ── Live Google Calendar API tests ───────────────────────────────────────────

describe.skipIf(!hasCredentials(REQUIRED))(
  "calendar sync/pull — live Google Calendar API",
  () => {
    let accessToken: string;

    beforeAll(async () => {
      accessToken = await acquireAccessToken();
    });

    test("pulls events from the primary calendar with expected response shape", async () => {
      const request = new Request("http://localhost/api/calendar/sync/pull", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ accessToken }),
      });

      const response = await POST(request);
      const body = (await response.json()) as Record<string, unknown>;

      expect(response.status, "should be 200").toBe(200);

      // Top-level shape
      expect(body.count, "count should be a number").toBeTypeOf("number");
      expect(body.windowStartISO, "windowStartISO should be a string").toBeTypeOf("string");
      expect(body.windowEndISO, "windowEndISO should be a string").toBeTypeOf("string");
      expect(Array.isArray(body.events), "events should be an array").toBe(true);
      expect((body.count as number), "count should match events length").toBe(
        (body.events as unknown[]).length
      );

      // Validate window ISO strings are parseable dates
      expect(
        Number.isNaN(new Date(body.windowStartISO as string).getTime()),
        "windowStartISO should be a valid ISO date"
      ).toBe(false);
      expect(
        Number.isNaN(new Date(body.windowEndISO as string).getTime()),
        "windowEndISO should be a valid ISO date"
      ).toBe(false);
    });

    test("each returned event has the required fields and correct types", async () => {
      const request = new Request("http://localhost/api/calendar/sync/pull", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ accessToken }),
      });

      const response = await POST(request);
      const body = (await response.json()) as {
        events: Array<Record<string, unknown>>;
      };

      for (const event of body.events) {
        expect(event.provider, `event.provider for "${event.title}" should be "google"`).toBe(
          "google"
        );
        expect(event.calendarId, "event.calendarId should be a string").toBeTypeOf("string");
        expect(event.providerEventId, "event.providerEventId should be a non-empty string").toBeTypeOf("string");
        expect((event.providerEventId as string).length).toBeGreaterThan(0);
        expect(event.title, "event.title should be a non-empty string").toBeTypeOf("string");
        expect((event.title as string).length).toBeGreaterThan(0);
        expect(typeof event.allDay, "event.allDay should be boolean").toBe("boolean");

        // startAtISO and endAtISO are nullable strings
        expect(
          event.startAtISO === null || typeof event.startAtISO === "string",
          "event.startAtISO should be null or string"
        ).toBe(true);
        expect(
          event.endAtISO === null || typeof event.endAtISO === "string",
          "event.endAtISO should be null or string"
        ).toBe(true);

        // If startAtISO is a string it must be a parseable ISO date
        if (typeof event.startAtISO === "string") {
          expect(
            Number.isNaN(new Date(event.startAtISO).getTime()),
            `event.startAtISO "${event.startAtISO}" should be a valid date`
          ).toBe(false);
        }
      }
    });

    test("windowDays=1 returns a narrower window than the default", async () => {
      const [narrow, wide] = await Promise.all([
        (async () => {
          const r = await POST(
            new Request("http://localhost/api/calendar/sync/pull", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ accessToken, windowDays: 1 }),
            })
          );
          return r.json() as Promise<{ windowStartISO: string; windowEndISO: string }>;
        })(),
        (async () => {
          const r = await POST(
            new Request("http://localhost/api/calendar/sync/pull", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ accessToken, windowDays: 7 }),
            })
          );
          return r.json() as Promise<{ windowStartISO: string; windowEndISO: string }>;
        })(),
      ]);

      const narrowSpan =
        new Date(narrow.windowEndISO).getTime() - new Date(narrow.windowStartISO).getTime();
      const wideSpan =
        new Date(wide.windowEndISO).getTime() - new Date(wide.windowStartISO).getTime();

      expect(narrowSpan, "1-day window should be smaller than 7-day window").toBeLessThan(wideSpan);
    });

    test("windowDays is clamped to a maximum of 30 days", async () => {
      const request = new Request("http://localhost/api/calendar/sync/pull", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ accessToken, windowDays: 9999 }),
      });

      const response = await POST(request);
      const body = (await response.json()) as {
        windowStartISO: string;
        windowEndISO: string;
      };

      expect(response.status).toBe(200);

      const spanDays =
        (new Date(body.windowEndISO).getTime() - new Date(body.windowStartISO).getTime()) /
        (1000 * 60 * 60 * 24);

      // Window is ±30 days = 60 days total span; must not exceed that.
      expect(spanDays, "window span should not exceed 60 days (±30)").toBeLessThanOrEqual(61);
    });

    test("returns 401 when the access token is invalid (Google rejects it)", async () => {
      const request = new Request("http://localhost/api/calendar/sync/pull", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ accessToken: "invalid-access-token" }),
      });

      const response = await POST(request);
      const body = (await response.json()) as { error?: string };

      expect(response.status, "should surface Google's 401").toBe(401);
      expect(body.error).toBeTruthy();
    });

    // Only runs when GOOGLE_TEST_EXTRA_CALENDAR_ID is configured.
    test.skipIf(!process.env.GOOGLE_TEST_EXTRA_CALENDAR_ID)(
      "fans out across multiple calendar IDs",
      async () => {
        const extra = process.env.GOOGLE_TEST_EXTRA_CALENDAR_ID!;

        const [singleResult, multiResult] = await Promise.all([
          POST(
            new Request("http://localhost/api/calendar/sync/pull", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ accessToken, selectedCalendarIds: ["primary"] }),
            })
          ).then((r) => r.json() as Promise<{ events: unknown[] }>),
          POST(
            new Request("http://localhost/api/calendar/sync/pull", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({ accessToken, selectedCalendarIds: ["primary", extra] }),
            })
          ).then((r) => r.json() as Promise<{ events: unknown[] }>),
        ]);

        // Multi-calendar result should have at least as many events as single.
        expect(
          multiResult.events.length,
          "fetching two calendars should return >= events of one"
        ).toBeGreaterThanOrEqual(singleResult.events.length);

        // Events from the extra calendar should have its ID tagged.
        const extraCalEvents = (
          multiResult.events as Array<{ calendarId: string }>
        ).filter((e) => e.calendarId === extra);
        expect(
          extraCalEvents.length,
          "at least one event should be tagged with the extra calendar ID"
        ).toBeGreaterThan(0);
      }
    );
  }
);
