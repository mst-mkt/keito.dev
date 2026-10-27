import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/string
import hinoto/body.{type Body}
import server/context.{type Context}
import server/middleware
import server/respond

const lines = ["User-agent: *", "Allow: /"]

pub fn handle(
  req: Request(Body),
  _context: Context,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  promise.resolve(respond.text(200, string.join(lines, "\n") <> "\n"))
}
