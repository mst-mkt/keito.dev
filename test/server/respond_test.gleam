import gleam/http/response
import server/respond

pub fn vary_test() {
  let res = respond.text(200, "OK")

  let result = res |> respond.vary("accept") |> respond.vary("user-agent")

  assert response.get_header(result, "vary") == Ok("accept, user-agent")
}

pub fn vary_duplicate_test() {
  let res = respond.text(200, "OK") |> respond.vary("user-agent")

  let result = res |> respond.vary("accept") |> respond.vary("User-Agent")

  assert response.get_header(result, "vary") == Ok("user-agent, accept")
}
