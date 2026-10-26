import gleam/bool
import gleam/http.{type Method, Get, Head, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import hinoto/body.{type Body}
import server/respond

pub fn apply(
  req: Request(Body),
  next: fn(Request(Body)) -> Promise(Response(Body)),
) -> Promise(Response(Body)) {
  let req = case req.method {
    Head -> request.set_method(req, Get)
    _ -> req
  }
  use <- bool.lazy_guard(req.method == Post && !same_origin(req), fn() {
    promise.resolve(respond.text(403, "Forbidden"))
  })

  next(req)
}

pub fn require_methods(
  req: Request(Body),
  allowed: List(Method),
  next: fn() -> Promise(Response(Body)),
) -> Promise(Response(Body)) {
  case list.contains(allowed, req.method) {
    True -> next()
    False -> promise.resolve(respond.method_not_allowed(allowed))
  }
}

fn same_origin(req: Request(Body)) -> Bool {
  case request.get_header(req, "origin"), request.get_header(req, "host") {
    Ok("https://" <> origin), Ok(host) | Ok("http://" <> origin), Ok(host) ->
      origin == host
    Ok(_), _ -> False
    Error(_), _ -> True
  }
}
