/**
 * Global debug flag. Set NEXT_PUBLIC_DEBUG=true in .env.local to enable.
 * Use this to gate any debug-only UI (screen numbers, overlays, logs, etc.)
 */
export const DEBUG = process.env.NEXT_PUBLIC_DEBUG === "true";
