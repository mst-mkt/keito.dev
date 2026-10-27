import components/button
import components/dock
import components/icons
import components/qr_code
import components/side_nav.{Item}
import features/links/link.{type Link}
import features/links/store
import gleam/http.{Get}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import hinoto/body.{type Body}
import layouts/base
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import pages/not_found
import server/context.{type Context}
import server/middleware
import server/respond

pub fn handle(
  req: Request(Body),
  context: Context,
  id: String,
) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get])
  use found <- promise.await(store.get(context.env, id))

  case found {
    Ok(current) -> promise.resolve(respond.html(200, view(context, current)))
    Error(_) -> not_found.handle(req, context)
  }
}

fn view(context: Context, current: Link) -> Element(Nil) {
  let short_url = link.short_url(current.id)

  base.document(
    current.name,
    left: [
      side_nav.view("Navigation", [
        Item("Back to top", "/", icons.fast_arrow_left),
        Item("All links", link.list_path, icons.nav_arrow_left),
      ]),
    ],
    content: [
      html.div([attribute.class("grid enter gap-y-12")], [
        html.hgroup([attribute.class("grid gap-y-1")], [
          html.h1([attribute.class("text-2xl font-bold break-all")], [
            html.text(current.name),
          ]),
          html.p([attribute.class("truncate text-sm text-subtle")], [
            html.text(link.display_url(current.url)),
          ]),
        ]),
        html.div([attribute.class("grid gap-y-3")], [
          qr_code.view(short_url, "QR code for " <> short_url),
          button.new()
            |> button.class("w-full")
            |> button.link(current.url, [], [
              icons.open_new_window([attribute.aria_hidden(True)]),
              html.text("Open link"),
            ]),
        ]),
      ]),
    ],
    right: [
      side_nav.view("Actions", [
        Item("Edit", link.edit_path(current.id), icons.edit_pencil),
        Item("Delete", link.delete_path(current.id), icons.trash),
      ]),
    ],
    dock: [
      dock.Link("Home", "/", icons.home_simple_door),
      dock.Link("All links", link.list_path, icons.list),
      dock.Link("Edit", link.edit_path(current.id), icons.edit_pencil),
      dock.Link("Delete", link.delete_path(current.id), icons.trash),
    ],
    client_entry: context.client_entry,
  )
}
