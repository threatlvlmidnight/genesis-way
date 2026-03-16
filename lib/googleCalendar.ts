import type { CalendarEvent } from "@/lib/calendar";

export interface GoogleAuthToken {
  accessToken: string;
  expiresAt: number;
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

export function beginGoogleOAuth(clientId: string): void {
  if (!clientId) {
    throw new Error("Google OAuth client id is missing. Set NEXT_PUBLIC_GOOGLE_CLIENT_ID.");
  }

  const redirectUri = window.location.origin + window.location.pathname;
  const state = randomState();
  sessionStorage.setItem("gw_google_oauth_state", state);

  const params = new URLSearchParams({
    client_id: clientId,
    redirect_uri: redirectUri,
    response_type: "token",
    scope: "https://www.googleapis.com/auth/calendar.readonly",
    include_granted_scopes: "true",
    prompt: "consent",
    state,
  });

  window.location.assign(`https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`);
}

export function consumeGoogleOAuthFromHash(): GoogleAuthToken | null {
  if (typeof window === "undefined") return null;
  const hash = window.location.hash.startsWith("#")
    ? window.location.hash.slice(1)
    : window.location.hash;
  if (!hash.includes("access_token=")) return null;

  const params = new URLSearchParams(hash);
  const accessToken = params.get("access_token");
  const expiresIn = Number(params.get("expires_in") ?? "3600");
  const state = params.get("state");
  const expectedState = sessionStorage.getItem("gw_google_oauth_state");

  if (!accessToken) return null;
  if (expectedState && state && state !== expectedState) {
    throw new Error("Google OAuth state check failed.");
  }

  sessionStorage.removeItem("gw_google_oauth_state");
  window.history.replaceState(null, "", window.location.pathname + window.location.search);

  return {
    accessToken,
    expiresAt: Date.now() + Math.max(60, expiresIn) * 1000,
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
