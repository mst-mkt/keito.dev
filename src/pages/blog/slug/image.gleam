import features/blog/images
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import gleam/result
import gleam/string
import hinoto/body.{type Body, EmptyBody, ReadableStreamBody}
import lib/stream
import pages/not_found
import server/context.{type Context}
import server/middleware
import server/respond

const forwarded_headers = ["if-none-match", "if-modified-since"]

pub fn handle(
  req: Request(Body),
  context: Context,
  slug: String,
  path: List(String),
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  let path = string.join(path, "/")
  use listed <- promise.await(images.list(context, slug))

  case result.map(listed, list.contains(_, "./" <> path)) {
    Ok(True) -> serve(req, context, slug, path)
    _ -> not_found.handle(req, context)
  }
}

fn serve(
  req: Request(Body),
  context: Context,
  slug: String,
  path: String,
) -> Promise(Response(Body)) {
  let headers =
    list.filter(req.headers, fn(header) {
      list.contains(forwarded_headers, header.0)
    })
  use found <- promise.map(images.get(context, slug, path, headers))

  case found {
    Ok(Response(status: 304, headers:, ..)) ->
      Response(status: 304, headers:, body: EmptyBody)
    Ok(Response(status:, headers:, body:)) ->
      Response(
        status:,
        headers:,
        body: ReadableStreamBody(stream.from_fetch_body(body)),
      )
    Error(Nil) -> respond.text(503, "Service Unavailable")
  }
}
