import bindings/kv
import bindings/service

pub type Env

@external(javascript, "./env.ffi.ts", "links")
pub fn links(env: Env) -> kv.Namespace

@external(javascript, "./env.ffi.ts", "embedCache")
pub fn embed_cache(env: Env) -> kv.Namespace

@external(javascript, "./env.ffi.ts", "posts")
pub fn posts(env: Env) -> service.Service

@external(javascript, "./env.ffi.ts", "googleWalletIssuerId")
pub fn google_wallet_issuer_id(env: Env) -> String

@external(javascript, "./env.ffi.ts", "googleWalletServiceAccount")
pub fn google_wallet_service_account(env: Env) -> String

@external(javascript, "./env.ffi.ts", "googleWalletPrivateKey")
pub fn google_wallet_private_key(env: Env) -> String

@external(javascript, "./env.ffi.ts", "githubToken")
pub fn github_token(env: Env) -> String
