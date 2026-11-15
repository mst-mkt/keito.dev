import features/blog/store
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
  slug: String,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use found <- promise.await(store.get(context, slug))

  case found {
    Ok(_) -> {
      use source <- promise.map(store.source(context, slug))

      case source {
        Ok(source) -> respond.markdown(200, source)
        Error(Nil) -> respond.text(503, "Service Unavailable")
      }
    }
    Error(Nil) -> not_found.handle(req, context)
  }
}
