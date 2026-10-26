import bindings/env.{type Env}
import gleam/javascript/promise.{type Promise}
import hinoto.{type JsRequest, type JsResponse}
import hinoto/runtime/workers.{type WorkersContext}
import server/context.{Context}
import server/router

pub fn handler(
  client_entry: String,
) -> fn(JsRequest, Env, WorkersContext) -> Promise(JsResponse) {
  fn(request, env, ctx) {
    let context = Context(env:, client_entry:)
    let serve =
      workers.serve(fn(hinoto) {
        use req <- hinoto.handle(hinoto)
        router.route(req, context)
      })
    serve(request, ctx)
  }
}
