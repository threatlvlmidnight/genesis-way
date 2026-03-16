interface ImportCalendarRequest {
  url?: string;
}

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as ImportCalendarRequest;
    const rawUrl = (body.url ?? "").trim();

    if (!rawUrl) {
      return Response.json({ error: "Missing calendar URL." }, { status: 400 });
    }

    let parsed: URL;
    try {
      parsed = new URL(rawUrl);
    } catch {
      return Response.json({ error: "Invalid URL." }, { status: 400 });
    }

    if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
      return Response.json({ error: "URL must be http or https." }, { status: 400 });
    }

    const upstream = await fetch(parsed.toString(), {
      method: "GET",
      headers: {
        Accept: "text/calendar,text/plain,*/*",
      },
      cache: "no-store",
    });

    if (!upstream.ok) {
      return Response.json(
        { error: `Calendar feed request failed (${upstream.status}).` },
        { status: 502 }
      );
    }

    const raw = await upstream.text();
    if (!raw.includes("BEGIN:VCALENDAR")) {
      return Response.json(
        { error: "URL did not return a valid ICS calendar." },
        { status: 422 }
      );
    }

    return Response.json({ raw });
  } catch {
    return Response.json({ error: "Calendar import failed." }, { status: 500 });
  }
}
