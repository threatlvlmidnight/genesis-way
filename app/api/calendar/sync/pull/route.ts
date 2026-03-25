interface CalendarSyncPullRequest {
  accessToken?: string;
  selectedCalendarIds?: string[];
  windowDays?: number;
}

interface GoogleCalendarApiItem {
  id?: string;
  summary?: string;
  start?: {
    date?: string;
    dateTime?: string;
  };
  end?: {
    date?: string;
    dateTime?: string;
  };
}

interface GoogleCalendarEventsResponse {
  items?: GoogleCalendarApiItem[];
  error?: {
    code?: number;
    message?: string;
  };
}

interface PulledCalendarEvent {
  provider: "google";
  calendarId: string;
  providerEventId: string;
  title: string;
  startAtISO: string | null;
  endAtISO: string | null;
  allDay: boolean;
}

function parseGoogleStart(start?: { date?: string; dateTime?: string }): { iso: string | null; allDay: boolean } {
  if (!start) return { iso: null, allDay: false };
  if (start.dateTime) {
    const date = new Date(start.dateTime);
    return { iso: Number.isNaN(date.getTime()) ? null : date.toISOString(), allDay: false };
  }
  if (start.date) {
    return { iso: `${start.date}T00:00:00.000Z`, allDay: true };
  }
  return { iso: null, allDay: false };
}

function parseGoogleEnd(end?: { date?: string; dateTime?: string }, allDay?: boolean): string | null {
  if (!end) return null;
  if (end.dateTime) {
    const date = new Date(end.dateTime);
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
  }
  if (allDay && end.date) {
    return `${end.date}T00:00:00.000Z`;
  }
  return null;
}

async function fetchCalendarEvents(
  accessToken: string,
  calendarId: string,
  windowStartISO: string,
  windowEndISO: string
): Promise<PulledCalendarEvent[]> {
  const params = new URLSearchParams({
    singleEvents: "true",
    orderBy: "startTime",
    maxResults: "250",
    timeMin: windowStartISO,
    timeMax: windowEndISO,
  });

  const encodedCalendarId = encodeURIComponent(calendarId);
  const response = await fetch(
    `https://www.googleapis.com/calendar/v3/calendars/${encodedCalendarId}/events?${params.toString()}`,
    {
      method: "GET",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: "application/json",
      },
      cache: "no-store",
    }
  );

  const payload = (await response.json()) as GoogleCalendarEventsResponse;
  if (!response.ok) {
    const message = payload.error?.message ?? `Google Calendar request failed (${response.status}).`;
    throw Object.assign(new Error(message), { statusCode: response.status });
  }

  const items = payload.items ?? [];
  return items
    .map((item, index): PulledCalendarEvent | null => {
      const title = (item.summary ?? "").trim();
      if (!title) return null;

      const parsedStart = parseGoogleStart(item.start);
      const startAtISO = parsedStart.iso;
      const allDay = parsedStart.allDay;
      const endAtISO = parseGoogleEnd(item.end, allDay);

      return {
        provider: "google",
        calendarId,
        providerEventId: item.id ?? `${calendarId}-${index}-${startAtISO ?? "na"}`,
        title,
        startAtISO,
        endAtISO,
        allDay,
      };
    })
    .filter((event): event is PulledCalendarEvent => Boolean(event));
}

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as CalendarSyncPullRequest;
    const accessToken = (body.accessToken ?? "").trim();

    if (!accessToken) {
      return Response.json({ error: "Missing access token." }, { status: 401 });
    }

    const selected = (body.selectedCalendarIds ?? [])
      .map((id) => id.trim())
      .filter((id) => id.length > 0);
    const calendarIds = selected.length > 0 ? selected : ["primary"];

    const rawWindowDays = Number(body.windowDays ?? 7);
    const windowDays = Number.isFinite(rawWindowDays)
      ? Math.max(1, Math.min(30, Math.floor(rawWindowDays)))
      : 7;

    const now = new Date();
    const windowStart = new Date(now.getTime() - windowDays * 24 * 60 * 60 * 1000);
    const windowEnd = new Date(now.getTime() + windowDays * 24 * 60 * 60 * 1000);

    const perCalendar = await Promise.all(
      calendarIds.map((calendarId) =>
        fetchCalendarEvents(accessToken, calendarId, windowStart.toISOString(), windowEnd.toISOString())
      )
    );

    const events = perCalendar.flat();

    return Response.json({
      count: events.length,
      windowStartISO: windowStart.toISOString(),
      windowEndISO: windowEnd.toISOString(),
      events,
    });
  } catch (error) {
    const statusCode =
      typeof error === "object" && error !== null && "statusCode" in error
        ? Number((error as { statusCode?: number }).statusCode ?? 500)
        : 500;

    const message =
      error instanceof Error && error.message
        ? error.message
        : "Calendar pull failed.";

    return Response.json({ error: message }, { status: statusCode >= 400 ? statusCode : 500 });
  }
}
