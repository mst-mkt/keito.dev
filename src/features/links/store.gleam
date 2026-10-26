import bindings/env.{type Env}
import bindings/kv
import features/links/link.{type Link, Link}
import gleam/bool
import gleam/dynamic/decode
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result

pub fn list(env: Env) -> Promise(List(Link)) {
  use entries <- promise.map(kv.list(env.links(env)))

  list.filter_map(entries, fn(entry) {
    decode.run(entry.1, decoder(entry.0)) |> result.replace_error(Nil)
  })
}

pub fn get(env: Env, id: String) -> Promise(Result(Link, Nil)) {
  let id = link.normalize_id(id)
  use found <- promise.map(kv.get(env.links(env), id))
  use #(_, metadata) <- result.try(found)

  decode.run(metadata, decoder(id)) |> result.replace_error(Nil)
}

pub fn save(
  env: Env,
  link: Link,
  replacing from: Option(String),
) -> Promise(Result(Nil, Nil)) {
  let namespace = env.links(env)
  use taken <- promise.await(case from == Some(link.id) {
    True -> promise.resolve(False)
    False -> promise.map(kv.get(namespace, link.id), result.is_ok)
  })

  use <- bool.guard(taken, promise.resolve(Error(Nil)))
  let metadata = [#("name", link.name), #("url", link.url)]
  use _ <- promise.await(kv.put(namespace, link.id, link.url, metadata))

  case from {
    Some(old) if old != link.id -> kv.delete(namespace, old)
    _ -> promise.resolve(Nil)
  }
  |> promise.map(Ok)
}

pub fn delete(env: Env, id: String) -> Promise(Nil) {
  kv.delete(env.links(env), id)
}

fn decoder(id: String) -> decode.Decoder(Link) {
  use name <- decode.optional_field("name", id, decode.string)
  use url <- decode.field("url", decode.string)

  decode.success(Link(id:, name:, url:))
}
