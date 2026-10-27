import { handler } from "gleam:server";
import { handler as devHandler } from "gleam:server/dev";

export default {
  fetch: import.meta.env.DEV ? devHandler("/entry/client.ts") : handler("/assets/client.js"),
} satisfies ExportedHandler<Env>;
