import { gleamImportPlugin } from "@chouquette/gleam-vite-loader";
import { cloudflare } from "@cloudflare/vite-plugin";
import { defineConfig, lazyPlugins } from "vite-plus";

export default defineConfig({
  plugins: lazyPlugins(() => [gleamImportPlugin(), cloudflare()]),
  environments: {
    client: {
      build: {
        rolldownOptions: {
          input: { client: "entry/client.ts" },
          output: { entryFileNames: "assets/[name].js" },
        },
      },
    },
  },
  fmt: {
    ignorePatterns: ["manifest.toml"],
  },
  lint: {
    jsPlugins: [{ name: "vite-plus", specifier: "vite-plus/oxlint-plugin" }],
    rules: { "vite-plus/prefer-vite-plus-imports": "error" },
    options: { typeAware: true, typeCheck: true },
  },
  run: {
    tasks: {
      dev: {
        command: "vp dev",
        cache: false,
      },
      fmt: ["vp fmt", "gleam format src"],
      check: {
        command: ["gleam format --check src", "vp check"],
        dependsOn: ["gleam:build", "cf:types"],
      },
      "gleam:build": {
        command: "gleam build --target javascript",
        cache: false,
      },
      "cf:types": "cf workers types",
      build: {
        command: "vp build",
        dependsOn: ["check"],
        cache: {
          input: [{ auto: true }, "!build/**", "!.cloudflare/output/**"],
          output: [{ auto: true }, "!build/**"],
        },
      },
      preview: {
        command: "vp preview",
        dependsOn: ["build"],
        cache: false,
      },
      deploy: {
        command: "cf deploy --prebuilt",
        dependsOn: ["build"],
        cache: false,
      },
    },
  },
});
