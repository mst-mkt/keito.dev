import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import server/context.{type Context}
import server/middleware
import server/respond

const source_url = "https://twitter.com/mimifuwacc/status/2075568279989723404"

pub fn handle(
  req: Request(Body),
  _context: Context,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  promise.resolve(respond.redirect(302, source_url))
}
