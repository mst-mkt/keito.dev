import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/result
import gleam/uri
import hinoto/body.{type Body}
import server/respond

pub fn read(
  req: Request(Body),
  handler: fn(List(#(String, String))) -> Promise(Response(Body)),
) -> Promise(Response(Body)) {
  use content <- promise.await(body.read_text(req.body))
  let fields =
    content |> result.replace_error(Nil) |> result.try(uri.parse_query)

  case fields {
    Ok(fields) -> handler(fields)
    Error(_) -> promise.resolve(respond.text(400, "Bad Request"))
  }
}
