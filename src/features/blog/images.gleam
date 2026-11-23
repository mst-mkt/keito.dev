import bindings/env
import bindings/service
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/fetch.{type FetchBody}
import gleam/http/request
import gleam/http/response.{type Response, Response}
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/result
import server/context.{type Context}

pub type Size {
  Size(width: Int, height: Int)
}

pub fn sizes(
  context: Context,
  slug: String,
) -> Promise(Result(Dict(String, Size), Nil)) {
  use found <- promise.try_await(fetch_file(context, slug, "images.json", []))

  case found {
    Response(status: 200, ..) as found -> {
      use found <- promise.map(fetch.read_text_body(found))
      use found <- result.try(result.replace_error(found, Nil))

      let size = {
        use width <- decode.field("width", decode.int)
        use height <- decode.field("height", decode.int)

        decode.success(Size(width:, height:))
      }

      json.parse(found.body, decode.dict(decode.string, size))
      |> result.replace_error(Nil)
    }
    _ -> promise.resolve(Error(Nil))
  }
}

pub fn get(
  context: Context,
  slug: String,
  path: String,
  headers: List(#(String, String)),
) -> Promise(Result(Response(FetchBody), Nil)) {
  fetch_file(context, slug, path, headers)
}

fn fetch_file(
  context: Context,
  slug: String,
  path: String,
  headers: List(#(String, String)),
) -> Promise(Result(Response(FetchBody), Nil)) {
  let req =
    request.Request(..request.new(), headers:)
    |> request.set_host("posts")
    |> request.set_path("/" <> slug <> "/" <> path)

  service.fetch(env.posts(context.env), fetch.to_fetch_request(req))
  |> promise.map(fn(sent) { Ok(fetch.from_fetch_response(sent)) })
  |> promise.rescue(fn(_) { Error(Nil) })
}
