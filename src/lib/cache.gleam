import gleam/javascript/promise.{type Promise}
import hinoto/body.{type JsTypedArray}

@external(javascript, "./cache.ffi.ts", "get")
pub fn get(name: String, key: String) -> Promise(Result(JsTypedArray, Nil))

@external(javascript, "./cache.ffi.ts", "put")
pub fn put(
  name: String,
  key: String,
  body: JsTypedArray,
  content_type: String,
  ttl: Int,
) -> Promise(Nil)
