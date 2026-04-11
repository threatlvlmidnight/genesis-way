// GET: Google redirects here after user authorizes. We bounce the code back
// to the iOS app via its custom URL scheme so ASWebAuthenticationSession can
// intercept it. The iOS app then POSTs to this endpoint for token exchange.
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get("code") ?? "";
  const state = searchParams.get("state") ?? "";
  const error = searchParams.get("error") ?? "";

  const params = new URLSearchParams();
  if (error) {
    params.set("error", error);
    const errorDesc = searchParams.get("error_description") ?? "";
    if (errorDesc) params.set("error_description", errorDesc);
  } else {
    if (code) params.set("code", code);
    if (state) params.set("state", state);
  }

  const callbackURL = `coachdan://oauth/callback?${params.toString()}`;
  return Response.redirect(callbackURL, 302);
}

interface GoogleOAuthCallbackRequest {
  code?: string;
  codeVerifier?: string;
  redirectUri?: string;
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
    const body = (await request.json()) as GoogleOAuthCallbackRequest;
    const code = (body.code ?? "").trim();
    const codeVerifier = (body.codeVerifier ?? "").trim();
    const redirectUri = (body.redirectUri ?? "").trim();

    if (!code || !codeVerifier || !redirectUri) {
      return Response.json({ error: "Missing OAuth callback fields." }, { status: 400 });
    }

    const env =
      (globalThis as { process?: { env?: Record<string, string | undefined> } }).process?.env ?? {};

    const clientId = env.GOOGLE_OAUTH_CLIENT_ID ?? env.NEXT_PUBLIC_GOOGLE_CLIENT_ID ?? "";
    const clientSecret = env.GOOGLE_OAUTH_CLIENT_SECRET ?? "";

    if (!clientId) {
      return Response.json({ error: "Server is missing Google OAuth client id." }, { status: 500 });
    }

    const params = new URLSearchParams({
      code,
      client_id: clientId,
      redirect_uri: redirectUri,
      grant_type: "authorization_code",
      code_verifier: codeVerifier,
    });

    if (clientSecret) {
      params.set("client_secret", clientSecret);
    }

    const upstream = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: params.toString(),
      cache: "no-store",
    });

    const payload = (await upstream.json()) as GoogleTokenResponse;
    if (!upstream.ok || !payload.access_token) {
      return Response.json(
        {
          error: payload.error_description ?? payload.error ?? "Google OAuth token exchange failed.",
        },
        { status: 502 }
      );
    }

    return Response.json({
      accessToken: payload.access_token,
      expiresIn: payload.expires_in ?? 3600,
      refreshToken: payload.refresh_token ?? null,
    });
  } catch {
    return Response.json({ error: "Google OAuth callback handling failed." }, { status: 500 });
  }
}
