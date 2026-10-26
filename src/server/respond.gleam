import gleam/http.{type Method}
import gleam/http/response.{type Response}
import gleam/list
import gleam/string
import hinoto/body.{type Body, EmptyBody, StringBody}
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
