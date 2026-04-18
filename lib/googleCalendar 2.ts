import type { CalendarEvent } from "@/lib/calendar";

export interface GoogleAuthToken {
  accessToken: string;
  expiresAt: number;
  refreshToken?: string;
}

interface GoogleCalendarApiItem {
  id?: string;
  summary?: string;
  start?: {
    date?: string;
    dateTime?: string;
  };
}

interface GoogleCalendarEventsResponse {
  items?: GoogleCalendarApiItem[];
}

function randomState(): string {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  return `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

function randomVerifier(length = 64): string {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
  const bytes = new Uint8Array(length);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, (byte) => chars[byte % chars.length]).join("");
}

function toBase64Url(input: ArrayBuffer): string {
  const bytes = new Uint8Array(input);
  let binary = "";
  bytes.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function pkceChallengeForVerifier(verifier: string): Promise<string> {
  const encoded = new TextEncoder().encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", encoded);
  return toBase64Url(digest);
}

const OAUTH_STATE_KEY = "gw_google_oauth_state";
const OAUTH_VERIFIER_KEY = "gw_google_oauth_pkce_verifier";

export async function beginGoogleOAuth(clientId: string): Promise<void> {
  if (!clientId) {
    throw new Error("Google OAuth client id is missing. Set NEXT_PUBLIC_GOOGLE_CLIENT_ID.");
  }

  const redirectUri = window.location.origin + window.location.pathname;
  const state = randomState();
  const codeVerifier = randomVerifier();
  const codeChallenge = await pkceChallengeForVerifier(codeVerifier);

  sessionStorage.setItem(OAUTH_STATE_KEY, state);
  sessionStorage.setItem(OAUTH_VERIFIER_KEY, codeVerifier);

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "code",
    scope: "https://www.googleapis.com/auth/calendar.readonly",
    include_granted_scopes: "true",
    access_type: "offline",
    prompt: "consent",
    state,
    code_challenge: codeChallenge,
    code_challenge_method: "S256",
  });

  window.location.assign(`https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`);
}

export async function consumeGoogleOAuthFromHash(): Promise<GoogleAuthToken | null> {
  if (typeof window === "undefined") return null;
  const params = new URLSearchParams(window.location.search);
  const authCode = params.get("code");
  if (!authCode) return null;

  const state = params.get("state");
  const expectedState = sessionStorage.getItem(OAUTH_STATE_KEY);
  const codeVerifier = sessionStorage.getItem(OAUTH_VERIFIER_KEY);

  if (!codeVerifier) {
    throw new Error("Google OAuth PKCE verifier is missing.");
  }

  if (expectedState && state && state !== expectedState) {
    throw new Error("Google OAuth state check failed.");
  }

  const response = await fetch("/api/calendar/oauth/callback", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      code: authCode,
      codeVerifier,
      redirectUri: window.location.origin + window.location.pathname,
    }),
  });

  if (!response.ok) {
    throw new Error("Google OAuth code exchange failed.");
  }

  const payload = (await response.json()) as {
    accessToken?: string;
    expiresIn?: number;
    refreshToken?: string;
  };

  const accessToken = payload.accessToken;
  const expiresIn = Number(payload.expiresIn ?? 3600);
  if (!accessToken) return null;

  sessionStorage.removeItem(OAUTH_STATE_KEY);
  sessionStorage.removeItem(OAUTH_VERIFIER_KEY);
  window.history.replaceState(null, "", window.location.pathname + window.location.search);

  return {
    accessToken,
    expiresAt: Date.now() + Math.max(60, expiresIn) * 1000,
    refreshToken: payload.refreshToken,
  };
}

function parseGoogleEventStart(start?: { date?: string; dateTime?: string }): { date?: Date; allDay: boolean } {
  if (!start) return { date: undefined, allDay: false };

  if (start.date) {
    const [year, month, day] = start.date.split("-").map(Number);
    if (!year || !month || !day) return { date: undefined, allDay: true };
    return { date: new Date(year, month - 1, day), allDay: true };
  }

  if (start.dateTime) {
    const d = new Date(start.dateTime);
    if (Number.isNaN(d.getTime())) return { date: undefined, allDay: false };
    return { date: d, allDay: false };
  }

  return { date: undefined, allDay: false };
}

export async function fetchGoogleEvents(accessToken: string): Promise<CalendarEvent[]> {
  if (!accessToken) return [];

  const now = new Date();
  const windowStart = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const windowEnd = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);

  const params = new URLSearchParams({
    singleEvents: "true",
    orderBy: "startTime",
    maxResults: "250",
    timeMin: windowStart.toISOString(),
    timeMax: windowEnd.toISOString(),
  });

  const response = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/primary/events?${params.toString()}`,
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    }
  );

  if (!response.ok) {
    throw new Error(`Google Calendar request failed (${response.status}).`);
  }

  const payload = (await response.json()) as GoogleCalendarEventsResponse;
  const items = payload.items ?? [];

  return items
    .map((item, index): CalendarEvent | null => {
      const title = (item.summary ?? "").trim();
      if (!title) return null;

      const { date, allDay } = parseGoogleEventStart(item.start);
      return {
        id: item.id ?? `google-${index}-${date?.getTime() ?? Date.now()}`,
        title,
        start: date,
        allDay,
      };
    })
    .filter((event): event is CalendarEvent => Boolean(event));
}
