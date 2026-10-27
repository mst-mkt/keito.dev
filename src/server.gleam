import bindings/env.{type Env}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto.{type JsRequest, type JsResponse}
import hinoto/body.{type Body}
import hinoto/runtime/workers.{type WorkersContext}
import server/context.{type Context, Context}
import server/router

pub fn handler(
  client_entry: String,
) -> fn(JsRequest, Env, WorkersContext) -> Promise(JsResponse) {
  serve(client_entry, router.route)
}

pub fn serve(
  client_entry: String,
  route: fn(Request(Body), Context) -> Promise(Response(Body)),
) -> fn(JsRequest, Env, WorkersContext) -> Promise(JsResponse) {
  fn(request, env, ctx) {
    let context = Context(env:, client_entry:)
    let serve =
      workers.serve(fn(hinoto) {
        use req <- hinoto.handle(hinoto)
        route(req, context)
      })
    serve(request, ctx)
  }
}
