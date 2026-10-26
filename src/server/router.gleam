import gleam/http.{Get, Head}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import pages/index
import pages/not_found
import server/context.{type Context}

pub fn route(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  let req = case req.method {
    Head -> request.set_method(req, Get)
    _ -> req
  }

  case req.method, request.path_segments(req) {
    Get, [] -> index.handle(req, context)
    _, _ -> not_found.handle(req, context)
  }
}
