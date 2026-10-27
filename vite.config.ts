import { gleamImportPlugin } from "@chouquette/gleam-vite-loader";
import { cloudflare } from "@cloudflare/vite-plugin";
import tailwindcss from "@tailwindcss/vite";
import { cn } from "cn/vite";
import { defineConfig, lazyPlugins } from "vite-plus";

export default defineConfig({
  plugins: lazyPlugins(() => [
    gleamImportPlugin(),
    tailwindcss(),
    cn({ content: ["src/**/*.gleam"], out: ".generated/cn-tables.ts" }),
    cloudflare(),
  ]),
  server: { watch: { ignored: ["**/build/**"] } },
  environments: {
    client: {
      build: {
        rolldownOptions: {
          input: { client: "entry/client.ts", style: "entry/style.css" },
          output: {
            entryFileNames: "assets/[name].js",
            assetFileNames: ({ names }) =>
              names.includes("style.css") ? "entry/[name][extname]" : "assets/[name][extname]",
          },
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
  staged: {
    "*.gleam": ["gleam run --no-print-progress -m sort_classes", "gleam format"],
    "*.{ts,json}": "vp check --fix",
  },
  run: {
    tasks: {
      dev: {
        command: "vp dev",
        cache: false,
      },
      fmt: ["gleam run --no-print-progress -m sort_classes", "vp fmt", "gleam format src dev"],
      check: {
        command: [
          "gleam run --no-print-progress -m sort_classes -- --check",
          "gleam run --no-print-progress -m generate_icons -- update --check",
          "gleam format --check src dev",
          "vp check",
        ],
        dependsOn: ["gleam:build", "cf:types", "cn:build"],
      },
      "cn:build": {
        command: "cn build --content 'src/**/*.gleam' -o .generated/cn-tables.ts",
        cache: { input: [{ auto: true }, "!.generated/**"] },
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
