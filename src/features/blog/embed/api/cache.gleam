import bindings/env
import bindings/kv
import features/blog/embed/api/remote.{type Fetched, Failed, Found, Gone}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/option.{Some}
import gleam/result
import lib/workers_context
import plinth/javascript/date
import server/context.{type Context}

const give_up_after_ms = 2000

pub fn get(
  context: Context,
  key: String,
  fetch: fn() -> Promise(Fetched),
) -> Promise(Result(String, Nil)) {
  let namespace = env.embed_cache(context.env)
  let fetch = fn() { promise.rescue(fetch(), fn(_) { Failed }) }
  use cached <- promise.await(
    kv.get(namespace, key) |> promise.rescue(fn(_) { Error(Nil) }),
  )
  let save_later = fn(fetched) {
    fetched
    |> promise.await(save(namespace, key, _, cached: result.is_ok(cached)))
    |> workers_context.wait_until(context.ctx, _)
  }

  case cached {
    Ok(#(body, metadata)) -> {
      case is_stale(metadata, at: now()) {
        True -> save_later(fetch())
        False -> Nil
      }

      promise.resolve(non_empty(body))
    }
    Error(Nil) -> {
      let fetched = fetch()
      save_later(fetched)

      let timeout =
        promise.map(promise.wait(give_up_after_ms), fn(_) { Failed })
      use fetched <- promise.map(promise.race_list([fetched, timeout]))

      case fetched {
        Found(body) -> non_empty(body)
        Gone | Failed -> Error(Nil)
      }
    }
  }
}

pub fn parse(body: Result(String, Nil), decoder: Decoder(a)) -> Result(a, Nil) {
  use body <- result.try(body)

  json.parse(body, decoder) |> result.replace_error(Nil)
}

@internal
pub fn is_stale(metadata: Dynamic, at now: Int) -> Bool {
  decode.run(metadata, decode.at(["fetched_at"], decode.string))
  |> result.replace_error(Nil)
  |> result.try(int.parse)
  |> result.map(fn(fetched_at) { now - fetched_at > days(1) })
  |> result.unwrap(True)
}

@internal
pub fn entry(
  fetched: Fetched,
  cached cached: Bool,
) -> Result(#(String, Int), Nil) {
  case fetched, cached {
    Found(body), _ -> Ok(#(body, days(30)))
    Gone, _ -> Ok(#("", days(30)))
    Failed, True -> Error(Nil)
    Failed, False -> Ok(#("", hours(1)))
  }
}

fn hours(count: Int) -> Int {
  count * 60 * 60
}

fn days(count: Int) -> Int {
  count * hours(24)
}

fn save(
  namespace: kv.Namespace,
  key: String,
  fetched: Fetched,
  cached cached: Bool,
) -> Promise(Nil) {
  case entry(fetched, cached:) {
    Ok(#(body, ttl)) -> {
      let metadata = [#("fetched_at", int.to_string(now()))]

      kv.put(namespace, key, body, metadata, ttl: Some(ttl))
    }
    Error(Nil) -> promise.resolve(Nil)
  }
}

fn non_empty(body: String) -> Result(String, Nil) {
  case body {
    "" -> Error(Nil)
    body -> Ok(body)
  }
}

fn now() -> Int {
  date.get_time(date.now()) / 1000
}
