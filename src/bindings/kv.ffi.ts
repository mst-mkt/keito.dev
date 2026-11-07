export const list = (namespace: KVNamespace, cursor?: string) => namespace.list({ cursor });

export const get = (namespace: KVNamespace, key: string) => namespace.getWithMetadata(key);

export const put = (
  namespace: KVNamespace,
  key: string,
  value: string,
  metadata: [string, string][],
  ttl?: number,
) => namespace.put(key, value, { metadata: Object.fromEntries(metadata), expirationTtl: ttl });

export const remove = (namespace: KVNamespace, key: string) => namespace.delete(key);
