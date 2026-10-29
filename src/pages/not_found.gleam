import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import layouts/base
import lustre/element.{type Element}
import lustre/element/html
import server/context.{type Context}
import server/respond
import server/user_agent.{Browser, Terminal}

pub fn handle(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use client <- user_agent.detect(req)

  promise.resolve(case client {
    Terminal -> respond.text(404, "Not Found")
    Browser -> respond.html(404, view(context))
  })
}

fn view(context: Context) -> Element(Nil) {
  base.document(
    "Not Found",
    left: [],
    content: [html.h1([], [html.text("Not Found")])],
    right: [],
    dock: [],
    head: [],
    client_entry: context.client_entry,
  )
}
