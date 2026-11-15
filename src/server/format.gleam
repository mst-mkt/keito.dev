import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import server/accept
import server/respond
import server/user_agent

pub type Format {
  Html
  Markdown
  Terminal
}

pub fn negotiate(
  req: Request(Body),
  next: fn(Format) -> Promise(Response(Body)),
) -> Promise(Response(Body)) {
  use res <- promise.map(next(from_request(req)))

  res
  |> respond.vary("accept")
  |> respond.vary("user-agent")
}

@internal
pub fn from_request(req: Request(body)) -> Format {
  case accept.preferred(req, ["text/html", "text/markdown"]) {
    Ok("text/markdown") -> Markdown
    _ ->
      case user_agent.from_request(req) {
        user_agent.Terminal -> Terminal
        user_agent.Browser -> Html
      }
  }
}
