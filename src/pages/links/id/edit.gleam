import components/dock
import components/icons
import components/side_nav.{Item}
import features/links/link.{type Draft, type Errors, type Link}
import features/links/link_form
import features/links/store
import features/links/submission
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}
import gleam/option.{Some}
import hinoto/body.{type Body}
import layouts/base
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import pages/not_found
import server/context.{type Context}
import server/form
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
      use fields <- form.read(req)
      let draft = submission.draft(fields)
      use submitted <- promise.map(submission.submit(
        context.env,
        draft,
        replacing: Some(current.id),
      ))

      case submitted {
        Ok(saved) -> respond.redirect(303, link.page_path(saved.id))
        Error(errors) ->
          respond.html(400, view(context, current, draft, errors))
      }
    }
    Ok(current), _ ->
      promise.resolve(respond.html(
        200,
        view(context, current, link.to_draft(current), link.no_errors),
      ))
    Error(_), _ -> not_found.handle(req, context)
  }
}

fn view(
  context: Context,
  current: Link,
  draft: Draft,
  errors: Errors,
) -> Element(Nil) {
  base.document(
    "Edit " <> current.name,
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
          html.text("Edit " <> current.name),
        ]),
        link_form.view(draft, errors, "Save changes"),
      ]),
    ],
    right: [
      side_nav.view("Actions", [
        Item("Delete", link.delete_path(current.id), icons.trash),
      ]),
    ],
    dock: [
      dock.Link("Home", "/", icons.home_simple_door),
      dock.Link(
        "Back to " <> current.name,
        link.page_path(current.id),
        icons.arrow_left,
      ),
      dock.Link("Delete", link.delete_path(current.id), icons.trash),
    ],
    client_entry: context.client_entry,
  )
}
