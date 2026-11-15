import gleam/http/response
import server/respond

pub fn link_test() {
  let res = respond.text(200, "OK")

  let result =
    res
    |> respond.link("/a", [#("rel", "alternate"), #("type", "text/markdown")])
    |> respond.link("/b", [#("rel", "sitemap")])

  assert response.get_header(result, "link")
    == Ok(
      "</a>; rel=\"alternate\"; type=\"text/markdown\", </b>; rel=\"sitemap\"",
    )
}

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
