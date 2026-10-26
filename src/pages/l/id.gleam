import features/links/store
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import pages/not_found
import server/context.{type Context}
import server/middleware
import server/respond

pub fn handle(
  req: Request(Body),
  context: Context,
  id: String,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use found <- promise.await(store.get(context.env, id))

  case found {
    Ok(current) -> promise.resolve(respond.redirect(302, current.url))
    Error(_) -> not_found.handle(req, context)
  }
}
