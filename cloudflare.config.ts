import { bindings, defineConfig } from "cf/config";
import * as entrypoint from "./entry/worker.ts" with { type: "cf-worker" };

export default defineConfig({
  worker: {
    name: "keito-dev",
    compatibilityDate: "2026-10-06",
    entrypoint,
    domains: ["keito.dev"],
    workersDev: false,
    previewUrls: false,
    observability: {
      enabled: true,
      logs: { enabled: true },
      traces: { enabled: true },
      issues: { enabled: true },
    },
    env: {
      LINKS: bindings.kv(),
      GOOGLE_WALLET_ISSUER_ID: bindings.text("3388000000023214309"),
      GOOGLE_WALLET_SERVICE_ACCOUNT: bindings.text(
        "wallet-issuer@vaulted-blend-513002-k6.iam.gserviceaccount.com",
      ),
      GOOGLE_WALLET_PRIVATE_KEY: bindings.secret(),
    },
  },
});
