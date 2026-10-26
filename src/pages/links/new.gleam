import components/icons
import components/side_nav.{Item}
import features/links/link.{type Errors, type Link, Link}
import features/links/link_form
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/option.{None}
import hinoto/body.{type Body}
import layouts/base
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/context.{type Context}
import server/form
import server/middleware
import server/respond

pub fn handle(req: Request(Body), context: Context) -> Promise(Response(Body)) {
  use <- middleware.require_methods(req, [Get, Post])

  case req.method {
    Post -> {
      use fields <- form.read(req)
      let draft = link_form.draft(fields)
      use submitted <- promise.map(link_form.submit(
        context.env,
        draft,
        replacing: None,
      ))

      case submitted {
        Ok(saved) -> respond.redirect(303, link.page_path(saved.id))
        Error(errors) -> respond.html(400, view(context, draft, errors))
      }
    }
    _ -> {
      let draft = Link(id: "", name: "", url: "")

      promise.resolve(respond.html(200, view(context, draft, link.no_errors)))
    }
  }
}

fn view(context: Context, draft: Link, errors: Errors) -> Element(Nil) {
  base.document(
    "New link",
    left: [
      side_nav.view("Navigation", [
        Item("Back to top", "/", icons.fast_arrow_left),
        Item("All links", link.list_path, icons.nav_arrow_left),
      ]),
    ],
    content: [
      html.div([attribute.class("grid enter gap-y-12")], [
        html.h1([attribute.class("text-2xl font-bold")], [
          html.text("New link"),
        ]),
        link_form.view(draft, errors, "Add link"),
      ]),
    ],
    right: [],
    scripts: [context.client_entry],
  )
}
