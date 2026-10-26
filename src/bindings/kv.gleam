import gleam/dynamic.{type Dynamic}
import gleam/javascript/promise.{type Promise}

pub type Namespace

@external(javascript, "./kv.ffi.ts", "list")
pub fn list(namespace: Namespace) -> Promise(List(#(String, Dynamic)))

@external(javascript, "./kv.ffi.ts", "get")
pub fn get(
  namespace: Namespace,
  key: String,
) -> Promise(Result(#(String, Dynamic), Nil))

@external(javascript, "./kv.ffi.ts", "put")
pub fn put(
  namespace: Namespace,
  key: String,
  value: String,
  metadata: List(#(String, String)),
) -> Promise(Nil)

@external(javascript, "./kv.ffi.ts", "remove")
pub fn delete(namespace: Namespace, key: String) -> Promise(Nil)
