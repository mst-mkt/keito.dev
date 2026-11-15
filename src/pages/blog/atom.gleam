import features/blog/feed
import features/blog/store
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import server/context.{type Context}
import server/middleware
import server/respond

pub fn handle(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use posts <- promise.map(store.list(context))

  case posts {
    Ok(posts) -> respond.atom(200, feed.atom(posts))
    Error(Nil) -> respond.text(503, "Service Unavailable")
  }
}
