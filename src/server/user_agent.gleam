import gleam/http/request.{type Request}
import gleam/list
import gleam/result
import gleam/string

pub type Client {
  Browser
  Terminal
}

const terminals = ["curl/", "wget/", "httpie/", "xh/"]

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
