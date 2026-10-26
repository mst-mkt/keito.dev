import gleam/http/response.{type Response}
import hinoto/body.{type Body, StringBody}
import lustre/element.{type Element}

pub fn html(status: Int, document: Element(Nil)) -> Response(Body) {
  response.new(status)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_body(StringBody(element.to_document_string(document)))
}
