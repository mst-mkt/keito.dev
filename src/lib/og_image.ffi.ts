import { googleFonts } from "@takumi-rs/helpers";
import { initSync, Renderer } from "@takumi-rs/wasm";
import module from "@takumi-rs/wasm/auto";

let renderer: Renderer | undefined;

const getRenderer = () => {
  if (renderer === undefined) {
    initSync({ module });
    renderer = new Renderer();
  }

  return renderer;
};

export const render = async (
  html: string,
  width: number,
  height: number,
  devicePixelRatio: number,
  font: string,
) => {
  const renderer = getRenderer();
  const prepared = await renderer.prepare(html, {
    width,
    height,
    devicePixelRatio,
    fonts: googleFonts([{ name: font, weight: [400, 500, 700] }]),
    images: { throwOnError: false },
  });

  return renderer.render(prepared);
};
