import { gleamImportPlugin } from "@chouquette/gleam-vite-loader";
import { cloudflare } from "@cloudflare/vite-plugin";
import tailwindcss from "@tailwindcss/vite";
import { cn } from "cn/vite";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { defineConfig, lazyPlugins, type Plugin } from "vite-plus";

const stories = (): Plugin => {
  const id = "virtual:stories";
  const resolved = `\0${id}`;
  let directory = "src";

  const storyModules = () => {
    return readdirSync(directory, { recursive: true, encoding: "utf8" })
      .filter((file) => file.endsWith(".gleam"))
      .filter((file) => /^pub fn stories\(\)/m.test(readFileSync(join(directory, file), "utf8")))
      .map((file) => file.slice(0, -".gleam".length))
      .sort();
  };

  return {
    name: "stories",
    configResolved: (config) => {
      directory = join(config.root, "src");
    },
    resolveId: (source) => (source === id ? resolved : null),
    load: (source) => {
      if (source !== resolved) return null;
      const modules = storyModules();
      const imports = modules.map(
        (module, index) => `import * as m${index} from "gleam:${module}";`,
      );
      const entries = modules.map((module, index) => `["${module}", m${index}.stories()]`);

      return [...imports, `export const modules = () => [${entries.join(", ")}];`].join("\n");
    },
    hotUpdate({ file, modules }) {
      const module = this.environment.moduleGraph.getModuleById(resolved);
      if (!file.endsWith(".gleam") || !module) return;

      return [...modules, module];
    },
  };
};

export default defineConfig({
  plugins: lazyPlugins(() => [
    gleamImportPlugin(),
    stories(),
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
      fmt: ["gleam run --no-print-progress -m sort_classes", "vp fmt", "gleam format src test dev"],
      check: {
        command: [
          "gleam run --no-print-progress -m sort_classes -- --check",
          "gleam run --no-print-progress -m generate_icons -- update --check",
          "gleam format --check src test dev",
          "vp check",
        ],
        dependsOn: ["gleam:build", "cf:types", "cn:build"],
      },
      test: {
        command: "gleam test",
        dependsOn: ["cn:build"],
        cache: { input: [{ auto: true }, "!build/**"] },
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
        dependsOn: ["check", "test"],
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
