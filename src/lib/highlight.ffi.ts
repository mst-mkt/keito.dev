import { createHighlighterCore, type HighlighterCore } from "shiki/core";
import { createOnigurumaEngine } from "shiki/engine/oniguruma";

const themes = () => [
  import("shiki/themes/github-light.mjs"),
  import("shiki/themes/github-dark.mjs"),
];

const langs = () => [
  import("shiki/langs/css.mjs"),
  import("shiki/langs/diff.mjs"),
  import("shiki/langs/gleam.mjs"),
  import("shiki/langs/go.mjs"),
  import("shiki/langs/html.mjs"),
  import("shiki/langs/javascript.mjs"),
  import("shiki/langs/json.mjs"),
  import("shiki/langs/jsx.mjs"),
  import("shiki/langs/markdown.mjs"),
  import("shiki/langs/nix.mjs"),
  import("shiki/langs/nushell.mjs"),
  import("shiki/langs/perl.mjs"),
  import("shiki/langs/rust.mjs"),
  import("shiki/langs/shellscript.mjs"),
  import("shiki/langs/sql.mjs"),
  import("shiki/langs/toml.mjs"),
  import("shiki/langs/tsx.mjs"),
  import("shiki/langs/typescript.mjs"),
  import("shiki/langs/yaml.mjs"),
];

let highlighter: Promise<HighlighterCore> | undefined;

export const get = () => {
  if (highlighter === undefined) {
    highlighter = createHighlighterCore({
      themes: themes(),
      langs: langs(),
      engine: createOnigurumaEngine(import("shiki/onig.wasm?init")),
    });
  }

  return highlighter;
};

export const isLoaded = (highlighter: HighlighterCore, lang: string) => {
  return highlighter.getLoadedLanguages().includes(lang);
};

export const tokens = (highlighter: HighlighterCore, code: string, lang: string) => {
  const { tokens } = highlighter.codeToTokens(code, {
    lang,
    themes: { light: "github-light", dark: "github-dark" },
    defaultColor: "light-dark()",
  });

  return tokens;
};
