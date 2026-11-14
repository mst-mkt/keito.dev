import bindings/env
import features/embeds/api/cache
import features/embeds/api/remote
import features/embeds/components/github_repository.{
  type Repository, Language, Repository,
}
import gleam/dynamic/decode.{type Decoder}
import gleam/http
import gleam/http/request.{type Request}
import gleam/javascript/promise.{type Promise}
import gleam/json
import server/context.{type Context}

const query =
  "
  query($owner: String!, $name: String!) {
    repository(owner: $owner, name: $name) {
      url
      name
      owner { login }
      description
      stargazerCount
      primaryLanguage { name color }
    }
  }
"

pub fn fetch(
  context: Context,
  owner: String,
  repo: String,
) -> Promise(Result(Repository, Nil)) {
  use body <- promise.map(
    cache.get(context, "github_repository:" <> owner <> "/" <> repo, fn() {
      remote.send(graphql(context, owner, repo), remote.read_text)
    }),
  )

  cache.parse(body, decode.at(["data", "repository"], decoder()))
}

fn graphql(context: Context, owner: String, repo: String) -> Request(String) {
  let variables =
    json.object([#("owner", json.string(owner)), #("name", json.string(repo))])
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
pub fn decoder() -> Decoder(Repository) {
  use url <- decode.field("url", decode.string)
  use name <- decode.field("name", decode.string)
  use owner <- decode.subfield(["owner", "login"], decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use stars <- decode.field("stargazerCount", decode.int)
  use language <- decode.field(
    "primaryLanguage",
    decode.optional({
      use name <- decode.field("name", decode.string)
      use color <- decode.field("color", decode.string)

      decode.success(Language(name:, color:))
    }),
  )

  decode.success(Repository(
    url:,
    owner:,
    name:,
    description:,
    stars:,
    language:,
  ))
}
