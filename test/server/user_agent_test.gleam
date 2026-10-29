import gleam/http/request.{type Request}
import gleam/http/response
import gleam/javascript/promise
import hinoto/body.{type Body, EmptyBody}
import server/respond
import server/user_agent.{Browser, Terminal}

fn new_request() -> Request(Body) {
  request.new()
  |> request.set_body(EmptyBody)
}

fn with_agent(agent: String) -> Request(Body) {
  new_request()
  |> request.set_header("user-agent", agent)
}

pub fn from_request_terminal_test() {
  let req = with_agent("curl/8.11.1")

  let result = user_agent.from_request(req)

  assert result == Terminal
}

pub fn from_request_case_insensitive_test() {
  let req = with_agent("Wget/1.25.0")

  let result = user_agent.from_request(req)

  assert result == Terminal
}

pub fn from_request_browser_test() {
  let req = with_agent("Mozilla/5.0 (X11; Linux x86_64)")

  let result = user_agent.from_request(req)

  assert result == Browser
}

pub fn from_request_without_user_agent_test() {
  let req = new_request()

  let result = user_agent.from_request(req)

  assert result == Browser
}

pub fn detect_vary_test() {
  let req = with_agent("curl/8.11.1")

  use res <- promise.map(
    user_agent.detect(req, fn(_) { promise.resolve(respond.text(200, "OK")) }),
  )

  assert response.get_header(res, "vary") == Ok("user-agent")
}
