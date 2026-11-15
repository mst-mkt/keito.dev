import components/dock
import components/icons
import components/side_nav.{Item}
import features/uuid
import gleam/bool
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/list
import hinoto/body.{type Body}
import layouts/base
import lib/ogp
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import pages/not_found
import server/context.{type Context}
import server/format.{Html, Markdown, Terminal}
import server/middleware
import server/respond

pub fn handle(
  req: Request(Body),
  context: Context,
  id: String,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use <- bool.lazy_guard(id != uuid.value, fn() {
    not_found.handle(req, context)
  })
  use format <- format.negotiate(req)

  promise.resolve(case format {
    Markdown -> respond.markdown(200, uuid.markdown())
    Terminal -> respond.text(200, uuid.text())
    Html -> respond.html(200, view(context))
  })
}

fn view(context: Context) -> Element(Nil) {
  base.document(
    uuid.value,
    left: [
      side_nav.view("Navigation", [
        Item("Back to top", "/", icons.fast_arrow_left),
      ]),
    ],
    content: [
      html.div([attribute.class("grid enter gap-y-8")], [
        html.h1([attribute.class("font-mono text-2xl font-bold break-all")], [
          html.text(uuid.value),
        ]),
        html.dl(
          [attribute.class("grid grid-cols-[auto_1fr] gap-x-6 gap-y-2")],
          list.flat_map(uuid.fields, fn(field) {
            [
              html.dt([attribute.class("text-muted")], [html.text(field.0)]),
              html.dd([attribute.class("min-w-0 wrap-break-word")], [
                html.text(field.1),
              ]),
            ]
          }),
        ),
      ]),
    ],
    right: [
      side_nav.view("Related", [
        Item("Plain text", uuid.text_path, icons.align_left),
        Item("Source post", uuid.source_path, icons.twitter),
      ]),
    ],
    dock: [
      dock.Link("Home", "/", icons.home_simple_door),
      dock.Link("Plain text", uuid.text_path, icons.align_left),
      dock.Link("Source post", uuid.source_path, icons.twitter),
    ],
    head: [
      base.canonical(uuid.page_path),
      html.link([
        attribute.rel("alternate"),
        attribute.type_("text/plain"),
        attribute.href(uuid.text_path),
      ]),
      ogp.property("og:type", "website"),
    ],
    client_entry: context.client_entry,
  )
}
