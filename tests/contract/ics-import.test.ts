/**
 * Contract tests: POST /api/calendar/import
 *
 * Verifies our ICS import route fetches and validates real calendar feeds.
 * The live network test uses the Google US Holidays public ICS feed (or a
 * custom URL from GOOGLE_TEST_ICS_URL in .env.contract). No auth required.
 *
 * Run: npm run test:contract
 */

import { describe, test, expect } from "vitest";
import { POST } from "@/app/api/calendar/import/route";

// ── Input validation (no network required) ────────────────────────────────────

describe("ICS import — input validation", () => {
  test("returns 400 when url is missing", async () => {
    const request = new Request("http://localhost/api/calendar/import", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });

    const response = await POST(request);
    const body = (await response.json()) as { error?: string };

    expect(response.status).toBe(400);
    expect(body.error).toBeTruthy();
  });

  test("returns 400 when url is an empty string", async () => {
    const request = new Request("http://localhost/api/calendar/import", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: "   " }),
    });

    const response = await POST(request);
    expect(response.status).toBe(400);
  });

  test("returns 400 for a malformed URL", async () => {
    const request = new Request("http://localhost/api/calendar/import", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: "not a url at all" }),
    });

    const response = await POST(request);
    expect(response.status).toBe(400);
  });

  test("returns 400 for a non-http/https scheme (SSRF guard)", async () => {
    const request = new Request("http://localhost/api/calendar/import", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: "file:///etc/passwd" }),
    });

    const response = await POST(request);
    expect(response.status).toBe(400);
  });

  test("returns 400 for javascript: scheme", async () => {
    const request = new Request("http://localhost/api/calendar/import", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: "javascript:alert(1)" }),
    });

    const response = await POST(request);
    expect(response.status).toBe(400);
  });
});

// ── Live ICS fetch ─────────────────────────────────────────────────────────────

const icsUrl =
  process.env.GOOGLE_TEST_ICS_URL ??
  "https://calendar.google.com/calendar/ical/en.usa%23holiday%40group.v.calendar.google.com/public/basic.ics";

describe("ICS import — live calendar feed", () => {
  test("fetches and returns a valid ICS payload from the public calendar", async () => {
    const request = new Request("http://localhost/api/calendar/import", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: icsUrl }),
    });

    const response = await POST(request);
    const body = (await response.json()) as { raw?: string; error?: string };

    expect(response.status, `should be 200 (error: ${body.error ?? "none"})`).toBe(200);
    expect(body.raw, "response should include raw ICS string").toBeTypeOf("string");

    const raw = body.raw as string;
    expect(raw, "raw should contain VCALENDAR header").toContain("BEGIN:VCALENDAR");
    expect(raw, "raw should contain at least one VEVENT").toContain("BEGIN:VEVENT");
    expect(raw, "raw should contain SUMMARY lines").toContain("SUMMARY");
    expect(raw, "raw should contain DTSTART lines").toContain("DTSTART");
  });

  test("returns 422 when a real URL returns non-ICS content", async () => {
    // example.com returns HTML, not a calendar — should be rejected.
    const request = new Request("http://localhost/api/calendar/import", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ url: "https://example.com" }),
    });

    const response = await POST(request);
    const body = (await response.json()) as { error?: string };

    expect(response.status).toBe(422);
    expect(body.error, "error message should mention ICS or calendar").toMatch(/ics|calendar/i);
  });
});
