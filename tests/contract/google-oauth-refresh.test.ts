/**
 * Contract tests: POST /api/calendar/oauth/refresh
 *
 * These tests call the real Google token endpoint through our own route handler.
 * They require GOOGLE_OAUTH_CLIENT_ID, GOOGLE_OAUTH_CLIENT_SECRET, and
 * GOOGLE_TEST_REFRESH_TOKEN to be set in .env.contract.
 *
 * Run: npm run test:contract
 */

import { describe, test, expect } from "vitest";
import { POST } from "@/app/api/calendar/oauth/refresh/route";
import { hasCredentials } from "./_helpers";

const REQUIRED = ["GOOGLE_OAUTH_CLIENT_ID", "GOOGLE_TEST_REFRESH_TOKEN"];

// ── Happy path ────────────────────────────────────────────────────────────────

describe.skipIf(!hasCredentials(REQUIRED))(
  "OAuth refresh — live token exchange",
  () => {
    test("exchanges a valid refresh token for an access token", async () => {
      const request = new Request("http://localhost/api/calendar/oauth/refresh", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken: process.env.GOOGLE_TEST_REFRESH_TOKEN }),
      });

      const response = await POST(request);
      const body = (await response.json()) as Record<string, unknown>;

      expect(response.status, "should be 200").toBe(200);

      expect(body.accessToken, "accessToken should be a non-empty string").toBeTypeOf("string");
      expect((body.accessToken as string).length, "accessToken should be non-empty").toBeGreaterThan(0);

      expect(body.expiresIn, "expiresIn should be a positive number").toBeTypeOf("number");
      expect(body.expiresIn as number, "expiresIn should be > 0").toBeGreaterThan(0);

      // refreshToken may or may not be rotated — either null or a string is valid.
      expect(
        body.refreshToken === null || typeof body.refreshToken === "string",
        "refreshToken should be null or string"
      ).toBe(true);
    });
  }
);

// ── Validation / error handling (no credentials needed) ───────────────────────

describe("OAuth refresh — input validation", () => {
  test("returns 400 when refreshToken is missing", async () => {
    const request = new Request("http://localhost/api/calendar/oauth/refresh", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({}),
    });

    const response = await POST(request);
    const body = (await response.json()) as { error?: string };

    expect(response.status).toBe(400);
    expect(body.error).toBeTruthy();
  });

  test("returns 400 when refreshToken is an empty string", async () => {
    const request = new Request("http://localhost/api/calendar/oauth/refresh", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refreshToken: "   " }),
    });

    const response = await POST(request);
    expect(response.status).toBe(400);
  });
});

describe.skipIf(!hasCredentials(["GOOGLE_OAUTH_CLIENT_ID"]))(
  "OAuth refresh — upstream error passthrough",
  () => {
    test("returns 502 when the refresh token is invalid/revoked", async () => {
      const request = new Request("http://localhost/api/calendar/oauth/refresh", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ refreshToken: "totally-invalid-token" }),
      });

      const response = await POST(request);
      const body = (await response.json()) as { error?: string };

      expect(response.status).toBe(502);
      expect(body.error, "should surface Google's error message").toBeTruthy();
    });
  }
);
