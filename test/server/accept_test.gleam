import gleam/http/request
import gleam/http/response
import gleam/javascript/promise
import hinoto/body.{EmptyBody}
import server/accept
import server/respond

fn preferred(header: String) -> Result(String, Nil) {
  request.new()
  |> request.set_header("accept", header)
  |> accept.preferred(["text/html", "text/markdown"])
}

pub fn preferred_browser_test() {
  let header = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"

  let preferred = preferred(header)

  assert preferred == Ok("text/html")
}

pub fn preferred_markdown_test() {
  let header = "text/markdown, text/html;q=0.9"

  let preferred = preferred(header)

  assert preferred == Ok("text/markdown")
}

pub fn preferred_wildcard_test() {
  let header = "*/*"

  let preferred = preferred(header)

  assert preferred == Ok("text/html")
}

pub fn preferred_excluded_test() {
  let header = "text/html;q=0, text/markdown;q=0"

  let preferred = preferred(header)

  assert preferred == Error(Nil)
}

pub fn negotiate_vary_test() {
  let req = request.new() |> request.set_body(EmptyBody)
  let next = fn(_) {
    respond.text(200, "OK")
    |> response.set_header("vary", "user-agent")
    |> promise.resolve
  }

  use res <- promise.map(accept.negotiate(req, ["text/html"], next))

  assert response.get_header(res, "vary") == Ok("user-agent, accept")
}
