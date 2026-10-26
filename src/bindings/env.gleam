import bindings/kv

pub type Env

@external(javascript, "./env.ffi.ts", "links")
pub fn links(env: Env) -> kv.Namespace
