import bindings/env
import features/blog/embed/api/cache
import features/blog/embed/api/remote
import features/blog/embed/components/github_permalink.{
  type Lines, type Permalink, Permalink, Range, WholeFile,
}
import gleam/bool
import gleam/dynamic/decode
import gleam/http
import gleam/http/request.{type Request}
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import lib/highlight
import server/context.{type Context}

const query =
  "
  query($owner: String!, $name: String!, $expression: String!) {
    repository(owner: $owner, name: $name) {
      object(expression: $expression) {
        ... on Blob { text }
      }
    }
  }
"

pub fn fetch(
  context: Context,
  url: String,
  owner: String,
  repo: String,
  ref: String,
  path: String,
  lines: Lines,
) -> Promise(Result(Permalink, Nil)) {
  let key = "github_permalink:" <> string.join([owner, repo, ref, path], "/")
  use body <- promise.await(
    cache.get(context, key, fn() {
      remote.send(
        graphql(context, owner, repo, ref <> ":" <> path),
        remote.read_text,
      )
    }),
  )
  let selected =
    cache.parse(
      body,
      decode.at(["data", "repository", "object", "text"], decode.string),
    )
    |> result.try(select(_, lines))

  case selected {
    Ok(#(code, skip)) -> {
      use code <- promise.map(highlight.highlight(code, language(path)))
      let code = list.drop(code, skip)

      Ok(Permalink(url:, owner:, repo:, ref:, path:, lines:, code:))
    }
    Error(Nil) -> promise.resolve(Error(Nil))
  }
}

fn graphql(
  context: Context,
  owner: String,
  repo: String,
  expression: String,
) -> Request(String) {
  let variables =
    json.object([
      #("owner", json.string(owner)),
      #("name", json.string(repo)),
      #("expression", json.string(expression)),
    ])
  let body =
    json.object([#("query", json.string(query)), #("variables", variables)])

  request.new()
  |> request.set_method(http.Post)
  |> request.set_host("api.github.com")
  |> request.set_path("/graphql")
  |> request.set_header(
    "authorization",
    "Bearer " <> env.github_token(context.env),
  )
  |> request.set_header("user-agent", "mst-mkt/keito.dev")
  |> request.set_body(json.to_string(body))
}

@internal
pub fn select(text: String, lines: Lines) -> Result(#(String, Int), Nil) {
  let text = trim_newline(text)

  case lines {
    WholeFile -> Ok(#(text, 0))
    Range(start:, end:) -> {
      let head = string.split(text, "\n") |> list.take(end)
      use <- bool.guard(list.length(head) < end, Error(Nil))

      Ok(#(string.join(head, "\n"), start - 1))
    }
  }
}

fn trim_newline(text: String) -> String {
  case string.ends_with(text, "\n") {
    True -> string.drop_end(text, 1)
    False -> text
  }
}

@internal
pub fn language(path: String) -> String {
  let file_name = string.split(path, "/") |> list.last |> result.unwrap(path)
  let extension = case string.split(file_name, ".") |> list.reverse {
    [extension, _, ..] -> string.lowercase(extension)
    _ -> ""
  }

  case extension {
    "pl" | "pm" -> "perl"
    "patch" -> "diff"
    extension -> extension
  }
}
