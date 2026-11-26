import components/dock
import components/icons
import components/side_nav.{Item}
import components/text_link
import features/links/link.{type Draft, type Errors}
import features/links/link_form
import features/links/submission
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
      let draft = submission.draft(fields)
      use submitted <- promise.map(submission.submit(
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
      let draft = link.empty_draft

      promise.resolve(respond.html(200, view(context, draft, link.no_errors)))
    }
  }
}

fn view(context: Context, draft: Draft, errors: Errors) -> Element(Nil) {
  base.document(
    "New link",
    og_image: base.og_image,
    left: [
      side_nav.view("Navigation", [
        Item("Back to top", "/", icons.fast_arrow_left),
        Item("All links", link.list_path, icons.nav_arrow_left),
      ]),
    ],
    content: [
      html.div([attribute.class("grid enter gap-y-8")], [
        html.h1([attribute.class("sr-only")], [html.text("New link")]),
        html.p([attribute.class("text-muted")], [
          html.text("Add a link to "),
          text_link.view(link.list_path, link.list_path),
          html.text(". It gets a short URL at "),
          html.code([attribute.class("font-mono text-sm")], [
            html.text(link.display_url(link.short_url("<id>"))),
          ]),
          html.text("."),
        ]),
        link_form.view(draft, errors, "Add link"),
      ]),
    ],
    right: [],
    dock: [
      dock.Link("Home", "/", icons.home_simple_door),
      dock.Link("All links", link.list_path, icons.list),
    ],
    head: [],
    client_entry: context.client_entry,
  )
}
