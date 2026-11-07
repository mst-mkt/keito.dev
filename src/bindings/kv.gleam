import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/javascript/array.{type Array}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, None, Some}

pub type Namespace

pub fn list(namespace: Namespace) -> Promise(List(#(String, Dynamic))) {
  list_from(namespace, do_list(namespace), [])
}

pub fn get(
  namespace: Namespace,
  key: String,
) -> Promise(Result(#(String, Dynamic), Nil)) {
  use found <- promise.map(do_get(namespace, key))
  let assert Ok(found) = decode.run(found, value_decoder())

  option.to_result(found, Nil)
}

pub fn put(
  namespace: Namespace,
  key: String,
  value: String,
  metadata: List(#(String, String)),
  ttl ttl: Option(Int),
) -> Promise(Nil) {
  let ttl = option.map(ttl, dynamic.int) |> option.unwrap(dynamic.nil())

  do_put(namespace, key, value, array.from_list(metadata), ttl)
}

@external(javascript, "./kv.ffi.ts", "remove")
pub fn delete(namespace: Namespace, key: String) -> Promise(Nil)

fn list_from(
  namespace: Namespace,
  page: Promise(Dynamic),
  keys: List(#(String, Dynamic)),
) -> Promise(List(#(String, Dynamic))) {
  use page <- promise.await(page)
  let assert Ok(#(page_keys, cursor)) = decode.run(page, page_decoder())
  let keys = list.append(keys, page_keys)

  case cursor {
    Some(cursor) -> list_from(namespace, do_list_after(namespace, cursor), keys)
    None -> promise.resolve(keys)
  }
}

fn page_decoder() -> Decoder(#(List(#(String, Dynamic)), Option(String))) {
  use keys <- decode.field("keys", decode.list(key_decoder()))
  use cursor <- decode.optional_field(
    "cursor",
    None,
    decode.optional(decode.string),
  )

  decode.success(#(keys, cursor))
}

fn key_decoder() -> Decoder(#(String, Dynamic)) {
  use name <- decode.field("name", decode.string)
  use metadata <- decode.optional_field(
    "metadata",
    dynamic.nil(),
    decode.dynamic,
  )

  decode.success(#(name, metadata))
}

fn value_decoder() -> Decoder(Option(#(String, Dynamic))) {
  use value <- decode.field("value", decode.optional(decode.string))
  use metadata <- decode.field("metadata", decode.dynamic)

  decode.success(option.map(value, fn(value) { #(value, metadata) }))
}

@external(javascript, "./kv.ffi.ts", "get")
fn do_get(namespace: Namespace, key: String) -> Promise(Dynamic)

@external(javascript, "./kv.ffi.ts", "list")
fn do_list(namespace: Namespace) -> Promise(Dynamic)

@external(javascript, "./kv.ffi.ts", "list")
fn do_list_after(namespace: Namespace, cursor: String) -> Promise(Dynamic)

@external(javascript, "./kv.ffi.ts", "put")
fn do_put(
  namespace: Namespace,
  key: String,
  value: String,
  metadata: Array(#(String, String)),
  ttl: Dynamic,
) -> Promise(Nil)
