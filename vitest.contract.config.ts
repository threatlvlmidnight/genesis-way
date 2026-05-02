import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "."),
    },
  },
  test: {
    name: "contract",
    include: ["tests/contract/**/*.test.ts"],
    globalSetup: ["tests/contract/_setup.ts"],
    // Each test can involve real network calls to Google — give them room.
    testTimeout: 30_000,
    hookTimeout: 30_000,
    // Run serially: token refresh must complete before pull tests use the token.
    sequence: {
      concurrent: false,
    },
    reporter: "verbose",
  },
});
