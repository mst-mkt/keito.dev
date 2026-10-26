import { List, Result$Error, Result$Ok } from "gleam:prelude";

export const list = async (namespace: KVNamespace) => {
  const entries: [string, unknown][] = [];
  let cursor: string | undefined;
  do {
    const page = await namespace.list({ cursor });
    entries.push(...page.keys.map(({ name, metadata }): [string, unknown] => [name, metadata]));
    cursor = page.list_complete ? undefined : page.cursor;
  } while (cursor !== undefined);
  return List.fromArray(entries);
};

export const get = async (namespace: KVNamespace, key: string) => {
  const { value, metadata } = await namespace.getWithMetadata(key);
  return value === null ? Result$Error(undefined) : Result$Ok([value, metadata]);
};

export const put = async (
  namespace: KVNamespace,
  key: string,
  value: string,
  metadata: List<[string, string]>,
) => {
  await namespace.put(key, value, { metadata: Object.fromEntries(metadata.toArray()) });
};

export const remove = async (namespace: KVNamespace, key: string) => {
  await namespace.delete(key);
};
