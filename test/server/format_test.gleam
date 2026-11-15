import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body, EmptyBody}
import server/format.{type Format, Html, Markdown, Terminal}
import server/respond

const browser = "Mozilla/5.0 (X11; Linux x86_64)"

const curl = "curl/8.11.1"

fn new_request(agent: String, accept: String) -> Request(Body) {
  request.new()
  |> request.set_header("user-agent", agent)
  |> request.set_header("accept", accept)
  |> request.set_body(EmptyBody)
}

fn respond_with(status: Int) -> fn(Format) -> Promise(Response(Body)) {
  fn(_) { promise.resolve(respond.text(status, "")) }
}

pub fn from_request_browser_test() {
  let req = new_request(browser, "text/html,application/xhtml+xml,*/*;q=0.8")

  let result = format.from_request(req)

  assert result == Html
}

pub fn from_request_terminal_test() {
  let req = new_request(curl, "*/*")

  let result = format.from_request(req)

  assert result == Terminal
}

pub fn from_request_markdown_test() {
  let req = new_request(browser, "text/markdown")

  let result = format.from_request(req)

  assert result == Markdown
}

pub fn from_request_markdown_over_terminal_test() {
  let req = new_request(curl, "text/markdown")

  let result = format.from_request(req)

  assert result == Markdown
}

pub fn negotiate_html_link_test() {
  let req = new_request(browser, "text/html") |> request.set_path("/blog")

  use res <- promise.map(format.negotiate(req, respond_with(200)))

  assert response.get_header(res, "link")
    == Ok("</blog>; rel=\"alternate\"; type=\"text/markdown\"")
}

pub fn negotiate_not_found_link_test() {
  let req = new_request(browser, "text/html")

  use res <- promise.map(format.negotiate(req, respond_with(404)))

  assert response.get_header(res, "link") == Error(Nil)
}

pub fn negotiate_markdown_link_test() {
  let req = new_request(browser, "text/markdown")

  use res <- promise.map(format.negotiate(req, respond_with(200)))

  assert response.get_header(res, "link") == Error(Nil)
}

pub fn negotiate_vary_test() {
  let req = new_request(curl, "*/*")

  use res <- promise.map(format.negotiate(req, respond_with(200)))

  assert response.get_header(res, "vary") == Ok("accept, user-agent")
}
