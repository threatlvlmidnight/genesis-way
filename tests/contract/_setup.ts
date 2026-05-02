/**
 * Global setup for contract tests.
 *
 * Runs once in the main process before any test files are loaded.
 * Loads .env.contract so all GOOGLE_* vars are available to route handlers
 * and test assertions without needing a running Next.js server.
 *
 * Node 20.12+ has process.loadEnvFile() natively — no dotenv needed.
 */
export default function setup() {
  try {
    // @ts-expect-error — loadEnvFile is Node ≥20.12 only; TS types may lag.
    process.loadEnvFile(".env.contract");
  } catch {
    // .env.contract does not exist. Tests that need credentials will skip
    // themselves via `describe.skipIf(!hasContractCredentials(...))`.
  }
}
