import gleam/http.{Get, Head, Post, Put}
import gleam/http/request.{type Request}
import gleam/http/response
import gleam/javascript/promise
import hinoto/body.{type Body, EmptyBody}
import server/middleware
import server/respond

fn new_request(method: http.Method) -> Request(Body) {
  request.new()
  |> request.set_method(method)
  |> request.set_host("keito.dev")
  |> request.set_header("host", "keito.dev")
  |> request.set_body(EmptyBody)
}

fn ok(_req: Request(Body)) {
  promise.resolve(respond.text(200, "OK"))
}

pub fn apply_cross_origin_post_test() {
  let req =
    new_request(Post) |> request.set_header("origin", "https://example.com")

  use res <- promise.map(middleware.apply(req, ok))

  assert res.status == 403
}

pub fn apply_same_origin_post_test() {
  let req =
    new_request(Post) |> request.set_header("origin", "https://keito.dev")

  use res <- promise.map(middleware.apply(req, ok))

  assert res.status == 200
}

pub fn apply_post_without_origin_test() {
  let req = new_request(Post)

  use res <- promise.map(middleware.apply(req, ok))

  assert res.status == 200
}

pub fn apply_head_request_test() {
  let req = new_request(Head)

  use res <- promise.map(
    middleware.apply(req, fn(req) {
      middleware.require_methods(req, [Get], fn() { ok(req) })
    }),
  )

  assert res.status == 200
}

pub fn require_methods_disallowed_method_test() {
  let req = new_request(Put)

  use res <- promise.map(
    middleware.require_methods(req, [Get, Post], fn() { ok(req) }),
  )

  assert res.status == 405
  assert response.get_header(res, "allow") == Ok("GET, POST")
}
