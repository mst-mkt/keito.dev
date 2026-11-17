import { Result$Error, Result$Ok } from "gleam:prelude";

export const get = async (name: string, key: string) => {
  const cache = await caches.open(name);
  const found = await cache.match(key);
  if (found === undefined) return Result$Error(undefined);

  const body = await found.arrayBuffer();
  return Result$Ok(new Uint8Array(body));
};

export const put = async (
  name: string,
  key: string,
  body: Uint8Array<ArrayBuffer>,
  contentType: string,
  ttl: number,
) => {
  const cache = await caches.open(name);
  const headers = { "content-type": contentType, "cache-control": `max-age=${ttl}` };
  await cache.put(key, new Response(body, { headers }));
};
