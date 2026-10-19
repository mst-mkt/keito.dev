import { handler } from "gleam:server";

export default {
  fetch: handler(import.meta.env.DEV ? "/entry/client.ts" : "/assets/client.js"),
} satisfies ExportedHandler<Env>;
