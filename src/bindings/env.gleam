import bindings/kv

pub type Env

@external(javascript, "./env.ffi.ts", "links")
pub fn links(env: Env) -> kv.Namespace

@external(javascript, "./env.ffi.ts", "googleWalletIssuerId")
pub fn google_wallet_issuer_id(env: Env) -> String

@external(javascript, "./env.ffi.ts", "googleWalletServiceAccount")
pub fn google_wallet_service_account(env: Env) -> String

@external(javascript, "./env.ffi.ts", "googleWalletPrivateKey")
pub fn google_wallet_private_key(env: Env) -> String
