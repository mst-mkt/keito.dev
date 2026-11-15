import gleam/javascript/promise.{type Promise}

@external(javascript, "./web_share.ffi.ts", "isSupported")
pub fn is_supported() -> Bool

@external(javascript, "./web_share.ffi.ts", "share")
pub fn share(
  title title: String,
  url url: String,
) -> Promise(Result(Nil, String))
