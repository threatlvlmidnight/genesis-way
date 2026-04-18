interface GoogleOAuthRefreshRequest {
  refreshToken?: string;
}

interface GoogleTokenResponse {
  access_token?: string;
  expires_in?: number;
  refresh_token?: string;
  error?: string;
  error_description?: string;
}

export async function POST(request: Request) {
  try {
    const body = (await request.json()) as GoogleOAuthRefreshRequest;
    const refreshToken = (body.refreshToken ?? "").trim();

    if (!refreshToken) {
      return Response.json({ error: "Missing refresh token." }, { status: 400 });
    }

    const env =
      (globalThis as { process?: { env?: Record<string, string | undefined> } }).process?.env ?? {};

    const clientId = env.GOOGLE_OAUTH_CLIENT_ID ?? env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";
    const clientSecret = env.GOOGLE_OAUTH_CLIENT_SECRET ?? "";

    if (!clientId) {
      return Response.json({ error: "Server is missing Google OAuth client id." }, { status: 500 });
    }

    const params = new URLSearchParams({
      client_id: clientId,
      grant_type: "refresh_token",
      refresh_token: refreshToken,
    });

    if (clientSecret) {
      params.set("client_secret", clientSecret);
    }

    const upstream = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: params.toString(),
      cache: "no-store",
    });

    const payload = (await upstream.json()) as GoogleTokenResponse;
    if (!upstream.ok || !payload.access_token) {
      return Response.json(
        { error: payload.error_description ?? payload.error ?? "Google token refresh failed." },
        { status: 502 }
      );
    }

    return Response.json({
      accessToken: payload.access_token,
      expiresIn: payload.expires_in ?? 3600,
      refreshToken: payload.refresh_token ?? null,
    });
  } catch {
    return Response.json({ error: "Token refresh failed." }, { status: 500 });
  }
}
