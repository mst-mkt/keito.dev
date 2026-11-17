import gleam/http.{type Method}
import gleam/http/response.{type Response}
import gleam/list
import gleam/string
import hinoto/body.{
  type Body, type JsTypedArray, EmptyBody, StringBody, TypedArrayBody,
}
import lustre/element.{type Element}

pub fn html(status: Int, document: Element(Nil)) -> Response(Body) {
  response.new(status)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(StringBody(element.to_document_string(document)))
}

pub fn text(status: Int, body: String) -> Response(Body) {
  response.new(status)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
  |> response.set_body(StringBody(body))
}

pub fn redirect(status: Int, location: String) -> Response(Body) {
  response.new(status)
  |> response.set_header("location", location)
  |> response.set_body(EmptyBody)
}

pub fn method_not_allowed(allowed: List(Method)) -> Response(Body) {
  let allow = list.map(allowed, http.method_to_string) |> string.join(", ")

  text(405, "Method Not Allowed")
  |> response.set_header("allow", allow)
}

pub fn atom(status: Int, body: String) -> Response(Body) {
  response.new(status)
  |> response.set_header("content-type", "application/atom+xml; charset=utf-8")
  |> response.set_body(StringBody(body))
}

pub fn xml(status: Int, body: String) -> Response(Body) {
  response.new(status)
  |> response.set_header("content-type", "application/xml; charset=utf-8")
  |> response.set_body(StringBody(body))
}

pub fn markdown(status: Int, body: String) -> Response(Body) {
  response.new(status)
  |> response.set_header("content-type", "text/markdown; charset=utf-8")
  |> response.set_body(StringBody(body))
}

pub fn png(status: Int, body: JsTypedArray) -> Response(Body) {
  response.new(status)
  |> response.set_header("content-type", "image/png")
  |> response.set_body(TypedArrayBody(body))
}

pub fn link(
  res: Response(Body),
  target: String,
  params: List(#(String, String)),
) -> Response(Body) {
  let value =
    list.fold(params, "<" <> target <> ">", fn(value, param) {
      value <> "; " <> param.0 <> "=\"" <> param.1 <> "\""
    })

  case response.get_header(res, "link") {
    Ok(link) -> response.set_header(res, "link", link <> ", " <> value)
    Error(Nil) -> response.set_header(res, "link", value)
  }
}

pub fn vary(res: Response(Body), header: String) -> Response(Body) {
  case response.get_header(res, "vary") {
    Error(Nil) -> response.set_header(res, "vary", header)
    Ok(vary) -> {
      let headers =
        string.split(vary, ",")
        |> list.map(fn(name) { string.lowercase(string.trim(name)) })

      case list.contains(headers, string.lowercase(header)) {
        True -> res
        False -> response.set_header(res, "vary", vary <> ", " <> header)
      }
    }
  }
}
