import gleam/http/request.{type Request}
import gleam/http/response
import gleam/javascript/promise
import hinoto/body.{type Body, EmptyBody}
import server/format.{Html, Markdown, Terminal}
import server/respond

fn new_request(agent: String, accept: String) -> Request(Body) {
  request.new()
  |> request.set_header("user-agent", agent)
  |> request.set_header("accept", accept)
  |> request.set_body(EmptyBody)
}

pub fn from_request_browser_test() {
  let req =
    new_request(
      "Mozilla/5.0 (X11; Linux x86_64)",
      "text/html,application/xhtml+xml,*/*;q=0.8",
    )

  let result = format.from_request(req)

  assert result == Html
}

pub fn from_request_terminal_test() {
  let req = new_request("curl/8.11.1", "*/*")

  let result = format.from_request(req)

  assert result == Terminal
}

pub fn from_request_markdown_test() {
  let req = new_request("Mozilla/5.0 (X11; Linux x86_64)", "text/markdown")

  let result = format.from_request(req)

  assert result == Markdown
}

pub fn from_request_markdown_over_terminal_test() {
  let req = new_request("curl/8.11.1", "text/markdown")

  let result = format.from_request(req)

  assert result == Markdown
}

pub fn negotiate_vary_test() {
  let req = new_request("curl/8.11.1", "*/*")

  use res <- promise.map(
    format.negotiate(req, fn(_) { promise.resolve(respond.text(200, "OK")) }),
  )

  assert response.get_header(res, "vary") == Ok("accept, user-agent")
}
