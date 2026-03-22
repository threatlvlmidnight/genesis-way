This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

## Google Calendar Setup (Web)

1. Create an OAuth 2.0 Client ID in Google Cloud Console with Application type `Web application`.
2. Add an authorized redirect URI for local dev:
	- `http://localhost:3000/`
3. Create a local env file at `.env.local`:

```bash
NEXT_PUBLIC_GOOGLE_CLIENT_ID=your_google_oauth_client_id
```

4. Restart the dev server after setting env vars.

The Fill screen `Link Google` action uses OAuth and imports events from your primary calendar for the upcoming two weeks.

## Simple Calendar Import (Web)

If you want the fastest path without OAuth setup:

1. Open Fill screen in the web app.
2. Use `Import .ics` to upload a calendar export file.
3. Or paste an `.ics` feed URL and click `Import URL`.

Imported events are mapped into Work/Personal tasks and deduplicated against existing task text + time.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## iOS Smoke Test (Lightweight)

Run a quick automated regression smoke check (build + simulator launch):

```bash
scripts/ios_smoke.sh
```

This is intentionally lightweight and meant to catch obvious breakages early.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
