import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/result
import gleam/string
import hinoto/body.{type Body}

pub type Client {
  Browser
  Terminal
}

const terminals = ["curl/", "wget/", "httpie/", "xh/"]

pub fn detect(
  req: Request(Body),
  next: fn(Client) -> Promise(Response(Body)),
) -> Promise(Response(Body)) {
  use res <- promise.map(next(from_request(req)))
  response.set_header(res, "vary", "user-agent")
}

pub fn from_request(req: Request(body)) -> Client {
  let agent =
    request.get_header(req, "user-agent")
    |> result.unwrap("")
    |> string.lowercase

  case list.any(terminals, string.starts_with(agent, _)) {
    True -> Terminal
    False -> Browser
  }
}
