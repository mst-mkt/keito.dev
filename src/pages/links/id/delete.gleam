import components/button
import components/dock
import components/icons
import components/side_nav.{Item}
import features/links/link.{type Link}
import features/links/store
import gleam/http.{Get, Post}
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
  use <- middleware.require_methods(req, [Get, Post])
  use found <- promise.await(store.get(context.env, id))

  case found, req.method {
    Ok(current), Post -> {
      use _ <- promise.map(store.delete(context.env, current.id))

      respond.redirect(303, link.list_path)
    }
    Ok(current), _ -> promise.resolve(respond.html(200, view(context, current)))
    Error(_), _ -> not_found.handle(req, context)
  }
}

fn view(context: Context, current: Link) -> Element(Nil) {
  base.document(
    "Delete " <> current.name,
    left: [
      side_nav.view("Navigation", [
        Item("Back to top", "/", icons.fast_arrow_left),
        Item(
          "Back to " <> current.name,
          link.page_path(current.id),
          icons.nav_arrow_left,
        ),
      ]),
    ],
    content: [
      html.div([attribute.class("grid enter gap-y-12")], [
        html.h1([attribute.class("text-2xl font-bold break-all")], [
          html.text("Delete " <> current.name),
        ]),
        html.p([], [
          html.code([], [html.text(link.redirect_path(current.id))]),
          html.text(
            " will stop working, including QR codes that have already been shared.",
          ),
        ]),
        html.form([attribute.method("post"), attribute.class("flex gap-x-3")], [
          button.new()
            |> button.variant(button.Danger)
            |> button.view([attribute.type_("submit")], [
              icons.trash([attribute.aria_hidden(True)]),
              html.text("Delete"),
            ]),
          button.new()
            |> button.link(link.page_path(current.id), [], [html.text("Cancel")]),
        ]),
      ]),
    ],
    right: [],
    dock: [
      dock.Link("Home", "/", icons.home_simple_door),
      dock.Link(
        "Back to " <> current.name,
        link.page_path(current.id),
        icons.arrow_left,
      ),
    ],
    client_entry: context.client_entry,
  )
}
