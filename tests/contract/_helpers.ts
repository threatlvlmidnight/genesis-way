/**
 * Shared utilities for contract tests.
 *
 * `hasCredentials(keys)` — returns true when all listed env vars are non-empty.
 * Use with `describe.skipIf(!hasCredentials([...]))` to skip gracefully when
 * .env.contract hasn't been configured.
 *
 * `acquireAccessToken()` — exchanges GOOGLE_TEST_REFRESH_TOKEN for a fresh
 * access token by calling our own /api/calendar/oauth/refresh route handler
 * directly (no running server needed).
 */

import { POST as refreshRoute } from "@/app/api/calendar/oauth/refresh/route";

export function hasCredentials(keys: string[]): boolean {
  return keys.every((k) => Boolean(process.env[k]));
}

export async function acquireAccessToken(): Promise<string> {
  const refreshToken = process.env.GOOGLE_TEST_REFRESH_TOKEN ?? "";

  const request = new Request("http://localhost/api/calendar/oauth/refresh", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refreshToken }),
  });

  const response = await refreshRoute(request);

  if (!response.ok) {
    const body = (await response.json()) as { error?: string };
    throw new Error(
      `Contract test setup: token refresh failed (${response.status}): ${body.error ?? "unknown"}`
    );
  }

  const data = (await response.json()) as { accessToken?: string };
  if (!data.accessToken) {
    throw new Error("Contract test setup: token refresh returned no accessToken.");
  }

  return data.accessToken;
}
