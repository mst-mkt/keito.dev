import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import pages/home
import pages/not_found
import server/context.{type Context}
import server/web

pub fn route(req: Request(Body), _context: Context) -> Promise(Response(Body)) {
  case req.method, request.path_segments(req) {
    Get, [] -> web.html(200, home.view())
    _, _ -> web.html(404, not_found.view())
  }
  |> promise.resolve
}
