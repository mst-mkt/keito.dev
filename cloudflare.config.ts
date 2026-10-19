import { defineConfig } from "cf/config";
import * as entrypoint from "./entry/worker.ts" with { type: "cf-worker" };

export default defineConfig({
  worker: {
    name: "keito-dev",
    compatibilityDate: "2026-10-06",
    entrypoint,
    observability: {
      enabled: true,
      logs: { enabled: true },
      traces: { enabled: true },
      issues: { enabled: true },
    },
    env: {},
  },
});
