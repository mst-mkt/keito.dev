import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import layouts/base
import lustre/element.{type Element}
import lustre/element/html
import server/context.{type Context}
import server/respond

pub fn handle(
  _req: Request(Body),
  _context: Context,
) -> Promise(Response(Body)) {
  promise.resolve(respond.html(404, view()))
}

fn view() -> Element(Nil) {
  base.document(
    "Not Found",
    left: [],
    content: [html.h1([], [html.text("Not Found")])],
    right: [],
    scripts: [],
  )
}
