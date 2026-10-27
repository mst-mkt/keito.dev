import bindings/env.{type Env}
import features/links/link.{type Draft, type Errors, type Link, Draft}
import features/links/store
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/option.{type Option}
import gleam/result

pub fn draft(fields: List(#(String, String))) -> Draft {
  let field = fn(key) { list.key_find(fields, key) |> result.unwrap("") }

  Draft(id: field("id"), name: field("name"), url: field("url"))
}

pub fn submit(
  env: Env,
  draft: Draft,
  replacing from: Option(String),
) -> Promise(Result(Link, Errors)) {
  case link.parse(draft) {
    Error(errors) -> promise.resolve(Error(errors))
    Ok(parsed) -> {
      use saved <- promise.map(store.save(env, parsed, replacing: from))

      result.replace(saved, parsed)
      |> result.replace_error(link.taken(parsed.id))
    }
  }
}
