import bindings/env.{type Env}
import gleam/http/request
import gleam/javascript/promise.{type Promise}
import hinoto.{type JsRequest, type JsResponse}
import hinoto/runtime/workers.{type WorkersContext}
import pages/story
import server
import server/middleware
import server/router

pub fn handler(
  client_entry: String,
) -> fn(JsRequest, Env, WorkersContext) -> Promise(JsResponse) {
  use req, context <- server.serve(client_entry)

  case request.path_segments(req) {
    ["story", ..segments] -> {
      use req <- middleware.apply(req)
      story.handle(req, context, segments)
    }
    _ -> router.route(req, context)
  }
}
